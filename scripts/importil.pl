#!/usr/bin/perl
use strict;
use warnings;
BEGIN {
	unshift @INC, ".";
};
use PciIds::Db;
use PciIds::DBQ;
use PciIds::Address;
use PciIds::Users;

my $dbh = connectDb();
print "Deleting all PCI devices\n";
$dbh->prepare( "DELETE FROM locations WHERE id like 'PC/%'" )->execute();
my $newcomment = $dbh->prepare( 'INSERT INTO history (owner, location, time, nodename, nodenote, discussion) VALUES (?, ?, FROM_UNIXTIME(?), ?, ?, ?)' );
my $mismatch = $dbh->prepare( "INSERT INTO history (location, nodename, nodenote, seen) VALUES(?, ?, ?, '1')" );
my $db = PciIds::DBQ::new( $dbh );
my @toMark;
my %ids;
my $id;
my $addr;
my $submitted = 0;

sub translateLoc( $ ) {
	my $loc = shift;
	$loc =~ s/(.{8})(.+)/$1\/$2/;
	$loc =~ s/(.{4})(.+)/$1\/$2/;
	return "PC/$loc";
}

my $cnt = 0;

sub checkSub() {
	if( !$submitted ) {
		$db->command( 'newitem', [ $addr->get(), $addr->parent()->get() ] );
		$submitted = 1;
	}
}

sub insertId( $ ) {
	my( $id ) = @_;
	print "$cnt\n" if( ++ $cnt % 1000 == 0 );
	$addr = PciIds::Address::new( $id );
	$submitted = 0;
}

sub getUser( $ ) {
	my( $email ) = @_;
	$email = "" unless defined $email;
	$email =~ s/.*<([^<>]*)>.*/$1/;
	my( $mailCheck ) = emailCheck( $email, undef );
	if( defined $mailCheck ) {
		print "Invalid email $email\n";
		return undef;
	}
	my $result = $db->query( 'email', [ $email ] );
	if( scalar @{$result} ) {
		return $result->[0]->[0];
	} else {
		$db->command( 'adduser-null', [ $email, '' ] );
		return $db->last();
	}
}

sub addComment( $$$$$ ) {
	my( $email, $time, $name, $comment, $discussion ) = @_;
	my $user = getUser( $email );
	$name = undef if( ( defined $name ) && $name !~ /\S/ && $name ne '' );
	$comment = undef if( ( defined $comment ) && $comment !~ /\S/ );
	$discussion = undef if( ( defined $discussion ) && $discussion !~ /\S/ );
	$newcomment->execute( $user, $addr->get(), $time, $name, $comment, $discussion );
	my $id = $db->last();
	$comment = "" unless defined $comment;
	$name = "" unless defined $name;
	$ids{"$name\t$comment"} = $id;
	push @toMark, $id;
	return $id;
}

sub markAllSeen() {
	$db->markChecked( $_ ) foreach( @toMark );
	@toMark = ();
}

sub setMain( $ ) {
	$db->setMainHistory( $addr->get(), shift );
}

print "Importing\n";

while( defined( $_ = <> ) ) {
	chomp;
	if( my( $lid ) = /^### ([0-9a-f]+) ###$/ ) {
		%ids = ();
		@toMark = ();
		$id = translateLoc( $lid );
		insertId( $id );
	} elsif( /^(|#.*)$/ ) {
		next;
	} else {
		my( $command, @params ) = split( /\t/ );
		checkSub();
		if( $command eq "CREATE" ) {
			my( $time, $email, $name, $comment, $discussion ) = @params;
			my $hid = addComment( $email, $time, $name, $comment, $discussion );
		} elsif ( $command eq "APPROVE" ) {
			my( $time, $email, $name, $comment ) = @params;
			$comment = "" if( !defined $comment || $comment !~ /\S/ );
			$name = "" if( !defined $name || $name !~ /\S/ );
			my $hid = $ids{"$name\t$comment"};
			$hid = addComment( $email, $time, $name, $comment, undef ) unless defined $hid;
			markAllSeen();
			setMain( $hid );
		} elsif ( $command eq "COMMENT" ) {# Comments are from admins -> they mark as seen too
			my( $time, $email, $discussion ) = @params;
			addComment( $email, $time, undef, undef, $discussion );
			markAllSeen();
		} elsif ( $command eq "MISMATCH" ) {
			my( $name, $comment ) = @params;
			$mismatch->execute( $addr->get(), $name, $comment );
			setMain( $db->last() );
		} else {
			die "Unknow command $command\n";
		}
	}
}
$dbh->commit();
