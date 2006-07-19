use Test::More;
use Data::Dump 'dump';

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 9);
}

INIT {
    use lib 't/lib';
    use_ok( 'DBIx::Class::FormTools' );
    use_ok('Test');
}

# Initialize database
my $schema = Test->initialize;
ok($schema, "Schema created");

my $helper = DBIx::Class::FormTools->new({ schema => $schema });
ok($helper,"Helper object created");

# Create test objects
my $film = $schema->resultset('Film')->create({
    title   => 'Office Space',
    comment => 'Funny film',
});

my $location = $schema->resultset('Location')->new({
    name    => 'Initec',
});


### Create a form with 1 existing objects with one non existing releation
my $formdata = {
    # The existing objects
    $helper->fieldname($film, 'title',         'o1') => 'Office Space - Behind the office',
    $helper->fieldname($film, 'length',        'o1') => 42,
    $helper->fieldname($film, 'comment',       'o1') => 'Short film about ...',
    $helper->fieldname($film, 'location_id',   'o1') => 'o2',
    $helper->fieldname($location, 'name',      'o2') => 'Initec HQ',
};
ok(1,"Formdata created:\n".dump($formdata));

my @objects = $helper->formdata_to_objects($formdata);
ok(@objects == 2, 'Excacly two object retrieved');
ok(ref($objects[0]) eq 'Schema::Film', 'Object is a Film');
ok(ref($objects[0]->location_id) eq 'Schema::Location', 'Object has a Location');

print 'Final objects: '.dump(\@objects) ."\n"
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");

1;
