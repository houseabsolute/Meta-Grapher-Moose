package Meta::Grapher::Moose::PlantUMLLink;
use Moose;

has 'from' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'to' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub to_plantuml {
    my $self = shift;

    return <<"END";
"@{[ $self->to ]}" --> "@{[ $self->from ]}"
END
}

__PACKAGE__->meta->make_immutable;
1;

