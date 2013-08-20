# @(#)Ident: 10test_script.t 2013-08-20 22:33 pjf ;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.8.%d', q$Rev: 1 $ =~ /\d+/gmx );
use File::Spec::Functions   qw( catdir updir );
use FindBin                 qw( $Bin );
use lib                 catdir( $Bin, 'lib' ), catdir( $Bin, updir, 'lib' );

use Module::Build;
use Test::More;

my $notes = {}; my $perl_ver;

BEGIN {
   my $builder = eval { Module::Build->current };
      $builder and $notes = $builder->notes;
      $perl_ver = $notes->{min_perl_version} || 5.008;
}

use Test::Requires "${perl_ver}";

{  package MyApp;

   use Catalyst qw( ConfigComponents );

   __PACKAGE__->config
      ( map { +"$_\::Explicit" => {
                parent_classes => [ "CatalystX::$_", "Catalyst::$_" ] },
              +"$_\::Explicit::Sub" => { parent_classes => "Catalyst::$_" },
              +"$_\::Implicit" => {},
           } qw( Model View Controller ) );

   __PACKAGE__->setup;
}

for my $comp (qw( Model View Controller )) {
   my  $method = lc $comp;

   for my $type (qw( Explicit Implicit )) {
      isa_ok( MyApp->$method( "$type"       ), "MyApp::$comp\::$type" );
      isa_ok( MyApp->$method( "$type"       ), "CatalystX::$comp" )
         if ($type eq 'Explicit');
      isa_ok( MyApp->$method( "$type"       ), "Catalyst::$comp" );
      isa_ok( MyApp->$method( "$type\::Sub" ), "MyApp::$comp\::$type\::Sub" );
      isa_ok( MyApp->$method( "$type\::Sub" ), "Catalyst::$comp" );
   }
}

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
