package Meta::Grapher::Moose;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.04';

use Getopt::Long;
use GraphViz2;
use Scalar::Util qw( blessed );
use Try::Tiny;

use Moose;

## no critic (ValuesAndExpressions::ProhibitConstantPragma)
use constant _CLASS  => 0;
use constant _ROLE   => 1;
use constant _P_ROLE => 2;
## use critic

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

has formatting => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    builder => '_build_formatting',
);

has _graph => (
    is      => 'ro',
    isa     => 'GraphViz2',
    lazy    => 1,
    builder => '_build_graphviz2',
);

has _edges => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Bool]',
    lazy    => 1,
    default => sub { {} },
    handles => {
        _set_edge         => 'set',
        _already_saw_edge => 'get',
    },
);

with 'MooseX::Getopt::Dashes';

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

    $self->_add_node_to_graph(
        name  => $self->_node_label_for($meta),
        shape => 'box',
    );

    # We halve the weight each time we go up the tree. This makes the graph
    # cleaner (straighter lines) nearest the node we start from.
    my $weight = 2048;
    $self->_follow_parents( $meta, $weight )
        if $meta->isa('Moose::Meta::Class');
    $self->_follow_roles( $meta, $meta, $weight );

    $self->_graph->run(
        format      => 'svg',
        output_file => $self->output,
    );

    return 0;
}

sub _add_node_to_graph {
    my $self = shift;

    $self->_graph->add_node(@_);

    return;
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
        $self->_maybe_add_edge_to_graph(
            from   => $parent,
            to     => $meta,
            type   => _CLASS,
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

    my @new_metas;

    # For the purposes of this graph, Composite roles are essentially an
    # implementation detail of Moose. We just want to see that Class A
    # consumes Roles X, Y, & Z. The fact that this was done in a single "with"
    # (or not) is not going to be included on the graph. We skip composite
    # roles and simply graph the roles that they are composed of.
    if ( $role->isa('Moose::Meta::Role::Composite') ) {
        @new_metas = $role;
    }
    else {
        my ( $role_for_node, $type );
        if (
            $role->isa(
                'MooseX::Role::Parameterized::Meta::Role::Parameterized')
            ) {
            $role_for_node = $role->genitor;
            $type          = _P_ROLE;

            # We need to look at the roles provided by by the genitor role as
            # well as the generated role. The latter case occurs when "with"
            # is called inside the role{} block.
            @new_metas = ( $role, $role->genitor );
        }
        else {
            $role_for_node = $role;
            $type          = _ROLE;
            @new_metas     = $role;
        }

        $self->_maybe_add_edge_to_graph(
            from   => $role_for_node,
            to     => $to_meta,
            weight => $weight,
            type   => $type,
        );

        $to_meta = $role_for_node;
    }

    $self->_follow_roles( $to_meta, $_, $weight ) for @new_metas;

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
sub _maybe_add_edge_to_graph {
    my $self = shift;
    my %p    = @_;

    @p{qw( from to )}
        = map { $self->_node_label_for($_) } @p{qw( from to )};

    # When a parameterized role consumes role inside its role{} block, we may
    # end up trying to add an edge from the parameterized role to itself,
    # which we can just ignore.
    return if $p{from} eq $p{to};

    my $key = join ' - ', @p{qw( from to )};
    return if $self->_already_saw_edge($key);

    $self->_add_edge_to_graph( key => $key, %p );

    return;
}

# This is separated out mostly so that the test class can override this and
# record its own version of the edges that are added to the graph.
sub _add_edge_to_graph {
    my $self = shift;
    my %p    = @_;

    $self->_graph->add_edge(
        from   => $p{from},
        to     => $p{to},
        weight => $p{weight},
        %{ $self->formatting->[ $p{type} ] },
    );

    $self->_set_edge( $p{key} => 1 );

    return;
}

sub _node_label_for {
    my $self = shift;
    my $meta = shift;

    return $meta unless blessed $meta && $meta->can('name');
    return $meta->name;
}

sub _build_formatting {
    return [
        {
            color => 'blue',
            label => 'extends',
        },
        {
            color => 'green',
            label => 'consumes',
        },
        {
            color => 'lawngreen',
            label => 'consumes with parameters',
        },
    ];
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Produce a GraphViz graph showing meta-information about classes and roles

__END__

=pod

=encoding UTF-8

=for Pod::Coverage run

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

=cut
