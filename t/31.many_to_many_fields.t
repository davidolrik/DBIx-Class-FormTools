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
    Test::Film->form_fieldname('title',   'o1') => 'Black Ninja III',
    Test::Film->form_fieldname('length',  'o1') => 122,
    Test::Film->form_fieldname('comment', 'o1') => 'It is night ..',
    Test::Role->form_fieldname(undef,     'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    }) => 'Dummy value',
    Test::Actor->form_fieldname('name',   'o2') => 'Chuck Norris',
};
print 'Formdata: '.Dumper($formdata);

my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 3,"formdata_to_objects: Ojects extracted");

print 'Final objects: '.Dumper(\@objects)
    if $ENV{DBIX_CLASS_FORMTOOLS_DEBUG};

ok((map { $_->insert_or_update } @objects),"Updating objects in db");
