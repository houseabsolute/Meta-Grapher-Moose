package Meta::Grapher::Moose::Role::Renderer;
use namespace::autoclean;
use Moose::Role;

# ASBTRACT: Base role for all Meta::Grapher::Moose renderers

our $VERSION = '1.00';

with 'MooseX::Getopt::Dashes';

requires 'add_edge', 'add_package', 'render';

=head2 Required Methods

There are several methods that must be implemented.

=over

=item add_package( name => $name, attributes => \@attr, methods => \@meth )

A request that a package is added to the rendered output.  The C<attributes>
and C<methods> contain arrays of attribute and method names which the renderer
may use if it wants.

=item add_edge( from => $from_package_name, to => $to_package_name )

A request that the rendered output indicate one package consumes another.

=item render()

Actually do the rendering, presumably rendering to an output file or some such

=back

=cut

1;
