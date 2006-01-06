use Test::More;
use Data::Dumper;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 3);
}

INIT {
    use lib 't/lib';
    use Location;
    use Film;
}

is(Film->__driver, "SQLite", "Driver set correctly");

# Create test objects
my $film     = Film->create_test_object;
my $location = Location->create_test_object;

### Create a form with 1 existing objects with one existing releation
my $formdata = {
    # The existing objects
    $film->form_fieldname('title',       'o1') => 'Title',
    $film->form_fieldname('length',      'o1') => 99,
    $film->form_fieldname('comment',     'o1') => 'This is a comment',
    $film->form_fieldname('location_id', 'o1') => $location->id,
};
print 'Formdata: '.Dumper($formdata);


my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 1
   && ref($objects[0]->location_id) eq 'Location',
   "formdata_to_objects: Existing object with existing relation"
   );

print 'Final objects: '.Dumper(\@objects);

ok(map { $_->insert_or_update } @objects);
