#!/usr/bin/env perl

use strict;
use warnings;

use Meta::Grapher::Moose;

exit Meta::Grapher::Moose->new_with_options->run;
