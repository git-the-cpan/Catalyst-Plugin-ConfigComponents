# @(#)$Id: 10component_dynamic.t 128 2012-04-19 23:21:40Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 128 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin  qw( $Bin );
use lib (catdir( $Bin, q(lib) ), catdir( $Bin, updir, q(lib) ));

use Module::Build;
use Test::More;

BEGIN {
   my $current = eval { Module::Build->current };

   $current and $current->notes->{stop_tests}
            and plan skip_all => $current->notes->{stop_tests};
}

{
   package MyApp;

   use Catalyst qw(ConfigComponents);

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
