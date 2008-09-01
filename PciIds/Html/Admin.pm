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
	print "<p><input type='checkbox' name='default-seen' value='default-seen' checked='checked'> Any action approves all discussion\n";
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

			print "<input type='hidden' name='loc-$cnt-subcnt' value='$subcnt'>" if( $subcnt );
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
			print "<td><input type='checkbox' name='loc-$cnt-softdel' value='del'>\n";
		}
		print "<tr class='unseen-history'><td class='empty'><td>".safeEncode( ( defined $name && $name eq '' ) ? 'Deletion request' : $name )."<td>".safeEncode( $note )."<td>".safeEncode( $disc )."<td>".mailEncode( $user );
		$hiscnt ++;
		$subcnt ++;
		print "<input type='hidden' name='his-$cnt-$subcnt' value='$hist'>";
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
		print "<input type='hidden' name='loc-$cnt-subcnt' value='$subcnt'>" if( $subcnt );
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

my $errors;

sub appendError( $ ) {
	if( $errors eq '' ) {
		$errors = "<p>".shift;
	} else {
		$errors .= "<br>".shift;
	}
}

sub submitAdminForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	my $authid = $auth->{'authid'};
	if( defined( $authid ) && hasRight( $auth->{'accrights'}, 'validate' ) ) {
		my( %deleted, %approved );
		my $maxcnt = getFormValue( 'max-cnt', 0 );
		my $maxhiscnt = getFormValue( 'max-hiscnt', 0 );
		$errors = '';
		# Scan for approved and deleted items
		for( my $i = 1; $i <= $maxhiscnt; $i ++ ) {
			my( $del ) = getFormValue( "del-$i", '' ) =~ /^del-(\d+)$/;
			$deleted{$del} = 1 if( defined $del && $del ne '' );
			my( $appr ) = getFormValue( "appr-$i", '' ) =~ /^appr-(\d+)$/;
			$approved{$appr} = 1 if( defined $appr && $appr ne '' );
		}
		for( my $i = 1; $i <= $maxcnt; $i ++ ) {
			my( $sel ) = getFormValue( "loc-$i-sel", '' ) =~ /^(\d+)$/;
			$approved{$sel} = 1 if( defined $sel && $sel ne '' );
		}
		# Check for collisions
		my %collision;
		foreach my $id ( keys %deleted ) {
			if( $approved{$id} ) {
				my $owner = getFormValue( "owner-$id", '' );
				appendError( "You can not approve and delete history at the same time, not modifying item ".PciIds::Address::new( $owner )->pretty() );
				$collision{$owner} = $_;
				delete $deleted{$id};
				delete $approved{$id};
			}
		}
		#Do the deletes and approves
		foreach my $del ( keys %deleted ) {
			$tables->deleteHistory( $del );
			#TODO notify
			tulog( $authid, "Discussion deleted $del" );
		}
		foreach my $appr ( keys %approved ) {
			$tables->markChecked( $appr );
			#TODO notify
			tulog( $authid, "Discussion checked $appr" );
		}
		#Handle the items
		my $defaultSeen = getFormValue( 'default-seen', '' ) =~ /^default-seen$/;
		for( my $i = 1; $i <= $maxcnt; $i ++ ) {
			my $addr = PciIds::Address::new( getFormValue( "loc-$i", '' ) );
			next if $collision{$addr->get()};
			next unless defined $addr;
			my $del = getFormValue( "loc-$i-del", '' );
			if( defined $del && $del eq 'del' && ( hasRight( $auth->{'accrights'}, 'prune' ) || ( !$tables->hasChildren( $addr->get() ) && !$tables->hasMain( $addr->get() ) ) ) ) {
				$tables->deleteItem( $addr->get() );
				#TODO notify
				tulog( $authid, "Item deleted (recursive) ".$addr->get() );
				next;
			}
			my $name = getFormValue( "name-$i", undef );
			$name = undef if defined $name && $name eq '';
			my $note = getFormValue( "note-$i", undef );
			$note = undef if defined $note && $note eq '';
			my $discussion = getFormValue( "disc-$i", '' );
			$discussion = undef if defined $discussion && $discussion eq '';
			my $delete = 0;
			if( getFormValue( "loc-$i-softdel", '' ) =~ /^del$/ ) {
				$delete = 1;
				$name = undef;
				$note = undef;
			}
			if( defined $note && !defined $name ) {
				appendError( "You must specify name if you set note at item ".$addr->pretty() );
				next;
			}
			my( $select ) = getFormValue( "loc-$i-sel", '' ) =~ /^(\d+)$/;
			my $action = 0;
			if( defined $name || defined $discussion || $delete ) {
				my $histId = $tables->submitHistory( { 'name' => $name, 'note' => $note, 'text' => $discussion, 'delete' => $delete }, $auth, $addr );
				$tables->markChecked( $histId );
				$select = $histId if defined $name || $delete;
				tulog( $authid, "Discussion submited (admin) $histId ".$addr->get()." ".logEscape( $name )." ".logEscape( $note )." ".logEscape( $discussion ) );
				$action = 1;
				#TODO notify
			}
			if( defined $select && select ne '' ) {
				$tables->setMainHistory( $addr->get(), $select );
				tulog( $authid, "Item main history changed ".$addr->get()." $select" );
				$action = 1;
				#TODO Notify
			}
			if( $action && $defaultSeen ) {#Approve anything in this item
				my $subcnt = getFormValue( "loc-$i-subcnt", 0 );
				for( my $j = 1;  $j <= $subcnt; $j ++ ) {
					my( $id ) = getFormValue( "his-$i-$j", '' ) =~ /^(\d+)$/;
					next unless defined $id;
					next if $approved{$id} || $deleted{$id};
					$tables->markChecked( $id );
					tulog( $authid, "Discussion checked $id" );
				}
			}
		}
		return genNewAdminForm( $req, $args, $tables, $errors, $auth );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

1;
