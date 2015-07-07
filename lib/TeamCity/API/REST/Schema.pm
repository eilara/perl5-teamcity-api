package TeamCity::API::REST::Schema;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use Moose::Autobox;
use MooseX::Types::Moose qw( ArrayRef HashRef Str );

use relative -aliased => qw( Meta Typemap Generator );

has _resources => (
    is      => 'ro',
    isa     => HashRef [ HashRef [HashRef] ],
    lazy    => 1,
    builder => '_build_resources',
);

has _typemap_delegate => (
    is      => 'ro',
    isa     => Typemap,
    lazy    => 1,
    default => sub { Typemap->new },
    handles => [qw( _typemap )],
);

has _generator => (
    is      => 'ro',
    isa     => Generator,
    lazy    => 1,
    default => sub { Generator->new },
);

sub generate_json_schema {
    my $self = shift;

    return $self->_generator->generate_json_schema(
        $self->_resources,
        $self->_typemap
    );
}

sub generate_html_description {
    my $self = shift;

    return $self->_generator->generate_html_description(
        $self->_describe_resources );
}

sub _describe_resources {
    my $self = shift;

    my $methods
        = $self->_resources->kv->map(
        sub { [ $_[0]->[0], $_[0]->[1]->{methods} ] } )->sort(
        sub {
            my $m1 = shift;
            my $m2 = shift;

            return $m1->[0] cmp $m2->[0];
        }
        )->map( sub { $self->_describe_resource( @{ shift() } ) } );

    my $prefix = '/app/rest';
    ( my $base = $methods->[0]->[0] )
        =~ s{^(http(?:s?)://[^/]+)$prefix.*$}{$1};
    $methods->each( sub { $_[1]->[0] =~ s{^\Q$base$prefix\E}{} } );
    $methods->[0]->[0] = q{/};

    return {
        base    => $base,
        prefix  => $prefix,
        methods => $methods,
    };
}

sub _describe_resource {
    my $self     = shift;
    my $resource = shift;
    my $ids      = shift;

    my @methods
        = $ids->kv->sort(
        sub {
            my $m1 = shift;
            my $m2 = shift;

            return $m1->[0] cmp $m2->[0];
        })->map( sub { $self->_describe_method_id( @{ shift() } ) } )
        ->flatten;
    $methods[0]->[0] = $resource;

    return @methods;
}

sub _describe_method_id {
    my $self  = shift;
    my $id    = shift;
    my $names = shift;

    my @methods = $names->kv->map(
        sub { $self->_describe_method_name( @{ shift() } ) } )->flatten;
    $methods[0]->[1] = $id;

    return @methods;
}

sub _describe_method_name {
    my $self   = shift;
    my $name   = shift;
    my $method = shift;

    return [
        q{},
        q{},
        $name,
        $method->{request}  || q{},
        $method->{response} || q{},
        ( $method->{param} || {} )->kv->map( sub { shift()->join(q{:}) } )
            ->join(q{ }),
        ( $method->{doc} || q{} ),
    ];
}

# Push all the methods we get from the meta schema into a tree of resources, so
# every method is inside a resource.
sub _build_resources {
    my $self = shift;

    my %resources;
    my $resource_pusher = sub {
        shift;
        my %method = %{ shift() };

        my $leaf
            = ( ( $resources{ $method{resource} } ||= { methods => {} } )
            ->{methods}->{ $method{id} } ||= {} )->{ $method{name} } = {};

        if ( my $representation
            = ( $method{request} // {} )->{representation} ) {
            $leaf->{request}
                = $self->_simplify_representation($representation);
        }

        if ( my $representation
            = ( $method{response} // [ {} ] )->[0]->{representation} ) {
            $leaf->{response}
                = $self->_simplify_representation($representation);
        }

        if ( my $params = ( $method{request} // {} )->{param} ) {
            $leaf->{param}
                = { $params->map( sub { $self->_simplify_param( shift() ) } )
                    ->flatten };
        }

        $leaf->{doc} = $method{doc} if $method{doc};
    };

    Meta->new->methods->each($resource_pusher);

    return \%resources;
}

sub _simplify_param {
    my $self  = shift;
    my $param = shift;

    my $type = $param->{type};
    if ($type) {
        $type =~ s/^xs://;
        $param->{type} = $type;
    }

    return ( $param->{name}, $param->{type} );
}

sub _simplify_representation {
    my $self           = shift;
    my $representation = shift;
    my %method         = @_;

    my $first_representation = $representation->[0];
    my $media_type           = $first_representation->{media_type};
    my $element              = $first_representation->{element};

    return
          defined $element      ? $element
        : $media_type =~ /text/ ? 'text'
        :                         'any';
}

__PACKAGE__->meta->make_immutable;

1;

