package Meta::Grapher::Moose;

our $VERSION = '0.05';
use Moose;

with (
    'Meta::Grapher::Moose::Role::Analyzer',
    'Meta::Grapher::Moose::Role::GraphViz2',
);

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Produce a GraphViz graph showing meta-information about classes and roles

__END__

=pod

=encoding UTF-8

=for Pod::Coverage run

=head1 SYNOPSIS

    you@hostname:~$ graph-meta.pl --package Your::Package --output your-package.svg

=head1 DESCRIPTION

This distribution ships an executable, F<graph-meta.pl>, that uses
L<GraphViz2> to produce a graph showing information about a package. It always
shows the roles consumed by the package, and the roles those roles consume,
and so on. If given a class name, it will also graph inheritance, but you can
give this tool a role name as well.

B<This is still a very early release and there are a lot of improvements that
could be made. Suggestions and pull requests are welcome.>

=cut

