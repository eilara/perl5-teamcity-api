package TeamCity::API::REST::Schema;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use Moose::Autobox;
use URI;

use relative -aliased => qw( Meta Meta::Server Typemap );
use relative -to      => qw( TeamCity::API::REST::Schema::Meta),
    -aliased          => qw( Action Entity Resource );

has _server => (
    is      => 'ro',
    isa     => Server,
    lazy    => 1,
    builder => '_build_server',
    handles => [qw( to_json to_html )],
);

has _typemap => (
    is      => 'ro',
    isa     => Typemap,
    lazy    => 1,
    default => sub { Typemap->new },
);

sub _build_server {
    my $self = shift;

    my ( $base_uri, $resources, $entities )
        = $self->_group_methods_into_resources_and_entities;

    my $make_entity = sub {
        my $entity_details = shift;

        my $make_resource = sub {
            my $resource_details = shift;

            my $actions
                = $resource_details->{actions}
                ->values->sort( sub { $_[0]->{id} cmp $_[1]->{id} } )
                ->map( sub          { $self->_make_action($_) } );

            return Resource->new(
                uri     => $resource_details->{uri},
                actions => $actions
            );
        };

        my $entity_resources
            = $entity_details->{resources}
            ->values->sort( sub { $_[0]->{uri} cmp $_[1]->{uri} } )
            ->map( sub          { $make_resource->($_) } );

        return Entity->new(
            name      => $entity_details->{name},
            resources => $entity_resources
        );
    };

    my $sorted_entities
        = $entities->values->sort( sub { $_[0]->{name} cmp $_[1]->{name} } )
        ->map( sub                     { $make_entity->($_) } );

    return Server->new( base_uri => $base_uri, entities => $sorted_entities );
}

sub _make_action {
    my $self           = shift;
    my $action_details = shift;

    my $response = delete $action_details->{response};
    my %response
        = $response
        ? (
        response => $self->_simplify_representation(
            $response->[0]->{representation}
        )
        )
        : ();

    my $request                = delete $action_details->{request};
    my $request_representation = delete $request->{representation};
    my %request_representation;
    if ($request_representation) {
        %request_representation
            = $request_representation
            ? ( request =>
                $self->_simplify_representation($request_representation) )
            : ();
    }

    my %param;
    if ( my $param = delete $request->{param} ) {
        %param = (
            param => {
                $param->map(
                    sub {
                        my $type = $_->{type};
                        $type =~ s/^xs://;
                        ( $_->{name}, $type );
                    }
                )->flatten
            }
        );
    }

    return Action->new(
        (
            map {
                $action_details->{$_}
                    ? ( $_ => $action_details->{$_} )
                    : ()
            } qw( doc id name )
        ),
        %param,
        %request_representation,
        %response,
    );
}

sub _simplify_representation {
    shift;
    my $representation = shift;

    my $first_representation = $representation->[0];
    my $media_type           = $first_representation->{media_type};
    my $element              = $first_representation->{element};

    return
          defined $element      ? $element
        : $media_type =~ /text/ ? 'text'
        :                         'any';
}

sub _group_methods_into_resources_and_entities {
    my $self = shift;

    my ( $base_uri, %resources, %entities );
    for my $method ( Meta->new->methods->flatten ) {

        my $uri             = $method->{resource};
        my $resource        = $resources{$uri};
        my $is_new_resource = !defined $resource;

        $resources{$uri} = $resource = { uri => $uri, actions => [] }
            if $is_new_resource;
        $resource->{actions}->push($method);

        my $entity_name = [ URI->new($uri)->path_segments ]->[3] || q{/};
        my $entity = $entities{$entity_name}
            ||= { name => $entity_name, resources => [] };
        $entity->{resources}->push($resource) if $is_new_resource;

        ( $base_uri = $uri ) =~ s{^(.+)(/app/rest).*$}{$1$2}
            unless $base_uri;
    }

    return ( $base_uri, \%resources, \%entities );
}

__PACKAGE__->meta->make_immutable;

1;

