#!/usr/bin/env perl
use strict;
use warnings;
use CGI qw/:standard/;

# TODO: replace stubs with actual code

my $value = rand();
if($value < 0.1) {
	# error condition
	print header(-status=>'500 Internal Server Error');
die;
}
elsif($value < 0.4) {
	# computation ongoing, no results yet
	print header(-status=>'202 Accepted');
}
elsif($value < 0.6) {
	# computation ongoing, partial results
	print header(-status=>'200 OK', -refresh=>'1');
	print 'partial: ', $value;
}
else {
	# computation done
	print header(-status=>'200 OK');
	print 'result: ', $value;
}
