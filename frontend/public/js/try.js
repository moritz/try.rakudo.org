$(function () {
    var keywords = ['class', 'let', 'my', 'our', 'state', 'temp', 'has', 'constant', 'sub',
                    'method', 'submethod', 'module', 'role', 'package', 'token', 'grammar',
                    'augment', 'use', 'require', 'is', 'does', 'take', 'do', 'when', 'next',
                    'last', 'redo', 'return', 'contend', 'maybe', 'defer', 'if', 'else', 
                    'elsif', 'unless', 'self', 'enum', 'slang', 'subset', 'macro', 'multi',
                    'proto', 'only', 'rule', 'regex', 'category', 'default', 'exit', 'make', 
                    'continue', 'break', 'goto', 'leave', 'async', 'lift', 'as', 'but', 'trusts',
                    'of', 'returns', 'handles', 'where', 'augment', 'supersede', 'die', 'fail', 
                    'try', 'warn'];
    var variables = /([&%$@](?:amp;)?(?!gt;|lt;|quot;)(?:[*^!?.])?(?:[a-zA-Z_][_a-zA-Z0-9:\-]*(?:\.&quot;.*&quot;(:?\(\))?)?)?)/gm;
    var constants = { str: [ /(&quot;.*&quot;)(?!>)/gm, "<strong class=\"str\">$1</strong>" ],
                      num: [ /\b(NaN|Inf|(?:0x[0-9a-f_]+)|(?:0b[01_]+)|(?:0d[0-9_]+)|(?:0o[0-7_]+)|(?:[0-9][0-9_]*(?:\.[0-9_]+)?))\b/igm, '<span class="num">$1</span>'],
                      list: [ /(&lt;.*&gt;)/g, "<span class=\"list\">$1</span>"]
                     };
    
    function highlight(text) {
        var html_entities = [[/&/g, "&amp;"], [/</g, "&lt;"], [/>/g, "&gt;"], [/"/g, "&quot;"]];
        $.each(html_entities, function () {
            if (this && this[0] && this[1])
                text = text.replace(this[0], this[1]);
            });
            text = text.replace(variables, '<b class="var">$1</b>');
            text = text.replace(new RegExp('\\b('+ keywords.join('|') +')(?!=)\\b', 'gm'), "<span class=\"keyword\">$1</span>");
            return text;
    }
    function format(input, output, error) {
        /* This function could be used for basic syntax highlighting. */
        input = highlight(input.replace(/^\s*/, ""));
        input.split("\n");
        var result = "";
        $.each(input.split("\n"), function () {
            result += "<p><span>&#x2192;</span>&nbsp;<kbd>" + this + "</kbd></p>";
        });
        output = output.replace(/^\s*/, "");
        result += "<p><samp>" + output + "</samp></p>";
        
        if (error) {
            result += "<p class=\"stderr\">&#9760;&nbsp;"+error+"</p>";
        }
        
        return result;
    }

    var commands = {
        help : function () {
            $("#feedback").html($("#help").html());
            $("#stdin").val('');
            return true;
        },
        'chapter (\\d+|index)' : function (match) {
            $("#stdin").val('');
            // Display chapter index if not already visible
            if ( match[1] == 'index' ) {
                load_tutorial_index();
            }
            if ( match[1] != 'index' ) {
                load_chapter(match[1]);
            }
            return true;
        },
        next : function () {
            tutorial && tutorial.next();
            $("#stdin").val('');
            $("#stdout").scrollTo($("#stdout p:last-child"), 300);
            return true;
        },
        prev : function () {
            tutorial && tutorial.prev();
            $("#stdin").val('');
            $("#stdout").scrollTo($("#stdout p:last-child"), 300);
            return true;
        },
        clear : function () {
            $("#stdout").html("");
            $("#stdin").val('');
            return true;
        }
    };
    var error_tracker = false;
    $("#stdin").keydown(function (evt) {
        if (evt.keyCode == 38) {
            //alert("Up pressed, only i don't have a command history yet");
        }
        if (evt.keyCode == 40) {
            //alert("Down pressed, only  i don't have a command history yet");
        }
        if (evt.keyCode == 9 && evt.shiftKey == false && evt.ctrlKey == false && evt.altKey == false && evt.metaKey == false) { // tab pressed
            $(this).val($(this).val() + "    ");
            evt.preventDefault();
        }
    });
    
    var send_enabled = true;
    
    function loading() {
        send_enabled = false;
        $("#console").addClass('loading');
        $("#console").append($('<div id="loading">').html("<img src=\"/images/ajax-loader.gif\" alt=\"Loading...\" class=\"loading_icon\" />"));
    }
    
    function done_loading() {
        send_enabled = true;
        $("#console").removeClass('loading');
        $("#console #loading").remove();
    }
    
    function send() {
        if (send_enabled == false) return;
        
        var done = false;
        $.each(commands, function (k, v) {
            var match;
            if (match = new RegExp(k, 'gmi').exec($("#stdin").val())) {
                done = done || v(match);
            }
        });
        
        if (done) return;

        loading();
        var input = $("#stdin").val();
        $.ajax({
            type: "GET",
            url: '/cmd', 
            data: "input=" + encodeURIComponent(input),
            dataType: "json",
            timeout: 35000,
            error: function (request, txt_status, error) {
                if (txt_status == 'timeout') {
                    $("#stdout").append("<p>Request Timeout, the server seems to be unavailable right now.</p>");
                }
                else {
                    alert("A serious error has occured,\nplease file a bug report describing what happened.");
                }

                $("#stdout").scrollTo($("#stdout p:last-child"), 300);
            },
            success: function (result) {
                done_loading();
                if (result == null) {
                    alert("An error has occured on the server.");
                    return;
                }
                if (result['error']) {
                    alert("An error has occured on the server. Error Message:\n\n" + result["error"]);
                    return;
                }
                else {
                    $("#stdout").append(format(input, result.stdout + "", ""));
                }

                if ( tutorial ) {
                    tutorial.do_step(input);
                }

                $("#stdout").scrollTo($("#stdout p:last-child"), 300);
            }
        });
        
        $("#stdin").val("");
    }
    $("#send_btn").mouseup(function () {
        $(this).toggleClass('active');
    }).mousedown(function () {
        $(this).toggleClass('active');
        send();
    });
    $("#stdin").keypress(function (evt) {
        if (evt.keyCode == 13 && evt.shiftKey == false) {
            send()
            evt.preventDefault();
        }
        
        var str = $(this).val();
        var cols = $(this).attr('cols');

        var linecount = 0;
        $.each(str.split("\n"), function(k, l) {
            linecount += Math.ceil( (this.length + 1) / cols );
        });
        
        $(this).attr('rows', linecount < 3 ? 3 : linecount + 1);
        $("#send_btn").height($(this).height());
    });
    
    $("#feedback").html($("#help").html());
    $("#send_btn").height($("#stdin").height());
    $("#stdin").focus();
});

