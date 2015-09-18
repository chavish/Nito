#!/usr/bin/perl
# Nito: A Simple Bot Written in Perl
# This is simply a kickoff script. Calling new will build the object
# Source: http://oreilly.com/pub/h/1964

use strict;
use Nito;

print "Gravelord Nito bot ver. 0.6\n";

my $nito = Nito->new();
$nito->run();
