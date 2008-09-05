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

package PciIds::Html::Tables;
use strict;
use warnings;
use base 'PciIds::DBQ';
use PciIds::Html::Format;
use PciIds::Address;

sub new( $ ) {
	my( $dbh ) = @_;
	return bless PciIds::DBQ::new( $dbh );
}

sub formatLink( $ ) {
	my $address = PciIds::Address::new( shift );
	return '<a href="/read/'.$address->get().'">'.$address->tail().'</a>';
}

sub nodes( $$$ ) {
	my( $self, $parent, $args ) = @_;
	my $restrict = $args->{'restrict'};
	$restrict = '' unless( defined $restrict );
	$restrict = PciIds::Address::new( $parent )->restrictRex( $restrict );#How do I know if the restrict is OK?
	htmlFormatTable( PciIds::DBQ::nodes( $self, $parent, $args, $restrict ), 3, [], [ \&formatLink ], sub { 1; }, sub {
		my $name = shift->[ 1 ];
		return ' class="'.( defined $name && $name ne '' ? 'item' : 'unnamedItem' ).'"';
	} );
}

1;
