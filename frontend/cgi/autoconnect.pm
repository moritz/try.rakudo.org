use strict;
use warnings;

use Session;

use constant SESSION => Session
	->new(logging=>1)
	->connect('dbi:mysql:try_rakudo', 'root', '', { PrintError=>0 });

END { SESSION->disconnect if defined SESSION; }

1;
