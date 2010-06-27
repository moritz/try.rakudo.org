#!/usr/bin/env perl

use strict;
use warnings;

use Rakudo::Try::config '../.config';
use Rakudo::Try::autoconnect qw(-check-session);
use Rakudo::Try::Session qw(respond);

SESSION->respond(200, SESSION->status);
