#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Test::More;
use Test::Exception;

use File::Temp;
use File::Compare;

use XML::Insert;

plan tests => 2;

my $engine = XML::Insert->new('t/test_data/test_in.xml');

$engine->register(
   path     => '/foo/bar/noo',
   before   => [qw/goo loo/], # goo doesn't exist
   callback => sub{ insert('noo', @_) },
);
$engine->register(
   path     => '/foo/bar/zoo',
   before   => [qw/foo/],
   callback => sub{ insert('zoo', @_) },
);
$engine->register(
   path     => '/foo/moo',
   before   => [qw/baz/],
   callback => sub{ insert('moo', @_) },
);
$engine->register(
   path     => '/foo/yoo',
   callback => sub{ insert('yoo', @_) },
   before   => [qw/fap/], # doesn't exist
);
$engine->register(
   path     => '/foo/yoo',
   callback => sub{ insert('yoo', @_) },
);

my $tmp_01 = File::Temp->new(UNLINK => 1);

$engine->set_output($tmp_01);
$engine->run;

ok( compare($tmp_01, 't/test_data/test_out_01.xml'), 'output 01 matches' );

# test 'multi' parameter

$engine = XML::Insert->new('t/test_data/test_in.xml');

$engine->register(
   path     => '/foo/bar/multi',
   callback => sub{ insert('multi', @_) },
   multi    => 1
);

my $tmp_02 = File::Temp->new(UNLINK => 1);

$engine->set_output($tmp_02);
$engine->run;

ok( compare($tmp_02, 't/test_data/test_out_02.xml'), 'output 02 matches' );

exit;


sub insert {

    my ($name, $depth, $indent) = @_;
    my $p = "$indent" x $depth;
    return "$p<$name />\n";

}
