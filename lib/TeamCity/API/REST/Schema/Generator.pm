package TeamCity::API::REST::Schema::Generator;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use JSON::XS;

sub generate_json_schema {
    my $self        = shift;
    my $entities    = shift;
    my $typemap     = shift;

    return JSON::XS->new->encode(
        {
            entities   => $entities,
            typemap    => $typemap,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
