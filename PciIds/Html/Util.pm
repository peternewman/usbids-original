package PciIds::Html::Util;
use strict;
use warnings;
use HTML::Entities;
use base 'Exporter';
use PciIds::Users;
use Apache2::Const qw(:common :http);
use APR::Table;

our @EXPORT = qw(&genHtmlHead &htmlDiv &genHtmlTail &genTableHead &genTableTail &parseArgs &buildExcept &buildArgs &genMenu &genCustomMenu &encode &setAddrPrefix &HTTPRedirect &genPath &logItem &genLocMenu &genCustomHead &genPathBare);

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
	print "<ul>\n";
	foreach( @{$list} ) {
		my( $label, $action, $param ) = @{$_};
		if( $action eq 'jump' ) {
			print "<li>\n";
			require PciIds::Html::Jump;
			PciIds::Html::Jump::jumpWindow( $req, $args );
		} else {
			my $prefix = '/mods';
			$prefix = '/read' if( !defined( $action ) or ( $action eq 'list' ) or ( $action eq '' ) or ( $action eq 'help' ) );
			my $suffix = '';
			$suffix = '?help='.$param if( $action eq 'help' );
			item( 'http://'.$req->hostname().$prefix.$url.$action.$suffix, $label );
		}
	}
	print "</ul>\n";
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
	my @list;
	if( defined $address ) {
		push @list, [ 'Add item', 'newitem' ] if( $address->canAddItem() );
		push @list, [ 'Discuss', 'newhistory' ] if( $address->canDiscuss() );
	}
	push @list, [ 'Administrate', 'admin' ] if( hasRight( $auth->{'accrights'}, 'validate' ) );
	push @list, @{$append} if defined $append;
	if( @list ) {
		print "<div class='lmenu'>\n";
		genCustomMenu( $req, $address, $args, \@list );
		print "</div>\n";
	}
	@list = ( logItem( $auth ) );
	push @list, [ 'Profile', 'profile' ] if defined $auth->{'authid'};
	push @list, [ 'Notifications', 'notifications' ] if defined $auth->{'authid'};
	print "<div class='rmenu'>\n";
	genCustomMenu( $req, $address, $args, \@list );
	print "</div>\n";
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
	foreach( keys %{$args} ) {
		$result .= "?$_=".$args->{$_} if( defined $args->{$_} );
	}
	return $result;
}

sub buildExcept( $$ ) {
	my( $except, $args ) = @_;
	my %backup = %{$args};
	delete $backup{$except};
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

sub genPathBare( $$$$ ) {
	my( $req, $address, $printAddr, $started ) = @_;
	my $path;
	if( defined $address ) {
		$path = $address->path();
		unshift @{$path}, $address if( $printAddr );
	} else {
		$path = [];
	}
	foreach my $addr ( reverse @{$path} ) {
		if( $started ) {
			print "&nbsp;-&gt;&nbsp;";
		} else {
			$started = 1;
		}
		print "<a href='http://".$req->hostname()."/read/".$addr->get()."'>".encode( $addr->pretty() )."</a>";
	}
}

sub genPath( $$$ ) {
	my( $req, $address, $printAddr ) = @_;
	print "<div class='path'>\n";
	print "<p><a href='http://".$req->hostname()."/index.html'>Main page</a>";
	genPathBare( $req, $address, $printAddr, 1 );
	print "</div>\n";
}

sub genLocMenu( $$$$$ ) {
	my( $req, $args, $addr, $lactions, $ractions ) = @_;
	print "<div class='lmenu'>\n";
	genCustomMenu( $req, $addr, $args, $lactions );
	print "</div>\n<div class='rmenu'>\n";
	genCustomMenu( $req, $addr, $args, $ractions );
	print "</div>\n";
}

sub genCustomHead( $$$$$$ ) {
	my( $req, $args, $addr, $caption, $lactions, $ractions ) = @_;
	print "<div class='top'>\n";
	print "<h1>$caption</h1>\n";
	genLocMenu( $req, $args, $addr, $lactions, $ractions );
	print "<div class='clear'></div></div>\n";
	genPath( $req, $addr, 1 );
}

1;
