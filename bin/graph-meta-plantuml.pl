#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.04';

use Meta::Grapher::Moose::PlantUML;

exit Meta::Grapher::Moose::PlantUML->new_with_options->run;
