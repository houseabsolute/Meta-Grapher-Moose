package Meta::Grapher::Moose::Constants;
use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '0.05';
our @EXPORT_OK;

sub _CLASS()  { return 0; }
sub _ROLE()   { return 1; }
sub _P_ROLE() { return 2; }

push @EXPORT_OK, qw(_CLASS _ROLE _P_ROLE);

1;
