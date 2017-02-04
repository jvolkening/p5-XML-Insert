#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Test::More;

use File::Temp;
use File::Compare;

use XML::Insert;

plan tests => 1;

my $engine = XML::Insert->new('t/test_in.xml');

$engine->register(
   parent => '/foo/bar',
   before => [qw/goo loo/], # goo doesn't exist
   callback => sub{ insert('noo', @_) },
);
$engine->register(
   parent => '/foo/bar',
   before => [qw/foo/],
   callback => sub{ insert('zoo', @_) },
);
$engine->register(
   parent => '/foo',
   before => [qw/baz/],
   callback => sub{ insert('moo', @_) },
);
$engine->register(
   parent => '/foo',
   callback => sub{ insert('yoo', @_) },
   before   => [qw/fap/], # doesn't exist
);
$engine->register(
   parent => '/foo',
   callback => sub{ insert('yoo', @_) },
);

my $tmp = File::Temp->new(UNLINK => 1);

$engine->set_output($tmp);
$engine->run;

close $tmp;

ok( compare($tmp, 't/test_out.xml'), 'output matches' );

exit;


sub insert {

    my ($name, $depth, $indent) = @_;
    my $p = "$indent" x $depth;
    return "$p<$name />\n";

}
