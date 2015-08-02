package TeamCity::API::REST::Schema::Typemap;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use Moose::Autobox;
use MooseX::Types::Moose qw(HashRef);
use MooseX::Types::Path::Class qw(File);
use XML::LibXML;

extends 'TeamCity::API::REST::Schema::ProjectFile';

use constant XSD_NAME => 'xsd1.xsd';

has xsd_file => (
    is      => 'ro',
    isa     => File,
    coerce  => 1,
    default => sub { shift->schema_file(XSD_NAME) },
);

has typemap => (
    is      => 'ro',
    isa     => HashRef [HashRef],
    lazy    => 1,
    builder => '_build_typemap',
);

sub _build_typemap {
    my $self = shift;

    my $xml = XML::LibXML->load_xml( location => $self->xsd_file->stringify );
    my $types
        = { [ $xml->findnodes('//xs:complexType') ]
        ->map( sub { $self->_build_typemap_for(shift) } )->flatten };

    my $expanded_types = {
        $types->kv->map(
            sub { $self->_expand_typemap_type( $types, @{ $_[0] } ) }
        )->flatten
    };

    my %type_to_alias = [ $xml->findnodes('//xs:schema/xs:element') ]->map(
        sub {
            ( $_[0]->getAttribute('type'), $_[0]->getAttribute('name') );
        }
    )->flatten;

    my $aliaser = sub {
        my ( $type, $details ) = @{ $_[0] };

        my $aliased_details = {
            $details->kv->map(
                sub {
                    $self->_alias_type_details( \%type_to_alias, @{ $_[0] } );
                }
            )->flatten
        };

        return ( $type_to_alias{$type} // $type, $aliased_details );
    };

    return { $expanded_types->kv->map($aliaser)->flatten };
}

sub _alias_type_details {
    my $self          = shift;
    my $type_to_alias = shift;
    my $name          = shift;
    my $child_details = shift;

    for my $target (qw( type from )) {
        my $child_target = $child_details->{$target};
        if ($child_target) {
            $child_target = $type_to_alias->{$child_target};
            $child_details->{$target} = $child_target
                if $child_target;
        }
    }

    return ( $name, $child_details );
}

sub _expand_typemap_type {
    my $self   = shift;
    my $types  = shift;
    my $type   = shift;
    my $fields = shift;

    my $expanded_fields = {
        $fields->kv->map(
            sub { $self->_expand_typemap_extension( $types, @{ $_[0] } ) }
        )->flatten
    };

    return ( $type, $expanded_fields );
}

sub _expand_typemap_extension {
    my $self    = shift;
    my $types   = shift;
    my $name    = shift;
    my $details = shift;

    return ( $name, $details ) unless $details->{is_extension};

    my $expander = sub {
        my $kv = shift;

        my ( $expanded_name, $expanded_details ) = @$kv;

        return (
            $expanded_name,
            $expanded_details->merge( { from => $name } )
        );
    };

    return $types->{$name}->kv->map($expander)->flatten;
}

sub _build_typemap_for {
    my $self = shift;
    my $type = shift;

    return (
        $type->getAttribute('name'),
        {
            [ $type->childNodes ]->grep( sub { ref(shift) !~ /Text/ } )
                ->map( sub { $self->_build_typemap_for_child(shift) } )
                ->flatten
        }
    );
}

sub _build_typemap_for_child {
    my $self  = shift;
    my $child = shift;

    my $tag = $child->localname;
    return
          $tag eq 'attribute'      ? $self->_build_attribute_typemap($child)
        : $tag eq 'complexContent' ? $self->_build_content_typemap($child)
        : $tag eq 'sequence'       ? [ $child->findnodes('xs:element') ]
        ->map( sub { $self->_build_sequence_typemap(shift) } )->flatten
        : ();
}

sub _build_attribute_typemap {
    my $self  = shift;
    my $child = shift;

    return (
        $child->getAttribute('name'),
        {
            type         => substr( $child->getAttribute('type'), 3 ),
            is_attribute => 1,
        },
    );
}

sub _build_content_typemap {
    my $self  = shift;
    my $child = shift;

    my $extension = [ $child->findnodes('xs:extension') ]->[0];
    my %extension_entry
        = ( $extension->getAttribute('base'), { is_extension => 1 } );

    my %children = $self->_build_typemap_for($extension)->flatten;
    return ( %extension_entry, %children );
}

sub _build_sequence_typemap {
    my $self  = shift;
    my $child = shift;

    my $name = $child->getAttribute(
        $child->hasAttribute('name') ? 'name' : 'ref' );
    my %details = ( is_sequence => 1 );
    $details{is_ref} = 1 if $child->hasAttribute('ref');
    for my $att (qw( minOccurs maxOccurs type )) {
        $details{$att} = $child->getAttribute($att)
            if $child->hasAttribute($att);
    }

    return ( $name, \%details );
}

__PACKAGE__->meta->make_immutable;

1;

