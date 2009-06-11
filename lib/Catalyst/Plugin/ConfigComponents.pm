package Catalyst::Plugin::ConfigComponents;

# @(#)$Id: ConfigComponents.pm 76 2009-06-11 18:35:59Z pjf $

use strict;
use warnings;
use Class::C3;
use Class::Inspector;
use Devel::InnerPackage ();
use English qw(-no_match_vars);
use Module::Pluggable::Object ();

use version; our $VERSION = qv( sprintf '0.2.%d', q$Rev: 76 $ =~ /\d+/gmx );

sub setup_components {
   my $class   = shift;
   my $config  = $class->config->{ "Plugin::ConfigComponents" }
              || $class->config->{ setup_components };
   my @paths   = qw(::Controller ::C ::Model ::M ::View ::V);

   push @paths, @{ delete $config->{ search_extra } || [] };

   my $exclude = delete $config->{ exclude_pattern } || q(\A \z);
   my $prefix  = join q(|), map { m{ :: (.*) \z }mx } @paths;
   my $paths   = [ map { m{ \A :: }mx ? $class.$_ : $_ } @paths ];
   my $finder  = Module::Pluggable::Object->new( search_path => $paths,
                                                 %{ $config } );
   my @comps   = grep { !m{ $exclude }mx }
                 sort { length $a <=> length $b } $finder->plugins;
   my %comps   = map { $_ => 1 } @comps;

   for my $component (@comps) {
      $class->_ensure_class_loaded( $component, { ignore_loaded => 1 } );
      $class->_setup_component_and_children( $component, \%comps );
   }

   my @config_comps
      = grep { m{ \A (?:$prefix) :: }mx } keys %{ $class->config };

   $comps{ "$class\::$_" } = 1 for (@config_comps);

   for my $suffix (sort { length $a <=> length $b } @config_comps) {
      my $component = "$class\::$suffix";

      next if ($class->components->{ $component });

      my $bases = delete $class->config->{ $suffix }->{ base_class }
               || $class->_expand_component_type( "Catalyst::$suffix" );

      $class->_load_component( $component, $bases );
      $class->_setup_component_and_children( $component, \%comps );
   }

   return;
}

# Private methods

sub _ensure_class_loaded {
   my ($self, $class, $opts) = @_; my $error;

   return 1 if (!$opts->{ignore_loaded} && Class::Inspector->loaded( $class ));

   ## no critic
   {  local $EVAL_ERROR; eval "require $class;"; $error = $EVAL_ERROR; }
   ## critic

   die $error if ($error);

   unless (Class::Inspector->loaded( $class )) {
      die "Class $class failed to load";
   }

   return 1;
}

sub _expand_component_type {
   my ($self, $class) = @_; my %expand = qw(M Model V View C Controller);

   $class =~ s/ (?<=::) ([MVC]) (?=::) /$expand{$1}/mx;

   return $class;
}

sub _load_component {
   my ($class, $child, $parents) = @_;

   $parents = [ $parents ] unless (ref $parents eq q(ARRAY));

   for my $parent (reverse @{ $parents }) {
      $class->_ensure_class_loaded( $parent );
      ## no critic
      {  no strict 'refs';
         unless ($child eq $parent || $child->isa( $parent )) {
            unshift @{ "$child\::ISA" }, $parent;
         }
      }
      ## critic
   }

   unless (exists $Class::C3::MRO{ $child }) {
      eval "package $child; import Class::C3;";
   }

   return;
}

sub _setup_component_and_children {
   my ($class, $component, $comps) = @_;

   my %modules = ( $component => $class->setup_component( $component ),
                   map  { $_ => $class->setup_component( $_ ) }
                   grep { !$comps->{ $_ } }
                   Devel::InnerPackage::list_packages( $component ) );

   for my $key ( keys %modules ) {
      $class->components->{ $key } = $modules{ $key };
   }

   return;
}

1;

__END__

=pod

=head1 Name

Catalyst::Plugin::ConfigComponents - Creates components from config entries

=head1 Version

0.2.$Revision: 76 $

=head1 Synopsis

   # In your Catalyst application
   package MyApp;

   use Catalyst qw(... ConfigComponents ...);

   __PACKAGE__->setup;

   # In your applications config file
   <component name="Model::Help">
      <base_class>MyExternal::Model::HelpE<lt>/base_class>
      <base_class>Catalyst::ModelE<lt>/base_class>
   </component>

   # Do not create MyApp::Model::Help this module will do it for you

   # In a controller this will call the get_help method in
   # the class MyExternal::Model::Help
   my $help = $c->model( q(Help) )->get_help( ... );

=head1 Description

When the application starts this module creates Catalyst component
class definitions using config information. The defined class inherits
from the list of base classes referenced in the config file

This code was originally posted to the Catalyst mailing list by
Dagfinn Ilmari Mannsåker as a patch in response to an idea by
Castaway. I thought it would be better as a plugin and have extended
it to handle MI

=head1 Configuration and Environment

Specify a I<setup_components> config option to pass additional options
directly to L<Module::Pluggable>. To add additional search paths, specify
a key named I<search_extra> as an array reference. Items in the array
beginning with B<::> will have the application class name prepended to
them. Add a key named I<exclude_pattern> as a regular expression to match
component names to exclude, e.g. B<:: \. \#> to exclude emacs temporary
files

=head1 Subroutines/Methods

=head2 setup_components

This overloads the core method. For each config key matching B<\A
([MVC]|Model|View|Controller) ::> it checks if the corresponding
component already exists, and if it doesn't this method creates it on
the fly. The base class is set to
C<< MyApp->config->{$component}->{base_class} >> if it exists,
C<Catalyst::$component> (with [MVC] expanded to the full component
type) otherwise. The I<base_class> can be an array ref in which case
the defined class will inherit from all classes in the list (multiple
inheritance).

You may want to add the line:

   Class::C3::initialize();

to your Catalyst application after the C<< __PACKAGE__->setup >> call if
the base class creates any "diamond" patterns in the inheritance tree

=head2 _expand_component_type

Expands the MVC abbreviations to Model, View and Controller
respectively

=head2 _setup_component_and_children

Calls C<setup_component> for the given component and all it's inner
packages

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Catalyst::Utils>

=item L<Class::C3>

=item L<Devel::InnerPackage>

=item L<Module::Pluggable::Object>

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

Copyright (c) 2008 Peter Flanigan. All rights reserved

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
