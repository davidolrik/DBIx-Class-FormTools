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

my $formdata = {
    # The existing objects
    Test::Film->form_fieldname('title',    'o1') => 'Timme on the run',
    Test::Film->form_fieldname('length',   'o1') => 99,
    Test::Film->form_fieldname('comment',  'o1') => 'TIMMY!!',
    Test::Actor->form_fieldname('name',   'o2') => 'Stan Marsh',
    Test::Role->form_fieldname('charater', 'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    }) => 'Kid',
};
print 'Formdata: '.Dumper($formdata);

my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 3,"formdata_to_objects: Ojects extracted");

print 'Final objects: '.Dumper(\@objects)
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");
