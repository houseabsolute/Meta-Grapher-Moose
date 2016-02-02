package Meta::Grapher::Moose::PlantUMLClass;
use Moose;

use Meta::Grapher::Moose::Constants qw( _CLASS _ROLE _P_ROLE );

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has class_type => (
    is => 'rw',         # ARRRRGH
    isa => 'Int',       # ARRRRGH, should have better type here
    default => _CLASS,  # Horrible Horrible code
);

########################################################################
# TODO: this shouldn't be created here!
########################################################################

has class_attributes => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    builder => '_build_class_attributes',
);

sub _build_class_attributes {
    my $self = shift;

    my $meta = $self->name->meta;
    return [$meta->get_attribute_list];
}

has class_methods => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    builder => '_build_class_methods',
);

sub _build_class_methods {
    my $self = shift;

    my $meta = $self->name->meta;
    return [$meta->get_method_list];
}

########################################################################

sub to_plantuml {
    my $self = shift;

    my $extra = '';
    if ($self->class_type == _ROLE) {
        $extra = '<<R,#FF7700>>';
    } elsif ($self->class_type == _P_ROLE) {
        $extra = '<<P,orchid>>';
    }

    my $attributes = join "\n", map { "$_" } sort @{ $self->class_attributes };
    my $methods = join "\n", map { "$_()" } sort @{ $self->class_methods };

    return <<"END";
class "@{[ $self->name ]}" ${extra}{
$attributes
$methods
}

END
}

__PACKAGE__->meta->make_immutable;
1;

