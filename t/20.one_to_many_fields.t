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

my $location = $schema->resultset('Location')->create({
    name    => 'Initec',
});

### Create a form with 1 existing objects with one existing releation
my $formdata = {
    # The existing objects
    $film->form_fieldname('title',       'o1') => 'Office Space II',
    $film->form_fieldname('length',      'o1') => 142,
    $film->form_fieldname('comment',     'o1') => 'Really funny film',
    $film->form_fieldname('location_id', 'o1') => $location->id,
};
print 'Formdata: '.Dumper($formdata);


my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 1
   && ref($objects[0]->location_id) eq 'Test::Location',
   "formdata_to_objects: Extracted one existing object with one existing relation"
   );

print 'Final objects: '.Dumper(\@objects)
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");
