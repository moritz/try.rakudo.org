package Rakudo::Try::autoconnect;

use strict;
use warnings;

use Rakudo::Try::Session;
use Rakudo::Try::config;
use Rakudo::Try::messages;

our $VERSION = '0.01';

my ($short, $refresh, $session);

sub error {
	my ($status, $msg) = @_;
	$msg = $msg."\n".$MSG{error} if not $short;
	$session->die($status, $msg);
}

sub fail {
	my ($status, $msg) = @_;
	my %headers;
	$msg = $msg."\n".($refresh ? $MSG{refresh} : $MSG{fail}) if not $short;
	$headers{'-refresh'} = REFRESH_TIMEOUT.'; '.$session->root if $refresh;
	$session->die($status, $msg, %headers);
}

BEGIN {
	($short, $refresh) = (0, 0);
	$session = Session_PROTO->clone->init;
	$session->connect(DB_SOURCE, DB_USER, DB_PASS)
		or error(503, 'Could not connect to database');
}

END { $session->disconnect }

my %actions = (
	':short' => sub { $short = 1 },

	':refresh' => sub { $refresh = 1 },

	'-EID' => sub { fail(404, 'Illegal session-id')
		if $session->errno == Session_EID },

	'-EUNKNOWN' => sub { fail(404, 'Unknown session-id')
		if $session->errno == Session_EUNKNOWN },

	'create_session' => sub {
		$session->errno = 0;
		($session->create and $session->redirect('/')
			or error(500, 'Could not create session'))
			if not $session->has_id;
	},

	'load_status' => sub {
		$session->errno = 0;
		error(400, 'Missing session-id')
			if not $session->has_id;
		error(500, 'Could not read session data')
			if (not defined $session->status(1) and
				$session->errno != Session_EUNKNOWN);
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
