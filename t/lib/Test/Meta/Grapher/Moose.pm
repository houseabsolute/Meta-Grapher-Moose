## no critic (Moose::RequireMakeImmutable)
package Test::Meta::Grapher::Moose;

use strict;
use warnings;

use lib 't/lib';

use Class::MOP ();
use Data::Dumper::Concise;
use File::Spec;
use Moose ();
use Moose::Meta::Class;
use Moose::Meta::Role;
use Moose::Util qw( find_meta );
use MooseX::Role::Parameterized ();
use Test::Meta::Grapher::Moose::Recorder;
use Test::Meta::Grapher::Moose;
use Test::More 0.96;

use Meta::Grapher::Moose::Constants qw( _CLASS _ROLE _P_ROLE );

use parent 'Exporter';

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = 'test_graphing_for';
## use critic

{
    my $prefix = 'Test001';

    sub test_graphing_for {
        my $package_to_test = shift;
        my %packages        = @_;

        my $expect = _define_packages( $prefix, %packages );

        my $root_package = join '::', $prefix, $package_to_test;

        my $output = File::Spec->devnull;
        if ( $ENV{TEST_GRAPH_DIR} ) {
            ( my $file = $root_package ) =~ s/::/-/g;
            $file .= '.svg';
            $output = File::Spec->catfile( $ENV{TEST_GRAPH_DIR}, $file );
        }

        my $grapher = Test::Meta::Grapher::Moose::Recorder->new(
            package => $root_package,
            output  => $output,
        );
        $grapher->run;

        is_deeply(
            $grapher->recorded_nodes_added_to_graph,
            [$root_package],
            'added a single node to the graph for the root node'
        );

        unless (
            is_deeply(
                $grapher->recorded_edges_added_to_graph,
                $expect,
                'got expected edges'
            )
            ) {

            diag('Got:');
            diag( Dumper( $grapher->recorded_edges_added_to_graph ) );
            diag('Expected:');
            diag( Dumper($expect) );
        }

        if ( $ENV{TEST_GRAPH_DIR} ) {
            diag("Graph is at $output");
        }

        return ( $prefix++, $grapher );
    }
}

sub _define_packages {
    my $prefix   = shift;
    my %packages = @_;

    my %expect;
    for my $package ( sort keys %packages ) {
        _define_one_package( $prefix, $package, \%packages, \%expect );
    }

    return \%expect;
}

sub _define_one_package {
    my $prefix   = shift;
    my $name     = shift;
    my $packages = shift;
    my $expect   = shift;

    my $full_name = join '::', $prefix, $name;

    return $full_name if find_meta($full_name);

    my @roles
        = map { _define_one_package( $prefix, $_, $packages, $expect ) }
        _listify( $packages->{$name}{with} );

    if ( $name =~ /^Class/ ) {
        my @super
            = map { _define_one_package( $prefix, $_, $packages, $expect ) }
            _listify( $packages->{$name}{extends} );

        Moose::Meta::Class->create(
            $full_name,
            ( @roles ? ( roles        => \@roles ) : () ),
            ( @super ? ( superclasses => \@super ) : () ),
        );

        _record_expect( $full_name, \@roles, \@super, $expect );
    }
    elsif ( $name =~ /^Role/ ) {
        Moose::Meta::Role->create(
            $full_name,
            ( @roles ? ( roles => \@roles ) : () ),
        );

        _record_expect( $full_name, \@roles, [], $expect );
    }
    elsif ( $name =~ /^ParamRole/ ) {
        my @role_block_roles
            = map { _define_one_package( $prefix, $_, $packages, $expect ) }
            _listify( $packages->{$name}{role_block_with} );

        my $outer_with_list = join ', ',
            map { B::perlstring($_) } @roles;

        my $inner_with_list = join ', ',
            map { B::perlstring($_) } @role_block_roles;

        ## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
        eval <<"EOF";
package $full_name;
use MooseX::Role::Parameterized;

with $outer_with_list if length q{$outer_with_list};

role {
    with $inner_with_list if length q{$inner_with_list};
};
EOF

        die $@ if $@;
        ## use critic

        _record_expect(
            $full_name, [ @roles, @role_block_roles ], [],
            $expect
        );
    }
    else {
        die "unknown prefix for package - $name";
    }

    return $full_name;
}

sub _listify {
    return () unless $_[0];
    return ref $_[0] ? @{ $_[0] } : $_[0];
}

sub _record_expect {
    my $name   = shift;
    my $roles  = shift;
    my $super  = shift;
    my $expect = shift;

    ## no critic (Subroutines::ProtectPrivateSubs)
    for my $role ( @{$roles} ) {
        $expect->{ join ' - ', $role, $name } = {
            from => $role,
            to   => $name,
            type => (
                $role =~ /::Param/
                ? _P_ROLE
                : _ROLE
            ),
        };
    }

    for my $super ( @{$super} ) {
        $expect->{ join ' - ', $super, $name } = {
            from => $super,
            to   => $name,
            type => _CLASS
        };
    }

    return;
}

1;
