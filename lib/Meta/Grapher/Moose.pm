package Meta::Grapher::Moose;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.01';

use Getopt::Long;
use GraphViz2;
use Scalar::Util qw( blessed );
use Try::Tiny;

use Moose;

has package => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has output => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has _graph => (
    is      => 'ro',
    isa     => 'GraphViz2',
    lazy    => 1,
    builder => '_build_graphviz2',
);

has _edges => (
    traits  => ['Hash'],
    is      => 'bare',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
    handles => {
        _set_edge         => 'set',
        _already_saw_edge => 'get',
    },
);

with 'MooseX::Getopt::Dashes';

=for Pod::Coverage run

=cut

sub run {
    my $self = shift;

    my $package = $self->package;

    # This just produces a better error message than Module::Runtime or any
    # other runtime loader.
    #
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval "require $package; 1;"
        or die $@;
    ## use critic

    my $meta = try { $package->meta }
        or die "$package does not have a ->meta method\n";

    die
        "$package->meta is not a Moose::Meta::Class or a Moose::Meta::Role, it's a "
        . ref($meta) . "\n"
        unless blessed $meta
        && ( $meta->isa('Moose::Meta::Class')
        || $meta->isa('Moose::Meta::Role') );

    $self->_graph->add_node(
        name  => $self->_node_label_for($meta),
        shape => 'box',
    );

    # We halve the weight each time we go up the tree. This makes the graph
    # cleaner (straighter lines) nearest the node we start from.
    my $weight = 2048;
    $self->_follow_parents( $meta, $weight );
    $self->_follow_roles( $meta, $meta, $weight );

    $self->_graph->run(
        format      => 'svg',
        output_file => $self->output,
    );

    return 0;
}

# Scaling the graph size in both dimensions at once does not change the shape
# or layout of the graph. It only changes the resolution of the resulting
# graphic. Given that SVGs are nicely scalable and the size of the file is not
# affected by the size of the canvas, we might as well use a large size. This
# makes it possible to render in high detail and still compress it to fit in a
# smaller space as needed.
sub _build_graphviz2 {
    return GraphViz2->new(
        global => { directed => 1 },
        graph  => {
            size  => '40,30',
            ratio => 'fill',
        },
    );
}

sub _follow_parents {
    my $self   = shift;
    my $meta   = shift;
    my $weight = shift;

    for my $parent ( map { Class::MOP::class_of($_) } $meta->superclasses ) {
        $self->_add_edge_to_graph(
            from   => $parent,
            to     => $meta,
            color  => 'blue',
            label  => 'extends',
            weight => $weight,
        );

        $self->_follow_roles( $parent, $parent, $weight );
        $self->_follow_parents( $parent, $weight / 2 );
    }

    return;
}

sub _follow_roles {
    my $self       = shift;
    my $to_meta    = shift;
    my $roles_from = shift;
    my $weight     = shift;

    if ( $roles_from->isa('Moose::Meta::Class') ) {
        for my $application ( $roles_from->role_applications ) {
            $self->_record_role(
                $to_meta,
                $application->role,
                $weight / 2
            );
        }
    }
    else {
        for my $role ( @{ $roles_from->get_roles } ) {
            $self->_record_role(
                $to_meta,
                $role,
                $weight / 2
            );
        }
    }
}

sub _record_role {
    my $self    = shift;
    my $to_meta = shift;
    my $role    = shift;
    my $weight  = shift;

    my $new_meta;

    # For the purposes of this graph, Composite roles are essentially an
    # implementation detail of Moose. We just want to see that Class A
    # consumes Roles X, Y, & Z. The fact that this was done in a single with
    # (or not) is not going to be included on the graph. We skip composite
    # roles and simply graph the roles that they are composed of.
    if ( $role->isa('Moose::Meta::Role::Composite') ) {
        $new_meta = $role;
    }
    else {
        my ( $role_for_node, $edge_color, $label_text );
        if (
            $role->isa(
                'MooseX::Role::Parameterized::Meta::Role::Parameterized')
            ) {
            $role_for_node = $role->genitor;
            $edge_color    = 'lawngreen';
            $label_text    = 'consumes with parameters';
        }
        else {
            $role_for_node = $role;
            $edge_color    = 'green';
            $label_text    = 'consumes';
        }

        $self->_add_edge_to_graph(
            from   => $role_for_node,
            to     => $to_meta,
            color  => $edge_color,
            label  => $label_text,
            weight => $weight,
        );

        $to_meta  = $role_for_node;
        $new_meta = $role_for_node;
    }

    $self->_follow_roles( $to_meta, $new_meta, $weight );

    return;
}

# We need to deduplicate edges - it's possible for an edge to appear twice if
# something earlier in the graph consumes a role directly that it also
# consumes via another role indirectly. For example, if class A consumes roles
# B & C, but role B _also_ consumes role C. In that case, we end up visiting
# role C twice. That means that if C consumes some roles we'd end up seeing
# that relationship twice as well.
#
# The same could happen with a weird inheritance tree where a class and its
# parent both inherit from the same (other) parent class.
sub _add_edge_to_graph {
    my $self = shift;
    my %args = @_;

    $args{$_} = $self->_node_label_for( $args{$_} ) for qw( from to );

    my $key = join "\0", @args{ 'from', 'to' };
    return if $self->_already_saw_edge($key);

    $self->_graph->add_edge(%args);

    $self->_record_edge($key);

    return;
}

sub _record_edge {
    my $self = shift;
    my $key  = shift;

    $self->_set_edge( $key => 1 );
}

sub _node_label_for {
    my $self = shift;
    my $meta = shift;

    return $meta unless blessed $meta && $meta->can('name');
    return $meta->name;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Produce a GraphViz graph showing meta-information about classes and roles

__END__

=head1 SYNOPSIS

    you@hostname:~$ graph-meta.pl --package Your::Package --output your-package.svg

=head1 DESCRIPTION

This distribution ships an executable, F<graph-meta.pl>, that uses
L<GraphViz2> to produce a graph showing information about a package. It always
shows the roles consumed by the package, and the roles those roles consume,
and so on. If given a class name, it will also graph inheritance, but you can
give this tool a role name as well.

B<This is still a very early release and there are a lot of improvements that
could be made. Suggestions and pull requests are welcome.>
