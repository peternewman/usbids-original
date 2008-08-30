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
	print "<h1>$head (".$addr->pretty().")</h1>\n";
	genMenu( $req, $addr, $args, $auth, undef );
	genPath( $req, $addr, 1 );
	my $url = '/read'.$req->uri().buildExcept( 'help', $args ).'?help=';
	print "<div class='navigation'><ul><li><a href='$url=index'>Help index</a></ul></div>\n" if( $helpname ne 'index' );
	while( defined( my $line = <HELP> ) ) {
		$line =~ s/\$CUR_LINK\$/$url/g;
		print $line;
	}
	close HELP;
	genHtmlTail();
	return OK;
}

1;
