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
    handles => { _generate_schema => 'generate_schema' },
);

sub generate_schema {
    my $self = shift;

    return $self->_generate_schema( $self->_resources, $self->_typemap );
}

sub describe_resources {
    my $self = shift;

    my $methods = $self->_resources->kv->sort(
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
        = $ids->kv->map( sub { $self->_describe_method_id( @{ shift() } ) } )
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
        ( $method->{request}  || [] )->join(q{:}),
        ( $method->{response} || [] )->join(q{:}),
        ( $method->{param}    || [] )->map( sub { shift()->join(q{:}) } )
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
            = ( ( $resources{ $method{resource} } ||= {} )->{ $method{id} }
                ||= {} )->{ $method{name} } = {};

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
                = $params->map( sub { $self->_simplify_param( shift() ) } );
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

    return [qw(name type style)]->map( sub { $param->{$_} } );
}

sub _simplify_representation {
    my $self           = shift;
    my $representation = shift;
    my %method         = @_;

    my $first_representation = $representation->[0];
    my $media_type           = $first_representation->{media_type};
    my $element              = $first_representation->{element};

    return [
          $media_type =~ /text/ ? 'text'
        : $media_type =~ /xml/  ? 'json'
        :                         'any'
    ]->push( $element // () );
}

__PACKAGE__->meta->make_immutable;

1;

