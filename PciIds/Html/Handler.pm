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

package PciIds::Html::Handler;
use strict;
use warnings;
use PciIds::Db;
use PciIds::Html::Tables;
use PciIds::Html::Util;
use PciIds::Html::List;
use PciIds::Html::Users;
use PciIds::Html::Debug;
use PciIds::Html::Changes;
use PciIds::Html::Admin;
use PciIds::Html::Notifications;
use PciIds::Html::Help;
use PciIds::Html::Jump;
use Apache2::Const qw(:common :http);

$ENV{'PATH'} = '';
my $dbh = connectDb();
my $tables = PciIds::Html::Tables::new( $dbh );

my %handlers = (
	'GET' => {
		'list' => \&PciIds::Html::List::list,#List items
		'' => \&PciIds::Html::List::list,
		#Database changes
		'newitem' => \&PciIds::Html::Changes::newItemForm,
		'newhistory' => \&PciIds::Html::Changes::newHistoryForm,
		#Registering users
		'register' => \&PciIds::Html::Users::registerForm,
		'register-confirm' => \&PciIds::Html::Users::confirmForm,
		#Logins
		'login' => \&PciIds::Html::Users::loginForm,
		'logout' => \&PciIds::Html::Users::logout,
		'respass' => \&PciIds::Html::Users::resetPasswdForm,
		'respass-confirm' => \&PciIds::Html::Users::resetPasswdConfirmForm,
		#User profile
		'profile' => \&PciIds::Html::Users::profileForm,
		#Admin
		'admin' => \&PciIds::Html::Admin::adminForm,
		#Some debug
		'test' => \&PciIds::Html::Debug::test,
		#Notifications
		'notifications' => \&PciIds::Html::Notifications::notifForm,
		'help' => \&PciIds::Html::Help::getHelp
	},
	'POST' => {
		'newitem' => \&PciIds::Html::Changes::newItemSubmit,
		'newhistory' => \&PciIds::Html::Changes::newHistorySubmit,
		'register' => \&PciIds::Html::Users::registerSubmit,
		'register-confirm' => \&PciIds::Html::Users::confirmSubmit,
		'login' => \&PciIds::Html::Users::loginSubmit,
		'respass' => \&PciIds::Html::Users::resetPasswdFormSubmit,
		'respass-confirm' => \&PciIds::Html::Users::resetPasswdConfirmFormSubmit,
		'profile' => \&PciIds::Html::Users::profileFormSubmit,
		'admin' => \&PciIds::Html::Admin::submitAdminForm,
		'notifications' => \&PciIds::Html::Notifications::notifFormSubmit,
		'jump' => \&PciIds::Html::Jump::jump,
		'help' => \&PciIds::Html::Help::getHelp
	}
);

sub handler( $$ ) {
	my( $req, $hasSSL ) = @_;
	my $args = parseArgs( $req->args() );
	return HTTPRedirect( $req, protoName( $hasSSL ).'://'.$req->hostname().'/index.html' ) if( $req->uri() eq '/' && ( !defined $args->{'action'} || $args->{'action'} ne 'help' ) );
	return DECLINED if( $req->uri() =~ /^\/((static)\/|robots.txt|index.html)/ );
	my $action = $args->{'action'};
	$action = '' unless( defined $action );
	return HTTPRedirect( $req, protoName( $hasSSL ).'://'.$req->hostname().'/' ) if $req->uri() =~ /^\/(read|mods)\/?$/  && ( $action eq '' || $action eq 'list' );
	my $method = $handlers{$req->method()};
	return HTTP_METHOD_NOT_ALLOWED unless( defined $method );#Can't handle this method
	my $sub = $method->{$action};
	return HTTP_BAD_REQUEST unless( defined $sub );#I do not know this action for given method
	my $auth = checkLogin( $req, $tables );#Check if logged in
	$auth->{'ssl'} = $hasSSL;
	my( $result );
	eval {
		$result = &{$sub}( $req, $args, $tables, $auth );#Just do the right thing
		$tables->commit();
	};
	if( $@ ) {
		$tables->rollback();
		die $@;
	}
	return $result;
}

1;
