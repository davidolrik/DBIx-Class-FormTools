package Film;

use strict;
use warnings;

use lib './t/testlib';
use base 'DBIx::Class::Test::SQLiteNoCompat';
use base 'DBIx::Class::FormTools';

__PACKAGE__->set_table('films');
__PACKAGE__->add_columns(qw[
    id
    title
    length
    comment
    location_id
]);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(location_id => 'Location');
__PACKAGE__->has_many(roles => 'Role', 'film_id');

sub create_sql { 
    return q{
        id          INTEGER PRIMARY KEY,
        title       CHAR(40),
        length      INT,
        comment     TEXT,
        location_id INT references location(id)
    };
}

sub create_test_object
{
    return shift->create({
        title   => 'Test film',
        length  => 99,
        comment => 'cool!'
    });
}

1;
