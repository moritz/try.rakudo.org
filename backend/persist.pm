use warnings;
use strict;
use POE qw(Component::Server::TCP);
use POE;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use IPC::Run qw(harness start kill_kill pump timeout finish);
use v5.12;

my $perl6 = '/Users/john/Projects/rakudo/parrot_install/bin/perl6';

{    
    package P6Interp;
    use Moose;
    use IPC::Run qw(harness timeout kill_kill);
    
    has 'p6interp' => (is => 'rw');
    
    sub BUILD {
        my ($self) = @_;
        
        $self->{in} = $self->{out} = $self->{err} = '';
        
        my $in = q<
my $*ARGFILES = open '/Users/john/Projects/try.rakudo.org/frontend/data/input_text.txt';
module Safe { 
    our sub forbidden(*@a, *%h) { die "Operation not permitted in safe mode" };
    &GLOBAL::open   := &forbidden;
    &GLOBAL::run    := &forbidden;
    &GLOBAL::slurp  := &forbidden;
    &GLOBAL::unlink := &forbidden;
    &GLOBAL::dir    := &forbidden;
    # Add Socket;
    Q:PIR {
        $P0 = get_hll_namespace
        $P1 = get_hll_global ['Safe'], '&forbidden'
        $P0['!qx']  = $P1
        null $P1
        set_hll_global ['IO'], 'Socket', $P1
    }; };
}
use FORBID_PIR;
>;
        $self->{timer} = timeout 15;
        
        my $h;
        eval {
            $h = harness [$perl6], \$self->{in}, \$self->{out}, \$self->{err}, $self->{timer}
                or die "perl6 died: $?";
            
            $self->{p6interp} = \$h;
            $h->start;
            $h->pump until ! length $self->{in};

            $h->pump until $self->{out} =~ /\n>\s/;
            $self->{out} = '';
        };
        if ( $@ ) {
            my $x = $@;    ## Preserve $@ in case another exception occurs
            kill_kill $h; ## kill it gently, then brutally if need be, or just
                       ## brutally on Win32.
            die $x;
        }
        # $self->{in} = q<my $*ARGFILES = open '/Users/john/Projects/try.rakudo.org/frontend/data/input_text.txt';>;
    }
    
    sub gather_result {
        my ($self) = shift;
        my $interp = $self->{p6interp};
        eval {
            ($$interp)->pump until $self->{out} =~ /\n>\s/m;
        };
        if ( $@ ) {
            die "failed to gather a result $@";
        }
    }
    
    sub send {
        my ($self, $command) = @_;
        my $interp = $self->{p6interp};
        $self->{timer}->start( 15 );

        $self->{in} = $command . "\n";
        pump $$interp while length $self->{in};
        $self->gather_result;
        
        my $result = $self->{out};
        $self->{out} = '';
        
        $result =~ s/\n>\s//m;
        
        
        return $result;
    }
    
    sub stop {
        my ($self) = shift;
        $self->{p6interp}->kill;
    }
    
    no Moose;
}

# Start a server, and run it until it's done.
Server::spawn('/tmp/poe-unix-socket');

$poe_kernel->run();
exit 0;
###############################################################################
# The UNIX socket server.
package Server;
use POE::Session;    # For KERNEL, HEAP, etc.
use Socket;          # For PF_UNIX.

# Spawn a UNIX socket server at a particular rendezvous.  jinzougen
# says "rendezvous" is a UNIX socket term for the inode where clients
# and servers get together.  Note that this is NOT A POE EVENT
# HANDLER.  Rather it is a plain function.
sub spawn {
    my $rendezvous = shift;
    POE::Session->create(
        inline_states => {
            _start     => \&server_started,
            got_client => \&server_accepted,
            got_error  => \&server_error,
        },
        heap => {rendezvous => $rendezvous,},
    );
}

# The server session has started.  Create a socket factory that
# listens for UNIX socket connections and returns connected sockets.
# This unlinks the rendezvous socket
sub server_started {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    unlink $heap->{rendezvous} if -e $heap->{rendezvous};
    $heap->{server} = POE::Wheel::SocketFactory->new(
        SocketDomain => PF_UNIX,
        BindAddress  => $heap->{rendezvous},
        SuccessEvent => 'got_client',
        FailureEvent => 'got_error',
    );
}

# The server encountered an error while setting up or perhaps while
# accepting a connection.  Register the error and shut down the server
# socket.  This will not end the program until all clients have
# disconnected, but it will prevent the server from receiving new
# connections.
sub server_error {
    my ($heap, $syscall, $errno, $error) = @_[HEAP, ARG0 .. ARG2];
    $error = "Normal disconnection." unless $errno;
    warn "Server socket encountered $syscall error $errno: $error\n";
    delete $heap->{server};
}

# The server accepted a connection.  Start another session to process
# data on it.
sub server_accepted {
    my $client_socket = $_[ARG0];
    ServerSession::spawn($client_socket);
}
###############################################################################
# The UNIX socket server session.  This is a server-side session to
# handle client connections.
package ServerSession;
use POE::Session;    # For KERNEL, HEAP, etc.

# Spawn a server session for a particular socket.  Note that this is
# NOT A POE EVENT HANDLER.  Rather it is a plain function.
sub spawn {
    my $socket = shift;
    POE::Session->create(
        inline_states => {
            _start           => \&server_session_start,
            got_client_input => \&server_session_input,
            got_client_error => \&server_session_error,
        },
        args => [$socket],
    );
}

# The server session has started.  Wrap the socket it's been given in
# a ReadWrite wheel.  ReadWrite handles the tedious task of performing
# buffered reading and writing on an unbuffered socket.
sub server_session_start {
    my ($heap, $socket) = @_[HEAP, ARG0];
    warn 'test';
    $heap->{client} = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        InputEvent => 'got_client_input',
        ErrorEvent => 'got_client_error',
    );
    $heap->{interp} = P6Interp->new;
}

# The server session received some input from its attached client.
# Echo it back.
sub server_session_input {
    my ($heap, $input) = @_[HEAP, ARG0];
    warn 'b';
    eval {
        $heap->{client}->put("testing...");
        my $result = $heap->{interp}->send($input);
        $heap->{client}->put($result);
    };
    if ( $@ ) {
        $heap->{client}->put("ERROR: $@");
    }
}

# The server session received an error from the client socket.  Log
# the error and shut down this session.  The main server remains
# untouched by this.
sub server_session_error {
    my ($heap, $syscall, $errno, $error) = @_[HEAP, ARG0 .. ARG2];
    $error = "Normal disconnection." unless $errno;
    warn "Server session encountered $syscall error $errno: $error\n";
 
    $heap->{interp}->stop() if ($heap->{interp});

    delete $heap->{client};
}
