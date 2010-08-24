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

my $perl6 = '/Users/john/Projects/rakudo/parrot_install/bin/perl6'; 
my $in_txt = '/Users/john/Projects/try.rakudo.org/frontend/data/input_text.txt';

get '/shell' => sub {
    my $self = shift;
    return $self->redirect_to('http://try.rakudo.org/'); 
};

get '/' => sub {
    my $self = shift;
    my $txt = $self->param('input');
    return $self->render(template => 'shell', txt => $txt);
};

get '/cmd' => sub {
    my $self = shift;
    my $result;
    eval {
        socket 
        $self->param('stdin');
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
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" 
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml"> 
 <head>
  <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
  <title>Try Rakudo and Learn Perl 6 -- all in your browser (Beta)</title>
  <link rel="stylesheet" type="text/css" href="/styles/shell.css" />
  <link rel="shortcut icon" type="image/x-icon" href="/images/fav.ico" />
  <script type="text/javascript" src="http://www.google.com/jsapi"></script>
  <script type="text/javascript">
  google.load('jquery', '1.4');
  </script>
  <script type="text/javascript" src="/js/jquery.scrollTo-1.4.2.js"></script>
  <script type="text/javascript" src="/js/try.js"></script>
 </head>
 <body>
    <div id="wrapper">
        <div id="content">
            <h1>Try Rakudo and Learn Perl 6 (Beta) <img id="camelia" alt="Camelia" src="http://perl6.org/camelia-logo.png" /><br /><small>&mdash; all in your browser</small></h1>
            <div id="console">
                <div>
                    <pre id="stdout"></pre>
                </div>
                <form id="stdin_form" action="try" method="post">
                    <p id="send_btn"><span>&#x21A9;<br/>Send</span></p>
                    <div>
                      <textarea id="stdin" cols="56" rows="3"><%= $txt %></textarea>
                    </div>
                </form>
            </div>

            <div id="feedback">
            </div>
            <div id="footer">
                Content, content and content.
            </div>
        </div>
        <div id="abs_footer">
            <p>Made possible by the folks that brought you Rakudo.</p>
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
</html>

