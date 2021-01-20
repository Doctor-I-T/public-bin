#!//usr/bin/perl

my $seed = srand();
printf STDERR "seed: %s\n",$seed;

local $/ = "\n";
my @lines = ();
while (<>) {
  push @lines, $_;
}

print sort randomly @lines;

sub randomly { rand(1.0) < 0.5 ? -1 : 1; };

1; # $Source: /my/perl/scripts/randomize.pl $
