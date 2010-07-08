#!/opt/local/bin/perl
use strict;
use warnings;
use v5.12;
use mro 'c3';
use feature 'say';

use Mojolicious::Lite;
use Mojo::Server::CGI;
use Mojo::JSON;

use IPC::Run qw(harness pump finish timeout);

my $cgi = Mojo::Server::CGI->new;

my @perl6 = '/Users/john/Projects/local/bin/perl6';

get '/' => 'shell';

get '/cmd' => sub {
    my $self = shift;
    my $result;
    eval {
        my ($p6in, $p6out, $p6err);
        my $h = harness \@perl6, \$p6in, \$p6out, \$p6err, timeout( 10 );
        my $in = $self->param('input');
        $in =~ tr/\n/ /;
        $p6in = $in;
        
        pump $h while length $p6in;
        finish $h;
        
        $self->app->log->debug("string was: ". $in . ' and ' . length($in) + 2);
        
        $p6out = substr $p6out, length($in) + 2;
        $p6out = substr $p6out, 0, length($p6out) - 2;
        $p6out =~ s/^\s+//;
        chomp $p6out;
        $result = $p6out . " "; # to keep it from thinking this is a number
    };
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
  <link rel="stylesheet" type="text/css" href="/markup/shell.css">
  <script type="text/javascript" src="http://www.google.com/jsapi"></script>
  <script type="text/javascript">
  google.load('jquery', '1.4');
  </script>
  <script type="text/javascript" src="/js/jquery.scrollTo-1.4.2.js"></script>
  <script>
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
            $.each(constants, function (klass) {
                text = text.replace(this[0], this[1]);
            });
            text = text.replace(variables, '<b class="var">$1</b>');
            text = text.replace(new RegExp('\\b('+ keywords.join('|') +')(?!=)\\b', 'gm'), "<span class=\"keyword\">$1</span>");
            return text;
        }
        function format(input, output, error) {
            /* This function could be used for basic syntax highlighting. */
            input = highlight(input);
            if (output)
                output = highlight(output);
            
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
        
        function send() {
            var input = $("#stdin").val();
            $.getJSON('/cmd', "input=" + encodeURIComponent($("#stdin").val()),
                function (result) {
                    if (result['error']) {
                        alert(result['error']);
                        return;
                    }
                    if (result['stderr']) {
                        $("#stdout").append(format(result.stdin, result.stdout, result.stderr));
                    }
                    else {
                        $("#stdout").append(format(result.stdin, result.stdout));
                    }
                    $("#stdout").scrollTo($("#stdout p:last-child"), 300);
                }
            );
            
            $.each(commands, function (k, v) {
                var match;
                if (match = new RegExp(k, 'gmi').exec($("#stdin").val())) {
                    v(match);
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
                <h1>Welcome</h1>
                <p>
                    Welcome statement
                </p>
                <h2>Commands List</h2>
                <ul>
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
            <div id="footer">
                Footer Goes Here
            </div>
        </div>
        <div id="abs_footer">
            <p>Abs Footer</p>
        </div>
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

@@ layouts/funky.html.ep
<!doctype html><html>
    <head><title>Funky!</title></head>
    <body><%== content %></body>
</html>
