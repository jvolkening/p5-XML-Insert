package XML::Insert 0.001;

use strict;
use warnings;
use 5.012;

use XML::Parser;
use List::Util qw/any/;
use Scalar::Util qw/openhandle/;

sub new {

    my ($class, $in) = @_;

    my $self = bless {
        prev        => '',
        indent      => '',
        inserts     => [],
        in          => $in,
        fh_out      => \*STDOUT,
    } => $class;

    return $self;

}

sub register {

    my ($self, %args) = @_;

    die "missing parent argument" if (! defined $args{parent});
    die "missing callback argument" if (! defined $args{callback});
    for my $p (keys %args) {
        die "Invalid parameter $p"
            if (! any {$p eq $_} qw/parent callback before/);
    }

    push @{ $self->{inserts} }, {%args};

}

sub set_output {

    my ($self, $fh) = @_;
   
    # handle either FH or filename
    openhandle $fh //
        open $fh, '>', $fh;

    $self->{fh_out} = $fh;

}

sub run {

    my ($self) = @_;

    my $parser = new XML::Parser(
        Handlers => {
            Start   => sub { _handle_tag($self, 'start', @_) },
            End     => sub { _handle_tag($self, 'end', @_)   },
            Default => sub { _handle_default($self, @_)      },
        }
    );

    # handle either FH or filename
    my $fh = openhandle $self->{in};
    if (! defined $fh) {
        open($fh, '<', $self->{in});
    }

    $parser->parse($fh);

    # don't forget last bit
    print $self->{prev};

}

sub _handle_tag {

    my ($self, $type, $expat, $el) = @_;

    my @context = $expat->context;
    push @context, $el if ($type eq 'end');

    my $path = '/' . join "/", @context;

    my $extra = $type eq 'start' ? 0 : 1;
    my $depth = $expat->depth;
    my $real_depth =  $depth + $extra;

    my $ins = '';
    for (@{ $self->{inserts} }) {
        next if ( $_->{was_handled} );
        next if ( $path ne $_->{parent} );
        next if ($type eq 'start'
            && ! any {$_ eq $el} @{ $_->{before} } );
        $ins .= $_->{callback}->($real_depth, $self->{indent});
        $_->{was_handled} = 1;
    }

    # The following logic is used to preserve formatting and is based on the
    # observed behavior of the expat parser.

    # If prev capture contains anything but whitespace, print that first (in
    # practice this never seems to happen for insertions). In addition, print
    # first if depth == 0. This should only happen for an insertion right
    # before the closing root element, which seems to need special treatment.

    if ($self->{prev} =~ /\S/ || $depth == 0) {
        print $self->{prev};
        print $ins;
    }
    else {
        print $ins;
        print $self->{prev};
    }
    $self->{prev} = $expat->original_string;
} 

sub _handle_default {

    my ($self, $expat, $str) = @_;

    print $self->{prev};
    $self->{prev} = $str;

    # determine default indent;
    return if (length $self->{indent});
    if ($str=~ /^([ \t]+)/) {
        $self->{indent} = $1;
    }

}

1;

__END__

=head1 NAME

XML::Insert - insert elements into streamed XML

=head1 SYNOPSIS

    use XML::Insert;

    my $engine = XML::Insert->new( $xml_file );

    $engine->register(
        'parent'   => '/root/other/stuff',
        'before'  => [qw/ four five six/],
        'callback'=> \&add_four,
    );

    $engine->run;
        

=head1 DESCRIPTION

C<XML::Insert> is designed to efficiently insert elements at specific
locations in a streaming XML file without the need to load the whole file into
a DOM representation. It's flexible syntax should allow insertion at a given
place in the tree, preserving element order and formatting and taking into
account the possibility of missing optional elements.

=head1 METHODS

=over 4

=item B<new>

    my $engine = XML::Insert->new( $xml_file );

Create a new C<XML::Insert> engine. Requires a single argument, which can be
either a filename of the XML to parse or a filehandle open to the file.

=item B<register>

    $engine->register(
        'parent'   => '/root/other/stuff',
        'before'  => [qw/ four five six/],
        'callback'=> \&add_four,
    );

Registers an insertion to make. There are two required arguments:

=over 1

=item * parent - the location in a simplified XPath format (i.e. no attributes,
etc) to the parent element within which the insertion should happen

=item * callback - a subroutine reference to call. The subroutine will be
passed two arguments (depth in the tree and string to use for each depth-wise
indentation) and should return the string to be inserted. See the SYNOPSIS for
an example callback

=back

There is one optional argument:

=over 1

=item * before - an array reference to element names. If the order in which
the new element is inserted within the parent matters, this reference should
contain a list of elements before which the element should be placed. If any
of these elements are seen within the parent, the element will be inserted
immediately before. If none are defined or none are seen (e.g. they may be
optional), the element will be inserted as the last item within the parent.

=back

=item B<set_output>

    $engine->set_output( $fn_or_fh );

Set the output target to which the modified XML will be printed. Can be either
a filename or filehandle. Defaults to STDOUT.

=item B<run>

    $engine->run;

Parses the file, inserting new content where appropriate, and prints the
results to the output target.

=back

=head1 CAVEATS AND BUGS

This is code is in alpha testing stage and the API is not guaranteed to be
stable.

Please reports bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


