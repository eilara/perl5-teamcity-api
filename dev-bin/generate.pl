#!/usr/bin/env perl

use Modern::Perl;

use lib 'lib';

use Path::Class qw(dir);

use relative -to => 'TeamCity::API::REST', -aliased => 'Schema';

my $schema = Schema->new;

my $schema_dir = dir('.')->subdir('schema');

$schema_dir->file('schema.json')->spew( $schema->generate_json_schema );


