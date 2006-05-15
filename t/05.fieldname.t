use Test::More;
use Data::Dumper;

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
        (?:\w+=(?:\d+|new))(?:;\w+=(?:\d+|new))*
    )
    \|           # Seperator
    \w*          # Attribute name (optional)
}x;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 16);
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
    comment => 'Funny film',
});

my $film3 = $schema->resultset('Film')->create({
    title   => 'Office Space III',
    comment => 'Funny film',
});

my $actor1 = $schema->resultset('Actor')->create({
    name => 'Samir',
});

# Test as instance methods
my @instance_method_fieldnames = (
    $film1->form_fieldname('title' ,  'o1'),
    $film1->form_fieldname('length',  'o1'),
    $film1->form_fieldname('comment', 'o1'),
    $film2->form_fieldname('title',   'o2'),
    $film2->form_fieldname('length',  'o2'),
    $film2->form_fieldname('comment', 'o2'),
);
# Validate that the fields match the definition
like($_, $field_definition, "fieldname: $_")
    foreach @instance_method_fieldnames;

# Test as class methods
my @class_method_fieldnames = (
    Test::Film->form_fieldname('title',     'o3'),
    Test::Film->form_fieldname('length',    'o3'),
    Test::Film->form_fieldname('comment',   'o3'),
    Test::Film->form_fieldname('title',     'o4'),
    Test::Film->form_fieldname('length',    'o4'),
    Test::Film->form_fieldname('comment',   'o4'),
);
# Validate that the fields match the definition
like($_, $field_definition, "fieldname: $_")
    foreach @class_method_fieldnames;


# Many to many without content
ok(1,Test::Role->form_fieldname(
    undef,
    'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    })
);

# Many to many with content
ok(1,Test::Role->form_fieldname(
    'charater',
    'o3', {
        film_id  => 'o1',
        actor_id => 'o2',
    })
);