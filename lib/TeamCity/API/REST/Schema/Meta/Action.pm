package TeamCity::API::REST::Schema::Meta::Action;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw( HashRef Str );

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has doc => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_doc',
);

has param => (
    is        => 'ro',
    isa       => HashRef [ Str ],
    predicate => 'has_param',
);

has request => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_request',
);

has response => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_response',
);

__PACKAGE__->meta->make_immutable;

1;

