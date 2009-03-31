#!/usr/bin/perl

use strict;
use warnings;
use File::Spec::Functions;
use FindBin  qw( $Bin );
use lib (catdir( $Bin, q(lib) ), catdir( $Bin, updir, q(lib) ));
use Test::More;

BEGIN {
   if ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CR_SMOKER_CURRENT}
       || ($ENV{PERL5OPT} || q()) =~ m{ CPAN-Reporter }mx
       || ($ENV{PERL5_CPANPLUS_IS_RUNNING} && $ENV{PERL5_CPAN_IS_RUNNING})) {
      plan skip_all => q(CPAN Testing stopped);
   }

   plan tests => 27;
}

{
   package MyApp;

   use Catalyst qw(ConfigComponents);

   __PACKAGE__->config
      ( map { +"$_\::Explicit" => { base_class => [ "CatalystX::$_",
                                                    "Catalyst::$_" ] },
              +"$_\::Explicit::Sub" => { base_class => "Catalyst::$_" },
              +"$_\::Implicit" => {},
           } qw/Model View Controller/ );

   __PACKAGE__->setup;
}

for my $comp (qw/Model View Controller/) {
   my  $method = lc $comp;
   for my $type (qw/Explicit Implicit/) {
      isa_ok(MyApp->$method("$type"), "MyApp::$comp\::$type");
      isa_ok(MyApp->$method("$type"), "CatalystX::$comp")
         if ($type eq q(Explicit));
      isa_ok(MyApp->$method("$type"), "Catalyst::$comp");
      isa_ok(MyApp->$method("$type\::Sub"), "MyApp::$comp\::$type\::Sub");
      isa_ok(MyApp->$method("$type\::Sub"), "Catalyst::$comp");
   }
}
