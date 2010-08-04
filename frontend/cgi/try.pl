#!/usr/bin/perl
# Good practice? 
use strict;
use warnings;
use mro 'c3';
use encoding 'utf8';

# Web Requirements
use Mojolicious::Lite;
use Mojo::Server::CGI;
use Mojo::JSON;

# Requirements for running the commands
use File::Temp qw(tempfile);
use IPC::Run qw(run timeout);

my $cgi = Mojo::Server::CGI->new;

my $perl6 = '/home/john/Projects/rakudo/parrot_install/bin/perl6'; 
my $in_txt = '/home/john/Projects/try.rakudo.org/frontend/data/input_text.txt';

get '/' => 'shell';

get '/cmd' => sub {
    my $self = shift;
    my $result;
    my ($fh, $filename);
    eval {
        my ($p6out, $p6err) = "";
        ($fh, $filename) = tempfile();
        
        # Stolen from pugs evalbot
        print $fh q<
module Safe { our sub forbidden(*@a, *%h) { die "Operation not permitted in safe mode" };
    Q:PIR {
        $P0 = get_hll_namespace
        $P1 = get_hll_global ['Safe'], '&forbidden'
        $P0['!qx']  = $P1
        null $P1
        set_hll_global ['IO'], 'Socket', $P1
    }; };
Q:PIR {
    .local pmc s
    s = get_hll_global ['Safe'], '&forbidden'
    $P0 = getinterp
    $P0 = $P0['outer';'lexpad';1]
    $P0['&run'] = s
    $P0['&open'] = s
    $P0['&slurp'] = s
    $P0['&unlink'] = s
    $P0['&dir'] = s
};
# EVALBOT ARTIFACT
use FORBID_PIR;
>;
        print $fh $self->param('input');
        $fh->flush;
        run ['cat', $in_txt], '|', [$perl6, $filename], '>&', \$p6out, timeout( 15 )
            or die "perl6 died: $filename and $?";
        
        chomp $p6out;
        $result = "$p6out"; # to keep it from thinking this is a number
        close $fh;
    };
    close $fh if $fh;
    if ($@) {
        return $self->render_json({error => 'yes' . $@});
    }
    else {
        return $self->render_json({stdout => $result, stdin=>$self->param('input')});
    }
};

app->secret('foo');
$cgi->run;
__DATA__

@@ shell.html.ep
<!DOCTYPE html>
<html>
 <head>
  <meta http-equiv="content-type" content="text/html; charset=UTF-8">
  <title>Try Rakudo and Learn Perl 6 -- all in your browser</title>
  <link rel="stylesheet" type="text/css" href="/styles/shell.css">
  <link rel="shortcut icon" href="/images/fav.ico" />
  <script type="text/javascript" src="http://www.google.com/jsapi"></script>
  <script type="text/javascript">
  google.load('jquery', '1.4');
  </script>
  <script type="text/javascript" src="/js/jquery.scrollTo-1.4.2.js"></script>
  <script>
    $(function () {
        var history = ["", ""];
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
            $.each(constants, function (klass) {
                text = text.replace(this[0], this[1]);
            });
            text = text.replace(variables, '<b class="var">$1</b>');
            text = text.replace(new RegExp('\\b('+ keywords.join('|') +')(?!=)\\b', 'gm'), "<span class=\"keyword\">$1</span>");
            return text;
        }
        function format(input, output, error) {
            /* This function could be used for basic syntax highlighting. */
            input = highlight(input.replace(/^\s*/, ""));
            if (output)
                output = highlight(output.replace(/^\s*/, ""));
            
            var result = "<p>" + input + "</p>";
            result += "<p><span>&#x2192;</span>&nbsp;" + output + "</p>";
            
            if (error) {
                result += "<p class=\"stderr\">&#9760;&nbsp;"+error+"</p>";
            }
            
            return result;
        }
        
        function load_chapter(id) {
            $("#feedback").fadeOut('slow', function () {
                $("#stdout").html("");
                $.getJSON('/frontend/data/chapters/index.js', function (data) {
                    $("#feedback").html($("<h1>").text(data.title));
                    if (data.steps) {
                    
                    }
                    else if (data.info) {
                        var list = $("<ul>");
                        $("#feedback").append(list)
                        for (var x in data.info) {
                            var item = $("<li>").text(data.info[x].title);
                            list.append(item);
                            (function (item) {
                                if (data.info[x].details) {
                                    var details = $("<ul>");
                                    item.append(details);
                                    for (var y in data.info[x].details) {
                                        details.append($("<li>").text(data.info[x].details[y]));
                                    }
                                }
                            })(item);
                        }
                    }
                });
                $("#feedback").fadeIn("slow");
            });
        }
        var commands = {
            help : function () {
                $("#feedback").html($("#help").html());
                return true;
            },
            'chapter (\\d+|index)' : function (match) {
                load_chapter(match[1]);
            },
            clear : function () {
                $("#stdout").html("");
            }
        };
        var error_tracker = false;
        var a = 0; // this is to cause a fake error every few calls
        $("#stdin").keydown(function (evt) {
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
            if (input[input.length - 1] != ';') input += ';';
            $.getJSON('/cmd', "input=" + encodeURIComponent(history[0] + input),
                function (result) {
                    done_loading();
                    if (result['error']) {
                        alert(result['error']);
                        return;
                    }
                    else {
                        history[0] += input;
                        result.stdout = result.stdout + "";
                        $("#stdout").append(format(input, result.stdout.replace(history[1], "")));
                        history[1] += result.stdout.replace(history[1], "");
                    }
                    $("#stdout").scrollTo($("#stdout p:last-child"), 300);
                }
            );
            
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
    
  </script>
 </head>
 <body>
    <div id="wrapper">
        <div id="content">
            <h1>Try Rakudo and Learn Perl 6 <img id="camelia" src="http://perl6.org/camelia-logo.png" /><br /><small>&mdash; all in your browser</small></h1>
            <div id="console">
                <div>
                    <pre id="stdout"></pre>
                </div>
                <form id="stdin_form" action="try" method="post">
                    <p id="send_btn"><span>&#x21A9;<br/>Send</span></p>
                    <textarea id="stdin" cols="56" rows="3"></textarea>
                </form>
            </div>

            <div id="feedback">
            </div>
            <div id="footer">
                Content, content and content.
            </div>
        </div>
        <div id="abs_footer">
            <p>Made possible by the guys that brought you Rakudo.</p>
        </div>
    </div>
    
    <div id="hidden">
        <div id="help">
            <h1>Welcome</h1>
            <h2>Commands List</h2>
            <ul>
                <li>help
                    <ul>
                        <li>Displays this message.</li>
                    </ul>
                </li>
                <li>Tab
                    <ul>
                        <li>Inserts 4 spaces</li>
                    </ul>
                </li>
                <li>Shift+&#x21A9;
                    <ul>
                        <li>New line in the text box</li>
                    </ul>
                </li>
                <li>clear
                    <ul>
                        <li>Resets the console</li>
                    </ul>
                </li>
                <li>chapter index
                    <ul>
                        <li>Lists an index of the tutorials</li>
                    </ul>
                </li>
                <li>chapter \d+
                    <ul>
                        <li>Goes to chapter # of the tutorial, where # is a number</li>
                    </ul>
                </li>
                <li>help /&lt;term&gt;/
                    <ul>
                        <li>Looks up a term</li>
                    </ul>
                </li>
                <li>links
                    <ul>
                        <li><a href="#">Some</a> useful Links</li>
                        <li><a href="https://www.google.com">Google is useful, right?</a></li>
                    </ul>
                </li>
            </ul>
        </div>
        <img src="/images/ajax-loader.gif" alt="Loading..." class="loading_icon" />
    </div>
 </body>
 <script type="text/javascript">

   var _gaq = _gaq || [];
   _gaq.push(['_setAccount', 'UA-10145968-1']);
   _gaq.push(['_trackPageview']);

   (function() {
     var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
     ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
     var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
   })();

 </script>
</html>

