package Test::Meta::Grapher::Moose::Recorder;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

extends 'Meta::Grapher::Moose';

has recorded_nodes_added_to_graph => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has recorded_edges_added_to_graph => (
    is      => 'ro',
    isa     => 'HashRef[HashRef]',
    default => sub { {} },
);

around _add_node_to_graph => sub {
    my $orig = shift;
    my $self = shift;
    my %p    = @_;

    push @{ $self->recorded_nodes_added_to_graph }, $p{name};

    return $self->$orig(%p);
};

around _add_edge_to_graph => sub {
    my $orig = shift;
    my $self = shift;
    my %p    = @_;

    $self->recorded_edges_added_to_graph->{ $p{key} } = {
        from => $p{from},
        to   => $p{to},
        type => $p{type},
    };

    return $self->$orig(%p);
};

__PACKAGE__->meta->make_immutable;

1;
