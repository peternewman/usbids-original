#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	unshift @INC, ".";
}
use PciIds::Config;
use PciIds::Db;
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
open TABLES, "tables" or die "Could not open table definitions\n";
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
