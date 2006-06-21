use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Class::FormTools',
    license             => 'perl',
    dist_author         => 'David Jack Olrik <david@olrik.dk>',
    dist_version_from   => 'lib/DBIx/Class/FormTools.pm',
    requires => {
        'Test::More'    => 0,
        'version'       => '0.50',
        'DBIx::Class'   => '0.06002',
    },
    add_to_cleanup      => [ 'DBIx-Class-FormTools-*' ],
);

$builder->create_build_script();
