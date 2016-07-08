#!/usr/bin/perl

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

my @nodes=( "UD", "UC", "AT", "HD", "UR", "BS", "PH", "HT", "UL", "HC", "VT" );
my $node;
foreach $node ( @nodes ) {
    $query->execute( $node, undef, undef, undef ) or die "Could not add toplevel node\n";
}

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
		if( $vendor =~ /^UD/ ) {
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
		$vendor = 'UC/'.$vendor;
		submit( $vendor );
	} elsif( /^AT\s/ ) {
		( $vendor, $name ) = /^AT\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'AT/'.$vendor;
		submit( $vendor );
	} elsif( /^HID\s/ ) {
		( $vendor, $name ) = /^HID\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'HD/'.$vendor;
		submit( $vendor );
	} elsif( /^R\s/ ) {
		( $vendor, $name ) = /^R\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'UR/'.$vendor;
		submit( $vendor );
	} elsif( /^BIAS\s/ ) {
		( $vendor, $name ) = /^BIAS\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'BS/'.$vendor;
		submit( $vendor );
	} elsif( /^PHY\s/ ) {
		( $vendor, $name ) = /^PHY\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'PH/'.$vendor;
		submit( $vendor );
	} elsif( /^HUT\s/ ) {
		( $vendor, $name ) = /^HUT\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'HT/'.$vendor;
		submit( $vendor );
	} elsif( /^L\s/ ) {
		( $vendor, $name ) = /^L\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'UL/'.$vendor;
		submit( $vendor );
	} elsif( /^HCC\s/ ) {
		( $vendor, $name ) = /^HCC\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'HC/'.$vendor;
		submit( $vendor );
	} elsif( /^VT\s/ ) {
		( $vendor, $name ) = /^VT\s+([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'VT/'.$vendor;
		submit( $vendor );
	} elsif( /^[0-9a-fA-F]/ ) {
		( $vendor, $name ) = /([0-9a-fA-F]+)\s+(.*)$/;
		$vendor = 'UD/'.$vendor;
		submit( $vendor );
	} else {
		die "Um what?? $_\n";
	}
}
$dbh->commit();
$dbh->disconnect;
