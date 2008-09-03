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
