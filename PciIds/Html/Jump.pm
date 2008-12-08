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

package PciIds::Html::Jump;
use strict;
use warnings;
use base 'Exporter';
use PciIds::Html::Forms;
use PciIds::Html::Users;
use PciIds::Html::Util;
use PciIds::Html::Format;
use PciIds::Address;
use Apache2::Const qw(:common :http);

our @EXPORT = qw(&jumpWindow);

sub jumpWindow( $$ ) {
	my( $req, $args ) = @_;
	print "<form id='jump' class='jump' name='jump' method='POST' action='".buildExcept( 'action', $args )."?action=jump".( defined $args->{'action'} ? "?origin=".$args->{'action'} : "" )."'>\n";
	print "<p>\n";
	print "<input type='text' class='jump' name='where'><input type='submit' value='Jump'>\n";
	print "</form>\n";
}

sub redirect( $$$$ ) {
	my( $req, $args, $addr, $hasSSL ) = @_;
	my $prefix = ( !defined $args->{'action'} || $args->{'action'} eq '' || $args->{'action'} eq 'list' ) ? 'read' : 'mods';
	my $url = protoName( $hasSSL )."://".$req->hostname()."/$prefix/$addr";
	return HTTPRedirect( $req, $url );
}

sub itemExists( $$ ) {
	my( $tables, $addr ) = @_;
	return defined $tables->item( $addr );
}

sub tryDirect( $$$$$ ) {
	my( $req, $args, $tables, $search, $hasSSL ) = @_;
	my $address = PciIds::Address::new( $req->uri() );
	$search =~ s/:/\//g;
	$search =~ s/ //g;
	if( defined $address ) {
		my( $top ) = $address->get() =~ /^([^\/]+)/;
		$search =~ s/^\//$top\//;
		#Is it absolute address?
		my $saddr = PciIds::Address::new( $search );
		return redirect( $req, $args, $saddr->get(), $hasSSL ) if( defined $saddr && itemExists( $tables, $saddr->get() ) );
	}
	while( defined $address ) {
		my $saddr = PciIds::Address::new( $address->get()."/$search" );
		return redirect( $req, $args, $saddr->get(), $hasSSL ) if( defined $saddr && itemExists( $tables, $saddr->get() ) );
		$address = $address->parent();
	}
	return undef;
}

sub jump( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	$args->{'action'} = delete $args->{'origin'};
	my $search = getFormValue( 'where', '' );
	my $idOnly = $search =~ s/^#//;
	my $direct = tryDirect( $req, $args, $tables, $search, $auth->{'ssl'} );
	return $direct if defined $direct;
	my $address = PciIds::Address::new( $req->uri() );
	$address = PciIds::Address::new( 'PC' ) unless defined $address;
	unless( $idOnly || length $search < 3 ) {#Try extended search
		my( $prefix ) = $address->get() =~ /^([^\/]+)/;
		$prefix = undef if $search =~ s/^\*//;
		my $result = $tables->searchName( $search, $prefix );
		if( @{$result} ) {
			genHtmlHead( $req, 'Search results', undef );
			print "<div class='top'>\n";
			print "<h1>Search results</h1>\n";
			genMenu( $req, $address, $args, $auth, [ [ 'Help', 'help', 'jump' ] ] );
			print "<div class='clear'></div>\n";
			print "</div>\n";
			genPath( $req, $address, 1 );
			print "<h2>Found items</h2>\n";
			genTableHead( 'found', [ 'ID', 'Name', 'Parent' ], [] );
			my $prefix = '/'.( ( !defined $args->{'action'} || $args->{'action'} eq '' || $args->{'action'} eq 'list' ) ? 'read/' : 'mods/' );
			htmlFormatTable( $result, 3, [], [ sub {
				my $addr = shift;
				my $address = PciIds::Address::new( $addr );
				return "<a href='$prefix".$address->get()."'>".encode( $address->fullPretty() )."</a>";
			} ], sub { 1; }, sub { ' class="item"'; } );
			genTableTail();
			genHtmlFooter( 1, $req, $args );
			return OK;
		}
	}
	genHtmlHead( $req, 'No matches', undef );
	print "<div class='top'>\n";
	genMenu( $req, $address, $args, $auth, [ [ 'Help', 'help', 'jump' ] ] );
	print '<h1>No matches</h1>';
	print "<div class='clear'></div>\n";
	print "</div\n>";
	genPath( $req, $address, 1 );
	print "<p>Your search request matches no item. Would you like to try again?\n<p>\n";
	jumpWindow( $req, $args );
	genHtmlTail();
	return OK;
}

1;
