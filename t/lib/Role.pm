package Role;

use strict;
use warnings;

use lib './t/testlib';
use base 'DBIx::Class::Test::SQLiteNoCompat';
use base 'DBIx::Class::FormTools';

__PACKAGE__->set_table('roles');
__PACKAGE__->add_columns(qw[
    film_id
    actor_id
    charater
]);
__PACKAGE__->set_primary_key(qw[
    film_id
    actor_id
]);

__PACKAGE__->belongs_to(film_id  => 'Film');
__PACKAGE__->belongs_to(actor_id => 'Actor');

sub create_sql { 
    return q{
        film_id  INTEGER references film(id),
        actor_id INTEGER references actor(id),
        charater VARCHAR(64),
        PRIMARY KEY(film_id,actor_id)
    };
}

1;
