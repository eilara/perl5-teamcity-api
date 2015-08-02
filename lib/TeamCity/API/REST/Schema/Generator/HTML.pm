package TeamCity::API::REST::Schema::Generator::HTML;
use Modern::Perl;
use Moose;
use namespace::autoclean;

use Moose::Autobox;
use Template::Caribou;
use Template::Caribou::Tags::HTML qw(
    a body div h1 head html span table table_row tbody td th thead title );
use Template::Caribou::Tags::HTML::Extended qw( css javascript );

use relative -to => qw( TeamCity::API::REST::Schema::Meta),
    -aliased     => qw( Server );

has server => (
    is       => 'ro',
    isa      => Server,
    required => 1,
);

with 'Template::Caribou';

template page => sub {
    my $self = shift;

    print ::RAW '<!doctype html>';

    html {
        attr lang => 'en';
        head {
            show 'html_meta';
            title { 'TeamCity REST API' };
            show 'css';
        };
        body {
            show 'content';
            show 'javascript';
        };
    };
};

template content => sub {
    my $self = shift;

    my $server = $self->server;

    table {
        thead {
            table_row {
                th { $_ }
                for (
                    qw(
                    Entity
                    Path
                    Type
                    Signature
                    Documentation
                    )
                );
            };
        };
        tbody {
            for my $entity ( $server->entities->flatten ) {
                for my $resource ( $entity->resources->flatten ) {
                    for my $action ( $resource->actions->flatten ) {
                        show action => $server, $entity, $resource, $action;
                    }
                }
            }
        };
    };
};

template action => sub {
    my $self     = shift;
    my $server   = shift;
    my $entity   = shift;
    my $resource = shift;
    my $action   = shift;

    my $entity_name = $entity->name;
    my $base_uri    = $server->base_uri;
    ( my $path = $resource->uri ) =~ s{\Q$base_uri}{};
    $path =~ s{/?\Q$entity_name}{}g;
    $path = '/' if $path eq q{};

    state $last_entity_name;
    my $entity_row_span;
    if ( !defined($last_entity_name) || $last_entity_name ne $entity_name ) {
        $last_entity_name = $entity_name;
        $entity_row_span  = scalar $entity->resources->map(
            sub {
                $_->actions->flatten;
            }
        )->flatten;
    }

    state $last_path;
    my $path_row_span;
    if ( !defined($last_path) || $last_path ne $path || $entity_row_span ) {
        $last_path     = $path;
        $path_row_span = scalar $resource->actions->flatten;
    }

    table_row {
        td { attr colspan => 5, class => 'spacer-cell' }
    }
    if $entity_row_span;

    table_row {

        td {
            attr rowspan => $entity_row_span, class => 'entity';
            $entity_name;
        }
        if $entity_row_span;

        td {
            attr rowspan => $path_row_span, class => 'path';
            $path;
        }
        if $path_row_span;

        td {
            my $name = $action->{name};
            span { attr class => "method-$name"; $name };

            my $request  = $action->{request};
            my $response = $action->{response};

            span { q{ } };
            span { attr class => 'param-type'; $request || '()' };
            span { q{→} };
            span { attr class => 'param-type'; $response || '()' };
        };

        td {
            span { attr class => 'action-id';  $action->{id} };
            span { attr class => 'param-name'; '(' };
            if ( my $param = $action->{param} ) {
                my $is_first = 1;
                for my $param ( $param->kv->flatten ) {
                    my ( $name, $type ) = @$param;
                    span { q{, } } unless $is_first;
                    span { attr class => 'param-name'; $name };
                    span { q{: } };
                    span { attr class => 'param-type'; $type };
                    $is_first = 0;
                }
            }
            span { attr class => 'param-name'; ')' };
        };

        td { $action->{doc} };
    };
};

template html_meta => sub {
    print ::RAW << 'HTML_META';
<meta charset="utf-8">
HTML_META
};

template css => sub {

    css << "CSS";

html, body {
    margin           : 0px;
    overflow         : auto;
    padding          : 0px;
}

table {
    border-collapse  : collapse;
    font-family      : Arial, Helvetica, sans-serif;
    width            : 100%;
}

th {
    background-color : #000000;
    border           : 1px solid #A0A0A0;
    color            : #FFFFFF;
    font-weight      : bold;
    padding          : 3pt;
}

td {
    border           : 1px solid #A0A0A0;
    padding          : 4pt;
}

.entity {
    background-color : #202020;
    color            : #FFFFFF;
    font-weight      : bold;
    text-align       : center;
}

.path {
    background-color : #404040;
    color            : #FFFFFF;
}

.action-id {
    color            : #404040;
    font-family      : monospace;
    font-style       : italic;
}

.param-name {
    color            : #404040;
    font-family      : monospace;
}

.param-type {
    color            : #404040;
    font-weight      : bold;
}

.method-GET, .method-POST, .method-PUT, .method-DELETE {
    border-radius    : 3pt;
    display          : inline-block;
    font-family      : monospace;
    font-weight      : bold;
    padding-left     : 2pt;
    padding-right    : 2pt;
    text-align       : center;
    width            : 4em;
}

.method-GET {
    background-color : #60C060;
}

.method-POST {
    background-color : #9090E0;
}

.method-PUT {
    background-color : #E0E050;
}

.method-DELETE {
    background-color : #E08080;
}

.spacer-cell {
    border-left      : none;
    border-right     : none;
    padding          : 2px;
    margin           : 0px;
}

CSS
};

template javascript => sub {
    javascript << 'JAVASCRIPT';
JAVASCRIPT
};

__PACKAGE__->meta->make_immutable;

1;

