#!/usr/bin/perl

my $seed=srand();
printf "--- # %s\n",$0;
printf "seed: %s\n",$seed;
printf "rand: %s\n",rand($ARGV[0]);

1; # $Source: /my/perl/scripts/random.pl$




