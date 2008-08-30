package PciIds::Address::PciClass;
use strict;
use warnings;
use PciIds::Address::Toplevel;
use base 'PciIds::Address::Base';

sub new( $ ) {
	my( $address ) = @_;
	return PciIds::Address::Toplevel::new( $address ) if( $address =~ /^PD\/?$/ );
	return bless PciIds::Address::Base::new( $address );
}

sub pretty( $ ) {
	my $self = shift;
	$_ = $self->get();
	s/^PD\/?//;
	s/\//:/g;
	my $prefix;
	if( /:.*:/ ) {
		$prefix = 'Program interface';
	} elsif( /:/ ) {
		$prefix = 'Device subclass';
	} else {
		$prefix = 'Device class';
	}
	#TODO Other levels? Are the names OK?
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
	return 'pci_class';
}

1;
