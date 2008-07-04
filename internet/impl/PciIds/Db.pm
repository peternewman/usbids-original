package PciIds::Db;
use strict;
use warnings;
use base 'Exporter';
use PciIds::Config;
use DBI;

our @EXPORT = qw( &connectDb );

sub connectDb() {
	my ( $uri, $user, $passwd ) = confList( [ "dburi", "dbuser", "dbpasswd" ] );
	my $result = DBI->connect( $uri, $user, $passwd, { 'AutoCommit' => 0, 'RaiseError' => 1, 'PrintError' => 0 } ) or die "Could not connect to database $uri (".DBI->errstr.")\n";
}

checkConf( [ "dbuser", "dbpasswd" ] );
defConf( { "dbname" => "pciids" } );
defConf( { "dburi" => "dbi:mysql:".$config{"dbname"} } );

return 1;
