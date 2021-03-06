package Catalyst::Component::Implicit;

use parent qw(Catalyst::Component);

use Catalyst::Utils;
use MRO::Compat;

sub COMPONENT {
    my ($self, $c, $arguments) = @_; my $class = ref $self || $self;

    # Inject an inner package intoto the subclass
    { no strict 'refs'; @{"$class\::Sub::ISA"} = @{"$class\::ISA"} }

    return $self->next::method( $c, $arguments );
}

1;
