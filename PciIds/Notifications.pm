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

package PciIds::Notifications;
use strict;
use warnings;
use PciIds::Address;
use PciIds::Config;
use PciIds::Email;
use PciIds::Xmpp;
use base 'Exporter';

our @EXPORT = qw(&notify &sendNotifs &flushNotifs);

sub notify( $$$$$ ) {
	my( $tables, $location, $comment, $priority, $reason ) = @_;
	$tables->pushNotifications( $location, $comment, $priority, $reason );
}

sub sendNotif( $$$ ) {
	my( $address, $message, $sendFun ) = @_;
	return unless defined $address;
	&{$sendFun}(
		$address,
		"Item change notifications for $config{hostname}",
		"$message\nThis is automatic notification message, do not respond to it.\nYou can change your notifications at http://$config{hostname}/mods/PC/?action=notifications\n" );
}

sub sendOut( $$ ) {
	my( $notifs, $sendFun ) = @_;
	my( $last_address, $last_user );
	my $message = '';
	foreach( @{$notifs} ) {
		my( $user, $address, $reason, $text, $newname, $newdesc, $time, $author, $location, $name, $desc ) = @{$_};
		if( ( !defined $last_user ) || ( $last_user != $user ) ) {
			sendNotif( $last_address, $message, $sendFun );
			$last_address = $address;
			$last_user = $user;
			$message = '';
		}
		my $note;
		my $addr = PciIds::Address::new( $location );
		if( $reason == 0 ) {
			$note = "New item was created.\n  Id: ".$addr->pretty()."\n  Name: $newname\n";
			$note .= "  Description: $newdesc\n" if( defined $newdesc && ( $newdesc ne '' ) );
			$note .= "  Comment text: $text\n" if( defined $text && ( $text ne '' ) );
			$note .= "  Author: $author\n" if( defined $author && ( $author ne '' ) );
			$note .= "  Time: $time\n";
			$note .= "  Address: http://".$config{'hostname'}."/read/".$addr->get()."\n";
		} elsif( $reason == 1 ) {
			$note = "New comment created.\n  Item:\n";
			$note .= "    Id: ".$addr->pretty()."\n";
			$note .= "    Name: $name\n" if( defined $name && ( $name ne '' ) && ( ( !defined $newname ) || ( $name ne $newname ) ) );
			$note .= "    Description: $desc\n" if( defined $desc && ( $desc ne '' ) && ( ( !defined $newdesc ) || ( $desc ne $newdesc ) ) );
			$note .= "    Address: http://".$config{'hostname'}."/read/".$addr->get()."\n";
			$note .= "  Comment:\n";
			$note .= "    Proposed name: $newname\n" if( defined $newname && ( $newname ne '' ) );
			$note .= "    Deletion request\n" if defined $newname && $newname eq '';
			$note .= "    Proposed description: $newdesc\n" if( defined $newdesc && ( $newdesc ne '' ) );
			$note .= "    Text: $text\n" if( defined $text && ( $text ne '' ) );
			$note .= "    Author: $author\n" if( defined $author && ( $author ne '' ) );
			$note .= "    Time: $time\n";
		} elsif( $reason == 2 ) {
			if( $name ne '' ) {
				$note = "Item name approved.\n  Id:".$addr->pretty()."\n";
				$note .= "  Name: $newname\n";
				$note .= "  Description: $newdesc\n" if( defined $newdesc && ( $newdesc ne '' ) );
				$note .= "  Comment text: $text\n" if( defined $text && ( $text ne '' ) );
				$note .= "  Address: http://".$config{'hostname'}."/read/".$addr->get()."\n";
			} else {
				$note = "Item deletion approved.\n  Id:".$addr->pretty()."\n";
				$note .= "  Address: http://".$config{'hostname'}."/read/".$addr->get()."\n";
			}
		}
		$message .= "\n" unless $message eq '';
		$message .= $note;
	}
	sendNotif( $last_address, $message, $sendFun );
}

sub sendNotifs( $ ) {
	my( $tables ) = @_;
	my $time = $tables->time();
	sendOut( $tables->mailNotifs( $time ), \&PciIds::Email::sendMail );
	sendOut( $tables->xmppNotifs( $time ), \&PciIds::Xmpp::sendXmpp );
	$tables->dropNotifs( $time );
}

checkConf( [ 'hostname' ] );

1;
