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
