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

package PciIds::Html::Debug;
use strict;
use warnings;
use Apache2::Const qw(:common :http);
use PciIds::Html::Util;

sub test( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	genHtmlHead( $req, 'Test', undef );
	print '<p>Logged in: '.$auth->{'authid'} if( defined $auth->{'authid'} );
	print $auth->{'logerror'} if( defined $auth->{'logerror'} );
	return OK unless defined $auth->{'authid'};
	print "<p>";
	foreach( keys %ENV ) {
		print encode( "$_: $ENV{$_}<br>" );
	}
	genHtmlTail();
	return OK;
}

1;
