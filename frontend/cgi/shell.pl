#!/usr/bin/env perl

#TODO: check status, modify HTML output accordingly
# u - uninitialized, a - active, b - busy, x - expired
#IDEA: add class to body

use strict;
use warnings;

use Rakudo::Try::config '../.config';
use Rakudo::Try::messages '../.messages';
use Rakudo::Try::autoconnect
	qw(:refresh -EID create_session load_status -EUNKNOWN);

open my $template, '<', join('/', ROOT_PATH, TEMPLATE_DIR, SHELL_TEMPLATE)
	or Session->die(500, 'Could not open template file'."\n".$MSG{error});

Session->send_headers(200);

LINE: while(<$template>) {
	while(/__RAKUDO_SHELL_(\w+)__/) {
		my ($pre, $post) = split /__RAKUDO_SHELL_$1__/, $_, 2;
		$_ = $post;
		print $pre;
		if($1 eq 'ID') { print Session->id }
		elsif($1 eq 'OUT') {
			Session->errno = 0;

			my $current = undef;
			if(Session->load_messages(0, \$current)) {
				print while Session->next_message;
			}

###TODO: error handling
			print "PANIC: $@" if Session->errno;

			Session->unload_messages;
		}
	}

	print;
}

close $template;
