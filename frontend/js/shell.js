new (function() {

RakudoShell = this;
RakudoShell.init = init;

var url = 'status';
var isLocked, timeout, input, output;

var focus = // only focus on input field if nothing is selected
	RakudoLib.getSelection ? (function() {
		if(RakudoLib.getSelection().length === 0)
			input.focus()
	}) : (function() {});

function setStatus(status) {
	RakudoLib.removeClass(document.body, 'RakudoShell-status-\\w+');
	RakudoLib.addClass(document.body, 'RakudoShell-status-' + status);
}

function lock() {
	isLocked = true;
	input.disabled = true;
}

function unlock(clear) {
	isLocked = false;
	input.disabled = false;
	if(clear) input.value = '';
	input.blur(); // FIX: makes cursor visible
	input.focus();
}

function checkStatus() {
	if(this.readyState === 4) {
		switch(this.status) {
			case 200:
			say(this.responseText);
			var ref = this.getResponseHeader('Refresh');
			if(ref) setTimeout(requestStatus, ref * 1000 || timeout);
			else {
				setStatus('ready');
				unlock(true);
			}
			break;

			case 202:
			setTimeout(requestStatus, timeout);
			break;

			default:
			cry('server returned status ' + this.status);
			unlock(false);
		}
	}
}

function requestStatus() {
	var req = new RakudoLib.XMLHttpRequest;
	req.onreadystatechange = checkStatus;

	try {
		req.open('POST', url, true);
		req.send(null);
	}
	catch(e) {
		cry('connection failure');
		unlock(false);
	}
}

function say(msg) {
	output.appendChild(document.createTextNode(msg + '\n'));
	output.scrollTop = output.scrollHeight;
}

function cry(msg) {
	say('error: ' + msg);
	setStatus('failed');
}

function send(event) {
	if(!event) event = window.event;
	if(isLocked) {
		if(event.preventDefault)
			event.preventDefault();
		else event.returnValue = false;
	}
	else {
		setStatus('locked');
		setTimeout(lock, 0); // defer field disabling after form submit
		setTimeout(requestStatus, timeout);
	}
}

function addField(form, name, value) {
	var field = document.createElement('input');
	field.type = 'hidden';
	field.name = name;
	field.value = value;
	form.appendChild(field);
}

function init(timeout_) {
	timeout = timeout_;
	input = document.getElementById('RakudoShell-in');
	output = document.getElementById('RakudoShell-out');
	var form = document.getElementById('RakudoShell-form');
	addField(form, 'js', '1');
	RakudoLib.addListener(form, 'submit', send);
	RakudoLib.addListener(document, 'click', focus);
	output.scrollTop = output.scrollHeight;
	setStatus('locked');
	lock();
	requestStatus();
}

});