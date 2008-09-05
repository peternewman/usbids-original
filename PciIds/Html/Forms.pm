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

package PciIds::Html::Forms;
use strict;
use warnings;
use base 'Exporter';
use CGI;
use HTML::Entities;

our @EXPORT = qw(&genForm &getForm &genFormEx &getFormValue &genRadios);

sub genFormEx( $$ ) {
	my( $inputs, $values ) = @_;
	print "<col class='label'><col class='edit'>\n";
	foreach( @{$inputs} ) {
		my( $kind, $label, $type, $name, $other ) = @{$_};
		$other = '' unless( defined $other );
		print '<tr><td>'.$label.'<td><'.$kind.( ( defined $type ) ? " type='$type' class='$type'" : '' ).' name="'.$name.'" '.$other.( defined( $values->{$name} && ( $label ne 'textarea' ) ) ? 'value="'.encode_entities( $values->{$name} ).'" ' : '' ).">\n";
		if( $kind eq 'textarea' ) {
			print encode_entities( $values->{$name} ) if( defined( $values->{$name} ) );
			print "</$kind>\n";
		}
	}
}

sub genForm( $$ ) {
	my( $inputs, $values ) = @_;
	my @transformed;
	foreach( @{$inputs} ) {
		my @ln = @{$_};
		unshift @ln, "input";
		push @transformed, \@ln;
	}
	genFormEx( \@transformed, $values );
}

sub getFormValue( $$ ) {
	my( $name, $default ) = @_;
	my $result = CGI::param( $name );
	$result = $default unless( defined( $result ) );
	return $result;
}

sub getForm( $$ ) {
	my( $data, $checks ) = @_;
	my %result;
	my @errors;
	foreach( keys %{$data} ) {
		my $d = CGI::param( $_ );
		my $sub = $data->{$_};
		my ( $err, $newval ) = &{$sub}( $d ) if( defined $sub );
		$d = $newval if( defined $newval );
		push @errors, $err if( defined $err );
		$result{$_} = $d;
	}
	foreach( @{$checks} ) {
		my $err = &{$_}( \%result );
		push @errors, $err if( defined $err );
	}
	return ( \%result, ( @errors ) ? ( join '<p>', ( '', @errors ) ) : undef );
}

sub genRadios( $$$ ) {
	my( $list, $name, $default ) = @_;
	foreach( @{$list} ) {
		my( $label, $value ) = @{$_};
		print "<input type='radio' name='$name' value='$value'".( $value eq $default ? " checked='checked' " : "" )."> $label<br>\n";
	}
}

1;
