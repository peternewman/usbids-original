#	PciIds web database
#	Copyright (C) 2008 Michal Vaner (vorner@ucw.cz)
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	he Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

package PciIds::Html::Changes;
use strict;
use PciIds::Html::Users;
use PciIds::Html::List;
use PciIds::Html::Util;
use PciIds::Html::Forms;
use PciIds::Notifications;
use PciIds::Log;
use PciIds::Address;
use Apache2::Const qw(:common :http);

sub genNewItemForm( $$$$$$ ) {
	my( $req, $args, $auth, $tables, $error, $values ) = @_;
	my( $ok, $parent, $name, $note, $address ) = loadItem( $tables, $req->uri() );
	return NOT_FOUND unless( $ok );
	genHtmlHead( $req, "Add new item", undef );
	genCustomHead( $req, $args, $address, "Add new item", [ $address->canDiscuss() ? [ 'Discuss', 'newhistory' ] : (), [ 'Help', 'help', 'newitem' ], [ 'ID syntax', 'help', $address->helpName() ] ], [ logItem( $auth ), [ 'Notifications', 'notifications' ] ] );
	print "<div class='error'>$error</div>\n" if( defined $error );
	print "<form name='newitem' id='newitem' method='POST' action=''>\n<table>";
	genFormEx( [ [ 'input', 'ID:', 'text', 'id', 'maxlength="'.$address->subIdSize().'"' ],
		[ 'input', 'Name:', 'text', 'name', 'maxlength="200"' ],
		[ 'input', 'Note:', 'text', 'note', 'maxlength="1024"' ],
		[ 'textarea', 'Discussion:', undef, 'discussion', 'rows="5" cols="50"' ],
		[ 'input', 'Subscribe:', 'checkbox', 'subscribe', 'value="subscribe" checked="checked"' ],
		[ 'input', '', 'submit', 'submit', 'value="Submit"' ] ], $values );
	print '</table></form>';
	print '
<p>
	Please enter only accurate information. Descriptions like "Unknown modem device" are only of a little use to anybody.
	Real chip names and numbers are preferred over marketing names. In case you know both, enclose the marketing name in square brackets like in
	"3c595 100BaseTX [Vortex]". Do not include names of superitems in the name (like vendor name in device name).
	Check information specific to this <a href="'.buildExcept( 'action', $args ).'?action=help?help='.$address->helpName().'">ID type</a>.
<p>
	If there is something you want to clarify about the item, you can use note (like the ID does not belong to people using it).
	Discussion is for things more relevant to history of the item than the real device (like information source).
	Both note and discussion is optional.';
	genHtmlFooter( 1, $req, $args );
	return OK;
}

sub newItemForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined $auth->{'authid'} ) {#Logged in alright
		return genNewItemForm( $req, $args, $auth, $tables, undef, {} );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

sub newItemSubmit( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined $auth->{'authid'} ) {
		my( $pok, $parent, $pname, $pnote, $paddress ) = loadItem( $tables, $req->uri() );
		return NOT_FOUND unless( $pok );
		my( $data, $error ) = getForm( {
			'id' => sub{ return ( length shift ) ? undef : 'Please, provide the ID'; }, #Checked at the bottom and added as address
			'name' => sub {
				my( $name ) = @_;
				return 'Too short for a name' if( length $name < 3 );
				return 'Lenght limit of the name is 200 characters' if( length $name > 200 );
				return undef;
			},
			'note' => sub { return ( length shift > 1024 ) ? 'Note can not be longer than 1024 characters' : undef; },
			'discussion' => sub { return ( length shift > 1024 ) ? 'Discussion can not be longer than 1024 characters' : undef; },
			'subscribe' => undef
		}, [ sub { my( $data ) = @_;
			my $errstr;
			return undef unless( length $data->{'id'} );#No address, so let it for the first check
			( $data->{'address'}, $errstr ) = $paddress->append( $data->{'id'} );
			return $errstr;
		}, sub { return $paddress->canAddItem() ? undef : 'Can not add items here'; } ] );
		return genNewItemForm( $req, $args, $auth, $tables, $error, $data ) if( defined $error );
		my( $result, $comName ) = $tables->submitItem( $data, $auth );
		if( $result eq 'exists' ) {
			genHtmlHead( $req, 'ID collision', undef );
			my $addr = PciIds::Address::new( $req->uri() );
			genCustomHead( $req, $args, $addr, 'ID collision', [ [ 'Add other item', 'newitem' ], $addr->canDiscuss() ? [ 'Discuss', 'newhistory' ] : (), ], [ logItem( $auth ) ] );
			print '<p>Sorry, this ID already exists.';
			genHtmlFooter( 0, undef, undef );
			return OK;
		} elsif( $result ) {
			return genNewItemForm( $req, $args, $auth, $tables, $result, $data );
		}
		notify( $tables, $data->{'address'}->parent()->get(), $comName, 2, 0 );#Notify the parent (parent gets new items)
		$tables->submitNotification( $auth->{'authid'}, $data->{'address'}->get(), { 'recursive' => 0, 'notification' => 0, 'way' => 0 } ) if( defined $data->{'subscribe'} && $data->{'subscribe'} eq 'subscribe' );
		tulog( $auth->{'authid'}, "Item created ".$data->{'address'}->get()." ".logEscape( $data->{'name'} )." ".logEscape( $data->{'note'} )." ".logEscape( $data->{'discussion'} )." $comName" );
		return HTTPRedirect( $req, '/read/'.$data->{'address'}->get().'?action=list' );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

sub genNewHistoryForm( $$$$$$ ) {
	my( $req, $args, $tables, $auth, $error, $values ) = @_;
	my( $ok, $parent, $name, $note, $address ) = loadItem( $tables, $req->uri() );
	return NOT_FOUND unless( $ok );
	genHtmlHead( $req, "Discuss", undef );
	genCustomHead( $req, $args, $address, "Discuss", [ $address->canAddItem() ? [ 'Add item', 'newitem' ] : (), [ 'Help', 'help', 'newhistory' ] ], [ logItem( $auth ),  [ 'Notifications', 'notifications' ] ] );
	print "<div class='error'>$error</div>\n" if( defined $error );
	print "<form name='newhistory' id='newhistory' method='POST' action=''>\n<table>";
	genFormEx( [ [ 'textarea', 'Text:', undef, 'text', 'rows="5" cols="50"' ],
		[ 'input', 'Request deletion', 'checkbox', 'delete', 'value="delete"' ],
		[ 'input', 'Name:', 'text', 'name', 'maxlength="200"' ],
		[ 'input', 'Note:', 'text', 'note', 'maxlength="1024"' ],
		!$tables->notifExists( $auth->{'authid'}, $address->get() ) ? [ 'input', 'Subscribe:', 'checkbox', 'subscribe', "value='subscribe' checked='checked'" ] : (),
		[ 'input', '', 'submit', 'submit', 'value="Submit"' ] ], $values );
	print '</table></form>';
	print '
<p>
	Please enter only accurate information. Descriptions like "Unknown modem device" are only of a little use to anybody.
	Real chip names and numbers are preferred over marketing names. In case you know both, enclose the marketing name in square brackets like in
	"3c595 100BaseTX [Vortex]". Do not include names of superitems in the name (like vendor name in device name).
	Check information specific to this <a href="'.buildExcept( 'action', $args ).'?action=help?help='.$address->helpName().'">ID type</a>.
<p>
	You may provide just discussion, request deletion or enter a new name and note.
	Note is for clarification of the device information, discussion is for reasons, why you change it and like that.
<p>
	You may add discussion note to name change or deletion request too.
	You must provide at last name or discussion or deletion request.
<p>
	If you provide note, you must provide name too.';
	genHtmlFooter( 1, $req, $args );
	return OK;
}

sub newHistoryForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined $auth->{'authid'} ) {
		return genNewHistoryForm( $req, $args, $tables, $auth, undef, {} );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

sub newHistorySubmit( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined $auth->{'authid'} ) {
		my( $ok, $parent, $name, $note, $address ) = loadItem( $tables, $req->uri() );
		return NOT_FOUND unless( $ok );
		my( $data, $error ) = getForm( {
			'name' => sub { return ( length shift > 200 ) ? 'Lenght limit of the name is 200 characters' : undef; },
			'note' => sub { return ( length shift > 1024 ) ? 'Note can not be longer than 1024 characters' : undef; },
			'text' => sub {
				my( $expl ) = @_;
				return 'Text can not be longer than 1024 characters' if ( length $expl > 1024 );
				return undef;
			},
			'delete' => sub {
				my( $delete ) = @_;
				return ( undef, '0' ) unless defined $delete;
				return undef if $delete eq 'delete';
				return 'Invalid form value';
				return undef;
			},
			'subscribe' => undef
		}, [ sub { my( $data ) = @_;
			return 'You must provide either name, text or request a deletion' if( ! length $data->{'name'} && ! length $data->{'text'} && ! $data->{'delete'} );
			return undef;
		}, sub { my( $data ) = @_;
			return 'You can not set name and request deletion at the same time' if( length $data->{'name'} && $data->{'delete'} );
			return undef;
		}, sub { my( $data ) = @_;
			return 'You must provide name too' if( ( length $data->{'note'} ) && ( ! length $data->{'name'} ) );
			return undef;
		}, sub { return $address->canDiscuss() ? undef : 'You can not discuss this item'; } ] );
		return genNewHistoryForm( $req, $args, $tables, $auth, $error, $data ) if( defined $error );
		my $hid = $tables->submitHistory( $data, $auth, $address );
		tulog( $auth->{'authid'}, "Discussion created $hid ".$address->get()." ".logEscape( $data->{'name'} )." ".logEscape( $data->{'description'} )." ".logEscape( $data->{'text'} ) );
		notify( $tables, $address->get(), $hid, ( defined $name && ( $name ne '' ) ) ? 1 : 0, 1 );
		$tables->submitNotification( $auth->{'authid'}, $address->get(), { 'recursive' => 0, 'notification' => 1, 'way' => 0 } ) if( defined $data->{'subscribe'} && $data->{'subscribe'} eq 'subscribe' );
		return HTTPRedirect( $req, '/read/'.$address->get().'?action=list' );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

1;
