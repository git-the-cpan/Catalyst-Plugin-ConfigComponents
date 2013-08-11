# @(#)Ident: 10test_script.t 2013-08-11 11:22 pjf ;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1 $ =~ /\d+/gmx );
use File::Spec::Functions   qw( catdir updir );
use FindBin                 qw( $Bin );
use lib                 catdir( $Bin, 'lib' ), catdir( $Bin, updir, 'lib' );

use Test::More;

{
   package MyApp;

   use Catalyst qw( ConfigComponents );

   __PACKAGE__->config
      ( map { +"$_\::Explicit" => {
                parent_classes => [ "CatalystX::$_", "Catalyst::$_" ] },
              +"$_\::Explicit::Sub" => { parent_classes => "Catalyst::$_" },
              +"$_\::Implicit" => {},
           } qw/Model View Controller/ );

   __PACKAGE__->setup;
}

for my $comp (qw/Model View Controller/) {
   my  $method = lc $comp;

   for my $type (qw/Explicit Implicit/) {
      isa_ok( MyApp->$method( "$type"       ), "MyApp::$comp\::$type" );
      isa_ok( MyApp->$method( "$type"       ), "CatalystX::$comp" )
         if ($type eq q(Explicit));
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
