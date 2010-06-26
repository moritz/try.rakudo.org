#!/usr/bin/env perl

use strict;
use warnings;

use Rakudo::Try::config '../.config';
use Rakudo::Try::autoconnect qw(-create-session);

#TODO: check status, modify HTML output accordingly

# u - uninitialized, a - active, b - busy, x - expired
#IDEA: add class to body

print SESSION->header;

open my $template, '<', join('/', ROOT_PATH, TEMPLATE_DIR, SHELL_TEMPLATE)
	or SESSION->fail(500, 'Could not open template file');

while(<$template>) {
	if(not /__RAKUDO_SHELL_(\w+)__/) {
		print;
	}
	elsif($1 eq 'ID') {
		s/__RAKUDO_SHELL_ID__/${\(SESSION->id_string)}/;
		print;
	}
	elsif($1 eq 'OUT') {
		print '-->';
		my $current = undef;
		if(not SESSION->load_messages(0, \$current)) {
			#TODO: error handling
			print STDERR $@;
			print 'TODO', "\n";
			next;
		}

		print $current, "\n" while SESSION->next_message;
		SESSION->unload_messages;
		print '<!--'."\n";
	}
}

close $template;