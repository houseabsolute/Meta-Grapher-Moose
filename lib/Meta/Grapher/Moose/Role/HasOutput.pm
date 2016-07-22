package Meta::Grapher::Moose::Role::HasOutput;
use namespace::autoclean;
use Moose::Role;

# ABSTRACT: Role with standard way to specify Meta::Grapher::Moose output

our $VERSION = '1.00';


# these are documented in the role consumers

=for Pod::Coverage output has_output format

=cut

has output => (
    is  => 'ro',
    isa => 'Str',
);

sub has_output { my $self = shift; return defined $self->output }

has format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_format',
);

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
