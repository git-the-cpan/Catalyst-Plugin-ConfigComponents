# @(#)$Id: 10component_dynamic.t 97 2009-06-21 19:58:36Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 97 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin  qw( $Bin );
use lib (catdir( $Bin, q(lib) ), catdir( $Bin, updir, q(lib) ));

use English  qw(-no_match_vars);
use Test::More;

BEGIN {
   if ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CR_SMOKER_CURRENT}
       || ($ENV{PERL5OPT} || q()) =~ m{ CPAN-Reporter }mx) {
      plan skip_all => q(CPAN Testing stopped);
   }

   plan tests => 27;
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

# Local Variables:
# mode: perl
# tab-width: 3
# End:
