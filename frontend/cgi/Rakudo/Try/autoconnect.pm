package Rakudo::Try::autoconnect;

use strict;
use warnings;

use Rakudo::Try::Session;
use Rakudo::Try::config;

sub fail_msg { (shift)."\n".
	'Try again later or bug someone on #perl6 at irc.freenode.net' }

sub refresh_msg { (shift)."\n".
	'You will shortly be redirected to a fresh session' }

my $session;

BEGIN {
	$session = Session_PROTO->clone->init;
	$session->connect(DB_SOURCE, DB_USER, DB_PASS)
		or $session->die(503, fail_msg('Could not connect to database'));
}

END { $session->disconnect }

my %actions = (
	':fail-on-EID' => sub {
		$session->die(404, fail_msg('Illegal session-id'))
			if $session->errno == Session_EID;
	},

	':refresh-on-EID' => sub {
		$session->die(404, refresh_msg('Illegal session-id'),
			-refresh => REFRESH_TIMEOUT.'; '.$session->root)
			if $session->errno == Session_EID;
	},

	':create-session' => sub {
		($session->create and $session->redirect('/')
			or $session->die(500, fail_msg('Could not create session')))
			if not $session->has_id;
	},

	':load-status' => sub {
### TODO
#	if(not defined SESSION->status(1)) {
#		SESSION->fail(500, 'Could not read database')
#			if SESSION->errno == Session::EDB;
#
#		SESSION_fail_404('Unknown session-id')
#			if SESSION->errno == Session::EID;
#
#		SESSION->fail(500, 'Could not read session data due to an '.
#			'unexpected error condition');
#	}
	}
);

sub import {
	shift;
	$actions{$_}->() for @_;

	{
		no strict 'refs';
		*{(caller).'::SESSION'} = \&SESSION;
	}
}

sub SESSION { $session }

1;
