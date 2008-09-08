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

package PciIds::Users;
use strict;
use warnings;
use base 'Exporter';
use PciIds::Db;
use DBI;
use PciIds::Config;
use Digest::MD5 qw(md5_base64 md5_hex);#TODO Some better algorithm?
use HTML::Entities;
use PciIds::Startup;
use PciIds::Log;
use Apache2::Connection;

my( %privnames, %privnums );

our @EXPORT = qw(&addUser &emailConfirm &checkConfirmHash &saltedPasswd &genAuthToken &checkAuthToken &hasRight &getRightDefs &genResetHash &changePasswd &pushProfile &emailCheck);

sub emailCheck( $$ ) {
	my( $email, $tables ) = @_;
	my $newmail;
	return 'Does not look like an email address' unless ( ( $newmail ) = ( $email =~ /^([^,? "'`;<>]+@[^@,?\/ "'`;<>]+\.[^@,?\/ "'`;<>]+)$/ ) );#make sure the mail is not only reasonable looking, but safe to work with too
	return 'Email too long' if length $newmail > 255;
	return 'An account for this email address already exists' if( ( defined $tables ) && $tables->hasEmail( $newmail ) );
	return ( undef, $newmail );
}

sub saltedPasswd( $$ ) {
	my( $email, $passwd ) = @_;
	my $salt = $config{'passwdsalt'};
	return md5_base64( "$email:$passwd:$salt" );
}

sub genResetHash( $$$$ ) {
	my( $id, $email, $login, $passwd ) = @_;
	my $salt = $config{'regmailsalt'};
	return md5_hex( "$id:$email:$login:$passwd:$salt" );
}

sub emailConfirm( $ ) {
	my( $email ) = @_;
	my $salt = $config{'regmailsalt'};
	return md5_hex( $email.$salt );
}

sub checkConfirmHash( $$ ) {
	my( $email, $hash ) = @_;
	return 0 unless( ( defined $email ) && ( defined $hash ) );
	my( $expected ) = emailConfirm( $email );
	return ( $expected eq $hash );
}

sub addUser( $$$$ ) {
	my( $tables, $name, $email, $passwd ) = @_;
	my $salted = saltedPasswd( $email, $passwd );
	tlog( "Creating user $email" . ( ( defined $name ) ? " - $name" : '' ) );
	my $id = $tables->addUser( $name, $email, $salted );
	tlog( "User ($email) id: $id" );
	return $id;
}

sub changePasswd( $$$$ ) {
	my( $tables, $id, $passwd, $email ) = @_;
	my $salted = saltedPasswd( $email, $passwd );
	$tables->changePasswd( $id, $salted );
}

sub genAuthToken( $$$$$ ) {
	my( $tables, $id, $req, $rights, $name ) = @_;
	unless( defined $rights ) {#Just logged in
		my $from = $req->connection()->remote_ip();
		$tables->setLastLog( $id, $from );
		$rights = $tables->rights( $id );
	}
	my $haveRights = scalar @{$rights};
	my $time = time;
	return "$id:$haveRights:$time:".md5_hex( "$id:$time:".$config{'authsalt'} ).":$name";
}

sub checkAuthToken( $$$ ) {
	my( $tables, $req, $token ) = @_;
	my( $id, $haveRights, $time, $hex, $name ) = defined( $token ) ? split( /:/, $token ) : ();
	return ( 0, 0, 0, [], "Not logged in", undef ) unless( defined $hex );
	my $expected = md5_hex( "$id:$time:".$config{'authsalt'} );
	my $actTime = time;
	my $tokOk = ( $expected eq $hex );
	my $authed = ( $tokOk && ( $time + $config{'authtime'} > $actTime ) );
	my $regen = $authed && ( $time + $config{'regenauthtime'} < $actTime );
	my $rights = [];
	if( $haveRights ) {
		foreach( @{$tables->rights( $id )} ) {
			my %r;
			( $r{'id'} ) = @{$_};
			$r{'name'} = $privnames{$r{'id'}};
			push @{$rights}, \%r;
		}
	}
	return ( $authed, $id, $regen, $rights, $authed ? undef : ( $tokOk ? "Login timed out" : "Not logged in" ), $name );
}

sub hasRight( $$ ) {
	my( $rights, $name ) = @_;
	foreach( @{$rights} ) {
		return 1 if( $_->{'name'} eq $name );
	}
	return 0;
}

sub getRightDefs() {
	return ( \%privnums, \%privnames );
}

sub pushProfile( $$$$ ) {
	my( $tables, $id, $oldData, $data ) = @_;
	my( $email, $passwd ) = ( $data->{'email'}, $data->{'current_password'} );
	if( ( defined $passwd ) && ( $passwd ne '' ) ) {
		my $salted = saltedPasswd( $email, $passwd );
		$tables->setEmail( $id, $email, $salted );
	}
	$data->{'login'} = undef if ( defined $data->{'login'} ) && ( $data->{'login'} eq '' );
	$data->{'xmpp'} = undef if ( defined $data->{'xmpp'} ) && ( $data->{'xmpp'} eq '' );
	$tables->pushProfile( $id, $data->{'login'}, $data->{'xmpp'}, $data->{'email_time'}, $data->{'xmpp_time'} );
	changePasswd( $tables, $id, $data->{'password'}, $email ) if ( defined $data->{'password'} ) && ( $data->{'password'} ne '' );
}

checkConf( [ 'passwdsalt', 'regmailsalt', 'authsalt' ] );
defConf( { 'authtime' => 2100, 'regenauthtime' => 300 } );

open PRIVS, $directory."cf/rights" or die "Could not open privilege definitions\n";
foreach( <PRIVS> ) {
	my( $num, $name ) = /^(\d+)\s+(.*)$/ or die "Invalid syntax in privileges\n";
	$privnames{$num} = $name;
	$privnums{$name} = $num;
}
close PRIVS;

1;
