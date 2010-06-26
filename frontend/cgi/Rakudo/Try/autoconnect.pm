use strict;
use warnings;

use Rakudo::Try::Session qw(new fail -errors);

use constant SESSION => Session::new(logging => LOGGING)
	->connect(DB_SOURCE, DB_USER, DB_PASS, { PrintError => 0 });

BEGIN {
	Session::fail(undef, 503, 'Could not connect to database')
		if not defined SESSION;
}

END { SESSION->disconnect if defined SESSION; }

package Rakudo::Try::autoconnect;

use constant SESSION => ::SESSION;

my %actions = (
	'-create-session' => \&create_session,
	'-check-session' => \&check_session
);

sub import {
	shift;
	$actions{$_}->() for @_;
};

sub SESSION_fail_404 {
	my $msg = shift;
	SESSION->fail(404, 'Illegal session-id',
		'You will shortly be redirected to a fresh session',
		-refresh=>'5; '.SESSION->root)
}

sub check_session {
	my $create_session = shift;

	if(not SESSION->has_id) {
		SESSION_fail_404('Illegal session-id')
			if (SESSION->has_query_string or not $create_session);

		(SESSION->create and SESSION->redirect('/'))
			or SESSION->fail(500, 'Could not create session');
	}

	if(not defined SESSION->status(1)) {
		SESSION->fail(500, 'Could not read database')
			if SESSION->errno == Session::EDB;

		SESSION_fail_404('Unknown session-id')
			if SESSION->errno == Session::EID;

		SESSION->fail(500, 'Could not read session data due to an '.
			'unexpected error condition');
	}
}

sub create_session {
	check_session(1);
}

1;
