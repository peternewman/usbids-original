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
use PciIds::DBQAny;

my $tree = shift;

die "Specify tree to dump as a first parameter\n" unless defined $tree;

my $db = PciIds::DBQAny::new( connectDb(), {
	'list' => 'SELECT id, name, note FROM locations WHERE id like ? ORDER BY id'
} );

my $lastInvalid = undef;

foreach( @{$db->query( 'list', [ "$tree/%" ] )} ) {
	my( $id, $name, $description ) = @{$_};
	next if defined $lastInvalid and substr( $id, 0, length $lastInvalid ) eq $lastInvalid;
	if( !defined $name || $name eq '' ) {
		$lastInvalid = $id;
		next;
	}
	$_ = $id;
	my $prefix = ( /^PD\/..$/ ) ? 'C ' : '';
	s/^P.\///;
	s/[^\/]//g;
	s/\//\t/g;
	my $tabs = $_;
	$id =~ s/.*\///;
	$id =~ s/([0-9a-f]{4})([0-9a-f]{4})/$1 $2/;
	if( defined( $description ) && ( $description ne '' ) ) {
		chomp $description;
		$description =~ s/\n/\n# /g;
		print "# $description\n";
	}
	print "$tabs$prefix$id  $name\n";
}

$db->commit();
