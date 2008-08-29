#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	unshift @INC, ".";
}
use PciIds::Db;
use PciIds::Config;
use DBI;

my( $orig ) = @ARGV;
my $newdb = connectDb();
my( $user, $passwd ) = confList( [ "dbuser", "dbpasswd" ] );
my $olddb = DBI->connect( "dbi:mysql:$orig", $user, $passwd, { 'RaiseError' => 1 } );

print "Submiting ordinary users\n";
my $uquery = $olddb->prepare( "SELECT DISTINCT author FROM ids WHERE author like '%@%'" );
my $upush = $newdb->prepare( "INSERT INTO users (email, passwd) VALUES (?, '')" );
$uquery->execute();
my %users = ( '' => undef );

while( my( $author ) = $uquery->fetchrow_array ) {
	$upush->execute( $author );
	$users{$author} = $newdb->last_insert_id( undef, undef, undef, undef );
}

my $clean = $newdb->prepare( "DELETE FROM locations WHERE id like 'PC/%'" );
print "Cleaning old PCI devices to make place for new ones\n";
$clean->execute();
print "Submiting items from database\n";

my $itemq = $olddb->prepare( "SELECT id, name, comment, author, status, type FROM ids ORDER BY LENGTH(id), id" );
my $itemp = $newdb->prepare( "INSERT INTO locations (id, parent) VALUES (?, ?)" );
my $comp = $newdb->prepare( "INSERT INTO history (owner, location, nodename, nodenote, seen, time) VALUES (?, ?, ?, ?, ?, '2000-01-01 00:00:00')" );
my $setMain = $newdb->prepare( 'UPDATE locations SET
				mainhistory = ?,
				name = ( SELECT nodename FROM history WHERE id = ? ),
				note = ( SELECT nodenote FROM history WHERE id = ? )
			WHERE
				id = ?' );

my %rex = (
	'v' => sub {
		my $i = shift;
		"PC/$i";
	},
	'd' => sub {
		my $i = shift;
		$i =~ s/(.{4,4})(.*)/PC\/$1\/$2/;
		return $i;
	},
	's' => sub {
		my $i = shift;
		$i =~ s/(.{4,4})(.{4,4})(.*)/PC\/$1\/$2\/$3/;
		return $i;
	}
);

$itemq->execute();
while( my( $id, $name, $description, $author, $status, $type ) = $itemq->fetchrow_array ) {
	$id = &{$rex{$type}}( $id );
	my $parent = $id;
	$parent =~ s/\/[^\/]+$//;
	eval {#Add it if not present yet
		$itemp->execute( $id, $parent );
	};
	$author = '' unless( defined $author );
	$comp->execute( $users{$author} ? $users{$author} : undef, $id, $name, $description, !$status );
	unless( $status ) {
		my $last = $newdb->last_insert_id( undef, undef, undef, undef );
		$setMain->execute( $last, $last, $last, $id );
	}
}

$newdb->commit();
$newdb->disconnect();
