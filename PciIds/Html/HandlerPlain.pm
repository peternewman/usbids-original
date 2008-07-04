package PciIds::Html::HandlerPlain;
use strict;
use warnings;
use PciIds::Html::Handler;

sub handler( $ ) {
	return PciIds::Html::Handler::handler( shift, 0 );
}

1;
