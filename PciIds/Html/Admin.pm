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

sub mailEncode( $$ ) {
	my( $email, $user ) = @_;
	return '' unless defined $email;
	( $user ) = $email =~ /^(.*)@/ unless( defined $user );
	return "<a href='mailto:$email'>".encode( $user )."</a>";
}

sub genHist( $$$$$$$$$$$ ) {
	my( $class, $email, $login, $time, $name, $note, $disc, $selname, $selvalue, $delname, $delvalue ) = @_;
	print "<tr class='$class'><td>";
	print "<span class='author'>".mailEncode( $email, $login )."<br></span>" if( defined $email );
	print "<span class='time'>".safeEncode( $time )."</span>";
	print "<td>";
	if( defined $name ) {
		if( $name eq '' ) {
			print "<span class='name'>Deletion request<br></span>";
		} else {
			print "<span class='name'>Name: ".encode( $name )."<br></span>";
		}
	}
	print "<span class='note'>Note: ".encode( $note )."<br></span>" if defined $note && $note ne '';
	print safeEncode( $disc );
	print "<td class='selects'><input type='radio' name='$selname' 'value='$selvalue'>\n";
	print "<td class='deletes'><input type='checkbox' name='$delname' value='$delvalue'>\n" if defined $delname
}

sub genNewForm( $ ) {
	my( $num ) = @_;
	print "<tr class='newhistory'><td>TODO combo";
	print "<td><span class='newname'>Name: <input type='text' name='name-$num'></span><span class='newnote'>Note: <input type='note-$num'></span><br>\n";
	print "<textarea name='disc-$num'></textarea>\n";
	print "<td><td class='deletes'><input type='checkbox' name='loc-$num-softdel' value='del'>\n";
}

sub genNewAdminForm( $$$$$ ) {
	my( $req, $args, $tables, $error, $auth ) = @_;
	my $address = PciIds::Address::new( $req->uri() );
	my $prefix = $address->get();
	my $limit = $args->{'limit'};
	$prefix = '' if( $args->{'global'} );
	my $caption = 'Administration '.( $args->{'global'} ? '(Global)' : '('.encode( $address->pretty() ).')' );
	genHtmlHead( $req, $caption, undef );
	my $glob = delete $args->{'global'};
	genCustomHead( $req, $args, $address, $caption, [ $address->canAddItem() ? [ 'Add item', 'newitem' ] : (), $address->canDiscuss() ? [ 'Discuss', 'newhistory' ] : (), $glob ? [ 'Local', 'admin' ] : [ 'Global', 'admin?global=1' ], [ 'Help', 'help', 'admin' ], [ '', 'jump' ] ], [ [ 'Log out', 'logout' ] ] );
	print "<div class='error'>$error</div>\n" if( defined $error );
	print "<form name='admin' id='admin' class='admin' method='POST' action=''>\n";
	my $lastId;
	my $started = 0;
	my $cnt = 0;
	my $hiscnt = 0;
	my $subcnt;
	foreach( @{$tables->adminDump( $prefix, $limit )} ) {
		my( $locId, $actName, $actNote, $actHist, $actEmail, $actLogin, $actDisc, $actTime,
			$hist, $disc, $name, $note, $email, $login, $time ) = @{$_};
		if( !defined( $lastId ) || ( $lastId ne $locId ) ) {
			last if( $hiscnt > ( defined $limit ? $limit : 80 ) );
			$lastId = $locId;
			if( $started ) {
				genNewForm( $cnt );
				print "</table>\n";
			} else {
				$started = 1;
			}
			my $addr = PciIds::Address::new( $locId );
			if( defined( $actHist ) ) {
				print "<table class='item'>\n";
			} else {
				print "<table class='unnamedItem'>\n";
			}
			print "<col class='author'><col class='main'><col class='controls' span='2'>\n";
			print "<tr class='label'><p>\n";
			print "<td class='path' colspan='2'>";
			genPathBare( $req, $addr, 0, 0, 0 );
			print "<input type='hidden' name='loc-$cnt-subcnt' value='$subcnt'>" if( $subcnt );
			$subcnt = 0;
			$cnt ++;
			print "<td class='selects'><input type='radio' name='loc-$cnt-sel' value='curr' checked='checked'>";
			print "<td class='deletes'><input type='checkbox' name='loc-$cnt-del' value='del'>" if hasRight( $auth->{'accrights'}, 'prune' ) || ( !defined $actHist && !$tables->hasChildren( $addr->get() ) );
			genHist( 'main-history', $actEmail, $actLogin, $actTime, $actName, $actNote, $actDisc, "loc-$cnt-sel", 'seen', undef, undef ) if( defined $actHist );
		}
		$hiscnt ++;
		$subcnt ++;
		genHist( 'unseen-history', $email, $login, $time, $name, $note, $disc, "loc-$cnt-sel", $hist, "del-$hiscnt", "del-$hist" );
	}
	print "<input type='hidden' name='subcnt-$cnt' value='$subcnt'>\n" if( defined( $subcnt ) );
	if( $started ) {
		genNewForm( $cnt );
		print "</table>\n";
		print "<p><input type='submit' name='submit' value='Submit'>\n";
		print "<input type='hidden' name='loc-$cnt-subcnt' value='$subcnt'>" if( $subcnt );
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
			tulog( $authid, "Discussion deleted $del" );
		}
		foreach my $appr ( keys %approved ) {
			$tables->markChecked( $appr );
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
				notify( $tables, $addr->get(), $histId, defined $name ? 1 : 0, 1 );
			}
			if( defined $select && select ne '' ) {
				$tables->setMainHistory( $addr->get(), $select );
				tulog( $authid, "Item main history changed ".$addr->get()." $select" );
				$action = 1;
				notify( $tables, $addr->get(), $select, 2, 2 );
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
