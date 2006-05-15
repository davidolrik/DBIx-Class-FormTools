use Test::More;
use Data::Dumper;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 4);
}

INIT {
    use lib 't/lib';
    use_ok('Test');
}

# Initialize database
my $schema = Test->initialize;
ok($schema, "Schema created");

### Create a form with 1 existing objects with one non existing releation
my $formdata = {
    # The existing objects
    Test::Film->form_fieldname('title',       'o1') => 'Sound of music',
    Test::Film->form_fieldname('length',      'o1') => 100,
    Test::Film->form_fieldname('comment',     'o1') => 'The hills are alive...',
    Test::Film->form_fieldname('location_id', 'o1') => 'o2',
    Test::Location->form_fieldname('name',    'o2') => 'Somewhere over the rainbow',
};

print 'Formdata: '.Dumper($formdata);

my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 2,
   "formdata_to_objects: Existing object with existing relation")
        || diag(Dumper(\@objects));

print 'Final objects: '.Dumper(\@objects)
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");
