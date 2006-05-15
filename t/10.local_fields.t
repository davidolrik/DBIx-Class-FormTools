use Test::More;
use Data::Dumper;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 6);
}

INIT {
    use lib 't/lib';
    use Film;
}

is(Film->__driver, "SQLite", "Driver set correctly");

# Create 2 test objects
my $film1 = Film->create_test_object;
my $film2 = Film->create_test_object;

my $field_definition = qr{
    dbic         # Prefix
    \|           # Seperator
    [\w]+        # Object id
    \|           # Seperator
    [\w:]+       # Classname
    \|           # Seperator
    (?:          # Id field
        \d+
        |
        (?:\w+=\d+)(?:;\w+=\d+)*
    )
    \|           # Seperator
    \w*          # Attribute name (optional)
}x;

# Validate that the fields match the definition
like($film1->form_fieldname('title','o1'),   $field_definition,
     "form_fieldname: " . $film1->form_fieldname('title','o1'));
like($film1->form_fieldname('length','o1'),  $field_definition,
     "form_fieldname: " . $film1->form_fieldname('length','o1'));
like($film1->form_fieldname('comment','o1'), $field_definition,
     "form_fieldname: " . $film1->form_fieldname('comment','o1'));

# Create a form with 2 existing objects and 2 new objects
my $formdata = {
    # The existing objects
    $film1->form_fieldname('title' ,  'o1') => 'Title',
    $film1->form_fieldname('length',  'o1') => 99,
    $film1->form_fieldname('comment', 'o1') => 'This is a comment',
    $film2->form_fieldname('title',   'o2') => 'Title',
    $film2->form_fieldname('length',  'o2') => 99,
    $film2->form_fieldname('comment', 'o2') => 'This is a comment',

    # The new objects
    Film->form_fieldname('title',     'o3') => 'Title',
    Film->form_fieldname('length',    'o3') => 99,
    Film->form_fieldname('comment',   'o3') => 'This is a comment',
    Film->form_fieldname('title',     'o4') => 'Title',
    Film->form_fieldname('length',    'o4') => 99,
    Film->form_fieldname('comment',   'o4') => 'This is a comment',
};

print 'Formdata: '.Dumper($formdata);

# Extract all 4 objects
my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);
print 'Objects: '.Dumper(\@objects);
ok((grep { ref($_) eq 'Film' } @objects) == 4,
   "formdata_to_objects: Extracted ".@objects." objects");

#print 'Final objects: '.Dumper(\@objects);

# Update objects
foreach my $object ( @objects ) {
    $object->insert_or_update || diag("Unable to update object $object");
#    warn(Dumper($object->_relationships));
}
ok(1,"Objects updated");

#warn(Dumper(\@objects));
