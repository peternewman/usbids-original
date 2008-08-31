package PciIds::Address::Toplevel;
use strict;
use warnings;
use base 'PciIds::Address::Base';

sub new( $ ) {
	my( $value ) = @_;
	if( $value =~ /^P[CD]\/?/ ) {
		return bless PciIds::Address::Base::new( $value );
	} else {
		return undef;
	}
}

sub pretty( $ ) {
	my $self = shift;
	if( $self->{'value'} =~ /^PC/ ) {
		return 'PCI Devices';
	} else {
		return 'PCI Device Classes';
	}
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
	if( $self->{'value'} =~ /^PC/ ) {#PCI
		return ( undef, "Invalid ID syntax" ) unless ( $suffix =~ /^[0-9a-f]{4,4}$/ );
	} else {#PCI Device Class
		return ( undef, "Invalid ID syntax" ) unless ( $suffix =~ /^[0-9a-f]{2,2}$/ );
	}
	return ( PciIds::Address::new( $self->{'value'} . ( ( $self->{'value'} =~ /\/$/ ) ? '' : '/' ) . $suffix ), undef );
}

sub canDiscuss( $ ) { return 0; }

sub defaultRestrict( $ ) {
	my( $self ) = @_;
	if( $self->get() =~ /^PC/ ) {
		return "0";
	} else {
		return "";
	}
}

sub defaultRestrictList( $ ) {
	my( $self ) = @_;
	if( $self->get() =~ /^PC/ ) {
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
	if( $self->{'value'} =~ /^PC/ ) {
		return 'pci';
	} else {
		return 'pci_class';
	}
}

sub subName( $ ) {
	my( $self ) = @_;
	if( $self->get() =~ /^PC/ ) {
		return 'Vendors';
	} else {
		return 'Device classes';
	}
}

1;
