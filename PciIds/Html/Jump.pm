use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw(&jumpWindow);

sub jumpWindow( $$ ) {
	my( $req, $args ) = @_;
	print "<form id='jump' class='jump' name='jump' method='POST' action='".buildExcept( 'action', $args )."?action=jump".( defined $args->{'action'} ? "?origin=".$args->{'action'} : "" )."'>\n";
	print "<p>\n";
	print "<input type='text' class='jump' name='where'><input type='submit' value='Jump'>\n";
	print "</form>\n";
}
