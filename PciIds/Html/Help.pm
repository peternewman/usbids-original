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
	genMenu( $req, $addr, $args, $auth, [ [ 'Help index', 'help', 'index' ] ] );
	print "<h1>$head</h1>\n";
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
	genHtmlTail();
	return OK;
}

1;
