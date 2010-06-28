#!/usr/bin/env perl

use strict;
use warnings;

use Rakudo::Try::config '../.config';
use Rakudo::Try::autoconnect qw(:fail-on-EID :load-status :fail-on-EUNKNOWN);

Session->die(200, Session->status);
