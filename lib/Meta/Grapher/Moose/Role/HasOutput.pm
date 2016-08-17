package Meta::Grapher::Moose::Role::HasOutput;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.01';

use Moose::Role;

has output => (
    is  => 'ro',
    isa => 'Str',
);

has format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_format',
);

sub has_output { defined $_[0]->output }

sub _build_format {
    my $self = shift;

    # attempt to use the file extension as the format, if there is a usable
    # extension that is...
    my $ext;
    unless ( $self->has_output
        && ( ($ext) = $self->output =~ /[.]([^.]+)\z/ ) ) {
        return 'src';
    }

    return $ext;
}

1;

# ABSTRACT: Role with standard way to specify Meta::Grapher::Moose output

__END__

=for Pod::Coverage output has_output format
