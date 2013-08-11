
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4004",
    "version" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.4004",
    "version" => "0.88"
  },
  "dist_abstract" => "Creates Catalyst components from config entries",
  "dist_author" => [
    "Peter Flanigan <pjfl\@cpan.org>"
  ],
  "dist_name" => "Catalyst-Plugin-ConfigComponents",
  "dist_version" => "0.7.2",
  "license" => "perl",
  "module_name" => "Catalyst::Plugin::ConfigComponents",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Catalyst" => "5.90010",
    "Devel::InnerPackage" => "0.3",
    "MRO::Compat" => "0.11",
    "Module::Pluggable" => "4.8",
    "Moose" => "2.0402",
    "Path::Class" => "0.16",
    "namespace::autoclean" => "0.05",
    "parent" => "0.224",
    "version" => "0.88"
  },
  "script_files" => [],
  "test_requires" => {}
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
