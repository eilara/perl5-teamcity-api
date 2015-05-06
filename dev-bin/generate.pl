#!/usr/bin/env perl

use Modern::Perl;

use lib 'lib';

use relative -to => 'TeamCity::API::REST', -aliased => 'Schema';

say Schema->new->generate_schema;
