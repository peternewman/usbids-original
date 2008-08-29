#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	unshift @INC, ".";
}
use PciIds::Db;
use PciIds::DBQAny;

my $db = PciIds::DBQAny::new( connectDb(), {
	'list' => 'SELECT id, name, note FROM locations WHERE name IS NOT NULL ORDER BY id'
} );

foreach( @{$db->query( 'list', [] )} ) {
	my( $id, $name, $description ) = @{$_};
	$_ = $id;
	my $prefix = ( /^PD\/..$/ ) ? 'C ' : '';
	s/^P.\///;
	s/[^\/]//g;
	s/\//\t/g;
	my $tabs = $_;
	$id =~ s/.*\///;
	print "$tabs$prefix$id  $name\n";
	if( defined( $description ) && ( $description ne '' ) ) {
		chomp $description;
		$description =~ s/\n/\n$tabs#/g;
		print "$tabs#$description\n";
	}
}

$db->commit();
