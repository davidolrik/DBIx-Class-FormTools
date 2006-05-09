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

my $actor = $schema->resultset('Actor')->create({
    name   => 'Cartman',
});

my $formdata = {
    $film->form_fieldname('title',   'o1') => 'Bigger longer uncut',
    $film->form_fieldname('length',  'o1') => 42,
    $film->form_fieldname('comment', 'o1') => 'Damn, they swear!',
    $actor->form_fieldname('name',   'o2') => 'Cartman',
    Test::Role->form_fieldname(undef,      'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    }) => 'Fat kid',
};
print 'Formdata: '.Dumper($formdata);

my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 3,"formdata_to_objects: Extracted ".@objects." objects");

print 'Final objects: '.Dumper(\@objects)
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");
