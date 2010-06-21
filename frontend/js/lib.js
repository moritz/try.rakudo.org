new (function() {

RakudoLib = this;

RakudoLib.XMLHttpRequest = // IE XHR hack
	window.XMLHttpRequest || (window.ActiveXObject ? (function() {
		try { return new ActiveXObject('Msxml2.XMLHTTP.6.0'); }
		catch(e) {}
		try { return new ActiveXObject('Msxml2.XMLHTTP.3.0'); }
		catch(e) {}
		return new ActiveXObject('Microsoft.XMLHTTP'); }) :
	fail('XMLHttpRequest unsupported'));

RakudoLib.addListener = // cross-browser event listeners
	document.addEventListener ? (function(el, type, listener) {
		el.addEventListener(type, listener, false); }) :
	document.attachEvent ? (function(el, type, listener) {
		el.attachEvent('on' + type, listener); }) :
	fail('event listeners unsupported');

RakudoLib.getSelection = // cross-browser selection handling
	document.getSelection ? (function() {
		return document.getSelection(); }) :
	window.getSelection ? (function() {
		return window.getSelection().toString();
	}) :
	document.selection ? (function() {
		return document.selection.createRange().text; }) :
	false;

RakudoLib.addClass = function(el, name) {
	el.className += ' ' + name;
};

RakudoLib.removeClass = function(el, regstr) {
	el.className = el.className.replace(
		new RegExp('(^|\\s+)' + regstr + '(\\s+|$)', 'g'), ' ');
};

function fail(msg) {
	throw new Error(msg);
}

});