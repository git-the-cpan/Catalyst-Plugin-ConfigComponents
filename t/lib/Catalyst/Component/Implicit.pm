package Catalyst::Component::Implicit;
use base qw/Catalyst::Component/;

use Catalyst::Utils;

sub COMPONENT {
    my ($self, $c, $arguments) = @_;
    my $class = ref $self || $self;

    # Inject an inner package intoto the subclass
    { no strict 'refs'; @{"$class\::Sub::ISA"} = @{"$class\::ISA"} }

    return $self->NEXT::COMPONENT( $c, $arguments );
}

1;