package Meta::Grapher::Moose::Role::PlantUML;
use Moose::Role;

use autodie;

use Meta::Grapher::Moose::PlantUMLClass;
use Meta::Grapher::Moose::PlantUMLLink;

requires 'output';

# right now there's no reason for this *not* to be rw since it just flips
# the mode of what we're creating.
has output_type => (
    is => 'rw',
    isa => 'Str', 
    default => 'text',
);

has _plantuml_classes => (
    is => 'ro',
    isa => 'HashRef[Meta::Grapher::Moose::PlantUMLClass]',
    default => sub { return {} },
    traits  => ['Hash'],
    handles   => {
        _add_plantuml_class => 'set',
        _get_plantuml_class => 'get',
        _all_plantuml_classes => 'values',
    },

);

has _plantuml_links => (
    is => 'ro',
    isa => 'ArrayRef[Meta::Grapher::Moose::PlantUMLLink]',
    default => sub { return [] },
    traits  => ['Array'],
    handles   => {
        _add_plantuml_link => 'push',
        _all_plantuml_links => 'elements',
    },
);

sub _calculate_source {
    my $self = shift;

    return '@startuml' . "\n" .
        join('', map { $_->to_plantuml } sort { $a->name cmp $b->name } $self->_all_plantuml_classes) . 
        join('', sort map { $_->to_plantuml } $self->_all_plantuml_links) .
        '@enduml' . "\n";
}

sub _update_plantuml_class_type {
    my $self = shift;
    my $name = shift;
    my $type = shift;

    $self->_add_package_to_graph( name => $name );
    $self->_get_plantuml_class( $name )->class_type( $type );
}

sub _create_tempfile {
    my $self = shift;

    my ($fh, $filename) = tempfile();
    print $fh, $self->_calculate_source;
    close $fh;

    return $filename;
}

#### required methods ######

sub _render_to_file {
    my $self = shift;

    my $src = $self->_calculate_source;

    if ($self->output_type eq 'text') {
        open my $fh, '>:encoding(UTF-8)', $self->output;
        print $fh $src;
        return;
    }

    my ($fh, $temp_filename) = tempfile();
    binmode $fh, ':encoding(UTF-8)';
    print $fh, $src;
    close $fh;

    # TODO: process that temp file


    unlink $temp_filename;

    return;
}

sub _add_package_to_graph {
    my $self = shift;
    my %args = @_;

    $self->_add_plantuml_class(
        $args{name},
        Meta::Grapher::Moose::PlantUMLClass->new(
            name => $args{name},
        )
    ) unless $self->_get_plantuml_class( $args{name} );

    return;
}

sub _add_edge {
    my $self = shift;
    my %p = @_;

    $self->_add_plantuml_link(
        Meta::Grapher::Moose::PlantUMLLink->new(
            from => $p{from},
            to => $p{to},
        )
    );

    # rather than keep track of the type of things with the links
    # we keep track of the actual thing itself
    $self->_update_plantuml_class_type( $p{from}, $p{type} );

    return;
}

1;
