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

package PciIds::Email;
use strict;
use warnings;
use PciIds::Config;
use PciIds::Users;
use base 'Exporter';

our @EXPORT = qw(&sendMail);

checkConf( [ 'from_addr', 'sendmail' ] );
defConf( { 'sendmail' => '/usr/sbin/sendmail' } );

sub sendMail( $$$ ) {
	my( $to, $subject, $body ) = @_;
	my( $from, $sendmail ) = confList( [ 'from_addr', 'sendmail' ] );
	my $error;
	( $error, $to ) = emailCheck( $to, undef );
	die "Invalid email in database $to\n" if defined $error;
	$body =~ s/^\.$/../gm;
	$ENV{'PATH'} = '/usr/sbin';
	open SENDMAIL, "|$sendmail -f'$from' '$to'" or die 'Can not send mail';
	print SENDMAIL "From: $from\n".
		"To: $to\n".
		"Subject: $subject\n".
		"Content-Type: text/plain; charset=\"utf8\"\n".
		"\n".
		$body."\n.\n";
	close SENDMAIL or die "Sending mail failed: $!, $?";
}

1;
