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
my $film1 = $schema->resultset('Film')->create({
    title   => 'Office Space',
    comment => 'Funny film',
});

my $film2 = $schema->resultset('Film')->create({
    title   => 'Office Space II',
    comment => 'Really funny film',
});


# Create a form with 2 existing objects and 2 new objects
my $formdata = {
    # The existing objects
    $film1->form_fieldname('title' ,  'o1') => 'Southpark',
    $film1->form_fieldname('length',  'o1') => 42,
    $film1->form_fieldname('comment', 'o1') => 'Damn it!',
    $film2->form_fieldname('title',   'o2') => 'Pulp Fiction',
    $film2->form_fieldname('length',  'o2') => 120,
    $film2->form_fieldname('comment', 'o2') => "Zed's dead baby...",

    # The new objects
    Test::Film->form_fieldname('title',     'o3') => 'Kill bill',
    Test::Film->form_fieldname('length',    'o3') => 99,
    Test::Film->form_fieldname('comment',   'o3') => 'Pussy wagon',
    Test::Film->form_fieldname('title',     'o4') => 'Donnie Darko',
    Test::Film->form_fieldname('length',    'o4') => 123,
    Test::Film->form_fieldname('comment',   'o4') => 'Watch the sky for engines',
};

print 'Formdata: '.Dumper($formdata);

# Extract all 4 objects
my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok((grep { ref($_) eq 'Test::Film' } @objects) == 4,
   "formdata_to_objects: Extracted ".@objects." objects");

print 'Final objects: '.Dumper(\@objects)
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

  ok((map { $_->insert_or_update } @objects),"Updating objects in db");
