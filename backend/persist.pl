use warnings;
use strict;
use POE qw(Component::Server::TCP);
use Time::HiRes qw(time);

my @perl6 = [
             '/Users/john/Projects/rakudo/parrot_install/bin/perl6',
             '/Users/john/Projects/try.rakudo.org/backend/p6safe.pl'
            ];
            
if (-e -x $perl6[0] && -e -x $perl6[1]) {
    die "Fix executable's for the Rakudo Eval daemon to function properly.";
}

{    
    package P6Interp;
    use Time::HiRes qw(time);
    use IPC::Run qw(harness timeout kill_kill);
    
    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
        
        $self->{in} = $self->{out} = $self->{err} = '';
        $self->{timer} = timeout 15;
        
        my $h;
        eval {
            $h = harness @perl6, \$self->{in}, \$self->{out}, $self->{timer}
                or die "perl6 died: $?";
            
            $self->{p6interp} = \$h;
            
            $self->{timer}->start( 15 );
            $h->start;
            
            $h->pump until $self->{out} =~ />\s/m;
            $self->{out} = '';
        };
        if ( $@ ) {
            my $x = $@;   ## Preserve $@ in case another exception occurs
            kill_kill $h; ## kill it gently, then brutally if need be, or just
                          ## brutally on Win32.
            die $x;
        }
        
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
  Alias       => "rakudo_eval",
  Port        => 11211,
  ClientInput => sub {
      my ($heap, $input) = @_[HEAP, ARG0];
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
          $heap->{client}->put("=>");
      };
      if ( $@ ) {
          $heap->{client}->put("ERROR: $@");
      }
  }
);

$poe_kernel->run();
exit 0;

package Server;

our $storage = {};

