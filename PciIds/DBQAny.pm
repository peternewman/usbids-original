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

package PciIds::DBQAny;
use strict;
use warnings;
use DBI;

sub new( $$ ) {
	my( $dbh, $queries ) = @_;
	my %qs;
	foreach( keys %{$queries} ) {
		$qs{$_} = $dbh->prepare( $queries->{$_} );
	}
	return bless {
		"dbh" => $dbh,
		"queries" => \%qs
	};
}

sub queryAll( $$$$ ) {
	my( $self, $name, $params, $fetch ) = @_;
	my $q = $self->{'queries'}->{$name};
	$q->execute( @{$params} );#Will die automatically
	if( $fetch ) {
		my @result = @{$q->fetchall_arrayref()};#Copy the array, finish() deletes the content
		$q->finish();
		return \@result;
	}
}

sub query( $$$ ) {
	my( $self, $name, $params ) = @_;
	return queryAll( $self, $name, $params, 1 );
}

sub command( $$$ ) {
	my( $self, $name, $params ) = @_;
	queryAll( $self, $name, $params, 0 );
}

sub commit( $ ) {
	shift->{'dbh'}->commit();
}

sub rollback( $ ) {
	shift->{'dbh'}->rollback();
}

sub last( $ ) {
	return shift->{'dbh'}->last_insert_id( undef, undef, undef, undef );
}

sub dbh( $ ) { return shift->{'dbh'}; }

1;
