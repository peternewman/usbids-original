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
		'jump' => \&PciIds::Html::Jump::jump
	}
);

sub handler( $$ ) {
	my( $req, $hasSSL ) = @_;
	my $args = parseArgs( $req->args() );
	return HTTPRedirect( $req, $req->uri()."index.html" ) if( $req->uri() eq '/' && ( !defined $args->{'action'} || $args->{'action'} ne 'help' ) );
	return DECLINED if( $req->uri() =~ /^\/((static)\/|robots.txt|index.html)/ );
	my $action = $args->{'action'};
	$action = '' unless( defined $action );
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
