requires "Getopt::Long" => "0";
requires "GraphViz2" => "0";
requires "Moose" => "0";
requires "MooseX::Getopt::Dashes" => "0";
requires "Scalar::Util" => "0";
requires "Try::Tiny" => "0";
requires "autodie" => "0";
requires "constant" => "0";
requires "namespace::autoclean" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Class::MOP" => "0";
  requires "Exporter" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Moose::Meta::Class" => "0";
  requires "Moose::Meta::Role" => "0";
  requires "Moose::Util" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Requires" => "0";
  requires "lib" => "0";
  requires "parent" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Code::TidyAll" => "0.24";
  requires "Data::Dumper::Concise" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "MooseX::Role::Parameterized" => "1.00";
  requires "Perl::Critic" => "1.123";
  requires "Perl::Tidy" => "20140711";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.24";
  requires "Test::EOL" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Pod::LinkCheck" => "0";
  requires "Test::Pod::No404s" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Version" => "1";
};
