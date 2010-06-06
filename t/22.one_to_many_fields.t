use Test::More;
use Data::Dump 'pp';

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

my $film = $schema->resultset('Film')->new({
    title   => 'Office Space',
    comment => 'Funny film',
});

my $location = $schema->resultset('Location')->new({
    name    => 'Initec',
});


### Create a form with 1 existing objects with one non existing releation
my $formdata = {
    # The existing objects
    $helper->fieldname($film, 'title',      'o1') => 'Sound of music',
    $helper->fieldname($film, 'length',     'o1') => 100,
    $helper->fieldname($film, 'comment',    'o1') => 'The hills are alive...',
    $helper->fieldname($film, 'location_id','o1') => 'o2',
    $helper->fieldname($location, 'name',   'o2') => 'Somewhere over the rainbow',
};
ok(1,"Formdata created:\n".pp($formdata));

my @objects = $helper->formdata_to_objects($formdata);
ok(@objects == 2, 'Excacly two object retrieved');
ok(ref($objects[0]) eq 'Schema::Film', 'Object is a Film');
ok(ref($objects[0]->location_id) eq 'Schema::Location', 'Object has a Location');

print 'Final objects: '.pp(\@objects) ."\n"
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");

1;
