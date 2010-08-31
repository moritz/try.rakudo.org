# This program is a simple unix socket client.  It will connect to the
# UNIX socket specified by $rendezvous.  This program is written to
# work with the UnixServer example in POE's cookbook.  While it
# touches upon several POE modules, it is not meant to be an
# exhaustive example of them.  Please consult "perldoc [module]" for
# more details.
use strict;
use warnings;
use Socket qw(AF_UNIX);
use POE;                          # For base features.
use POE::Wheel::SocketFactory;    # To create sockets.
use POE::Wheel::ReadWrite;        # To read/write lines with sockets.
use POE::Wheel::ReadLine;         # To read/write lines on the console.

use IO::Socket;

my $remote = IO::Socket::INET->new(
		Proto    => "tcp",
		PeerAddr => "localhost",
		PeerPort => 11211,
	    )
	  or die "cannot connect to Rakudo Eval Server port at localhost";

$remote->autoflush(1);

my $id = int(rand(100));

POE::Session->create(
  inline_states => {
    _start => \&start_cli,
    cli_input      => \&console_input,
  },
);

$poe_kernel->run();
exit 0;

sub start_cli {
  my ($heap, $socket) = @_[HEAP, ARG0];
  delete $heap->{connect_wheel};
  print "My id is: $id\n";
  $heap->{cli_wheel} = POE::Wheel::ReadLine->new(InputEvent => 'cli_input');
  $heap->{cli_wheel}->get("=> ");
}

sub console_input {
  my ($heap, $input, $exception) = @_[HEAP, ARG0, ARG1];
  if (defined $input) {
    print $remote "id<$id> $input\n";

    my $done = 0;
    while (<$remote>) {
        print;
    }
  }
  elsif ($exception eq 'cancel') {
    $heap->{cli_wheel}->put("Canceled.");
  }
  else {
    $heap->{cli_wheel}->put("Bye.");
    delete $heap->{cli_wheel};
    delete $heap->{io_wheel};
    return;
  }

  # Prompt for the next bit of input.
  $heap->{cli_wheel}->get("=> ");
}
