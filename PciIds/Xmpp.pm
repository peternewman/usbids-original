package PciIds::Xmpp;
use strict;
use warnings;
use PciIds::Config;
use base 'Exporter';

our @EXPORT = qw(&sendXmpp &flushXmpp);

my @pending;

sub sendXmpp( $$$ ) {
	my( $to, $subject, $body ) = @_;
	push @pending, [ $to, $subject, $body ];
}

sub flushXmpp() {
	return unless @pending;
	open JELNET, "|$config{jelnet} --silent-passwd \"$config{xmpp_name}\" > /dev/null" or die "Could not start XMPP sender\n";
	print JELNET $config{"xmpp_passwd"}."\n";
	foreach( @pending ) {
		my( $to, $subject, $body ) = @{$_};
		$subject =~ s/&/&amp;/g;
		$subject =~ s/'/&apos;/g;
		$subject =~ s/"/&quot;/g;
		$body =~ s/&/&amp;/g;
		$body =~ s/</&lt;/g;
		$body =~ s/>/&gt;/g;
		print JELNET "<message to='$to'><subject>$subject</subject><body>$body</body></message>";
	}
	close JELNET;
}

checkConf( [ "xmpp_name", "xmpp_passwd", "jelnet" ] );

1;
