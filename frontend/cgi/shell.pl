#!/usr/bin/env perl

use strict;
use warnings;

use autoconnect;
use File::Basename 'dirname';

use constant TEMPLATE_PATH => dirname($0).'/'.'../markup/shell.html';
use constant REDIRECTION_FOOTER =>
	'You will shortly be redirected to a fresh session';

EXEC: {

	if(not defined SESSION) {
		Session::fail(undef, 503, 'Could not connect to database');
		last EXEC;
	}

	if(not SESSION->has_id) {
		if(SESSION->has_query_string) {
			SESSION->fail(404, 'Illegal session-id', REDIRECTION_FOOTER,
				-refresh=>'5; '.SESSION->root);
		}
		else {
			(SESSION->create and SESSION->redirect('/'))
				or SESSION->fail(500, 'Could not create session');
		}

		last EXEC;
	}

	if(not defined SESSION->status(1)) {
		if(SESSION->errno == Session::EDB) {
			SESSION->fail(500, 'Could not read database');
		}
		elsif(SESSION->errno == Session::EID) {
			SESSION->fail(404, 'Unknown session-id', REDIRECTION_FOOTER,
				-refresh=>'5; '.SESSION->root);
		}
		else {
			SESSION->fail(500, 'Could not read session data due to an '.
				'unexpected error condition');
		}

		last EXEC;
	}

	#TODO: check status, modify HTML output accordingly

# u - uninitialized, a - active, b - busy, x - expired
#IDEA: add class to body

	print SESSION->header;
	open my $template, '<', TEMPLATE_PATH
		or SESSION->fail(500, 'Could not open template file');

	while(<$template>) {
		if(not /^\s*__RAKUDO_SHELL_OUT__\s*$/) { print; }
		else {
			my $current = undef;
			if(not SESSION->load_messages(0, \$current)) {
				print STDERR $@;
				print 'TODO', "\n";
				next;
			}

			print $current, "\n" while SESSION->next_message;
			SESSION->unload_messages;
		}
	}

	close $template;

}
