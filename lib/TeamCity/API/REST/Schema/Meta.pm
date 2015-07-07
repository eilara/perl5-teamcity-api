package TeamCity::API::REST::Schema::Meta;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use Moose::Autobox;
use MooseX::Types::Moose qw( ArrayRef HashRef Str );
use MooseX::Types::Path::Class qw(File);
use Try::Tiny;

use relative
    -to      => 'W3C::SOAP::WADL',
    -aliased => qw(
    Document
    Document::Resources
    Document::Resource
    Document::Method
    Document::Param
    Document::Request
    Document::Response
    Document::Representation
);

extends 'TeamCity::API::REST::Schema::ProjectFile';

use constant WADL_NAME => 'application.wadl';

has wadl_file => (
    is      => 'ro',
    isa     => File,
    coerce  => 1,
    default => sub { shift->schema_file(WADL_NAME) },
);

has _meta_schema => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef [ ArrayRef [Str] ],
    lazy    => 1,
    builder => '_build_meta_schema',
    handles => { _describe_tag => 'get' },
);

has _collected_methods => (
    is      => 'ro',
    isa     => ArrayRef [HashRef],
    default => sub { [] },
);

sub _build_meta_schema {
    return {
        Resources,      [qw( resource )],
        Resource,       [qw( doc method path resource )],
        Method,         [qw( doc id name request response )],
        Request,        [qw( doc representation param )],
        Response,       [qw( representation )],
        Representation, [qw( element media_type )],
        Param,          [qw( default name type )],
    };
}

sub methods {
    my $self = shift;

    my $document = Document->new( file => $self->wadl_file->stringify );
    my $resources = $document->resources->[0];
    ( my $base = $resources->path ) =~ s{/$}{};
    $self->_unfold_element( $resources, $base );

    return $self->_collected_methods;
}

sub _unfold_element {
    my $self    = shift;
    my $element = shift;
    my $base    = shift;

    my $element_meta = $self->_describe_tag( ref($element) );

    $base = $base
        . (
        { $element_meta->map( sub { ( $_ => 1 ) } )->flatten }->{path}
        ? $element->path
        : q{}
        );

    my $schema = {
        $element_meta->map(
            sub { $self->_unfold_child( $element, $base, shift ) }
        )->flatten,
    };

    return $schema->{path}
        ? $self->_unfold_resource( $schema, $base )
        : $schema;
}

sub _unfold_resource {
    my $self   = shift;
    my $schema = shift;
    my $base   = shift;

    $schema->{path} = $base;

    my $methods = $schema->{method};
    if ($methods) {
        $self->_collected_methods->push(
            $methods->map( sub { $_[0]->merge( { resource => $base } ) } )
                ->flatten );
    }

    return $schema;
}

sub _unfold_child {
    my $self           = shift;
    my $parent_element = shift;
    my $base           = shift;
    my $child_name     = shift;

    my $child_element
        = $self->_try_unfold_child( $parent_element, $child_name );

    return
          $child_name eq 'doc' ? $self->_unfold_doc($child_element)
        : !defined($child_element) || $child_element eq q{} ? ()
        : ref($child_element) eq 'ARRAY' && !@$child_element ? ()
        : ref($child_element)
        ? $self->_unfold_dual( $child_name, $child_element, $base )
        : ( $child_name => $child_element );
}

sub _try_unfold_child {
    my $self           = shift;
    my $parent_element = shift;
    my $child_name     = shift;

    my ( $child_element, $error );
    try { $child_element = $parent_element->$child_name }
    catch { $error = $_ };

    if ($error) {

        # some tags in meta schema are missing from schema
        return () if $error =~ /does not pass the type constraint/;
        die $error;
    }

    return $child_element;
}

sub _unfold_dual {
    my $self          = shift;
    my $child_name    = shift;
    my $child_element = shift;
    my $base          = shift;

    my $unfolder = sub { $self->_unfold_element( shift, $base ) };
    my $child_schema
        = ref($child_element) eq 'ARRAY'
        ? $child_element->map($unfolder)
        : $unfolder->($child_element);

    return () if ref($child_schema) eq 'ARRAY' && !@$child_schema;

    return ( $child_name => $child_schema );
}

sub _unfold_doc {
    my $self    = shift;
    my $element = shift;

    my $doc = $element->[0];
    return () if !defined($doc) || $doc eq q{};
    $doc =~ s/\n//g;

    return ( doc => $doc );
}

__PACKAGE__->meta->make_immutable;

1;

