# NAME

TeamCity::API - TeamCity REST Perl API

# VERSION

version 0.000001

# SCHEMA

[REST schema](http://eilara.github.io/perl5-teamcity-api/).

# DESIGN

    dev-bin/generate.pl - serialize TeamCity REST API schema

    TeamCity::API::REST::Schema::Meta::Server - the schema entry point

        A server has a base uri and an ordered list of entities. This is where
        you start navigating the schema.

    TeamCity::API::REST::Schema - the API schema

        Composed of meta schema and typemap. Converts these into a server.

    TeamCity::API::REST::Schema::Meta - the WADL meta schema

        A model of a WADL file, converts it into a list of methods.

    TeamCity::API::REST::Schema::Types - the typemap

        A model of an XSD file, converts it into a hash type name => type
        details.


# AUTHOR

Ran Eilam <reilam@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by MaxMind, Inc..

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
