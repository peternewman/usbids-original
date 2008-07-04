#!/usr/bin/perl

use strict;
BEGIN {
	unshift @INC, ".";
}
use PciIds::Db;
use PciIds::DBQAny;
use PciIds::Users;

my( $privnums, $privnames ) = getRightDefs();

sub userRights( $$ ) {
	my( $tables, $user ) = @_;
	foreach( @{$tables->query( 'rightsName', [ $user, $user ] )} ) {
		my( $rid ) = @{$_};
		print "  $privnames->{$rid} ($rid)\n";
	}
}

my $dbh = connectDb();
my $tables = PciIds::DBQAny::new( $dbh, {
	'rightsName' => 'SELECT rightId FROM users INNER JOIN rights ON users.id = rights.userId WHERE users.email = ? OR users.login = ? ORDER BY rightId',
	'allrights' => 'SELECT users.id, users.login, users.email, rights.rightId FROM users INNER JOIN rights ON users.id = rights.userId ORDER BY users.login, users.email, users.id, rights.rightId',
	'getId' => 'SELECT id FROM users WHERE email = ? OR login = ?',
	'add' => 'INSERT INTO rights (userId, rightId) VALUES(?, ?)',
	'del' => 'DELETE FROM rights WHERE userId = ? AND rightId = ?'
});

while( scalar @ARGV ) {
	my $cmd = shift @ARGV;
	if( $cmd eq '-a' ) {
		my $lastid = undef;
		foreach( @{$tables->query( 'allrights', [] )} ) {
			my( $id, $name, $mail, $rid ) = @{$_};
			if( $id != $lastid ) {
				print "$mail ($id)\t$name\n";
				$lastid = $id;
			}
			print "  $privnames->{$rid} ($rid)\n";
		}
	} elsif( $cmd =~ /^[+-]l?$/ ) {
		my $user = shift @ARGV;
		my $id = $tables->query( 'getId', [ $user, $user ] )->[ 0 ]->[ 0 ];
		die "Invalid user $user\n" unless( defined $id );
		my $right = $privnums->{shift @ARGV};
		die "Invalid right $right\n" unless( defined $right );
		my @params = ( $id, $right );
		my $q = ( $cmd =~ /-/ ) ? 'del' : 'add';
		$tables->command( $q, \@params );
	} elsif( $cmd eq '-h' ) {
		print "rights.pl username\t\t\tPrint user's rights\n";
		print "rights.pl -a\t\t\t\tPrint all users and their rights\n";
		print "rights.pl +/- user right\t\tGrant/revoke user's right\n";
	} else {
		print "$cmd\n";
		userRights( $tables, $cmd );
	}
}
$dbh->commit();
$dbh->disconnect();
