#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	unshift @INC, ".";
}
use PciIds::DBQ;
use PciIds::Db;
use PciIds::Notifications;
use PciIds::Xmpp;

my $dbh = connectDb();
my $tables = PciIds::DBQ::new( $dbh );

sendNotifs( $tables );
flushXmpp();
$tables->commit();
