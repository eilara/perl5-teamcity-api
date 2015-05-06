package TeamCity::API::REST::Schema::ProjectFile;

use Modern::Perl;
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class qw( Dir File );

has project_dir => (
    is      => 'ro',
    isa     => Dir,
    coerce  => 1,
    default => sub { '.' },
    handles => { project_subdir => 'subdir' },
);

has schema_dir => (
    is      => 'ro',
    isa     => Dir,
    coerce  => 1,
    default => sub { shift->project_subdir('schema') },
    handles => { schema_file => 'file' },
);

__PACKAGE__->meta->make_immutable;

1;

