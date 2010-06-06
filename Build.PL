use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name         => 'DBIx::Class::FormTools',
    license             => 'perl',
    dist_author         => 'David Jack Olrik <david@olrik.dk>',
    dist_version_from   => 'lib/DBIx/Class/FormTools.pm',
    requires => {
        'Test::More'    => 0,
        'version'       => '0.50',
        'DBIx::Class'   => '0.06003',
        'Moose'         => '0.11',
    },
    build_requires      => {
        'Data::Dump'    => 0,
    },
    add_to_cleanup      => [ 'DBIx-Class-FormTools-*' ],
    create_makefile_pl  => 'passthrough',
);

$build->create_build_script;
