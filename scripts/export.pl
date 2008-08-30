#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	unshift @INC, ".";
}
use PciIds::Db;
use PciIds::DBQAny;

my $db = PciIds::DBQAny::new( connectDb(), {
	'list' => 'SELECT id, name, note FROM locations WHERE id like "PC/%" OR id like "PD/%" ORDER BY id'
} );

my $lastInvalid = undef;

foreach( @{$db->query( 'list', [] )} ) {
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
	print "$tabs$prefix$id  $name\n";
	if( defined( $description ) && ( $description ne '' ) ) {
		chomp $description;
		$description =~ s/\n/\n$tabs#/g;
		print "$tabs# $description\n";
	}
}

$db->commit();
