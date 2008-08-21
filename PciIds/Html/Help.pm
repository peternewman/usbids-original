package PciIds::Html::Help;
use strict;
use warnings;
use PciIds::Startup;
use PciIds::Html::Util;
use Apache2::Const qw(:common :http);
use base 'Exporter';

our @EXPORT=qw(getHelp);

sub getHelp($) {
	my( $req ) = @_;
	my( $helpname ) = ( $req->uri() =~ /^\/help\/(.*)/ );
	return NOT_FOUND if( $helpname =~ /[\/.]/ || $helpname eq '' );
	open HELP, "$directory/help/$helpname" or return NOT_FOUND;
	my $head = <HELP>;
	chomp $head;
	genHtmlHead( $req, $head, undef );
	print "<h1>$head</h1>\n";
	while( defined( my $line = <HELP> ) ) {
		print $line;
	}
	close HELP;
	genHtmlTail();
	return OK;
}

1;
