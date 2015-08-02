package TeamCity::API::REST::Schema::Meta::Entity;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw( ArrayRef Str );

use relative -to => qw( TeamCity::API::REST::Schema::Meta),
    -aliased     => qw( Resource );

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has resources => (
    is       => 'ro',
    isa      => ArrayRef [Resource],
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

