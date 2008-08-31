package PciIds::Html::List;
use strict;
use warnings;
use PciIds::Address;
use PciIds::Html::Util;
use Apache2::Const qw(:common :http);
use base 'Exporter';

our @EXPORT = qw(&loadItem);

sub loadItem( $$ ) {
	my( $tables, $uri ) = @_;
	my $address = PciIds::Address::new( $uri );
	return ( 0 ) unless( defined $address );
	my $item = $tables->item( $address->get() );
	return ( 0 ) unless( defined $item );
	my( $parent, $name, $note, $mainhistory ) = @{$item};
	return ( 1, $parent, $name, $note, $address, $mainhistory );
}

sub list( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	my( $ok, $parent, $name, $note, $address, $mid ) = loadItem( $tables, $req->uri() );
	return NOT_FOUND unless( $ok );
	my $id = $address->pretty();
	genHtmlHead( $req, $id, undef );
	print "<div class='top'>\n";
	print '<h1>'.encode( $id ).'</h1>';
	genMenu( $req, $address, $args, $auth, [ [ 'Help', 'help', 'list' ], $address->helpName() ? [ 'ID syntax', 'help', $address->helpName() ] : () ] );
	print "<div class='clear'></div>\n";
	print "</div\n>";
	genPath( $req, $address, 0 );
	print htmlDiv( 'name', '<p>'.encode( $name ) ) if defined( $name );
	print htmlDiv( 'note', '<p>'.encode( $note ) ) if( defined( $note ) );
	my $diss = 0;
	my $history;
	foreach $history ( @{$tables->history( $address->get() )} ) {
		unless( $diss ) {
			print "<div class='discussion'>\n<h2>Discussion</h2>";
			$diss = 1;
		}
		my( $id, $text, $time, $name, $note, $seen, $user, $email ) = @{$history};
		my $type = $seen ? 'history' : 'unseen-history';
		$type = 'main-history' if( defined( $mid ) && ( $id == $mid ) );
		print "<div class='$type'>\n";
		print "<p class='itemname'>Name: ".encode( $name )."\n" if( defined( $name ) && ( $name ne '' ) );
		print "<p class='itemname'>Deletion request\n" if( defined $name && $name eq '' );
		print "<p class='itemnote'>Note: ".encode( $note )."\n" if( defined( $note ) && ( $note ne '' ) );
		if( defined( $text ) && ( $text ne '' ) ) {
			$text = encode( $text );
			$text =~ s/\n/<br>/g;
			print "<p class='discussion-text'>$text\n";
		}
		( $user ) = ( $email =~ /^(.*)@/ ) if defined $email && !defined $user;
		print "<p class='author'>".encode( $user )."\n" if( defined( $user ) );
		print "<p class='time'>".encode( $time )."\n";
		print "</div>\n";
	}
	print "</div>\n" if( $diss );
	my $url_prefix = $args->{'full_links'} ? 'http://'.$req->hostname() : '';
	unless( $address->leaf() ) {
		print "<h2>Sub-items</h2>\n";
		my $restricts = $address->defaultRestrictList();
		if( scalar @{$restricts} ) {
			print "<p>";
			my $url = '/read/'.$address->get().buildExcept( 'restrict', $args ).'?restrict=';
			foreach( @{$restricts} ) {
				print "<a href='".$url_prefix.$url.$_->[0]."'>".$_->[1]."</a> ";
			}
		}
		my $url = '/read/'.$address->get().buildExcept( 'sort', $args );
		my $sort = ( $args->{'sort'} or 'id' );
		my( $sort_id, $sort_name ) = ( ( $sort eq 'id' ? 'rid' : 'id' ), ( $sort eq 'name' ? 'rname' : 'name' ) );
		genTableHead( 'subnodes', [ '<a href="'.$url_prefix.$url.'?sort='.$sort_id.'">Id</a>', '<a href="'.$url_prefix.$url.'?sort='.$sort_name.'">Name</a>', 'Note' ], [ 'id-col', 'name-col', 'note-col' ] );
		$args->{'restrict'} = $address->defaultRestrict() unless( defined( $args->{'restrict'} ) );
		$tables->nodes( $address->get(), $args, $url_prefix );
		genTableTail();
	}
	genHtmlTail();
	return OK;
}

1;
