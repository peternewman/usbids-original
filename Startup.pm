package Startup;
use strict;
use warnings;
use base 'Exporter';

#Where are data?
our $directory = '/home/vorner/prog/pciids/';
our @EXPORT=qw($directory);

#Where are the modules?
use lib ( '/home/vorner/prog/pciids/' );

1;
