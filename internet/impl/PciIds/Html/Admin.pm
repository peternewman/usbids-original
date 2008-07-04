package PciIds::Html::Admin;
use strict;
use warnings;
use PciIds::Users;
use PciIds::Html::Util;
use PciIds::Html::Users;
use PciIds::Html::Forms;
use PciIds::Notifications;
use PciIds::Log;
use Apache2::Const qw(:common :http);

sub genNewAdminForm( $$$$ ) {
	my( $req, $args, $tables, $error ) = @_;
	genHtmlHead( $req, 'Administration ‒ pending events', undef );
	print "<h1>Administration ‒ pending events</h1>\n";
	print "<div class='error'>".$error."</div>\n" if( defined $error );
	print '<form name="admin" id="admin" class="admin" method="POST" action="'.setAddrPrefix( $req->uri(), 'mods' ).buildExcept( 'action', $args )."?action=admin\">\n";
	my $lastId;
	my $started = 0;
	my $cnt = 0;
	my $hiscnt = 0;
	my $subcnt;
	foreach( @{$tables->adminDump()} ) {
		my( $locId, $actName, $actDescription, $actCom, $actUser, $actText,
			$com, $text, $name, $description, $user ) = @{$_};
		if( !defined( $lastId ) || ( $lastId ne $locId ) ) {
			$lastId = $locId;
			print "</div>\n" if( $started );
			$started = 1;
			print "<div class='".( defined( $actCom ) ? 'item' : 'unnamedItem' )."'>\n";
			my $addr = PciIds::Address::new( $locId );
			print "<h3><a href='/read/".$addr->get()."/'>".encode( $addr->pretty() )."</a></h3>\n";
			print htmlDiv( 'name', '<p>'.encode( $actName ) ) if( defined( $actName ) );
			print htmlDiv( 'description', '<p>'.encode( $actDescription ) ) if( defined( $actDescription ) );
			print '<p>'.encode( $actText ) if( defined( $actText ) );
			print '<p><a class="navigation" href="/read/'.$addr->parent()->get().'/">'.encode( $addr->parent()->pretty() )."</a>" if( defined( $addr->parent() ) );
			print htmlDiv( 'author', '<p>'.encode( $actUser ) ) if( defined( $actUser ) );
			print "<input type='hidden' name='subcnt-$cnt' value='$subcnt'>\n" if( defined( $subcnt ) );
			$subcnt = 0;
			$cnt++;
			print "<input type='hidden' name='loc-$cnt' value='".$addr->get()."'>\n";
			print "<p><input type='radio' name='action-$cnt' value='ignore' checked='checked'> I will decide later.\n";
			if( defined( $actCom ) ) {
				print "<br><input type='radio' name='action-$cnt' value='keep'> Keep current name.\n";
			}
			print "<br><input type='radio' name='action-$cnt' value='delete'> Delete item.\n";
			print "<br>Add comment:\n";
			print "<br><table>\n";
			print "<tr><td>Set name:<td><input type='text' name='name-$cnt' maxlength='200'>\n";
			print "<tr><td>Set description:<td><input type='text' name='description-$cnt' maxlength='1024'>\n";
			print "<tr><td>Text:<td><textarea name='text-$cnt' rows='2'></textarea>\n";
			print "</table>\n";
		}
		print "<div class='unseen-comment'>\n";
		print "<p class='name'>".encode( $name ) if( defined( $name ) );
		print "<p class='description'>".encode( $description ) if( defined( $description ) );
		print '<p>'.encode( $text ) if( defined( $text ) );
		print "<p class='author'>".encode( $user ) if( defined( $user ) );
		print "<p><input type='radio' name='action-$cnt' value='set-$com'> Use this one.\n" if( defined( $name ) && ( $name ne "" ) );
		$hiscnt ++;
		print "<br><input type='checkbox' name='delete-$hiscnt' value='delete-$com'> Delete comment.\n";
		print "</div>\n";
		$subcnt ++;
		print "<input type='hidden' name='sub-$cnt-$subcnt' value='$com'>\n";
	}
	print "<input type='hidden' name='subcnt-$cnt' value='$subcnt'>\n" if( defined( $subcnt ) );
	if( $started ) {
		print "</div>\n" if( $started );
		print "<p><input type='submit' name='submit' value='Submit'>\n";
		print "<input type='hidden' name='max-cnt' value='$cnt'><input type='hidden' name='max-hiscnt' value='$hiscnt'>\n";
	} else {
		print "<p>No pending comments.\n";
	}
	print "</form>\n";
	genHtmlTail();
	return OK;
}

sub adminForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined( $auth->{'authid'} ) && hasRight( $auth->{'accrights'}, 'validate' ) ) {
		return genNewAdminForm( $req, $args, $tables, undef );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

sub markAllChecked( $$$$ ) {
	my( $tables, $itemNum, $deleted, $authid ) = @_;
	my $i;
	my $subcnt = getFormValue( "subcnt-$itemNum", 0 );
	for( $i = 1; $i <= $subcnt; ++ $i ) {
		my $id = getFormValue( "sub-$itemNum-$i", undef );
		next unless( defined( $id ) );
		next if( $deleted->{$id} );#Do not update this one, already deleted
		$tables->markChecked( $id );
		tulog( $authid, "Comment checked $id" );
	}
}

sub submitAdminForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	my $authid = $auth->{'authid'};
	if( defined( $authid ) && hasRight( $auth->{'accrights'}, 'validate' ) ) {
		my $errors = '';
		my %deleted;
		my $maxcnt = getFormValue( 'max-cnt', 0 );
		my $maxhiscnt = getFormValue( 'max-hiscnt', 0 );
		for( my $i = 1; $i <= $maxhiscnt; $i ++ ) {
			my $del = getFormValue( "delete-$i", "" );
			$del =~ s/^delete-//;
			if( $del ne '' ) {
				$deleted{$del} = 1;
				$tables->deleteHistory( $del );
				tulog( $authid, "Comment deleted $del" );
			}
		}
		for( my $i = 1; $i <= $maxcnt; $i ++ ) {
			my $action = getFormValue( "action-$i", 'ignore' );
			my $loc = getFormValue( "loc-$i", undef );
			next unless( defined( $loc ) );
			my( $text, $name, $description ) = (
				getFormValue( "text-$i", undef ),
				getFormValue( "name-$i", undef ),
				getFormValue( "description-$i", undef ) );
			if( defined( $description ) && ( $description ne '' ) && ( !defined( $name ) || ( length $name < 3 ) ) ) {
				if( $errors eq '' ) {
					$errors = '<p>';
				} else {
					$errors .= '<br>';
				}
				$errors .= "$loc - You need to provide name if you provide description\n";
				next;
			}
			if( ( defined( $name ) && ( length $name >= 3 ) ) || ( defined( $text ) && ( $text ne '' ) ) ) { #Submited comment
				my $addr = PciIds::Address::new( $loc );
				my $comId = $tables->submitComment( { 'name' => $name, 'description' => $description, 'explanation' => $text }, $auth, $addr );
				my $main = defined $name && ( $name ne '' );
				notify( $tables, $addr->get(), $comId, $main ? 2 : 0, $main ? 2 : 1 );
				$tables->markChecked( $comId );
				tulog( $authid, "Comment created (admin) $comId $loc ".logEscape( $name )." ".logEscape( $description )." ".logEscape( $text ) );
				if( defined( $name ) && ( length $name >= 3 ) ) {
					$tables->setMainComment( $loc, $comId );
					tulog( $authid, "Item main comment changed $loc $comId" );
					$action = 'keep';
				}
			}
			next if( $action eq 'ignore' );
			if( $action eq 'keep' ) {
				markAllChecked( $tables, $i, \%deleted, $authid );
			} elsif( $action eq 'delete' ) {
				eval {
					$tables->deleteItem( $loc );
					tulog( $authid, "Item deleted (recursive) $loc" );
				} #Ignore if it was already deleted by superitem
			} elsif( my( $setId ) = ( $action =~ /set-(.*)/ ) ) {
				next if( $deleted{$setId} );
				$tables->setMainComment( $loc, $setId );
				notify( $tables, $loc, $setId, 2, 2 );
				tulog( $authid, "Item main comment changed $loc $setId" );
				markAllChecked( $tables, $i, \%deleted, $authid );
			}
		}
		return genNewAdminForm( $req, $args, $tables, $errors );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

1;
