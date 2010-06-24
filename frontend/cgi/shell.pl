#!/usr/bin/env perl

use strict;
use warnings;

use autoconnect;

# This script is responsible for sending the HTML document to the client. The
# expected request type is GET.
# If no session-id is provided, a new session will be created. This involves
# adding an entry to the Sessions table, querying for its sid, choosing an unused
# TCP port and starting a new backend process. A 30x response navigates the
# client to / with the session-id appended.
# If a session-id is provided, the DB is queried for the state of the session and
# all entries in the Messages table belonging to this id. The messages will be
# written to the output area of the HTML document. If the session is busy or
# expired, the user input elements will be disabled.

if(not defined SESSION) {
	#TODO: fatal error
}

elsif(not SESSION->has_id) {
	#TODO: create session
	#dummy id for now:
	SESSION->{id} = 42;
	SESSION->redirect('/');
}

else {
	#TODO: check status, print HTML
}
