<?php
// dummy server so you can see the frontend in action
// TODO: server-side session handling; should echo previous computations, 
// which is especially important if client-side scripting is disabled;
// currently, no output will be produced if scripting is disabled

if($_SERVER['QUERY_STRING'] == 'status') {
	// check computation result

	$value = rand(); // dummy value

	if($value < getrandmax() / 10) {
		// simulate error condition
		header('HTTP/1.0 500 Internal Server Error');
	}
	elseif($value < getrandmax() / 2) {
		// computation finished
		header('HTTP/1.0 200 OK');
		echo 'rakudo: '.$value;
	}
	else {
		// computation ongoing
		header('HTTP/1.0 202 Accepted');
	}

	die();
}

if(isset($_GET['cmd'])) {
	// execute new command

	if(isset($_GET['js'])) {
		// if client-side scripting is enabled, don't refresh the page
		header('HTTP/1.0 204 No Content');
		die();
	}
	else {
		// TODO: redirect to original address to discard cmd=... query
		// too lazy to implement this
	}
}

include 'markup/shell.html';
?>