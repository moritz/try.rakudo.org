#!/usr/bin/env perl
use strict;
use warnings;
use CGI qw/:standard/;

# TODO: replace stubs with actual code

my $value = rand();
if($value < 0.1) {
	# error condition
	print header(-status=>'500 Internal Server Error');
}
elsif($value < 0.5) {
	# computation ongoing
	print header(-status=>'202 Accepted');
}
else {
	# computation done
	print header(-status=>'200 OK');
	print 'dummy: ', $value;
}
