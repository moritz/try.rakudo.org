#!/usr/bin/env perl

use strict;
use warnings;

use autoconnect;
use File::Basename 'dirname';

use constant TEMPLATE_PATH => '../markup/shell.html';

EXEC: {

	if(not defined SESSION) {
		Session::fail(undef, 503, 'Could not connect to database');
		last EXEC;
	}

	if(not SESSION->has_id) {
		(SESSION->create and SESSION->redirect('/'))
			or SESSION->fail(500, 'Could not create session');
		last EXEC;
	}

	if(not defined SESSION->status(1)) {
		if(SESSION->errno == Session::EDB) {
			SESSION->fail(500, 'Could not read database');
			last EXEC;
		}

		if(SESSION->errno == Session::EID) {
			SESSION->fail(404, 'Illegal session-id',
				'You will shortly be redirected to a new session',
				-refresh=>'5; '.SESSION->root);
			last EXEC;
		}

		SESSION->fail(500,
			'Could not read session data due to an unexpected error condition');

		last EXEC;
	}

	#TODO: check status, modify HTML output accordingly

	print SESSION->header;
	open my $template, '<', dirname($0).'/'.TEMPLATE_PATH
		or SESSION->fail(500, 'Could not open template file');

	while(<$template>) {
		if(/^\s*__RAKUDO_SHELL_OUT__\s*$/) {
			print '--> TODO: get messages <!--', "\n";
		}
		else { print; }
	}

	close $template;

}
