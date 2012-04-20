# @(#)$Id: Build.PL 1182 2012-04-19 15:29:38Z pjf $

use strict;
use warnings;
use inc::Bob; # Module::Build subclass
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 1182 $ =~ /\d+/gmx );

Bob->new( {
   module     => q(Catalyst::Plugin::ConfigComponents),
   home_page  => q(http://www.roxsoft.co.uk),
   requires   => {
      'perl'                 => 5.010,
      'namespace::autoclean' => 0.05,
      'version'              => 0.74,
      'Catalyst'             => 5.90010,
      'Devel::InnerPackage'  => 0.3,
      'Moose'                => 2.0402,
      'Path::Class'          => 0.16, },
   configure_requires => { 'version'       => 0.74,
                           'Module::Build' => 0.38,
                           'MRO::Compat'   => 0.11, },
   build_requires     => { 'Test::More'    => 0.74, },
} )->create_build_script; # Goal!

# Local Variables:
# mode: perl
# tab-width: 3
# End:
