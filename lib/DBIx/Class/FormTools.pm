package DBIx::Class::FormTools;

our $VERSION = '0.000002';

use strict;
use warnings;

use Carp;

use base qw/Class::Data::Inheritable/;

__PACKAGE__->mk_classdata('_objects'  => {});
__PACKAGE__->mk_classdata('_formdata' => {});

=head1 NAME

DBIx::Class::FormTools - Build forms with multiple interconnected objects.


=head1 VERSION

This document describes DBIx::Class::FormTools version 0.0.1


=head1 SYNOPSIS

=head2 In your Model class

=over

    use base qw/DBIx::Class/;
    __PACKAGE__->load_components(qw/PK::Auto::SQLite Core DB FormTools/);

=back

=head2 In your view - Mason example


=over

    <%init>
    my $o = Film->retrieve(42);
    </%init>
    <form>
        <input name="<% $film->form_fieldname('title', 'o1') => 'Title' %>" type="text" value="<% $o-> %>" />
        <input name="<% $film->form_fieldname('length', 'o1') %>" type="text" value="<% $o->length %>" />
        <input name="<% $film->form_fieldname('comment', 'o1') %>" type="text" value="<% $o->comment %>" />
        <input name="<% Role->form_fieldname(undef,'o3', { film_id => 'o1', actor_id => 'o2' }) %>" type="text" value="Pirate" />
        <input name="<% $actor->form_fieldname('name', 'o2') %>" type="text" value="<% $o->name %>" />
    </form>

=back


=head2 In your controler

    my @objects = Class::DBI::FormTools->formdata_to_objects($quesrstring);
    foreach my $object ( @objects ) {
        $object->insert_or_update;
    }

=head1 DESCRIPTION

DBIx::Class::FormTools is a data serializer, that can convert HTML formdata to DBIx::Class objects.

It uses usersupplied object ids to connect the objects, even if the objects does not exist on beforehand.

=head1 METHODS

=over

=item form_fieldname($accessor, $object_id, $foreign_object_ids)

=over

=item $accessor
The field in the object you wish to create a key for

=item $object_id
A unique string identifying this object. It is this key that is used to connect the dots.

=item $foreign_object_ids
A HASHREF containing attribute => object_id pairs.

=back

Create unique form field name for use in HTML form

=cut
sub form_fieldname
{
    my ($self,$accessor,$object_id,$foreign_object_ids) = @_;

    # Get class name
    my $class = ref $self || $self;

    my @primary_keys  = $class->primary_columns;
    my %relationships = %{ $class->_relationships || {} };

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


=item formdata_to_objects($formdata)

Turn formdata in the form of a HASHREF into DBIx::Class objects

=cut
sub formdata_to_objects
{
    my ($self,$formdata) = @_;

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
    my $relations = $class->_relationships;
    foreach my $foreign_accessor ( keys %$relations ) {
        my $foreign_class = $relations->{$foreign_accessor}->{'class'};
        my $foreign_relation_type = $relations->{$foreign_accessor}
                                              ->{'attrs'}
                                              ->{'accessor'};

        # Do not process multicolumn relationships, they will be processed
        # seperatly when the object to wich they relate is inflated
        # I.e. only process "local" fields
        next if $foreign_relation_type eq 'multi';

        # Lookup foreign object
        my $foreign_id = $self->_formdata
                              ->{$oid}
                              ->{'form_id'}
                              ->{$foreign_accessor};

        # No id found, no inflate needed
        next unless $foreign_id;

        my $foreign_object = $self->_inflate_object(
            $foreign_id,
            $foreign_class,
        );

        # Store object for later use
        $self->_objects->{$foreign_class}->{$oid}
            = $foreign_object;

        # If the field is part of the id then store it there as well
        $id->{$foreign_accessor} = $foreign_object->id
            if exists $id->{$foreign_accessor};

        # Store the foreign object with all the other object data
        $attributes->{$foreign_accessor} = $foreign_object;
    }
    # All foreign objects have been now been inflated

    # Look up object in memory
    my $object = $self->_objects->{$class}->{$oid};

    # Lookup in object in db
    unless ( $object ) {
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

=back

=cut

1; # Magic true value required at end of module
__END__


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dbix-class-formtools@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

David Jack Olrik  C<< <david@olrik.dk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, David Jack Olrik C<< <david@olrik.dk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
