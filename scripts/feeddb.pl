#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	unshift @INC, ".";
}
use PciIds::Db;
use DBI;

my $dbh = connectDb();
my $query = $dbh->prepare( "INSERT INTO locations (id, name, note, parent) VALUES(?, ?, ?, ?);" ) or die "Could not create the query (".DBI->errstr.")\n";
my $comment = $dbh->prepare( "INSERT INTO history (location, nodename, nodenote, seen) VALUES(?, ?, ?, '1')" ) or die "Could not create query (".DBI->errstr.")\n";
my $update = $dbh->prepare( "UPDATE locations SET mainhistory = ? WHERE id = ?" ) or die "Could not create query (".DBI->errstr.")\n";
my( $vendor, $type, $sub, $description, $name );

$query->execute( "PC", undef, undef, undef ) or die "Could not add toplevel node\n";
$query->execute( "PD", undef, undef, undef ) or die "Could not add toplevel node\n";

sub submit( $ ) {
	my( $id ) = @_;
	my $parent = $id;
	$parent =~ s/\/[^\/]+$//;
	$query->execute( $id, $name, $description, $parent );
	$comment->execute( $id, $name, $description );
	my $com = $dbh->last_insert_id( undef, undef, undef, undef );
	$update->execute( $com, $id );
	undef $description;
}

print "Filling database from id file\n";

foreach( <> ) {
	chomp;
	if( s/^\s*#\s*// ) {
		$description = $_;
	} elsif( /^\s*$/ ) {
		undef $description;
	} elsif( /^\t\t/ ) {
		if( $vendor =~ /^PC/ ) {
			( $sub, $name ) = /^\s*([0-9a-fA-F]+\s[0-9a-fA-F]+)\s+(.*)$/;
			$sub =~ s/\s+//g;
		} else {
			( $sub, $name ) = /^\s*([0-9a-fA-F]+)\s+(.*)$/;
		}
		submit( $vendor.'/'.$type.'/'.$sub );
	} elsif( /^\t/ ) {
		( $type, $name ) = /^\s*([0-9a-fA-F]+)\s+(.*)$/;
		submit( $vendor.'/'.$type );
	} elsif( /^C\s/ ) {
		( $vendor, $name ) = /^C\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'PD/'.$vendor;
		submit( $vendor );
	} elsif( /^[0-9a-fA-F]/ ) {
		( $vendor, $name ) = /([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'PC/'.$vendor;
		submit( $vendor );
	} else {
		die "Um what?? $_\n";
	}
}
$dbh->commit();
$dbh->disconnect;
