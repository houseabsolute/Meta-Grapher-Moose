package Meta::Grapher::Moose::Constants;
use base qw(Exporter);

# ABSTRACT: Internal constants used by Meta::Grapher::Moose

=head1 SYNOPSIS

  use Meta::Grapher::Moose::Constants qw(
    _CLASS _ROLE _P_ROLE
  );

=head1 DESCRIPTION

This module allows you to import several constants that are used throughout
the L<Meta::Grapher::Moose> code base.

=head3 CLASS

Constant representing that the package is a Moose class.

=head3 ROLE

Constant representing that the package is a parameterized Moose role.

=head3 P_ROLE

Constant representing that the package is a non-parameterized Moose role.

=head3 ANON_ROLE

Constant representing that the package is an anonymous role created by a
parameterized role

=cut

use strict;
use warnings;

our $VERSION = '1.00';
our @EXPORT_OK;

# note that these constants need to have actual human readable values
# because they allow the user to configure things like the color of output
# from the command line in the plantuml renderer.
sub CLASS()     { return 'class'; }
sub ROLE()      { return 'role'; }
sub P_ROLE()    { return 'prole'; }
sub ANON_ROLE() { return 'anonrole'; }

push @EXPORT_OK, qw( CLASS ROLE P_ROLE ANON_ROLE );

1;
