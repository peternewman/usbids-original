package PciIds::Html::Changes;
use strict;
use PciIds::Html::Users;
use PciIds::Html::List;
use PciIds::Html::Util;
use PciIds::Html::Forms;
use PciIds::Notifications;
use PciIds::Log;
use Apache2::Const qw(:common :http);

sub genNewItemForm( $$$$$ ) {
	my( $req, $args, $tables, $error, $values ) = @_;
	my( $ok, $parent, $name, $note, $address ) = loadItem( $tables, $req->uri() );
	return NOT_FOUND unless( $ok );
	my $prettyAddr = encode( $address->pretty() );
	genHtmlHead( $req, "$prettyAddr - add new item", undef );
	print "<h1>$prettyAddr - add new item</h1>\n";
	print "<div class='error'>$error</div>\n" if( defined $error );
	print "<form name='newitem' id='newitem' method='POST' action=''>\n<table>";
	genFormEx( [ [ 'input', 'Id:', 'text', 'id', 'maxlength="50"' ],
		[ 'input', 'Name:', 'text', 'name', 'maxlength="200"' ],
		[ 'input', 'Note*:', 'text', 'note', 'maxlength="1024"' ],
		[ 'textarea', 'Discussion*:', undef, 'discussion', 'rows="5" cols="50"' ],
		[ 'input', '', 'submit', 'submit', 'value="Submit"' ] ], $values );
	print '</table></form>';
	print '<p>Items marked with * are optional.';
	genHtmlTail();
	return OK;
}

sub newItemForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined $auth->{'authid'} ) {#Logged in alright
		return genNewItemForm( $req, $args, $tables, undef, {} );
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
			'discussion' => sub { return ( length shift > 1024 ) ? 'Discussion can not be longer than 1024 characters' : undef; }
		}, [ sub { my( $data ) = @_;
			my $errstr;
			return undef unless( length $data->{'id'} );#No address, so let it for the first check
			( $data->{'address'}, $errstr ) = $paddress->append( $data->{'id'} );
			return $errstr;
		}, sub { return $paddress->canAddItem() ? undef : 'Can not add items here'; } ] );
		return genNewItemForm( $req, $args, $tables, $error, $data ) if( defined $error );
		my( $result, $comName ) = $tables->submitItem( $data, $auth );
		if( $result eq 'exists' ) {
			genHtmlHead( $req, 'ID collision', undef );
			print '<h1>ID collision</h1>';
			print '<p>This ID already exists. Have a look <a href="/read/'.$data->{'address'}->get().'?action=list">at it</a>';
			genHtmlTail();
			return OK;
		} elsif( $result ) {
			die "Failed to submit new item: $result\n";
		}
		notify( $tables, $data->{'address'}->get(), $comName, 2, 0 );
		tulog( $auth->{'authid'}, "Item created ".$data->{'address'}->get()." ".logEscape( $data->{'name'} )." ".logEscape( $data->{'note'} )." ".logEscape( $data->{'discussion'} )." $comName" );
		return HTTPRedirect( $req, '/read/'.$data->{'address'}->get().'?action=list' );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

sub genNewHistoryForm( $$$$$ ) {
	my( $req, $args, $tables, $error, $values ) = @_;
	my( $ok, $parent, $name, $note, $address ) = loadItem( $tables, $req->uri() );
	return NOT_FOUND unless( $ok );
	my $prettyAddr = encode( $address->pretty() );
	genHtmlHead( $req, "$prettyAddr - discuss", undef );
	print "<h1>$prettyAddr - discuss</h1>\n";
	print "<div class='error'>$error</div>\n" if( defined $error );
	print "<form name='newhistory' id='newhistory' method='POST' action=''>\n<table>";
	genFormEx( [ [ 'textarea', 'Text:', undef, 'text', 'rows="5" cols="50"' ],
		[ 'input', 'Name*:', 'text', 'name', 'maxlength="200"' ],
		[ 'input', 'Note*:', 'text', 'note', 'maxlength="1024"' ],
		[ 'input', '', 'submit', 'submit', 'value="Submit"' ] ], $values );
	print '</table></form>';
	print '<p>Items marked with * are optional, use them only if you want to change the name and note.';
	print '<p>If you specify note, you must include name too.';
	genHtmlTail();
	return OK;
}

sub newHistoryForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined $auth->{'authid'} ) {
		return genNewHistoryForm( $req, $args, $tables, undef, {} );
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
				return 'You must provide the text of comment' unless( length $expl );
				return undef;
			}
		}, [ sub { my( $data ) = @_;
			return 'You must provide name too' if( ( length $data->{'note'} ) && ( ! length $data->{'name'} ) );
			return undef;
		}, sub { return $address->canAddComment() ? undef : 'You can not discuss this item'; } ] );
		return genNewHistoryForm( $req, $args, $tables, $error, $data ) if( defined $error );
		my $hid = $tables->submitHistory( $data, $auth, $address );
		tulog( $auth->{'authid'}, "Comment created $hid ".$address->get()." ".logEscape( $data->{'name'} )." ".logEscape( $data->{'description'} )." ".logEscape( $data->{'text'} ) );
		notify( $tables, $address->get(), $hid, ( defined $name && ( $name ne '' ) ) ? 1 : 0, 1 );
		return HTTPRedirect( $req, '/read/'.$address->get().'?action=list' );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

1;
