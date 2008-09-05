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

package PciIds::Address::Base;
use strict;
use warnings;
use PciIds::Address;

sub new( $ ) {
	return bless {
		'value' => shift
	}
}

sub get( $ ) {
	return shift->{'value'};
}

sub parent( $ ) {
	my( $new ) = ( shift->get() );
	$new =~ s/[^\/]+\/?$//;
	return PciIds::Address::new( $new );
}

sub tail( $ ) {
	my( $new ) = ( shift->get() );
	$new =~ s/.*\/(.)/$1/;
	return $new;
}

sub canDiscuss( $ ) {
	return 1; #By default, comments can be added anywhere
}

sub canAddItem( $ ) { return !shift->leaf(); }

sub defaultRestrict( $ ) { return "" };

sub defaultRestrictList( $ ) { return [] };

sub path( $ ) {
	my( $self ) = @_;
	my @result;
	my $address = $self;
	while( defined( $address = $address->parent() ) ) {
		push @result, [ $address, 0 ];
	}
	unshift @result, [ $self, 0, 1 ];
	return \@result;
}

sub helpName( $ ) {
	return undef;
}

sub addressDeps( $ ) {
	return [];
}

sub top( $ ) {
	my( $topAd ) = shift->get() =~ /^([^\/]+)/;
	return PciIds::Address::new( $topAd );
}

1;
