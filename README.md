# NAME

TeamCity::API - TeamCity REST Perl API

# VERSION

version 0.000001

# DESIGN

    dev-bin/generate.pl -

        generates TeamCity schema Perl code by using Schema

    TeamCity::API::Rest::Schema -

        a schema is composed of a meta schema, a typemap, and a generator. It
        collects the methods parsed by the meta schema into resources.

    TeamCity::API::Rest::Schema::Meta -

        a model of a WADL file, converts it into a list of methods.

    TeamCity::API::Rest::Schema::Meta -

        a model of an XSD file, converts it into a hash type name => type
        details.

    TeamCity::API::Rest::Schema::Generator -

        converts the list of entities methods and type definitions into a
        facade of Perl classes.


# AUTHOR

Ran Eilam <reilam@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by MaxMind, Inc..

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
