use Test::More;
use Data::Dumper;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 2);
}

INIT {
    use lib 't/lib';
    use Film;
    use Actor;
    use Role;
    use Location;
}

is(Film->__driver, "SQLite", "Driver set correctly");

my $film  = Film->create_test_object;
my $actor = Actor->create_test_object;


my $formdata = {
    # The existing objects
    $film->form_fieldname('title',   'o1') => 'Title',
    $film->form_fieldname('length',  'o1') => 99,
    $film->form_fieldname('comment', 'o1') => 'This is a comment',
    Role->form_fieldname(undef,      'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    }) => 'Test',
    $actor->form_fieldname('name',   'o2') => 'Test actor',
};
print 'Formdata: '.Dumper($formdata);

my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
ok(@objects == 3,"formdata_to_objects: Extracted ".@objects." objects");
print 'Final objects: '.Dumper(\@objects);

# Update objects
map { $_->update || diag("Unable to update object ".Dumper($_)) } @objects;
