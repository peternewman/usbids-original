package PciIds::Html::HandlerSSL;
use strict;
use warnings;
use PciIds::Html::Handler;

sub handler( $ ) {
	return PciIds::Html::Handler::handler( shift, 1 );
}

1;
