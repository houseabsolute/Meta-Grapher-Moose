package Meta::Grapher::Moose::Renderer::Plantuml::Link;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.03';

use Digest::MD5 qw(md5_hex);

use Moose;

has from => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has to => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub to_plantuml {
    my $self = shift;

    return <<"END";
"@{[ md5_hex($self->to) ]}" --> "@{[ md5_hex($self->from) ]}"
END
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Utility class for Meta::Grapher::Moose::Renderer::Plantuml

__END__

=pod

=encoding UTF-8

=head1 DESCRIPTION

Internal class. Part of the L<Meta::Grapher::Moose::Renderer::Plantuml>
renderer. Represents a link between two packages to be rendered.

=head1 ATTRIBUTES

This class accepts the following attributes:

=head2 from

The id of the package we're linking from.

Required.

=head2 to

The id of the package we're linking to.

Required.

=head1 METHODS

This class provides the following methods:

=head2 to_plantuml

Return source code representing this link as plantuml source.

=cut
