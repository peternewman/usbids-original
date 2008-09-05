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

package PciIds::Address::Pci;
use strict;
use warnings;
use PciIds::Address::Toplevel;
use base 'PciIds::Address::Base';

sub new( $ ) {
	my( $address ) = @_;
	return PciIds::Address::Toplevel::new( $address ) if( $address =~ /^PC\/?$/ );
	return bless PciIds::Address::Base::new( $address );
}

sub fullPretty( $ ) {
	$_ = shift->get();
	s/^PC\/?//;
	s/\//:/g;
	if( /:.*:/ ) {
		s/^/PCI subsystem /;
	} elsif( /:/ ) {
		s/^/PCI device /;
	} else {
		s/^/PCI vendor /;
	}
	return $_;
}

sub pretty( $ ) {
	my $self = shift;
	$_ = $self->get();
	s/^PC\/?//;
	s/\//:/g;
	s/([0-9a-f]{4})([0-9a-f]{4})/$1 $2/g;
	my $prefix = '';
	if( /:.*:/ ) {
		$prefix = 'Subsystem';
	} elsif( /:/ ) {
		$prefix = 'Device';
	} else {
		$prefix = 'Vendor';
	}
	return $prefix.' '. $_;
}

sub tail( $ ) {
	my( $new ) = ( shift->get() );
	$new =~ s/.*\/(.)/$1/;
	$new =~ s/([0-9a-f]{4})([0-9a-f]{4})/$1 $2/g;
	return $new;
}

sub restrictRex( $$ ) {
	my( $self, $restrict ) = @_;
	my( $result ) = ( $restrict =~ /^([a-f0-9]{1,4})/ );#TODO every time?
	return $result;
}

sub leaf( $ ) {
	return ( shift->get() =~ /\/.*\/.*\// );
}

sub append( $$ ) {
	my( $self, $suffix ) = @_;
	return ( undef, 'You can not add to leaf node' ) if( $self->leaf() );
	$suffix =~ s/ //g;
	return ( undef, "Invalid ID syntax" ) unless ( ( ( $self->get() !~ /^PC\/.*\// ) && ( $suffix =~ /^[0-9a-f]{4}$/ ) ) || ( ( $self->get() =~ /^PC\/.*\// ) && ( $suffix =~ /^[0-9a-f]{8}$/ ) ) );
	return ( PciIds::Address::new( $self->{'value'} . ( ( $self->{'value'} =~ /\/$/ ) ? '' : '/' ) . $suffix ), undef );
}

sub path( $ ) {
	my( $self ) = @_;
	my $result = PciIds::Address::Base::path( $self );
	my( $vid ) = ( $self->get() =~ /^PC\/[0-9a-f]{4}\/[0-9a-f]{4}\/([0-9a-f]{4})/ );
	unshift @{$result}, [ PciIds::Address::new( "PC/$vid" ), 1 ] if( defined $vid );# && ( $result->[1]->[0]->get() ne "PC/$vid" );
	return $result;
}

sub helpName( $ ) {
	return 'pci';
}

sub addressDeps( $ ) {
	my( $addr ) = ( shift->get() =~ /^PC\/....\/....\/(....)/ );
	return [] unless defined $addr;
	return [ [ PciIds::Address::new( "PC/$addr" ), "Subsystem vendor $addr does not exist" ] ];
}

sub subName( $ ) {
	my( $self ) = @_;
	return 'Subsystems' if $self->get() =~ /^PC\/....\/..../;
	return 'Devices' if $self->get() =~ /^PC\/..../;
	die "Can not happend\n";
}

sub subIdSize( $ ) {
	my( $self ) = @_;
	return 9 if $self->get() =~ /^PC\/....\/..../;
	return 4 if $self->get() =~ /^PC\/..../;
	die "Can not happen\n";
}

1;
