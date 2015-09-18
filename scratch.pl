#!/usr/bin/perl

use warnings;
use strict;

my @colors = qw/4 8 9 10 11 12 13/;
my $regular = 1;
my $blink = 14;
my $output;

my $string = join(' ', @ARGV);

print "STRING: $string\n";

my @letters = split//, $string;

foreach my $i (0..$#letters)
{
    my $ci = $i % @colors;
    $output .= "\x03$colors[$ci],$regular$letters[$i]"; 
}

$output .= "\x03";

print "$output\n";


