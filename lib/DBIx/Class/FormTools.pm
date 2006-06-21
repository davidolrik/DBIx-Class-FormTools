package DBIx::Class::FormTools;

our $VERSION = '0.000004';

use strict;
use warnings;

use Carp;

use base qw/Class::Data::Inheritable/;

__PACKAGE__->mk_classdata('_objects'   => {});
__PACKAGE__->mk_classdata('_formdata'  => {});

=head1 NAME

DBIx::Class::FormTools - Utility module for building forms with multiple related L<DBIx::Class> objects.

=head1 VERSION

This document describes DBIx::Class::FormTools version 0.0.3

=head1 SYNOPSIS

=head2 Prerequisites

In the examples I use 3 objects, a C<Film>, an C<Actor> and a C<Role>.
C<Role> is a many to many relation between C<Film> and C<Actor>.

    package MySchema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_classes(qw[
        Film
        Actor
        Role
    ]);


    package MySchema::Film;
    __PACKAGE__->table('films');
    __PACKAGE__->add_columns(qw[
        id
        title
    ]);
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(roles => 'MySchema::Role', 'film_id');
    

    package MySchema::Actor;
    __PACKAGE__->table('films');
    __PACKAGE__->add_columns(qw[
        id
        name
    ]);
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(roles => 'MySchema::Role', 'actor_id');


    package MySchema::Role;
    __PACKAGE__->table('roles');
    __PACKAGE__->add_columns(qw[
        film_id
        actor_id
    ]);
    __PACKAGE__->set_primary_key(qw[
        film_id
        actor_id
    ]);

    __PACKAGE__->belongs_to(film_id  => 'MySchema::Film');
    __PACKAGE__->belongs_to(actor_id => 'MySchema::Actor');


=head2 In your Model class

    use base qw/DBIx::Class/;
    __PACKAGE__->load_components(qw/PK::Auto::Pg Core FormTools/);

=head2 In your view - L<HTML::Mason> example

    <%init>
    my $film  = $schema->resultset('Film')->find(42);
    my $actor = $schema->resultset('Actor')->find(24);
    </%init>
    <form>
        <input
            name="<% $film->form_fieldname('title', 'o1') => 'Title' %>"
            type="text"
            value="<% $film->title %>"
        />
        <input
            name="<% $film->form_fieldname('length', 'o1') %>"
            type="text"
            value="<% $film->length %>"
        />
        <input
            name="<% $film->form_fieldname('comment', 'o1') %>"
            type="text"
            value="<% $film->comment %>"
        />
        <input
            name="<% $actor->form_fieldname('name', 'o2') %>"
            type="text"
            value="<% $actor->name %>"
        />
        <input
            name="<% MyNamespace::Role->form_fieldname(undef, 'o3', {
                film_id  => 'o1',
                actor_id => 'o2'
            }) %>"
            type="hidden"
            value="dummy"
        />
    </form>


=head2 In your controller (or cool helper module, used in your controller)

    my @objects = DBIx::Class::FormTools->formdata_to_objects($querystring);
    foreach my $object ( @objects ) {
        # Assert and Manupulate $object as you like
        $object->insert_or_update;
    }

=head1 DESCRIPTION

=head2 Introduction

L<DBIx::Class::FormTools> is a data serializer, that can convert HTML formdata
to L<DBIx::Class> objects based on element names created with 
L<DBIx::Class::FormTools>.

It uses user supplied object ids to connect the objects with each-other.
The objects do not need to exist on beforehand.

The module is not ment to be used directly, although it can of-course be done
as seen in the above example, but rather used as a utility module in a
L<Catalyst> helper module or other equivalent framework.

=head2 Connecting the dots - The problem at hand

Creating a form with data from one object and storing it in a database is
easy, and several modules that does this quite well already exists on CPAN.

What I am trying to accomplish here, is to allow multiple objects to be
created and updated in the same form - This includes the relations between
the objects i.e. "connecting the dots".

=head2 Non-existent ids - Enter object_id

When converting the formdata to objects, we need "something" to identify the
objects by, and sometimes we also need this "something" to point to another
object in the formdata to signify a relation. For this purpose we have the
C<object_id> which is user definable and can be whatever you like.

=head1 METHODS

=head2 C<form_fieldname($accessor, $object_id, $foreign_object_ids)>

    my $name_film  = $film->form_fieldname('title', 'o1');
    my $name_actor = $actor->form_fieldname('name', 'o2');
    my $name_role  = MyNamespace::Role->form_fieldname(
        undef,'o3', { film_id => 'o1', actor_id => 'o2' }
    );
    my $name_role  = MyNamespace::Role->form_fieldname(
        'charater','o3', { film_id => 'o1', actor_id => 'o2' }
    );

Creates a unique form field name for use in an HTML form.

=over

=item C<$accessor>

The attribute in the object you wish to create a key for.

=item C<$object_id>

A unique string identifying a specific object in the form.

=item C<$foreign_object_ids>

A C<HASHREF> containing C<attribute =E<gt> object_id> pairs, use this to
connect objects with each-other as seen in the above example.

=back

=cut
sub form_fieldname
{
    my ($self,$accessor,$object_id,$foreign_object_ids) = @_;

    # Get class name
    my $class = ref $self || $self;

    my @primary_keys  = $class->primary_columns;
    
    my %relationships
        = ( map { $_,$class->relationship_info($_) } $class->relationships );

    my %id_fields = ();
    foreach my $primary_key ( @primary_keys ) {
        # Field is foreign key
        if ( exists $relationships{$primary_key} ) {;
            $id_fields{$primary_key} = $foreign_object_ids->{$primary_key};
        }
        # Field is local
        else {
            $id_fields{$primary_key}
                = ( ref($self) ) ? $self->$primary_key : 'new';
        }
    }

    # Build object key
    my $fieldname = join('|',
        'dbic',
        $object_id,
        $class,
        join(q{;}, map { "$_=".$id_fields{$_} } keys %id_fields),
        ($accessor || ''),
    );

    return($fieldname);
}


=head2 C<formdata_to_objects($formdata)>

    my @objects = DBIx::Class::FormTools->formdata_to_objects($formdata);

Turn formdata in the form of a C<HASHREF> into an C<ARRAY> of C<DBIx::Class>
objects.

=cut
sub formdata_to_objects
{
    my ($self,$formdata) = @_;

    # Cleanup old objects
    $self->_objects({});
    $self->_formdata({});

    # Extract all dbic fields
    my @dbic_formkeys = grep { /^dbic\|/ } keys %$formdata;

    my $objects = {};

    # Create a todo list with one entry for each unique objects
    # So we can process them in reverse order of dependency
    my %todolist;

    # Sort data into piles for later object creation/updating
    foreach my $formkey ( @dbic_formkeys ) {
        my ($prefix,$object_id,$class,$id,$attribute) = split(/\|/,$formkey);

        # Store form contents
        $self->_formdata->{$object_id}->{'content'}->{$attribute}
            = $formdata->{$formkey} if $attribute;

        # Build id field
        my %id;
        foreach my $field ( split(/;/,$id) ) {
            my ($key,$value) = split(/=/,$field);
            $id{$key} = $value;
        }

        # Store id field
        $self->_formdata->{$object_id}->{'form_id'} = \%id;

        # Save class name and id in the todo list
        # (hash used to avoid dupes)
        $todolist{"$class|$object_id"} = {
            class     => $class,
            object_id => $object_id,
        };
    }

    # Flatten todo hash into a todolist array
    my @todolist = values %todolist;

    # Build objects from form data
    my @objects;
    foreach my $todo ( @todolist ) {
        my $object = $self->_inflate_object(
            $todo->{ 'object_id' },
            $todo->{ 'class'     },
        );        
        push(@objects,$object);
    }

    # Cleanup old objects
    $self->_objects({});
    $self->_formdata({});

    return(@objects);
}

sub _flatten_id
{
    my ($id) = @_;
    
    return join(';', map { $_.'='.$id->{$_} } sort keys %$id);
}

sub _inflate_object
{
    my ($self,$oid,$class) = @_;

    my $attributes;
    my $id;

    # Object exists in form
    if ( exists($self->_formdata->{$oid}) ) {
        $id         = $self->_formdata->{$oid}->{'form_id'};
        $attributes = $self->_formdata->{$oid}->{'content'};
    }
    # Object does not exist in form, use oid as id
    # FIXME -> Should this be removed ?
    else {
        $id = { id => $oid };
    }

    # Return object if is already inflated
    return $self->_objects->{$class}->{$oid}
        if $self->_objects->{$class}
        && $self->_objects->{$class}->{$oid};

    # Inflate foreign fields that map to a *single* column
    my $relationships
        = { map { $_,$class->relationship_info($_) } $class->relationships };
    
    my $schema = $class->class_resolver;
    foreach my $foreign_accessor ( keys %$relationships ) {
        # Resolve foreign class name
        my $foreign_class = $schema->class(
            $relationships->{$foreign_accessor}->{'class'}
        );

        my $foreign_relation_type = $relationships->{$foreign_accessor}
                                                  ->{'attrs'}
                                                  ->{'accessor'};

        # Do not process multicolumn relationships, they will be processed
        # seperatly when the object to which they relate is inflated
        # I.e. only process "local" attributes
        next if $foreign_relation_type eq 'multi';

        # Lookup foreign object id
        # FIXME: Should we really look in both places?
        my $foreign_oid = ( $self->_formdata
                                 ->{$oid}
                                 ->{'form_id'}
                                 ->{$foreign_accessor} )
                        ? $self->_formdata
                               ->{$oid}
                               ->{'form_id'}
                               ->{$foreign_accessor}
                        : $self->_formdata
                               ->{$oid}
                               ->{'content'}
                               ->{$foreign_accessor};
        # No id found, no inflate needed
        next unless $foreign_oid;

        my $foreign_object = $self->_inflate_object(
            $foreign_oid,
            $foreign_class,
        );

        # Store object for later use
        $self->_objects->{$foreign_class}->{$oid}
            = $foreign_object;

        # If the field is part of the id then store it there as well
        $id->{$foreign_accessor} = $foreign_object->id
            if exists $id->{$foreign_accessor};

        # Store the foreign object with all the other object data
        # FIME: Shouldn't I be able to just pass the whole object here ?
        $attributes->{$foreign_accessor} = $foreign_object->id;
    }
    # All foreign objects have been now been inflated

    # Look up object in memory
    my $object = $self->_objects->{$class}->{$oid};

    # Lookup in object in db
    # FIXME: Maybe add check for 'new' in id and skip if it exists
    unless ( $object || $id eq 'new' ) {
        $object = $class->find($id);
    }

    # Still no object, the create it
    unless ( $object ) {
        $object = $class->create($attributes);
    }

    # If we have a object update it with form data, if it exists
    $object->set_columns($attributes) if $attributes && $object;

    # Store object for later use
    if ( $id && $object ) {
        $self->_objects->{$class}->{$oid} = $object;
    }

    return($object);
}

1; # Magic true value required at end of module
__END__

=head1 CAVEATS

=head2 Transactions

When using this module it is prudent that you use a database that supports
transactions.

The reason why this is important, is that when calling C<formdata_to_objects>,
C<DBIx::Class::Row-E<gt>create()> is called foreach nonexistent object in
order to get the C<primary key> filled in. This call to C<create> results in a
SQL C<insert> statement, and might leave you with one object successfully put
into the database and one that generates an error - Transactions will allow
you to examine the C<ARRAY> of objects returned from C<formdata_to_objects>
before actually storing them in the database.

=head2 Automatic Primary Key generation

You must use on of the C<DBIx::Class::PK::Auto::*> classes, otherwise the
C<formdata_to_objects> will fail when creating new objects, as it is unable to
determine the value for the primary key, and therefore is unable to connect
the object to any related objects in the form.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dbix-class-formtools@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

David Jack Olrik  C<< <djo@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, David Jack Olrik C<< <djo@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 TODO

=over

=item * Create methods for building html elements using some thing like
        L<HTML::Widget>.

=back

=head1 SEE ALSO

L<DBIx::Class>, L<DBIx::Class::PK::Auto>
