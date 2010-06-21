#!/usr/bin/env perl
use strict;
use warnings;
use CGI qw/:standard/;

# THIS IS BROKEN - the 204 seems to be lost somewhere

# FIXME
my $path = 'D:/dev/rakudo-shell/try.rakudo.org/frontend/';

if($ENV{'QUERY_STRING'} eq 'status') {
	my $value = rand();
	if($value < 0.1) { print header(-status=>'500 Internal Server Error'); }
	elsif($value < 0.5) { print header(-status=>'200 OK'), $value; }
	else { print header(-status=>'202 Accepted') }
}
elsif(url_param('cmd')) {
	if(url_param('js') eq '1') { print header(-status=>'204 No Content'); }
	else { print redirect(url()); }
}
else {
	print header;
	open(my $file, '<', $path.'markup/shell.html') or die $!;
	print while(<$file>);
}
