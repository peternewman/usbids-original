package PciIds::Config;
use strict;
use warnings;
use Startup;
use base 'Exporter';

our @EXPORT = qw(&checkConf &defConf %config &confList);

our %config;

sub loadConf() {
	open CONFIG, $directory."/config" or die "Config file not found. Make sure config is in the directory and the correct path is in Startup.pm\n";
	foreach( <CONFIG> ) {
		next if( /^\s*(|#.*)$/ );
		chomp;
		my( $name, $val );
		die "Invalid syntax on line $_\n" unless( ( $name, $val ) = /^\s*(.*\S)\s*=\s*(.*\S)\s*$/ );
		$val =~ s/^"(.*)"$/$1/;
		$config{$name} = $val;
	}
	close CONFIG;
}

sub checkConf( $ ) {
	my( $names ) = @_;
	foreach( @{$names} ) {
		die "Variable not set: $_\n" unless( defined $config{$_} );
	}
}

sub defConf( $ ) {
	my( $underlay ) = @_;
	foreach( keys %{$underlay} ) {
		$config{$_} = $underlay->{$_} unless( defined $config{$_} );
	}
}

sub confList( $ ) {
	my( $names ) = @_;
	my( @result );
	push @result, $config{$_} foreach( @{$names} );
	return( @result );
}

loadConf();

return 1;
