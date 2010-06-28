package Rakudo::Try::autoconnect;

use strict;
use warnings;

use Rakudo::Try::Session;
use Rakudo::Try::config;

our $VERSION = '0.01';

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
	':create-session' => sub {
		$session->errno = 0;
		($session->create and $session->redirect('/')
			or $session->die(500, fail_msg('Could not create session')))
			if not $session->has_id;
	},

	':load-status' => sub {
		$session->die(400, fail_msg('Missing session-id'))
			if not $session->has_id;
		$session->errno = 0;
		$session->die(500, fail_msg('Could not read session data'))
			if (not defined $session->status(1) and
				$session->errno != Session_EUNKNOWN);
	},

	':fail-on-EID' => sub {
		$session->die(404, fail_msg('Illegal session-id'))
			if $session->errno == Session_EID;
	},

	':refresh-on-EID' => sub {
		$session->die(404, refresh_msg('Illegal session-id'),
			-refresh => REFRESH_TIMEOUT.'; '.$session->root)
			if $session->errno == Session_EID;
	},

	':fail-on-EUNKNOWN' => sub {
		$session->die(404, fail_msg('Unknown session-id'))
			if $session->errno == Session_EUNKNOWN;
	},

	':refresh-on-EUNKNOWN' => sub {
		$session->die(404, refresh_msg('Unknown session-id'),
			-refresh => REFRESH_TIMEOUT.'; '.$session->root)
			if $session->errno == Session_EUNKNOWN;
	}
);

sub import {
	shift;
	$actions{$_}->() for @_;

	{
		no strict 'refs';
		*{(caller).'::Session'} = \&Session;
	}
}

sub Session { $session }

1;
