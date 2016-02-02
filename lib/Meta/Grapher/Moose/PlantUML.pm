package Meta::Grapher::Moose::PlantUML;

our $VERSION = '0.05';
use Moose;

with (
    'Meta::Grapher::Moose::Role::Analyzer',
    'Meta::Grapher::Moose::Role::PlantUML',
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Produce PlantUML source showing meta-information about classes and roles

__END__

=pod

=encoding UTF-8

=for Pod::Coverage run

=head1 SYNOPSIS

    you@hostname:~$ graph-meta-plantuml.pl --package Your::Package --output your-package.txt
    you@hostname:~$ java -jar plantuml.jar your-package.txt
    you@hostname:~$ open your-package.png

=head1 DESCRIPTION

Similar to L<plantuml>.

B<This is still a very early release and there are a lot of improvements that
could be made. Suggestions and pull requests are welcome.>

=cut

