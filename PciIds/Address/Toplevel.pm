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

package PciIds::Address::Toplevel;
use strict;
use warnings;
use base 'PciIds::Address::Base';

sub new( $ ) {
	my( $value ) = @_;
	if( $value =~ /^U[CD]\/?/ ) {
		return bless PciIds::Address::Base::new( $value );
	} else {
		return undef;
	}
}

sub pretty( $ ) {
	my $self = shift;
	if( $self->{'value'} =~ /^UD/ ) {
		return 'USB Devices';
	} else {
		return 'USB Device Classes';
	}
}

sub fullPretty( $ ) {
	return pretty( shift );
}

sub restrictRex( $$ ) {
	my( $self, $restrict ) = @_;
	return PciIds::Address::new( $self->get().'/0000' )->restrictRex( $restrict );#Nasty trick, get the right address of any subnode and try it there
}

sub leaf( $ ) {
	return 0;
}

sub append( $$ ) {
	my( $self, $suffix ) = @_;
	$suffix = lc $suffix;
	if( $self->{'value'} =~ /^UD/ ) {#PCI
		return ( undef, "Invalid ID syntax" ) unless ( $suffix =~ /^[0-9a-f]{4,4}$/ );
	} else {#PCI Device Class
		return ( undef, "Invalid ID syntax" ) unless ( $suffix =~ /^[0-9a-f]{2,2}$/ );
	}
	return ( PciIds::Address::new( $self->{'value'} . ( ( $self->{'value'} =~ /\/$/ ) ? '' : '/' ) . $suffix ), undef );
}

sub canDiscuss( $ ) { return 0; }

sub defaultRestrict( $ ) {
	my( $self ) = @_;
	if( $self->get() =~ /^UD/ ) {
		return "0";
	} else {
		return "";
	}
}

sub defaultRestrictList( $ ) {
	my( $self ) = @_;
	if( $self->get() =~ /^UD/ ) {
		my @result;
		for(my $i = '0'; $i < '10'; ++ $i ) {
			push @result, $i;
		}
		push @result, ( 'a', 'b', 'c', 'd', 'e', 'f' );
		my @final;
		push @final, [ $_, $_ ] foreach( @result );
		push @final, [ "", "all" ];
		return \@final;
	} else {
		return [];
	}
}

sub parent( $ ) {
	return undef;
}

sub helpName( $ ) {
	my( $self ) = @_;
	if( $self->{'value'} =~ /^UD/ ) {
		return 'usb';
	} else {
		return 'usb_class';
	}
}

sub subName( $ ) {
	my( $self ) = @_;
	if( $self->get() =~ /^UD/ ) {
		return 'Vendors';
	} else {
		return 'Device classes';
	}
}

sub subIdSize( $ ) {
	my( $self ) = @_;
	if( $self->get() =~ /^UD/ ) {
		return 4;
	} else {
		return 2;
	}
}

1;
