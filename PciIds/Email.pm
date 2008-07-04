package PciIds::Email;
use strict;
use warnings;
use PciIds::Config;
use base 'Exporter';

our @EXPORT = qw(&sendMail);

checkConf( [ 'from_addr', 'sendmail' ] );
defConf( { 'sendmail' => '/usr/sbin/sendmail' } );

sub sendMail( $$$ ) {
	my( $to, $subject, $body ) = @_;
	my( $from, $sendmail ) = confList( [ 'from_addr', 'sendmail' ] );
	$body =~ s/^\.$/../gm;
	open SENDMAIL, "|$sendmail -f$from $to" or die 'Can not send mail';
	print SENDMAIL "From: $from\n".
		"To: $to\n".
		"Subject: $subject\n".
		"Content-Type: text/plain; charset=\"utf8\"\n".
		"\n".
		$body."\n.\n";
	close SENDMAIL or die "Sending mail failed: $!, $?";
}

1;
