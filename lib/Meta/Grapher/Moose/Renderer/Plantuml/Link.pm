package Meta::Grapher::Moose::Renderer::Plantuml::Link;
use namespace::autoclean;
use Moose;

use Digest::MD5 qw(md5_hex);

our $VERSION = '1.00';

# ABSTRACT: Utility class for Meta::Grapher::Moose::Renderer::Plantuml

=head1 DESCRIPTION

Internal class.  Part of the L<Meta::Grapher::Moose::Renderer::Plantuml>
renderer.  Represents a link between two packages to be rendered.

=head2 Attributes

=head3 from

The id of the package we're linking from.

Required.

=cut

has from => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head3 to

The id of the package we're linking to.

Required.

=cut

has to => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 Methods

=head3 to_plantuml

Return source code representing this link as plantuml source.

=cut

sub to_plantuml {
    my $self = shift;

    return <<"END";
"@{[ md5_hex($self->to) ]}" --> "@{[ md5_hex($self->from) ]}"
END
}

__PACKAGE__->meta->make_immutable;
1;
