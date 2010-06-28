package Rakudo::Try::messages;

use strict;
use warnings;

use File::Basename qw(dirname);

our $VERSION = '0.01';

my %messages;

sub import {
	my (undef, $path) = @_;

	{
		no strict 'refs';
		*{(caller).'::MSG'} = \%messages;
	}

	return if not defined $path;
	return unless open my $file, '<', dirname($0).'/'.$path;

	while(<$file>) {
		chomp;
		my ($key, $value) = split /\s*=\s*/, $_, 2;
		$messages{$key} = $value;
	}

	close $file;
}

1;
