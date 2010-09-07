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
                         session => $self->session->{sess_id}, 
                         txt => $txt);
};

get '/cmd' => sub {
    my $self = shift;
    my $result = '';
    $self->session(sess_id => sha1_hex(time + rand)) 
        unless $self->session('sess_id');
    
    eval {
        my $remote = IO::Socket::INET->new(
                Proto    => "tcp",
                PeerAddr => "localhost",
                PeerPort => 11211)
            or die "Cannot connect to Rakudo Eval Server";
        $remote->autoflush(1);
        $remote->timeout( 15 );
        
        my $input = $self->param('input');
        my $id = $self->session->{sess_id};
        my $end = qr/>>$id<</;

        eval {
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
        };
        if ($@) { 
            app->log->warn("Got an error, $! $@");
        }
        close $remote;
    };
    if ($@) {
        app->log->warn("Got an error, $! $@");
        return $self->render_json({error => $@});
    }
    else {
        my $escaped_result = Mojo::ByteStream->new(decode('utf8' => $result));
        return $self->render_json({stdout => $escaped_result->xml_escape->to_string, 
                                   stdin => $self->param('input')});
    }
};

app->start;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
