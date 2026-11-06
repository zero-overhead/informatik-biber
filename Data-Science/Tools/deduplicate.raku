#!/usr/bin/env raku

#| # read filename from arguments and print the content of the file
sub MAIN(Str :$input-file!, 
         Bool :$debug) {

    $input-file.IO.lines.unique.sort.join("\n").say
}


