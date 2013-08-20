# @(#)$Ident: DZ_Build.PL 2013-08-15 13:04 pjf ;

use strict;
use warnings;

use Module::Build;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

my $perl_ver = 5.008;
my $name     = 'Catalyst-Plugin-ConfigComponents'; $name =~ s{ - }{::}gmx;

$] >= $perl_ver or $ENV{PERL5_CPANPLUS_IS_VERSION}
   or whimper "Minimum required Perl version is ${perl_ver}";

Module::Build->subclass( code => do { local $/; <DATA> } )->new(
  'module_name' => $name,
  'notes'       => { min_perl_version => $perl_ver },
  'build_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'requires' => {
    'Catalyst' => '5.90010',
    'Devel::InnerPackage' => '0.3',
    'MRO::Compat' => '0.11',
    'Module::Pluggable' => '4.8',
    'Moose' => '2.0402',
    'Path::Class' => '0.16',
    'namespace::autoclean' => '0.05',
    'parent' => '0.224',
    'perl' => '5.008',
    'version' => '0.88'
  },

)->create_build_script;

exit 0;

__DATA__

sub _normalize_prereqs { # Dynamic config
   my $self = shift; my $p = $self->SUPER::_normalize_prereqs; return $p;
}
