#!/usr/bin/env perl6
use v6;
my $backend_dir = '.';
my $*ARGFILES = open "$backend_dir/data/input_text.txt";

module Safe {
    our sub forbidden(*@a, *%h) { die "Operation not permitted in safe mode" };
    Q:PIR {
        $P0 = get_hll_namespace
        $P1 = get_hll_global ['Safe'], '&forbidden'
        $P0['!qx']  = $P1
        null $P1
        set_hll_global ['IO'], 'Socket', $P1
    };
};
Q:PIR {
    .local pmc s
    s = get_hll_global ['Safe'], '&forbidden'
    $P0 = getinterp
    $P0 = $P0['outer';'lexpad';1]
    $P0['&run'] = s
    $P0['&open'] = s
    $P0['&slurp'] = s
    $P0['&unlink'] = s
    $P0['&dir'] = s
    $P0['&chdir'] = s
    $P0['&mkdir'] = s
};

use FORBID_PIR;

Perl6::Compiler.interactive(:encoding<utf8>);
