package PciIds::DBQAny;
use strict;
use warnings;
use DBI;

sub new( $$ ) {
	my( $dbh, $queries ) = @_;
	my %qs;
	foreach( keys %{$queries} ) {
		$qs{$_} = $dbh->prepare( $queries->{$_} );
	}
	return bless {
		"dbh" => $dbh,
		"queries" => \%qs
	};
}

sub queryAll( $$$$ ) {
	my( $self, $name, $params, $fetch ) = @_;
	my $q = $self->{'queries'}->{$name};
	$q->execute( @{$params} );#Will die automatically
	if( $fetch ) {
		my @result = @{$q->fetchall_arrayref()};#Copy the array, finish() deletes the content
		$q->finish();
		return \@result;
	}
}

sub query( $$$ ) {
	my( $self, $name, $params ) = @_;
	return queryAll( $self, $name, $params, 1 );
}

sub command( $$$ ) {
	my( $self, $name, $params ) = @_;
	queryAll( $self, $name, $params, 0 );
}

sub commit( $ ) {
	shift->{'dbh'}->commit();
}

sub rollback( $ ) {
	shift->{'dbh'}->rollback();
}

sub last( $ ) {
	return shift->{'dbh'}->last_insert_id( undef, undef, undef, undef );
}

sub dbh( $ ) { return shift->{'dbh'}; }

1;
