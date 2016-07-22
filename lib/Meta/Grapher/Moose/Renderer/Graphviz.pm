package Meta::Grapher::Moose::Renderer::Graphviz;
use namespace::autoclean;
use Moose;

our $VERSION = '1.00';

# ABSTRACT: Render a Meta::Grapher::Moose as a graph using GraphViz2

use File::Temp qw( tempfile );
use GraphViz2;
use Meta::Grapher::Moose::Constants qw(
    CLASS ROLE P_ROLE ANON_ROLE
);

=head1 SYNOPSIS

    Meta::Grapher::Moose->new(
        renderer => Meta::Grapher::Moose::Renderer::Graphviz->new(),
        ...
    );

=head1 DESCRIPTION

This is one of the standard renderers that ships as part of the
Meta-Grapher-Moose distribution.

It uses the GraphViz2 module to use GraphViz to create graphs.

=head2 Attributes

=cut

########################################################################
# attributes
########################################################################

has _graph => (
    is      => 'ro',
    isa     => 'GraphViz2',
    lazy    => 1,
    builder => '_build_graph',
);

sub _build_graph {
    return GraphViz2->new;
}

=head3 output

The name of the file that output should be written to.  For example C<foo.png>.
If no output is specified then output will be sent to STDOUT.

=cut

has output => (
    is  => 'ro',
    isa => 'Str',
);

=head3 format

The format of the output;  Accepts any value that GraphViz2 will accept,
including C<png>, C<jpg>, C<svg>, C<pdf> and C<dot>

If this is not specified then, if possible, it will be extracted from the
extension of the C<output>.  If either the C<output> has not been set or the
output filename has no file extension then the output will default to outputting
raw dot source code.

=cut

=head3 formatting

The GraphViz attributes that you want to apply to your package nodes depending
on what type they are.  The default values are:

    {
        class => {
            fontname => 'Helvettica',
            fontsize => 9,
            shape    => 'rect',
            style    => 'bold',
        },
        role => {
            fontname => 'Helvettica',
            fontsize => 9,
            shape    => 'rect',
        },
        prole => {
            fontname => 'Helvettica',
            fontsize => 9,
            shape    => 'rect',
            style    => 'dotted',
        },
        anonrole => {
            fontname => 'Helvettica',
            fontsize => 9,
            shape    => 'rect',
            style    => 'dashed',
        },
    }

More information on GraphViz attributes can be found at
L<http://www.graphviz.org/doc/info/attrs.html>

=cut

# TODO: Make this configurable from the command line, either by accepting
# some sort of JSON-as-command-line-argument-flag setting, or by having
# multiple attributes that *are* individually settable and are lazily
# built into this formatting hashref if nothing is passed.

has formatting => (
    is      => 'ro',
    isa     => 'HashRef[HashRef]',
    builder => '_build_formatting',
);

sub _build_formatting {
    my @std = (
        fontname => 'Helvettica',
        fontsize => 9,
        shape    => 'rect',
    );

    return {
        CLASS()     => { @std, style => 'bold', },
        ROLE()      => { @std, },
        P_ROLE()    => { @std, style => 'dashed', },
        ANON_ROLE() => { @std, style => 'dotted', },
    };
}

with(
    'Meta::Grapher::Moose::Role::HasOutput',
    'Meta::Grapher::Moose::Role::Renderer',
);

########################################################################
# required methods
########################################################################

=for Pod::Coverage render add_package add_edge

=cut

sub render {
    my $self = shift;

    # are we rendering to a named file or a temp file?
    my $output = (
        $self->has_output ? $self->output : do {
            my ( undef, $filename ) = tempfile();
            $filename;
            }
    );

    $self->_graph->run(
        format => ( $self->format eq 'src' ? 'dot' : $self->format ),
        output_file => $output,
    );

    # If we were rendering to STDOUT, send to STDOUT
    unless ( $self->has_output ) {
        open my $fh, '<:raw', $output;
        print while <$fh>;
        close $fh;
        unlink $output;
    }

    return;
}

sub add_package {
    my $self = shift;
    my %args = @_;

    $self->_graph->add_node(
        name  => $args{id},
        label => $args{label},
        %{ $self->formatting->{ $args{type} } },
    );

    return;
}

sub add_edge {
    my $self = shift;
    my %p    = @_;

    $self->_graph->add_edge(
        from   => $p{from},
        to     => $p{to},
        weight => $p{weight},
    );

    return;
}

########################################################################

__PACKAGE__->meta->make_immutable;
no Moose;
1;
