#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	unshift @INC, ".";
}
use PciIds::Db;
use DBI;

my $dbh = connectDb();
$dbh->prepare( 'DELETE FROM locations' )->execute();
$dbh->prepare( 'DELETE FROM history' )->execute();
$dbh->commit();
$dbh->disconnect();
