package PciIds::Html::Util;
use strict;
use warnings;
use HTML::Entities;
use base 'Exporter';
use PciIds::Users;
use Apache2::Const qw(:common :http);
use APR::Table;

our @EXPORT = qw(&genHtmlHead &htmlDiv &genHtmlTail &genTableHead &genTableTail &parseArgs &buildExcept &buildArgs &genMenu &genCustomMenu &encode &setAddrPrefix &HTTPRedirect &genPath &logItem &genLocMenu);

sub encode( $ ) {
	return encode_entities( shift, "\"'&<>" );
}

sub genHtmlHead( $$$ ) {
	my( $req, $caption, $metas ) = @_;
	$req->content_type( 'text/html; charset=utf-8' );
	$req->headers_out->add( 'Cache-control' => 'no-cache' );
	print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'."\n";
	print '<html lang="en"><head><title>'.encode( $caption )."</title>\n";
	print "<link rel='stylesheet' type='text/css' media='screen' href='/static/screen.css'>\n";
	print "<link rel='stylesheet' type='text/css' media='print' href='/static/print.css'>\n";
	print $metas if( defined( $metas ) );
	print "</head><body>\n";
}

sub genHtmlTail() {
	print '</body></html>';
}

sub htmlDiv( $$ ) {
	my( $class, $text ) = @_;
	return '<div class="'.$class.'">'.$text.'</div>';
}

sub item( $$ ) {
	my( $url, $label ) = @_;
	print "  <li><a href='".$url."'>$label</a>\n";
}

sub genCustomMenu( $$$$ ) {
	my( $req, $address, $args, $list ) = @_;
	my $url;
	if( defined $address ) {
		$url = '/'.$address->get().buildExcept( 'action', $args ).'?action=';
	} else {
		$url = '/read/?action=';
	}
	print "<div class='menu'>\n<ul>\n";
	foreach( @{$list} ) {
		my( $label, $action, $param ) = @{$_};
		my $prefix = '/mods';
		$prefix = '/read' if( !defined( $action ) or ( $action eq 'list' ) or ( $action eq '' ) or ( $action eq 'help' ) );
		my $suffix = '';
		$suffix = '?help='.$param if( $action eq 'help' );
		item( 'http://'.$req->hostname().$prefix.$url.$action.$suffix, $label );
	}
	print "</ul></div>\n";
}

sub logItem( $ ) {
	my( $auth ) = @_;
	if( defined( $auth->{'authid'} ) ) {
		return [ 'Log out ('.encode( $auth->{'name'} ).')', 'logout' ];
	} else {
		return [ 'Log in', 'login' ];
	}
}

sub genMenu( $$$$$ ) {
	my( $req, $address, $args, $auth, $append ) = @_;
	my @list = ( logItem( $auth ) );
	if( defined $address ) {
		push @list, [ 'Add item', 'newitem' ] if( $address->canAddItem() );
		push @list, [ 'Discuss', 'newhistory' ] if( $address->canDiscuss() );
	}
	push @list, [ 'Administrate', 'admin' ] if( hasRight( $auth->{'accrights'}, 'validate' ) );
	push @list, [ 'Profile', 'profile' ] if defined $auth->{'authid'};
	push @list, [ 'Notifications', 'notifications' ] if defined $auth->{'authid'};
	push @list, @{$append} if defined $append;
	genCustomMenu( $req, $address, $args, \@list );
}

sub genTableHead( $$$ ) {
	my( $class, $captions, $cols ) = @_;
	print '<table class="'.$class.'">';
	foreach( @{$cols} ) {
		print "<col class='$_'>\n";
	}
	print "<tr>\n";
	foreach( @{$captions} ) {
		print '<th>'.$_."\n";
	}
}

sub genTableTail() {
	print '</table>';
}

sub parseArgs( $ ) {
	my %result;
	foreach( split /\?/, shift ) {
		next unless( /=/ );
		my( $name, $value ) = /^([^=]+)=(.*)$/;
		$result{$name} = $value;
	}
	return \%result;
}

sub buildArgs( $ ) {
	my( $args ) = @_;
	my $result = '';
	$result .= "?$_=".$args->{$_} foreach( keys %{$args} );
	return $result;
}

sub buildExcept( $$ ) {
	my( $except, $args ) = @_;
	my %backup = %{$args};
	delete $backup{$except};
	delete $backup{'full_links'};#This one is internal
	return buildArgs( \%backup );
}

sub setAddrPrefix( $$ ) {
	my( $addr, $prefix ) = @_;
	$addr =~ s/\/(mods|read|static)//;
	return "/$prefix$addr";
}

sub HTTPRedirect( $$ ) {
	my( $req, $link ) = @_;
	$req->headers_out->add( 'Location' => $link );
	return HTTP_SEE_OTHER;
}

sub genPath( $$$ ) {
	my( $req, $address, $printAddr ) = @_;
	my $path;
	if( defined $address ) {
		$path = $address->path();
		unshift @{$path}, $address if( $printAddr );
	} else {
		$path = [];
	}
	print "<div class='navigation-menu'><ul>\n";
	foreach my $addr ( @{$path} ) {
		print "  <li><a href='http://".$req->hostname()."/read/".$addr->get()."/'>".encode( $addr->pretty() )."</a>\n";
	}
	print "<li><a href='http://".$req->hostname()."/index.html'>Main page</a>\n";
	print "</ul></div>\n";
}

sub genLocMenu( $$$ ) {
	my( $req, $args, $actions ) = @_;
	my $addr = PciIds::Address::new( $req->uri() );
	genCustomMenu( $req, $addr, $args, $actions );
	genPath( $req, $addr, 1 );
}

1;
