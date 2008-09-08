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
use PciIds::Config;
use PciIds::Db;
use PciIds::Startup;
use DBI;

my @lines;
my $tablename;

defConf( { "dbcharset" => "UTF8", "dbtype" => "InnoDB" } );

my %replaces = (
	"CHARSET" => "CHARSET ".$config{"dbcharset"}
);

sub createTable( $ ) {
	die "Invalid table definition\n" unless( defined( $tablename ) && @lines );
	my $nt = $_[ 0 ]->prepare( "CREATE TABLE ".$tablename." (".( join "\n", @lines ).") TYPE = $config{dbtype};" );
	$nt->execute();
	@lines = ();
	print "Created table $tablename\n";
	undef $tablename;
}

my $dbh = connectDb();
open TABLES, $directory."cf/tables" or die "Could not open table definitions\n";
foreach( <TABLES> ) {
	chomp;
	if( /^\s*$/ ) {
		createTable( $dbh );
	} elsif( s/^@// ) {
		$tablename = $_;
	} else {
		s/#.*//;
		s/<<([^<>]+)>>/$replaces{$1}/g;
		push @lines, $_;
	}
}
close TABLES;
createTable( $dbh );
$dbh->commit();
$dbh->disconnect;
