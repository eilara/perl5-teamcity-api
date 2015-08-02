package TeamCity::API::REST::Schema::Meta::Server;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use Data::Structure::Util qw( unbless );
use JSON::XS;
use MooseX::Types::Moose qw( ArrayRef Str );

use relative -to => qw( TeamCity::API::REST::Schema::Generator),
    -aliased     => qw( HTML );

use relative -to => qw( TeamCity::API::REST::Schema::Meta),
    -aliased     => qw( Entity );

our $JSON = JSON::XS->new->allow_blessed(1)->convert_blessed(1);

has base_uri => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has entities => (
    is       => 'ro',
    isa      => ArrayRef [Entity],
    required => 1,
);

sub to_json { $JSON->encode( unbless( $_[0] ) ) }

sub to_html { HTML->new( server => shift )->render('page') }

# For benefit of JSON::XS serialization
sub TO_JSON { unbless shift() }

__PACKAGE__->meta->make_immutable;

1;

