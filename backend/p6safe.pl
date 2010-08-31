my $*ARGFILES = open '/Users/john/Projects/try.rakudo.org/frontend/data/input_text.txt'; 

module Safe { 
    our sub forbidden(*@a, *%h) { die "Operation not permitted in safe mode" }; 
    &GLOBAL::open   := &forbidden; 
    &GLOBAL::run    := &forbidden; 
    &GLOBAL::slurp  := &forbidden; 
    &GLOBAL::unlink := &forbidden; 
    &GLOBAL::dir    := &forbidden; 
}
use FORBID_PIR;

Perl6::Compiler.interactive();
