#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib");
use Test::More tests => 27;

{
    package MyApp;

    use Catalyst qw(ConfigComponents);

    __PACKAGE__->config(
        map { +"$_\::Explicit" => { base_class => [ "CatalystX::$_",
                                                    "Catalyst::$_" ] },
              +"$_\::Explicit::Sub" => { base_class => "Catalyst::$_" },
              +"$_\::Implicit" => {},
            } qw/Model View Controller/
    );
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
