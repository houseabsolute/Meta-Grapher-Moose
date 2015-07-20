#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.03';

use Meta::Grapher::Moose;

exit Meta::Grapher::Moose->new_with_options->run;
