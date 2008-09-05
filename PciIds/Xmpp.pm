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
