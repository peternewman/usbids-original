package Startup;
use strict;
use warnings;
use base 'Exporter';

#Where are data?
our $directory = '/home/vorner/skola/cvika/internet/impl';
our @EXPORT=qw($directory);

#Where are the modules?
use lib ( '/home/vorner/skola/cvika/internet/impl' );

1;
