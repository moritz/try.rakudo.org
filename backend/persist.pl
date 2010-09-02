use warnings;
use strict;
use POE;
use POE qw(Component::Server::TCP);
use Time::HiRes qw(time);
use encoding 'utf8';

my $timeout = 60 * 10; # in seconds

open(my $cfg, '<', '.config') or die $!;

my $perl6;
while (<$cfg>) {
    $_ =~ s/^\s+//;
    $_ =~ s/\s+$//;
    
    $perl6 = $_;
}

{    
    package P6Interp;
    use Time::HiRes qw(time);
    use IO::Pty::HalfDuplex;
    
    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
        
        my $pty;
        eval {
            $pty = IO::Pty::HalfDuplex->new;
            $pty->spawn($perl6);
            
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
        my ($self) = shift;
        my $result = '';
        eval {
            while (my $recv = $self->{p6interp}->recv(5)) {
                if ($recv =~ /\n>\s$/m){
                    $recv =~ s/\n>\s$//m;
                    $result .= $recv . "\n";
                    last;
                } 
                else {
                    $result .= $recv . "\n";
                }
                if (!$self->{p6interp}->is_active) {
                    $result .= "Rakudo REPL has closed... restarting\n";
                }
            }
        };
        if ( $@ ) {
            die "failed to gather a result $@";
        }
        
        if (!$self->{p6interp}->is_active) {
            $result .= "Rakudo REPL has closed... restarting\n";
        }
        return $result;
    }
    
    sub send {
        my ($self, $command) = @_;
        if (!$self->{p6interp}->is_active) {
            my $pty = IO::Pty::HalfDuplex->new;
            $pty->spawn($perl6);
            
            while (my $result = $pty->recv(5)) {
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
        my ($self) = shift;
        
        eval {
            $self->{p6interp}->kill;
        };
        if ($@) {
            die "$@";
        }
    }
}

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->delay(tick => 15);
        },
        
        tick => sub {
            while (my ($k, $v) = each %$Server::storage) {
                my $last_used = $v->{time};
                
                if ($v->{time} < time) {
                    $v->stop;
                    delete $Server::storage->{$k};
                }
            }
            $_[KERNEL]->delay(tick => 15);
        }
    },
);

POE::Component::Server::TCP->new(
  Alias       => "rakudo_eval",
  Port        => 11211,
  ClientInput => sub {
      my ($heap, $input) = @_[HEAP, ARG0];
      warn "Got inpur: $input";
      eval {
          my $ssid;
          $input =~ /^id<([^>]+)>\s/m;
          $ssid = $1;
          $input =~ s/^id<([^>]+)>\s//m;
          unless ($Server::storage->{$ssid}) {
              $Server::storage->{$ssid} = P6Interp->new;
          }
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

package Server;

our $storage = {};

