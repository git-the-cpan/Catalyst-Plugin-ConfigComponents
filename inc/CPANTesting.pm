# @(#)$Id: CPANTesting.pm 128 2012-04-19 23:21:40Z pjf $

package CPANTesting;

use strict;
use warnings;

my $uname = qx(uname -a); my $osname = lc $^O;

sub broken_toolchain {
   return 0;
}

sub exceptions {
   $osname eq q(cygwin)  and return 'Cygwin not supported';
   $osname eq q(mirbsd)  and return 'Mirbsd not supported';
   $osname eq q(mswin32) and return 'Mswin  not supported';
   $osname eq q(netbsd)  and return 'Netbsd not supported';
   return 0;
}

1;

__END__
