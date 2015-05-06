package TeamCity::API::REST::Schema::Generator;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use Data::Section::Simple qw(get_data_section);
use JSON::XS;
use Moose::Autobox;
use String::CamelCase qw(camelize);

sub generate_schema {
    my $self        = shift;
    my $description = shift;
    my $entities    = shift;
    my $typemap     = shift;

    return JSON::XS->new->encode(
        {
            description => $description,
            entities    => $entities,
            typemap     => $typemap,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
