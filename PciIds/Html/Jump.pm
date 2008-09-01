package PciIds::Html::Jump;
use strict;
use warnings;
use base 'Exporter';
use PciIds::Html::Forms;
use PciIds::Html::Users;
use PciIds::Html::Util;
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

sub redirect( $$$ ) {
	my( $req, $args, $addr ) = @_;
	my $prefix = ( !defined $args->{'action'} || $args->{'action'} eq '' || $args->{'action'} eq 'list' ) ? 'read' : 'mods';
	my $url = "http://".$req->hostname()."/$prefix/$addr".buildArgs( $args );
	return HTTPRedirect( $req, $url );
}

sub itemExists( $$ ) {
	my( $tables, $addr ) = @_;
	return defined $tables->item( $addr );
}

sub tryDirect( $$$$ ) {
	my( $req, $args, $tables, $search ) = @_;
	my $address = PciIds::Address::new( $req->uri() );
	#Is it absolute address?
	$search =~ s/:/\//g;
	$search =~ s/ //g;
	my( $top ) = $address->get() =~ /^([^\/]+)/;
	$search =~ s/^\//$top\//;
	my $saddr = PciIds::Address::new( $search );
	return redirect( $req, $args, $saddr->get() ) if( defined $saddr && itemExists( $tables, $saddr->get() ) );
	while( defined $address ) {
		$saddr = PciIds::Address::new( $address->get()."/$search" );
		return redirect( $req, $args, $saddr->get() ) if( defined $saddr && itemExists( $tables, $saddr->get() ) );
		$address = $address->parent();
	}
	return undef;
}

sub jump( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	$args->{'action'} = delete $args->{'origin'};
	my $search = getFormValue( 'where', '' );
	my $idOnly = $search =~ s/^#//;
	my $direct = tryDirect( $req, $args, $tables, $search );
	return $direct if defined $direct;
	unless( $idOnly ) {#Try extended search

	}
	genHtmlHead( $req, 'No matches', undef );
	print "<div class='top'>\n";
	print '<h1>No matches</h1>';
	my $address = PciIds::Address::new( $req->uri() );
	genMenu( $req, $address, $args, $auth, [ [ 'Help', 'help', 'jump' ] ] );
	print "<div class='clear'></div>\n";
	print "</div\n>";
	genPath( $req, $address, 1 );
	print "<p>Your search request matches no item. Would you like to try again?\n<p>\n";
	jumpWindow( $req, $args );
	genHtmlTail();
	return OK;
}

1;
