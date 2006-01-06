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

### Create a form with 1 existing objects with one non existing releation
my $formdata = {
    # The existing objects
    Film->form_fieldname('title',       'o1') => 'Title',
    Film->form_fieldname('length',      'o1') => 99,
    Film->form_fieldname('comment',     'o1') => 'This is a comment',
    Film->form_fieldname('location_id', 'o1') => 'o2',
    Location->form_fieldname('name',    'o2') => 'Somewhere',
};

print 'Formdata: '.Dumper($formdata);

my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 2,
   "formdata_to_objects: Existing object with existing relation")
        || diag(Dumper(\@objects));

print 'Final objects: '.Dumper(\@objects);

ok(map { $_->update } @objects);

