package Meta::Grapher::Moose::Role::GraphViz2;
use Moose::Role;

use Meta::Grapher::Moose::Constants qw( _CLASS _ROLE _P_ROLE );
use GraphViz2;

requires 'output';

our $VERSION = '0.05';

has _graph => (
    is      => 'ro',
    isa     => 'GraphViz2',
    lazy    => 1,
    builder => '_build_graph',
);

sub _build_graph {
    return GraphViz2->new;
}

has formatting => (
    is      => 'ro',
    isa     => 'HashRef[HashRef]',
    builder => '_build_formatting',
);

sub _build_formatting {
    return {
        _CLASS() => {
            color => 'blue',
            label => 'extends',
        },

        _ROLE() => {
            color => 'green',
            label => 'consumes',
        },
        _P_ROLE() => {
            color => 'lawngreen',
            label => 'consumes with parameters',
        },
    };
}

#### required methods ######

sub _render_to_file {
    my $self = shift;

    $self->_graph->run(
        format      => 'svg',
        output_file => $self->output,
    );

    return;
}

sub _add_package_to_graph {
    my $self = shift;
    my %args = @_;

    $self->_graph->add_node(
        shape => 'box',
        name  => $args{name},
    );

    return;
}

sub _add_edge {
    my $self = shift;
    my %p = @_;

    $self->_graph->add_edge(
        from   => $p{from},
        to     => $p{to},
        weight => $p{weight},
        %{ $self->formatting->{ $p{type} } },
    );

    return;
}

1;
