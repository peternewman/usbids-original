package PciIds::Address;
use strict;
use warnings;
use PciIds::Address::Pci;
use PciIds::Address::PciClass;

sub new( $ ) {
	my( $address ) = @_;
	$address =~ s/\/(mods|read|static)//;#Eat the prefix
	$address =~ s/\/$//;
	$address =~ s/^\///;
	if( $address =~ /^PC/ ) {
		return PciIds::Address::Pci::new( $address );
	} elsif( $address =~ /^PD/ ) {
		return PciIds::Address::PciClass::new( $address );
	} else {
		return undef;
	}
}

1;
