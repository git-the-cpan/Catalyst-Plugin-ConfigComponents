# @(#)$Id: ConfigComponents.pm 109 2009-06-25 21:17:17Z pjf $

package Catalyst::Plugin::ConfigComponents;

use strict;
use warnings;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.4.%d', q$Rev: 109 $ =~ /\d+/gmx );

use Class::C3;
use Catalyst::Utils;
use Devel::InnerPackage ();

sub setup_components {
   my $class  = shift;
   my $config = $class->config->{ q(Plugin::ConfigComponents) };
   my $method = delete $config->{setup_method} || q(_setup_config_components);

   $class->next::method; # After parent class setup_components
   $class->$method( $config );
   return;
}

# Private methods

sub _setup_config_components {
   my ($class, $config) = @_;

   my @paths = qw(::Controller ::Model ::View);

   push @paths, @{ delete $config->{ search_extra } || [] };

   my $prefix = join q(|), map { m{ :: (.*) \z }mx } @paths;
   my @comps  = grep { m{ \A (?:$prefix) :: }mx } keys %{ $class->config };

   for my $suffix (sort { length $a <=> length $b } @comps) {
      my $component = "$class\::$suffix";

      next if ($class->components->{ $component });

      my $cc     = $class->config->{ $suffix };
      my $active = delete $cc->{component_active};

      next if (defined $active and not $active);

      my $parents = delete $cc->{parent_classes}
                 || delete $cc->{base_class} # Deprecated
                 || "Catalyst::$suffix";

      $class->_load_component( $component, $parents );

      my %modules = ( $component => $class->setup_component( $component ),
                      map  { $_ => $class->setup_component( $_ ) }
                      grep { not exists $class->components->{ $_ } }
                      Devel::InnerPackage::list_packages( $component ) );

      for my $key ( keys %modules ) {
         $class->components->{ $key } = $modules{ $key };
      }
   }

   return;
}

sub _load_component {
   my ($class, $child, $parents) = @_;

   $parents = [ $parents ] unless (ref $parents eq q(ARRAY));

   for my $parent (reverse @{ $parents }) {
      Catalyst::Utils::ensure_class_loaded( $parent );
      ## no critic
      {  no strict 'refs';
         unless ($child eq $parent or $child->isa( $parent )) {
            unshift @{ "$child\::ISA" }, $parent;
         }
      }
      ## critic
   }

   unless (exists $Class::C3::MRO{ $child }) {
      eval "package $child; import Class::C3;"; ## no critic
   }

   return;
}

1;

__END__

=pod

=head1 Name

Catalyst::Plugin::ConfigComponents - Creates components from config entries

=head1 Version

0.4.$Revision: 109 $

=head1 Synopsis

   # In your Catalyst application
   package YourApp;

   use Catalyst qw(... ConfigComponents ...);

   __PACKAGE__->setup;

   Class::C3::initialize();

   # In your applications config file
   <component name="Model::YourModel">
      <parent_classes>YourExternal::ModelE<lt>/parent_classes>
      <parent_classes>Catalyst::ModelE<lt>/parent_classes>
   </component>

   # Do not create YourApp::Model::YourModel this module will do it for you

   # In a controller this will call your_method in
   # the class YourExternal::Model
   $result = $c->model( q(YourModel) )->your_method( ... );

=head1 Description

When the application starts this module creates Catalyst component
class definitions using config information. The defined class inherits
from the list of parent classes referenced in the config file

This code was originally posted to the Catalyst mailing list by
Dagfinn Ilmari Mannsåker as a patch in response to an idea by
Castaway. I thought it would be better as a plugin and have extended
it to handle MI

=head1 Configuration and Environment

Specify a I<Plugin::ConfigComponents> config option. Attributes are

=over 3

=item I<component_active>

If the I<component_active> config attribute exists and is false the
component will not be loaded

=item I<parent_classes>

List of classes for the derived component to inherit from

=item I<search_extra>

To add additional search paths, specify a key named I<search_extra>
as an array reference. Items in the array beginning with B<::> will
have the application class name prepended to them

=item I<setup_method>

Defaults to C<_setup_config_components>, the method to call after the
call to L<Catalyst::setup_components|Catalyst/setup_components>

=back

You may want to add the line:

   Class::C3::initialize();

to your Catalyst application after the C<< __PACKAGE__->setup >> call if
the base class creates any "diamond" patterns in the inheritance tree

=head1 Subroutines/Methods

=head2 setup_components

Calls the setup method (which defaults to
L</_setup_config_components>) after the L<parent
method|Catalyst/setup_components>

=head2 _setup_config_components

For each config key matching C<\A Model|View|Controller ::> it checks
if the corresponding component already exists, and if it doesn't this
method creates it at run-time

The parent class is set to C<< MyApp->config->{ $component
}->{parent_classes} >> if it exists, C<Catalyst::$component>
otherwise. The I<parent_classes> can be an array ref in which case the
defined class will inherit from all classes in the list (multiple
inheritance)

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::C3>

=item L<Catalyst::Utils>

=item L<Devel::InnerPackage>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan,  C<< <Support at RoxSoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2008-2009 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:

