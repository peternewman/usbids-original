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
