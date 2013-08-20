# @(#)Ident: ConfigComponents.pm 2013-08-15 13:15 pjf ;

package Catalyst::Plugin::ConfigComponents;

use strict;
use warnings;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.8.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Catalyst::Utils;
use Devel::InnerPackage ();
use Moose::Role;
use Scalar::Util      qw( blessed );

my $KEY = 'Plugin::ConfigComponents';

after 'setup_components' => sub {
   my $self = shift; my $config = $self->config->{ $KEY } || {}; my $method;

   if ($method = $config->{setup_method}) { $self->$method( $config ) }
   else {  $self->_setup_config_components( $config ) }

   return;
};

around 'setup_component' => sub {
   my ($next, $self, $component) = @_; my $class = blessed $self || $self;

   my $suffix = Catalyst::Utils::class2classsuffix( $component );

   # Catalyst 5.9.13 merged C::C::ActionRole into C::C and started
   # producing warnings. Adding the _application attribute to the
   # config shuts the fucker up
   $class->config->{ $suffix }->{_application} ||= $class;

   return $self->$next( $component );
};

# Private methods
sub _setup_config_components {
   my ($self, $plugin_config) = @_;

   my $class  = blessed $self || $self;
   my @paths  = qw( ::Controller ::Model ::View );

   push @paths, @{ $plugin_config->{ search_extra } || [] };

   my $prefix = join '|', map { m{ :: (.*) \z }mx } @paths;
   my @comps  = grep { m{ \A (?:$prefix) :: }mx } keys %{ $self->config };

   for my $suffix (sort { length $a <=> length $b } @comps) {
      my $component = "${class}::${suffix}";

      $self->components->{ $component } and next;

      my $config = $self->config->{ $suffix };
      my $active = delete $config->{component_active};

      defined $active and not $active and next;

      my $parents = delete $config->{parent_classes} || "Catalyst::${suffix}";

      $self->_load_config_component( $component, $parents );

      my %modules = ( $component => $self->setup_component( $component ),
                      map  { $_ => $self->setup_component( $_ ) }
                      grep { not exists $self->components->{ $_ } }
                      Devel::InnerPackage::list_packages( $component ) );

      for my $key ( keys %modules ) {
         $self->components->{ $key } = $modules{ $key };
      }
   }

   return;
}

sub _load_config_component {
   my ($self, $child, $parents) = @_;

   ref $parents eq 'ARRAY' or $parents = [ $parents ];

   for my $parent (reverse @{ $parents }) {
      Catalyst::Utils::ensure_class_loaded( $parent );
      ## no critic
      {  no strict 'refs';
         ($child eq $parent or $child->isa( $parent ))
            or unshift @{ "${child}::ISA" }, $parent;
      }
      ## critic
   }

   exists $Class::C3::MRO{ $child }
      or eval "package ${child}; import Class::C3;"; ## no critic

   return;
}

no Moose::Role;

1;

__END__

=pod

=encoding utf8

=head1 Name

Catalyst::Plugin::ConfigComponents - Creates components from config entries

=head1 Synopsis

   # In your Catalyst application
   package YourApp;

   use Catalyst qw(ConfigComponents);

   __PACKAGE__->setup;

   # In your applications config file
   <component name="Model::YourModel">
      <parent_classes>YourExternal::ModelE<lt>/parent_classes>
      <parent_classes>Catalyst::ModelE<lt>/parent_classes>
   </component>

   # Do not create YourApp::Model::YourModel this module will do it for you

   # In a controller this will call your_method in
   # the class YourExternal::Model
   $result = $c->model( q(YourModel) )->your_method( ... );

=head1 Version

This documents version v0.8.$Rev: 1 $ of L<Catalyst::Plugin::ConfigComponents>

=head1 Description

When the application starts this module creates Catalyst component
class definitions using config information. The defined class inherits
from the list of parent classes referenced in the config file

=head1 Configuration and Environment

Specify a I<Plugin::ConfigComponents> config option. Attributes are

=over 3

=item C<component_active>

If the C<component_active> config attribute exists and is false the
component will not be loaded

=item C<parent_classes>

List of classes for the derived component to inherit from

=item C<search_extra>

To add additional search paths, specify a key named I<search_extra>
as an array reference. Items in the array beginning with C<::> will
have the application class name prepended to them

=item C<setup_method>

Defaults to C<_setup_config_components>, the method to call after the
call to L<Catalyst::setup_components|Catalyst/setup_components>

=back

=head1 Subroutines/Methods

=head2 setup_components

Calls the setup method (which defaults to
L</setup_config_components>) after the L<parent
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

=item L<Moose::Role>

=item L<Catalyst::Utils>

=item L<Devel::InnerPackage>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-ConfigComponents.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

This code was originally posted to the Catalyst mailing list by
Dagfinn Ilmari Mannsåker as a patch in response to an idea by
Castaway. I thought it would be better as a plugin and have extended
it to handle MI

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2013 Peter Flanigan. All rights reserved

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
# vim: expandtab shiftwidth=3:
