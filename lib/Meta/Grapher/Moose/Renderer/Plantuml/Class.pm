package Meta::Grapher::Moose::Renderer::Plantuml::Class;
use namespace::autoclean;
use Moose;

our $VERSION = '1.00';

# ABSTRACT: Utility class for Meta::Grapher::Moose::Renderer::Plantuml

use Digest::MD5 qw(md5_hex);

=head1 DESCRIPTION

Internal class part of the L<Meta::Grapher::Moose::Renderer::Plantuml>
renderer.  Represents a package to be rendered.

=head2 Attributes

=head3 id

The id of the package (which is the actual true classname of the package,
even if the class is an anonymous class)

Required.

=cut

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head3 label

The classname we put on the diagram (which might be the true classname or the
parameterized class name we create an anonymous class from)

=cut

has label => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->name },
);

=head3 type

The type of the package.

One of the values provided by L<Meta::Grapher::Moose::Constants>: C<_CLASS>,
C<_ROLE>, C<_ANON_ROLE> or C<_P_ROLE>

Required.

=cut

# TODO: This should probably be an enum type
has class_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head3 class_attributes

An arrayref of strings, the name of attributes for the class.

Required.

=cut

has class_attributes => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

=head3 class_methods

An arrayref of strings, the name of methods for the class.

Required.

=cut

has class_methods => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

=head3 formatting

A copy of the C<formatting> attribute from the controlling
L<Meta::Grapher::Moose::Renderer::Plantuml> instance that created this
instance.

Required.

=cut

has formatting => (
    is       => 'ro',
    isa      => 'HashRef[Str]',
    required => 1,
);

########################################################################

=head2 Methods

=head3 to_plantuml

Return source code representing this class

=cut

sub to_plantuml {
    my $self = shift;

    my $extra = $self->formatting->{ $self->class_type } // q{};

    my $attributes = join "\n", map {"$_"} sort @{ $self->class_attributes };
    my $methods    = join "\n", map {"$_()"} sort @{ $self->class_methods };

    return <<"END";
class "@{[ $self->label ]}" as @{[ md5_hex($self->id) ]} ${extra}{
$attributes
$methods
}

END
}

__PACKAGE__->meta->make_immutable;
1;

