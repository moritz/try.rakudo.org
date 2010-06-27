package Rakudo::Try::config;

use strict;
use warnings;

use File::Basename qw(dirname);

my %config;

sub import {
	my (undef, $path) = @_;

	{
		no strict 'refs';
		my $caller = (caller).'::';
		*{$caller.'ROOT_PATH'} = \&ROOT_PATH;
		*{$caller.'DB_SOURCE'} = \&DB_SOURCE;
		*{$caller.'DB_USER'} = \&DB_USER;
		*{$caller.'DB_PASS'} = \&DB_PASS;
		*{$caller.'TEMPLATE_DIR'} = \&TEMPLATE_DIR;
		*{$caller.'SHELL_TEMPLATE'} = \&SHELL_TEMPLATE;
		*{$caller.'REFRESH_TIMEOUT'} = \&REFRESH_TIMEOUT;
		*{$caller.'CONTROLLER_PORT'} = \&CONTROLLER_PORT;
	}

	return if not defined $path;

	$path = dirname($0).'/'.$path;
	$config{'root-path'} = dirname($path);

	return unless open my $file, '<', $path;

	while(<$file>) {
		chomp;
		my ($key, $value) = split /\s*=\s*/, $_, 2;
		$config{$key} = $value;
	}

	close $file;
}

sub ROOT_PATH { $config{'root-path'} }
sub DB_SOURCE { $config{'db-source'} }
sub DB_USER { $config{'db-user'} }
sub DB_PASS { $config{'db-pass'} }
sub TEMPLATE_DIR { $config{'template-dir'} }
sub SHELL_TEMPLATE { $config{'shell-template'} }
sub REFRESH_TIMEOUT { $config{'refresh-timeout'} }
sub CONTROLLER_PORT { $config{'controller-port'} }

1;
