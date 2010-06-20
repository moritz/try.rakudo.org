#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

my $binary  = 'perl6'; # optionally put a full PATH here
my $timeout = 300;

alarm $timeout;

use IPC::Run qw(harness timeout);

my $in;
my $h = harness [$binary], \$in, \my $out, \my $err, timeout $timeout;
$h->start();

die "Can't start rakudo" unless $h;

warn $err if $err;
# TODO: listen at a socket
# TODO: pipe incoming data to rakudo;
# TODO: and push the response back to the connect
