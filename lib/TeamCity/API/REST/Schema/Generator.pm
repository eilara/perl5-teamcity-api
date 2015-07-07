package TeamCity::API::REST::Schema::Generator;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use JSON::XS;
use Moose::Autobox;

sub generate_json_schema {
    my $self     = shift;
    my $entities = shift;
    my $typemap  = shift;

    return JSON::XS->new->encode(
        {
            entities => $entities,
            typemap  => $typemap,
        }
    );
}

sub generate_html_description {
    my $self        = shift;
    my $description = shift;

    my $header
        = '<tr>'
        . [qw( Resource Id Name Request Response Param Doc )]
        ->map( sub { "<th>$_</th>" } )->join(q{}) . '</tr>';

    my $make_row = sub {
        my $cells = shift;

        return $cells->map( sub { "<td>$_</td>" } )->join(q{});
    };

    my $body = $description->{methods}
        ->map( sub { '<tr>' . $make_row->($_) . '</tr>' } )->join(q{});

    return $self->_wrap_html_description( $header, $body );
}

sub _wrap_html_description {
    shift;
    my $header = shift;
    my $body = shift;

    return <<"HTML_TEMPLATE";
<html>
    <head>
        <style>
.tc table { border-collapse : collapse; width : 100%; }
.tc { background : #FFFFFF; overflow : auto; border : 1px solid #A0A0A0; border-radius : 5px; }
.tc table td,.tc table th { padding : 2px; }
.tc table thead th { background-color : #303030; color : #FFFFFF; border-bottom : 1px solid #A0A0A0; border-left : 1px solid #A0A0A0; }
.tc table thead th:first-child { border-left : none; }
.tc table tbody td { color : #000000; border-bottom : 1px solid #A0A0A0; border-left : 1px solid #A0A0A0; }
.tc table tbody tr:last-child td { border-bottom : none; }
.tc table tbody tr td:first-child { white-space: nowrap; font-family: monospace; }
.tc table tbody tr td:nth-child(3) { font-family: monospace; }
        </style>
    </head>
    <body>
        <div class="tc">
            <table>
                <thead>$header</thead>
                <tbody>$body</tbody>
            </table>
        </div>
    </body>
</html>
HTML_TEMPLATE
}

__PACKAGE__->meta->make_immutable;

1;
