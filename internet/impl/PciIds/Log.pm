package PciIds::Log;
use strict;
use warnings;
use base 'Exporter';
use PciIds::Config;

our @EXPORT = qw(&flog &tlog &logEscape &tulog);

checkConf( [ 'logfile' ] );

sub flog( $ ) {
	my( $text ) = @_;
	open LOG, '>>'.$config{'logfile'} or die "Could not open log file\n";
	print LOG "$text\n";
	close LOG;
}

sub tlog( $ ) {
	my( $text ) = @_;
	my $time = time;
	flog( "$time: $text" );
}

sub tulog( $$ ) {
	my( $user, $text ) = @_;
	tlog( "User $user: $text" );
}

sub logEscape( $ ) {
	my( $text ) = @_;
	return "''" unless defined $text;
	$text =~ s/(['"\\])/\\$1/g;
	return "'$text'";
}

1;
