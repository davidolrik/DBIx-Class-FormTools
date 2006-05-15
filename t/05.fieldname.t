use Test::More;
use Data::Dumper;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 14);
}

INIT {
    use lib 't/lib';
    use Location;
    use Film;
    use Actor;
}

is(Film->__driver, "SQLite", "Driver set correctly");

# Create 2 test objects
my $film1 = Film->create_test_object;
my $film2 = Film->create_test_object;

my $film3  = Film->create_test_object;
my $actor1 = Actor->create_test_object;

ok(1,$film1->form_fieldname('title' ,  'o1'));
ok(1,$film1->form_fieldname('length',  'o1'));
ok(1,$film1->form_fieldname('comment', 'o1'));
ok(1,$film2->form_fieldname('title',   'o2'));
ok(1,$film2->form_fieldname('length',  'o2'));
ok(1,$film2->form_fieldname('comment', 'o2'));

# The new objects
ok(1,Film->form_fieldname('title',     'o3'));
ok(1,Film->form_fieldname('length',    'o3'));
ok(1,Film->form_fieldname('comment',   'o3'));
ok(1,Film->form_fieldname('title',     'o4'));
ok(1,Film->form_fieldname('length',    'o4'));
ok(1,Film->form_fieldname('comment',   'o4'));

ok(1,Role->form_fieldname(
    undef,
    'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    })
);