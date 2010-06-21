#!/usr/bin/env perl
use strict;
use warnings;
use CGI qw/:standard/;
use File::Basename;

# TODO: session handling, display stored output

print header;
open(my $file, '<', dirname($0).'/../markup/shell.html');
print while(<$file>);
close($file);
