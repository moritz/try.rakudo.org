#!/usr/bin/env perl
use strict;
use warnings;
use CGI qw/:standard/;
use File::Basename;

# TODO: session handling, display stored output
my $root = dirname($0).'/..';

print header;
open(my $file, '<', $root.'/markup/shell.html');
print while(<$file>);
close($file);
