#!/usr/bin/env perl

use strict;
use warnings;

use autoconnect;

# This script is responsible for sending the HTML document to the client. The
# expected request type is GET.
# If no session-id is provided, a new session will be created. This involves
# adding an entry to the Sessions table, querying for its sid, choosing an unused
# TCP port and starting a new backend process. The hexadecimal session-id
# notation is the result of xor-ing the sid value with a masking constant, which
# is necessary to avoid tempting the user to manually generate session-ids by
# incrementing existing ones. A 30x response navigates the client to / with the
# session-id appended.
# If a session-id is provided, the DB is queried for the state of the session and
# all entries in the Messages table belonging to this id. The messages will be
# written to the output area of the HTML document. If the session is busy or
# expired, the user input elements will be disabled.