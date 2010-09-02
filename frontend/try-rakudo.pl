#!/usr/bin/perl
use strict;
use warnings;
use mro 'c3';
use encoding 'utf8';

# Web Requirements
use Mojolicious::Lite;
use Mojo::Server::CGI;
use Mojo::JSON;
use IO::Socket;
use Digest::SHA1 qw(sha1_hex);

# Requirements for running the commands
use File::Temp qw(tempfile);
use IPC::Run qw(run timeout);

my $perl6 = '/Users/john/Projects/rakudo/parrot_install/bin/perl6'; 
my $in_txt = '/Users/john/Projects/try.rakudo.org/frontend/data/input_text.txt';

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
            print $remote "id<$id> $input\n";
            while (<$remote>) {
                app->log->debug("id<$id> received: $input");
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
        return $self->render_json({stdout => $result, stdin => $self->param('input')});
    }
};

app->start;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
