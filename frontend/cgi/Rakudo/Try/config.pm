package Rakudo::Try::config;

use strict;
use warnings;

use File::Basename qw(dirname);

my %config;

BEGIN {
	*::ROOT_PATH = sub { $config{'root-path'} };
	*::LOGGING = sub { $config{'logging'} };
	*::DB_SOURCE = sub { $config{'db-source'} };
	*::DB_USER = sub { $config{'db-user'} };
	*::DB_PASS = sub { $config{'db-pass'} };
	*::TEMPLATE_DIR = sub { $config{'template-dir'} };
	*::SHELL_TEMPLATE = sub { $config{'shell-template'} }
}

sub import {
	my (undef, $path) = @_;
	$path = dirname($0).'/'.$path;
	$config{'root-path'} = dirname($path);

	return unless open my $file, '<', $path;
	while(<$file>) {
		chomp;
		my ($key, $value) = split /\s*=\s*/, $_, 2;
		$config{$key} = $value if length $key;
	}

	close $file;
}

1;
