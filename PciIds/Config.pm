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

package PciIds::Config;
use strict;
use warnings;
use PciIds::Startup;
use base 'Exporter';

our @EXPORT = qw(&checkConf &defConf %config &confList);

our %config;

sub loadConf() {
	open CONFIG, $directory."cf/config" or die "Config file not found. Make sure config is in the cf directory and the correct path is in Startup.pm\n";
	foreach( <CONFIG> ) {
		next if( /^\s*(|#.*)$/ );
		chomp;
		my( $name, $val );
		die "Invalid syntax on line $_\n" unless( ( $name, $val ) = /^\s*(.*\S)\s*=\s*(.*\S)\s*$/ );
		$val =~ s/^"(.*)"$/$1/;
		( $val ) = ( $val =~ /(.*)/ ); #Untaint the value - config is considered part of the program
		$config{$name} = $val;
	}
	close CONFIG;
}

sub checkConf( $ ) {
	my( $names ) = @_;
	foreach( @{$names} ) {
		die "Variable not set: $_\n" unless( defined $config{$_} );
	}
}

sub defConf( $ ) {
	my( $underlay ) = @_;
	foreach( keys %{$underlay} ) {
		$config{$_} = $underlay->{$_} unless( defined $config{$_} );
	}
}

sub confList( $ ) {
	my( $names ) = @_;
	my( @result );
	push @result, $config{$_} foreach( @{$names} );
	return( @result );
}

loadConf();

return 1;
