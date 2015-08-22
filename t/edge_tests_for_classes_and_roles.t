## no critic (Modules)
use warnings;
use strict;
use version;
use lib '../lib';
use File::Temp qw(tempfile);
use Scalar::Util qw(reftype);
use Data::Dumper;
use Test::More tests => 31;
use Storable qw(dclone);

my $DEBUG = $ARGV[0];    # this will double as the location to store the graph

### Testing begin now.
use_ok( 'Meta::Grapher::Moose', qv('v0.3')->numify );

my $test_config = {
    ClassA => {
        ClassB => { RoleA => { RoleB => { RoleC => 1, RoleD => 1 } } },
        ClassC => {
            ClassD => 1,
            ParamRoleW =>
                { ParamRoleX => 1, ParamRoleY => { ParamRoleZ => 1 } }
        },
    },
};

print 'Test Config: ' . Dumper($test_config) || die if $DEBUG;

my $parsed = { packages => [], edges => [] };
$parsed = parse_config( $test_config, $parsed );

print 'Parsed Config: ' . Dumper($parsed) || die if $DEBUG;

foreach my $package_string ( @{ $parsed->{packages} } ) {
    my ( $parent, $package ) = split m/\0/, $package_string;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval "$package" or die $@;
    use_ok($parent);
    new_ok($parent) if $parent =~ m/class/i;
}

# List context is needed to get the path which we need, but list context
#  also returns the file handle (e.g. $fh), which we don't need.
my ( undef, $temp_filename ) = tempfile();

# Use whatever was provided as the DEBUG, if anything was provided.
my $filename = $DEBUG ? $DEBUG : $temp_filename;

my $meta_graph = new_ok(
    'Meta::Grapher::Moose',
    [ output => $filename, package => 'ClassA' ]
);
$meta_graph->run;
my $got = dclone $meta_graph->{_edges};

print 'Obtained Graph Edges: ' . Dumper($got) || die if $DEBUG;

foreach my $expected_edge ( @{ $parsed->{edges} } ) {
    my ( $from, $to ) = split m/\0/, $expected_edge;
    my $found_edge = delete $got->{$expected_edge};
    ok( defined $found_edge, "Got the expected edge between $from and $to." );
}

foreach my $extra_edge ( keys %$got ) {
    my ( $from, $to ) = split /\0/, $extra_edge;
    fail("Unexpected edge between $from and $to!");
}

exit;    # Done testing.

### Supporting Subroutines
sub convert_to_package_string {
    my ( $from, @to_list ) = @_;
    my $package = "{ package $from; ";
    my $type    = get_package_type($from);
    $package .= "use $type; ";
    $package .= 'role { ' if $from =~ m/param/i;
    my ( @roles, @parents );
    foreach my $to (@to_list) {
        if ( $to =~ m/class/i ) {
            push @parents, $to;
        }
        elsif ( $to =~ m/role/i ) {
            push @roles, $to;
        }
        else {
            die 'Expected names that include "class" or "role". Not sure '
                . "how to make '$from' of type '$type' interact with '$to'!";
        }
    }
    if (@parents) {
        $package .= 'extends "' . ( join '", "', @parents ) . '"; ';
    }
    foreach my $role (@roles) {
        $package .= "with '$role'; ";
    }
    $package .= '}; ' if $from =~ m/param/i;
    $package .= '1; }';
}

sub get_package_type {
    my ($from) = @_;
    my ($type);
    if ( $from =~ m/class/i ) {
        $type = 'Moose';
    }
    elsif ( $from =~ m/param/i ) {
        $type = 'MooseX::Role::Parameterized';
    }
    elsif ( $from =~ m/role/i ) {
        $type = 'Moose::Role';
    }
    else {
        die "Could not determine type of '$from'!";
    }
    return $type;
}

sub parse_config {
    my ( $config, $result ) = @_;
    while ( my ( $this, $family ) = each $config ) {

        # Validate our configuration 'syntax'
        die 'Bad config (expects each key to be a hashref or "1")!'
            if $family != 1 && reftype($family) ne 'HASH';
        die
            'Bad config (expects non-empty hash-ref, use "1" instead of "{}")!'
            if ref $family
            && reftype($family) eq 'HASH'
            && 0 == keys %$family;

        # Base recursion case.
        $family = {} if $family == 1;

        # To process the 'parent' we need just the keys from the nexted
        # configuration. Later on, we will recurse into the nexted data.

        my @relations = keys %$family;

        # Create and 'use' the package.
        my $package = convert_to_package_string( $this, @relations );

        # Recursion case.
        $result = parse_config( $family, $result );

        # Update our expecations
        print $this. '(' . ( scalar @relations ) . '): $package' . "\n"
            || die
            if $DEBUG;
        push @relations, 'Moose::Object'
            if $this =~ m/class/i && 0 == grep {m/class/i} @relations;
        push @{ $result->{edges} }, map { join "\0", $_, $this } @relations;
        push @{ $result->{packages} }, $this . "\0" . $package;
    }
    return $result;
}
