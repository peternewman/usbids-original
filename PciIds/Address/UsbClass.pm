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

package PciIds::Address::UsbClass;
use strict;
use warnings;
use PciIds::Address::Toplevel;
use base 'PciIds::Address::Base';

sub new( $ ) {
	my( $address ) = @_;
	return PciIds::Address::Toplevel::new( $address ) if( $address =~ /^UC\/?$/ );
	return bless PciIds::Address::Base::new( $address );
}

sub fullPretty( $ ) {
	$_ = shift->get();
	s/^PC\/?//;
	s/\//:/g;
	if( /:.*:/ ) {
		s/^/Program interface /;
	} elsif( /:/ ) {
		s/^/USB device subclass /;
	} else {
		s/^/USB device class /;
	}
	return $_;
}
sub pretty( $ ) {
	my $self = shift;
	$_ = $self->get();
	s/^UC\/?//;
	s/\//:/g;
	my $prefix;
	if( /:.*:/ ) {
		$prefix = 'Program interface';
	} elsif( /:/ ) {
		$prefix = 'Device subclass';
	} else {
		$prefix = 'Device class';
	}
	return $prefix.' '.$_;
}

sub restrictRex( $$ ) {
	my( $self, $restrict ) = @_;
	my( $result ) = ( $restrict =~ /^([a-f0-9]{1,2})/ );#TODO every time?
	return $result;
}

sub leaf( $ ) {
	return shift->get() =~ /\/.*\/.*\//;
}

sub append( $$ ) {
	my( $self, $suffix ) = @_;
	return ( undef, 'You can not add to leaf node' ) if( $self->leaf() );
	return ( undef, "Invalid ID syntax" ) unless ( $suffix =~ /^[0-9a-f]{2,2}$/ );
	return ( PciIds::Address::new( $self->{'value'} . ( ( $self->{'value'} =~ /\/$/ ) ? '' : '/' ) . $suffix ), undef );
}

sub helpName( $ ) {
	return 'usb_class';
}

sub subName( $ ) {
	my( $self ) = @_;
	return 'Program interfaces' if $self->get() =~ /UC\/..\/../;
	return 'Device subclasses' if $self->get() =~ /UC\/../;
	die "Can not happen\n";
}

sub subIdSize( $ ) {
	my( $self ) = @_;
	return 2;
}

1;
