package PciIds::Html::Debug;
use strict;
use warnings;
use Apache2::Const qw(:common :http);
use PciIds::Html::Util;

sub test( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	genHtmlHead( $req, 'Test', undef );
	print '<p>Logged in: '.$auth->{'authid'} if( defined $auth->{'authid'} );
	print $auth->{'logerror'} if( defined $auth->{'logerror'} );
	return OK unless defined $auth->{'authid'};
	print "<p>";
	foreach( keys %ENV ) {
		print encode( "$_: $ENV{$_}<br>" );
	}
	genHtmlTail();
	return OK;
}

1;
