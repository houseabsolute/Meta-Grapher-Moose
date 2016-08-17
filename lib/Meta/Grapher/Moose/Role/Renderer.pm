package Meta::Grapher::Moose::Role::Renderer;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.01';

use Moose::Role;

with 'MooseX::Getopt::Dashes';

requires 'add_edge', 'add_package', 'render';

1;

# ABSTRACT: Base role for all Meta::Grapher::Moose renderers

__END__

=head1 REQUIRED METHODS

There are several methods that must be implemented.

=head3 add_package( name => $name, attributes => \@attr, methods => \@meth )

A request that a package is added to the rendered output.  The C<attributes>
and C<methods> contain arrays of attribute and method names which the renderer
may use if it wants.

=head3 add_edge( from => $from_package_name, to => $to_package_name )

A request that the rendered output indicate one package consumes another.

=head3 render()

Actually do the rendering, presumably rendering to an output file or some such

=cut
