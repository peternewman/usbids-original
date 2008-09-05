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
BEGIN {
	unshift @INC, ".";
};
use PciIds::Db;

my %tracked;

sub translateLoc( $ ) {
	my $loc = shift;
	$loc =~ s/(.{8})(.+)/$1\/$2/;
	$loc =~ s/(.{4})(.+)/$1\/$2/;
	return "PC/$loc";
}

my $dbh = connectDb();
my $clearHist = $dbh->prepare( 'DELETE FROM history WHERE location = ?' );
my %coms;
my $com = $dbh->prepare( 'INSERT INTO history (owner, location, time, nodename, nodenote) VALUES (?, ?, FROM_UNIXTIME(?), ?, ?)' );
my $user = $dbh->prepare( 'SELECT id FROM users WHERE email = ?' );
my $delHis = $dbh->prepare( 'DELETE FROM history WHERE id = ?' );
my $markMain = $dbh->prepare( 'UPDATE locations SET
				mainhistory = ?,
				name = ( SELECT nodename FROM history WHERE id = ? ),
				note = ( SELECT nodenote FROM history WHERE id = ? )
			WHERE
				id = ?' );
my $markSeen = $dbh->prepare( "UPDATE history SET seen = '1' WHERE id = ?" );

sub getUser( $ ) {
	$user->execute( shift );
	if( my( $id ) = $user->fetchrow_array ) {
		return $id;
	} else {
		return undef;
	}
}

my $accept = 0;
my $reject = 0;
my $del = 0;
my $appr = 0;

print "Parsing and importing log\n";

foreach( <> ) {
	my( $time, $who, $ip, $command, $id, $location, $name, $description, $email );
	if( ( $time, $who, $ip, $command, $id, $location, $name, $description, $email ) = /^(\d+) (\S+) ([0-9.]+) (Create|Batch submit:) (\d+) ([0-9a-f]+) '(.*)(?<!\\)' '(.*)(?<!\\)' '(.*)(?<!\\)'/ ) {
		my $translated = translateLoc( $location );
		unless( $tracked{$location} ) {#From now on, it is restored from the log
			$tracked{$location} = 1;
			$clearHist->execute( $translated );
		}
		$name =~ s/\\(.)/$1/g;
		$description =~ s/\\(.)/$1/g;
		$name = undef if( $name eq '' );
		$description = undef if( $description eq '' );
		eval {#If the item is not here at all, it was deleted -> no need to add it here
			$com->execute( getUser( $email ), $translated, $time, $name, $description );
			$coms{$id} = $dbh->last_insert_id( undef, undef, undef, undef );
			$accept ++;
		};
		if( $@ ) {
			$reject ++;
		}
	} elsif( ( $time, $who, $ip, $command, $id, $location, $description, $email ) = /^(\d+) (\S+) ([0-9.]+) (Approve|Delete|Overriden) (\d+) ([0-9a-f]+) '(.*)(?<!\\)' '(.*)(?<!\\)'/ ) {
		next unless( defined( $coms{$id} ) );#This one not tracked yet
		if( $command eq 'Approve' ) {
			my $i = $coms{$id};
			$markMain->execute( $i, $i, $i, translateLoc( $location ) );
			$markSeen->execute( $i );
			$appr ++;
		} elsif( $command eq 'Delete' ) {
			$delHis->execute( $coms{$id} );
			$del ++;
		} else {
			$markSeen->execute( $coms{$id} );
		}
	} else {
		print "Unparsed line: $_";
	}
}

$dbh->commit();
$dbh->disconnect();
