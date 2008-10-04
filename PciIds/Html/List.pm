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
	my $id = $address->top()->pretty();
	genHtmlHead( $req, $id, "<style type='text/css' media='screen,print'>col.id-col { width: ".$address->subIdSize()*1.25."ex; }</style>\n" );
	print "<div class='top'>\n";
	genMenu( $req, $address, $args, $auth, [ [ 'Help', 'help', 'list' ], $address->helpName() ? [ 'ID syntax', 'help', $address->helpName() ] : () ] );
	print '<div class="bluesquare"><h1>The PCI ID Repository</h1><p class="home">The home of the <code>pci.ids</code> file</div>';
	print "<div class='clear'></div></div>\n";
	genPath( $req, $address, 0 );
	print htmlDiv( 'name', '<p>Name: '.encode( $name ) ) if defined $name && $name ne '';
	print htmlDiv( 'note', '<p>Note: '.encode( $note ) ) if defined $note && $note ne '';
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
	if( $diss ) {
		print "<p><a href='".buildExcept( 'action', $args )."?action=newhistory'>Discuss</a>\n";
		print "</div>\n" if( $diss );
	}
	unless( $address->leaf() ) {
		print "<h2>".encode( $address->subName() )."</h2>\n";
		my $restricts = $address->defaultRestrictList();
		if( scalar @{$restricts} ) {
			print "<p>";
			my $url = '/read/'.$address->get().buildExcept( 'restrict', $args ).'?restrict=';
			foreach( @{$restricts} ) {
				print "<a href='".$url.$_->[0]."'>".$_->[1]."</a> ";
			}
		}
		my $url = '/read/'.$address->get().buildExcept( 'sort', $args );
		my $sort = ( $args->{'sort'} or 'id' );
		my( $sort_id, $sort_name ) = ( ( $sort eq 'id' ? 'rid' : 'id' ), ( $sort eq 'name' ? 'rname' : 'name' ) );
		genTableHead( 'subnodes', [ '<a href="'.$url.'?sort='.$sort_id.'">Id</a>', '<a href="'.$url.'?sort='.$sort_name.'">Name</a>', 'Note' ], [ 'id-col', 'name-col', 'note-col' ] );
		$args->{'restrict'} = $address->defaultRestrict() unless( defined( $args->{'restrict'} ) );
		$tables->nodes( $address->get(), $args );
		genTableTail();
		print "<p><a href='".buildExcept( 'action', $args )."?action=newitem'>Add item</a>\n";
	}
	genHtmlFooter( 1, $req, $args );
	return OK;
}

1;
