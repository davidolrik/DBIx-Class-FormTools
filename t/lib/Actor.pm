package Actor;

use strict;
use warnings;

use lib './t/testlib';
use base 'DBIx::Class::Test::SQLiteNoCompat';
use base 'DBIx::Class::FormTools';

__PACKAGE__->set_table('actors');
__PACKAGE__->add_columns(qw[
    id
    name
]);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(roles => 'Role', 'actor_id');

sub create_sql { 
    return q{
        id         INTEGER PRIMARY KEY,
        name       CHAR(40)
    };
}

sub create_test_object
{
    return shift->create({
        name => 'Christoper Walken',
    });
}



1;
