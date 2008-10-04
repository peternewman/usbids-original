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

package PciIds::Html::Help;
use strict;
use warnings;
use PciIds::Startup;
use PciIds::Html::Util;
use PciIds::Address;
use Apache2::Const qw(:common :http);
use base 'Exporter';

our @EXPORT=qw(getHelp);

sub getHelp( $$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	my $helpname = $args->{'help'};
	return NOT_FOUND if( !defined $helpname || $helpname =~ /[\/.]/ || $helpname eq '' );
	open HELP, "$directory/help/$helpname" or return NOT_FOUND;
	my $head = <HELP>;
	chomp $head;
	genHtmlHead( $req, $head, undef );
	my $addr = PciIds::Address::new( $req->uri() );
	print "<div class='top'>\n";
	genMenu( $req, $addr, $args, $auth, [ ( $helpname eq 'index' ) ? () : [ 'Help index', 'help', 'index' ] ] );
	print "<div class='bluesquare'><h1>$head</h1><p class='home'>The PCI ID Repository</div>\n";
	print "<div class='clear'></div></div>\n";
	genPath( $req, $addr, 1 );
	my $url = setAddrPrefix( $req->uri(), 'read' ).buildExcept( 'help', $args ).'?help=';
	delete $args->{'help'};
	my %repls = ( 'HELP_URL' => $url, 'AC_URL' => setAddrPrefix( $req->uri(), 'mods' ).buildExcept( 'action', $args ).'?action=' );
	while( defined( my $line = <HELP> ) ) {
		$line =~ s/\$(\w+_URL)\$/$repls{$1}/g;
		print $line;
	}
	close HELP;
	genHtmlFooter( 1, $req, $args );
	return OK;
}

1;
