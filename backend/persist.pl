#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;
use autodie;

use Encode;
use Date::Format;
use POE qw(Component::Server::TCP);
use Time::HiRes qw(time);

use constant backend_dir => '.';
use constant {
    default_cmd => 'perl6 p6safe.pl',
    config_file => backend_dir . '/backend.conf',
    pid_file    => backend_dir . '/persist.pid',
};

sub file_contents {
    my $file = shift;

    return undef unless -e $file;
    open(my $fh, '<', $file);
    chomp(my $line = <$fh>);
    $line =~ s/^\s+//;

    return $line;
}

my $started = 0;
my $timeout = 60 * 10; # in seconds

if ( my $pid = file_contents(pid_file) ) {
    die "REPL server already started as PID $pid" if kill(0, $pid);
}

{
    open(my $pid_fh, '>', pid_file);
    say {$pid_fh} $$;
}

$started = 1;

END {
    unlink(pid_file) if $started;
}

# backend.conf should be a single line containing the perl6 command to use.
# The default might work for you though.
my $perl6_cmd = default_cmd;
if ( my $config = file_contents(config_file) ) {
    $perl6_cmd = $config;
}

{
    package P6Interp;
    use IO::Pty::HalfDuplex;

    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};

        my $pty;
        eval {
            $pty = IO::Pty::HalfDuplex->new;
            $pty->spawn($perl6_cmd);

            while (my $result = $pty->recv(5)) {
                if ($result =~ />\s$/){
                    last;
                }
            }

            $self->{p6interp} = $pty;
        };
        if ( $@ ) {
            die $@;
        }

        bless ($self, $class);
        return $self;
    }

    sub gather_result {
        my $self = shift;
        my $result = '';
        eval {
            while (1) {
                my $recv = $self->{p6interp}->recv(15);
                unless (defined $recv) {
                    $result .= "Rakudo REPL has timed out... reaping.\n";
                    if ($self->{p6interp}->is_active) {
                        $self->stop;
                    }
                    last;
                }

                if ($recv =~ /\n>\s$/m){
                    $recv =~ s/\n>\s$//mg;
                    $result .= $recv . "\n";
                    last;
                }
                else {
                    $result .= $recv . "\n";
                }

                if (!$self->{p6interp}->is_active) {
                    $result .= "Rakudo REPL has closed... restarting.\n";
                    last;
                }
            }
        };
        if ($@) {
            die "failed to gather a result $@";
        }

        # Remove script filename from error output (let the user think its a buffer)
        $result =~ s[\(.*backend/p6safe\.pl:(\d+)\)$][\(line $1\)];

        return $result;
    }

    sub send {
        my ($self, $command) = @_;
        if (!$self->{p6interp}->is_active) {
            my $pty = IO::Pty::HalfDuplex->new;
            $pty->spawn($perl6_cmd);

            while (my $result = $pty->recv(15)) {
                unless (defined $result) {
                    return "REPL Timeout... trying to reboot.\n";
                }
                if ($result =~ />\s$/){
                    last;
                }
            }

            $self->{p6interp} = $pty;
        }
        $self->{time} = time + $timeout;
        $self->{p6interp}->write($command . "\n");
        my $result = $self->gather_result;
        return $result;
    }

    sub stop {
        my $self = shift;

        $self->{p6interp}->kill;
    }

    1;
}

{
    package Server;
    our $storage = {};
    1;
}

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->delay(tick => 15);
        },

        tick => sub {
            while (my ($k, $v) = each %$Server::storage) {
                my $last_used = $v->{time};

                if ($v->{time} && $v->{time} < time) {
                    $v->stop;
                    delete $Server::storage->{$k};
                }
            }
            $_[KERNEL]->delay(tick => 15);
        }
    },
);

POE::Component::Server::TCP->new(
    Alias       => 'rakudo_eval',
    Port        => 11211,
    ClientInput => sub {
        my ($heap, $input) = @_[HEAP, ARG0];
        warn time2str('%Y-%m-%d %T', time) . " Received input: '$input'";
        eval {
            my $ssid;
            $input =~ /^id<([^>]+)>\s/m;
            $ssid = $1;
            $input =~ s/^id<([^>]+)>\s//m;

            $Server::storage->{$ssid} ||= P6Interp->new;

            if ($input) {
                my $result = $Server::storage->{$ssid}->send($input);
                $heap->{client}->put($result);
            }
            $heap->{client}->put(">>$ssid<<");
        };
        if ( $@ ) {
            $heap->{client}->put("ERROR: $@");
        }
    }
);

POE::Kernel->run();

exit 0;
