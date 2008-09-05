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

package PciIds::Log;
use strict;
use warnings;
use base 'Exporter';
use PciIds::Config;

our @EXPORT = qw(&flog &tlog &logEscape &tulog);

checkConf( [ 'logfile' ] );

sub flog( $ ) {
	my( $text ) = @_;
	open LOG, '>>'.$config{'logfile'} or die "Could not open log file\n";
	print LOG "$text\n";
	close LOG;
}

sub tlog( $ ) {
	my( $text ) = @_;
	my $time = time;
	flog( "$time: $text" );
}

sub tulog( $$ ) {
	my( $user, $text ) = @_;
	tlog( "User $user: $text" );
}

sub logEscape( $ ) {
	my( $text ) = @_;
	return "''" unless defined $text;
	$text =~ s/(['"\\])/\\$1/g;
	return "'$text'";
}

1;
