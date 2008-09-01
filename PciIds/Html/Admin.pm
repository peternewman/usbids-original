package PciIds::Html::Admin;
use strict;
use warnings;
use PciIds::Users;
use PciIds::Html::Util;
use PciIds::Html::Users;
use PciIds::Html::Forms;
use PciIds::Notifications;
use PciIds::Address;
use PciIds::Log;
use Apache2::Const qw(:common :http);

sub safeEncode( $ ) {
	my( $text ) = @_;
	return encode( $text ) if defined $text;
	return '';
}

sub mailEncode( $ ) {
	my( $email ) = @_;
	return '' unless defined $email;
	return "<a href='mailto:$email'>".encode( $email )."</a>";
}

sub genNewAdminForm( $$$$$ ) {
	my( $req, $args, $tables, $error, $auth ) = @_;
	my $address = PciIds::Address::new( $req->uri() );
	my $prefix = $address->get();
	$prefix = '' if( $args->{'global'} );
	my $caption = 'Administration '.( $args->{'global'} ? '(Global)' : '('.encode( $address->pretty() ).')' );
	genHtmlHead( $req, $caption, undef );
	genCustomHead( $req, $args, $address, $caption, [ $address->canAddItem() ? [ 'Add item', 'newitem' ] : (), $address->canDiscuss() ? [ 'Discuss', 'newhistory' ] : (), [ 'Help', 'help', 'admin' ], [ '', 'jump' ] ], [ [ 'Log out', 'logout' ] ] );
	print "<div class='error'>$error</div>\n" if( defined $error );
	print "<form name='admin' id='admin' class='admin' method='POST' action=''>\n";
	my $lastId;
	my $started = 0;
	my $cnt = 0;
	my $hiscnt = 0;
	my $subcnt;
	print "<table class='admin'>\n";
	print "<col class='id-col'><col class='name-col'><col class='note-col'><col class='disc-col'><col class='auth-col'><col class='control-col' span='3'>\n";
	print "<tr class='head'><th>ID<th>Name<th>Note<th>Discussion<th>Author<th>Ok<th>Sel<th>Del\n";
	foreach( @{$tables->adminDump( $prefix )} ) {
		my( $locId, $actName, $actNote, $actHist, $actUser, $actDisc,
			$hist, $disc, $name, $note, $user ) = @{$_};
		if( !defined( $lastId ) || ( $lastId ne $locId ) ) {
			last if( $hiscnt > 80 );
			$lastId = $locId;
			$started = 1;
			my $addr = PciIds::Address::new( $locId );
			if( defined( $actHist ) ) {
				print "<tr class='item'>";
			} else {
				print "<tr class='unnamedItem'>";
			}
			print "<td><a href='/read/".$addr->get()."'>".encode( $addr->pretty() )."</a><td>".safeEncode( $actName )."<td>".safeEncode( $actNote )."<td>".safeEncode( $actDisc )."<td>".mailEncode( $actUser );

			$subcnt = 0;
			$cnt++;
			print "<input type='hidden' name='loc-$cnt' value='".$addr->get()."'>\n";
			print "<td class='empty'>";
			print "<td><input type='radio' name='loc-$cnt-sel' value='curr' checked='checked'>";
			if( hasRight( $auth->{'accrights'}, 'prune' ) || ( !defined $actHist && !$tables->hasChildren( $addr->get() ) ) ) {
				print "<td><input type='checkbox' name='loc-$cnt-del' value='del'>\n";
			} else {
				print "<td class='empty'>";
			}
			print "<tr class='new'><td>New:<td><input type='text' name='name-$cnt' class='text'><td><input type='text' name='note-$cnt' class='text'><td><textarea name='disc-$cnt'></textarea>\n";
			print "<td colspan='3'>";
			genPathBare( $req, $addr, 0, 0 );
			print "<td><input type='checkbox' name='loc-$cnt-softdel'>\n";
		}
		print "<tr class='unseen-history'><td class='empty'><td>".safeEncode( ( defined $name && $name eq '' ) ? 'Deletion request' : $name )."<td>".safeEncode( $note )."<td>".safeEncode( $disc )."<td>".mailEncode( $user );
		$hiscnt ++;
		$subcnt ++;
		print "<td><input type='checkbox' name='appr-$hiscnt' value='appr-$hist'>";
		if( defined $name ) {
			print "<td><input type='radio' name='loc-$cnt-sel' value='$hist'>";
		} else {
			print "<td class='empty'>";
		}
		print "<td><input type='checkbox' name='del-$hiscnt' value='del-$hist'>";
		print "<input type='hidden' name='owner-$hist' value='$lastId'>\n";
	}
	print "</table>\n";
	print "<input type='hidden' name='subcnt-$cnt' value='$subcnt'>\n" if( defined( $subcnt ) );
	if( $started ) {
		print "<p><input type='submit' name='submit' value='Submit'>\n";
		print "<input type='hidden' name='max-cnt' value='$cnt'><input type='hidden' name='max-hiscnt' value='$hiscnt'>\n";
	} else {
		print "<p>No pending items.\n";
	}
	print "</form>\n";
	genHtmlTail();
	return OK;
}

sub adminForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined( $auth->{'authid'} ) && hasRight( $auth->{'accrights'}, 'validate' ) ) {
		return genNewAdminForm( $req, $args, $tables, undef, $auth );
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
		tulog( $authid, "Discussion checked $id" );
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
				tulog( $authid, "Discussion deleted $del" );
			}
		}
		for( my $i = 1; $i <= $maxcnt; $i ++ ) {
			my $action = getFormValue( "action-$i", 'ignore' );
			my $loc = getFormValue( "loc-$i", undef );
			next unless( defined( $loc ) );
			my( $discussion, $name, $note ) = (
				getFormValue( "discussion-$i", undef ),
				getFormValue( "name-$i", undef ),
				getFormValue( "note-$i", undef ) );
			if( defined( $note ) && ( $note ne '' ) && ( !defined( $name ) || ( length $name < 3 ) ) ) {
				if( $errors eq '' ) {
					$errors = '<p>';
				} else {
					$errors .= '<br>';
				}
				$errors .= "$loc - You need to provide name if you provide note\n";
				next;
			}
			if( ( defined( $name ) && ( length $name >= 3 ) ) || ( defined( $discussion ) && ( $discussion ne '' ) ) ) { #Submited comment
				my $addr = PciIds::Address::new( $loc );
				my $histId = $tables->submitHistory( { 'name' => $name, 'note' => $note, 'text' => $discussion }, $auth, $addr );
				my $main = defined $name && ( $name ne '' );
				notify( $tables, $addr->get(), $histId, $main ? 2 : 0, $main ? 2 : 1 );
				$tables->markChecked( $histId );
				tulog( $authid, "Discussion submited (admin) $histId $loc ".logEscape( $name )." ".logEscape( $note )." ".logEscape( $discussion ) );
				if( defined( $name ) && ( length $name >= 3 ) ) {
					$tables->setMainHistory( $loc, $histId );
					tulog( $authid, "Item main history changed $loc $histId" );
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
				$tables->setMainHistory( $loc, $setId );
				notify( $tables, $loc, $setId, 2, 2 );
				tulog( $authid, "Item main history changed $loc $setId" );
				markAllChecked( $tables, $i, \%deleted, $authid );
			}
		}
		return genNewAdminForm( $req, $args, $tables, $errors, $auth );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

1;
