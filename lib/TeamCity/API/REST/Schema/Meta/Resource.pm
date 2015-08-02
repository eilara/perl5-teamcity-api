package TeamCity::API::REST::Schema::Meta::Resource;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw( ArrayRef Str );

use relative -to => qw( TeamCity::API::REST::Schema::Meta),
    -aliased     => qw( Action );

has uri => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has actions => (
    is       => 'ro',
    isa      => ArrayRef[ Action ],
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

