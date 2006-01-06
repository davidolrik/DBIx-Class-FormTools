use Test::More;
use Data::Dumper;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 2);
}

INIT {
    use lib 't/lib';
    use Location;
    use Film;
    use Actor;
}

is(Film->__driver, "SQLite", "Driver set correctly");

my $formdata = {
    # The existing objects
    Film->form_fieldname('title',    'o1') => 'Title',
    Film->form_fieldname('length',   'o1') => 99,
    Film->form_fieldname('comment',  'o1') => 'This is a comment',
    Role->form_fieldname('charater', 'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    }) => 'Stan Marsh',
    Actor->form_fieldname('name',   'o2') => 'Test actor',
};
print 'Formdata: '.Dumper($formdata);

my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 3,"formdata_to_objects: Ojects extracted");
print 'Final objects: '.Dumper(\@objects);

# Update objects
map { $_->update || diag("Unable to update object ".Dumper($_)) } @objects;
