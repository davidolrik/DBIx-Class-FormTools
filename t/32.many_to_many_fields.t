use Test::More;
use Data::Dump 'pp';

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 10);
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

# Create test objects in memory
my $film = $schema->resultset('Film')->new({
    title   => 'Office Space',
    comment => 'Funny film',
});
my $actor = $schema->resultset('Actor')->new({
    name   => 'Cartman',
});

my $role = $schema->resultset('Role')->new({
#    charater => 'The New guy',
});

my $formdata = {
    # The existing objects
    $helper->fieldname($film,  'title',    'o1') => 'Timmy on the run',
    $helper->fieldname($film,  'length',   'o1') => 99,
    $helper->fieldname($film,  'comment',  'o1') => 'TIMMY!!',
    $helper->fieldname($actor, 'name',    'o2') => 'Stan Marsh',
    $helper->fieldname($role,  'charater', 'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    }) => 'Kid',
};
ok(1,"Formdata created:\n".pp($formdata));

my @objects = $helper->formdata_to_objects($formdata);
ok(@objects == 3, 'Excacly three object retrieved ('.scalar(@objects).')');
ok(ref($objects[0]) eq 'Schema::Film', 'Object is a Film');
ok(ref($objects[1]) eq 'Schema::Actor', 'Object is a Actor');
ok(ref($objects[2]) eq 'Schema::Role', 'Object is a Role');


print 'Final objects: '.pp(\@objects) ."\n"
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");

1;
