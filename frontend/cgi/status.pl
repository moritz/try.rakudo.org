#!/usr/bin/env perl

use strict;
use warnings;

use Rakudo::Try::config '../.config';
use Rakudo::Try::messages '../.messages';
use Rakudo::Try::autoconnect qw(:short -EID load_status -EUNKNOWN);

Session->die(200, Session->status);
