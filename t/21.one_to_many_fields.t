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

# Create test objects
my $film = $schema->resultset('Film')->create({
    title   => 'Office Space',
    comment => 'Funny film',
});

### Create a form with 1 existing objects with one non existing releation
my $formdata = {
    # The existing objects
    $film->form_fieldname('title',         'o1') => 'Office Space - Behind the office',
    $film->form_fieldname('length',        'o1') => 42,
    $film->form_fieldname('comment',       'o1') => 'Short film about ...',
    $film->form_fieldname('location_id',   'o1') => 'o2',
    Test::Location->form_fieldname('name', 'o2') => 'Initec HQ',
};
print 'Formdata: '.Dumper($formdata);

my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 2,
   "formdata_to_objects: Existing object with nonexisting relation")
        || diag(Dumper(\@objects));

print 'Final objects: '.Dumper(\@objects)
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");
