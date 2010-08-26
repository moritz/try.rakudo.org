use warnings;
use strict;
use POE qw(Component::Server::TCP);
use Time::HiRes qw(time);
use v5.12;

my $perl6 = '/Users/john/Projects/rakudo/parrot_install/bin/perl6';

{    
    package P6Interp;
    use Time::HiRes qw(time);
    use IPC::Run qw(harness timeout kill_kill);
    
    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
        
        $self->{in} = $self->{out} = $self->{err} = '';
        
        # my $in = q<my $*ARGFILES = open '/Users/john/Projects/try.rakudo.org/frontend/data/input_text.txt'; module Safe { our sub forbidden(*@a, *%h) { die "Operation not permitted in safe mode" }; &GLOBAL::open := &forbidden; &GLOBAL::run := &forbidden; &GLOBAL::slurp := &forbidden; &GLOBAL::unlink := &forbidden; &GLOBAL::dir := &forbidden; }; use FORBID_PIR;>;
#     # Add Socket;
#     Q:PIR {
#         $P0 = get_hll_namespace
#         $P1 = get_hll_global ['Safe'], '&forbidden'
#         $P0['!qx']  = $P1
#         null $P1
#         set_hll_global ['IO'], 'Socket', $P1
#     }; };
# }
#>;
        $self->{timer} = timeout 15;
        
        my $h;
        eval {
            $h = harness [$perl6], \$self->{in}, \$self->{out}, $self->{timer}
                or die "perl6 died: $?";
            
            $self->{p6interp} = \$h;
            # $self->{in} = $in;
            
            $h->start;
            $self->{timer}->start( 15 );
            
            $h->pump until $self->{out} =~ />\s/m;
            $self->{out} = '';
        };
        if ( $@ ) {
            my $x = $@;    ## Preserve $@ in case another exception occurs
            kill_kill $h; ## kill it gently, then brutally if need be, or just
                       ## brutally on Win32.
            die $x;
        }
        
        warn 'made a new p6interp';
        # $self->{in} = q<my $*ARGFILES = open '/Users/john/Projects/try.rakudo.org/frontend/data/input_text.txt';>;
        
        bless ($self, $class);
        return $self;
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
        
        $self->{time} = time; 
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

POE::Component::Server::TCP->new(
  Alias       => "echo_server",
  Port        => 11211,
  ClientInput => sub {
      my ($heap, $input) = @_[HEAP, ARG0];
      warn 'yo!';
      eval {
          my $ssid;
          $input =~ /^id<(.+)>/m;
          $ssid = $1;
          $input =~ s/^id<(.+)>\s//m;
          unless ($Server::storage->{$ssid}) {
              $Server::storage->{$ssid} = P6Interp->new;
          }
          if ($input) {
              my $result = $Server::storage->{$ssid}->send($input);
              $heap->{client}->put($result);
          }
          warn 'done evaling... ' . ref($heap->{client});
          $heap->{client}->put("=>");
      };
      if ( $@ ) {
          $heap->{client}->put("ERROR: $@");
      }
  }
);

$poe_kernel->run();
exit 0;
###############################################################################
# The UNIX socket server.
package Server;
use POE::Session;    # For KERNEL, HEAP, etc.

our $storage = {};

