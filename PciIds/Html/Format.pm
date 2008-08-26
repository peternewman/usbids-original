package PciIds::Html::Format;
use strict;
use warnings;
use PciIds::Html::Util;
use base 'Exporter';

our @EXPORT = qw(&htmlFormatTable);

sub htmlFormatTable( $$$$$$ ) {
	my( $data, $cols, $headers, $funcs, $filter, $trHead ) = @_;
	$trHead = sub { return ''; } unless( defined $trHead );
	foreach my $line ( @{$data} ) {
		next unless( &{$filter}( $line ) );
		my $i;
		print '<tr'.&{$trHead}( $line ).'>';
		for( $i = 0; $i < $cols; $i ++ ) {
			my( $header, $func );
			if( ( scalar( @{$headers} ) > $i ) && defined( $headers->[ $i ] ) ) {
				$header = $headers->[ $i ];
			} else {
				$header = '<td>';
			}
			if( ( scalar( @{$funcs} ) > $i ) && defined( $funcs->[ $i ] ) ) {
				$func = $funcs->[ $i ];
			} else {
				$func = \&encode;
			}
			my $data = &{$func}( $line->[ $i ] );
			$data = "" unless( defined( $data ) );
			print $header.$data;
		}
		print "\n";
	}
}

1;
