#!/usr/bin/env perl
use strict;
use warnings;
use CGI qw/:standard/;

# TODO: execute url_param('cmd') in rakudo

if(url_param('js') eq '1') {
	print header(-status=>'204 No Content');
}
else {
	# reload root
	$_ = url();
	s/run$//;
	redirect(-uri=>$_);
}
