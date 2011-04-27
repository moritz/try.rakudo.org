#!/usr/bin/perl
use strict;
use warnings;
use Encode;
use Mojolicious::Lite;
use Mojo::JSON;
use IO::Socket;
use Digest::SHA1 qw(sha1_hex);

get '/shell' => sub {
    my $self = shift;
    return $self->redirect_to('http://try.rakudo.org/');
};

get '/' => sub {
    my $self = shift;
    my $txt = $self->param('input');

    $self->session(sess_id => sha1_hex(time + rand))
        unless $self->session('sess_id');

    return $self->render(template => 'shell',
                         txt => $txt);
};

get '/cmd' => sub {
    my $self = shift;
    my $result = '';
    $self->session(sess_id => sha1_hex(time + rand))
        unless $self->session('sess_id');

    my %errors = (
        connect => 'Cannot connect to Rakudo eval server',
        timeout => "Timeout, operation took too long.\n",
    );

    eval {
        my $remote = IO::Socket::INET->new(
                Proto    => 'tcp',
                PeerAddr => 'localhost',
                PeerPort => 11211
        ) or die "$errors{connect}: $@";
        $remote->autoflush(1);

        my $input = $self->param('input');
        my $id = $self->session->{sess_id};
        my $end = qr/>>$id<</;

        local $SIG{ALRM} = sub { die $errors{timeout} };
        alarm 30;
        $input =~ s/\n//m;
        my $msg = "id<$id> $input\n";
        print $remote encode('utf8' => $msg);
        while (<$remote>) {
            app->log->debug($msg);
            $_ =~ s/^[ ]+//;
            $_ =~ s/[ ]+$//;
            last if m/$end/;
            $result .= $_;
        }
        alarm 0;

        close $remote;
    };
    if ($@) {
        app->log->debug("Timeout!, $!") if $@ eq $errors{timeout};
        app->log->warn("Got an error, $! $@");
        my $escaped_error  = Mojo::ByteStream->new($@);
        my $escaped_result = Mojo::ByteStream->new(decode('utf8' => $result));
        return $self->render_json({error  => $escaped_error->xml_escape->to_string,
                                   stdout => $escaped_result->xml_escape->to_string,
                                   stdin  => $self->param('intput')});
    }
    else {
        my $escaped_result = Mojo::ByteStream->new(decode('utf8' => $result));
        return $self->render_json({stdout => $escaped_result->xml_escape->to_string,
                                   stdin  => $self->param('input')});
    }
};

app->start;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
