#!/usr/bin/env perl

use strict;
use warnings;

use autoconnect;

print defined SESSION ? 'SESSION defined' : 'SESSION not defined';