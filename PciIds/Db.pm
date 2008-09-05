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
