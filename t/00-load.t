#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::Insert' ) || print "Bail out!\n";
}

diag( "Testing XML::Insert $XML::Insert::VERSION, Perl $], $^X" );
