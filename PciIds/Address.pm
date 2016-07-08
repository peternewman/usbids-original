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

package PciIds::Address;
use strict;
use warnings;
use PciIds::Address::Usb;
use PciIds::Address::UsbClass;

sub new( $ ) {
	my( $address ) = @_;
	$address =~ s/\/(mods|read|static)//;#Eat the prefix
	$address =~ s/\/$//;
	$address =~ s/^\///;
	if( $address =~ /^UD/ ) {
		return PciIds::Address::Usb::new( $address );
	} elsif( $address =~ /^UC/ ) {
		return PciIds::Address::UsbClass::new( $address );
	} else {
		return undef;
	}
}

1;
