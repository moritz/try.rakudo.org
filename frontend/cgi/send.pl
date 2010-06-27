#!/usr/bin/env perl

use strict;
use warnings;

use Rakudo::Try::config '../.config';
use Rakudo::Try::autoconnect qw(-refresh -check-session);
use Rakudo::Try::Session qw(respond);

#IDEA: return 204 if server is busy and one tries to send

# This script relays user input to the backend. The expected request type is
# POST, with a mandatory parameter named 'cmd' containing the user input and
# an optional parameter named 'js', which signifies that client-side scripting is
# available. The request will be generated by an HTML form. The session-id should
# be available.
# If the session is not expired, a TCP connection to the backend has to be
# established and the user input transferred.
# If client-side scripting is available, a 204 response prevents the page from
# reloading. No data will be transferred as the backend output will be received
# via client-side polling.
# If client-side scripting is not available, a 30x response navigates the client
# to /, which in turn reads the output from the DB.


my $status = SESSION->status;
my $has_js = SESSION->param('js');
my $input = SESSION->param('input');

if($status ne 'a') {
	SESSION->respond(204) if not $has_js;

	#TODO: send different responses depending on status if JS available
}

#TODO: send data to backend
