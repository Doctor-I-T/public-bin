#!/usr/bin/perl


my $all = 0;
my $seed=srand();

while (@ARGV && $ARGV[0] =~ m/^-/)
{
  $_ = shift;
  #/^-(l|r|i|s)(\d+)/ && (eval "\$$1 = \$2", next);
  if (/^-v(?:erbose)?/) { $verbose= 1; }
  elsif (/^-a(?:ll)?/) { $all= 1; }
  elsif (/^-y(?:ml)?/) { $yml= 1; }
  else                  { die "Unrecognized switch: $_\n"; }

}
#understand variable=value on the command line...
eval "\$$1='$2'"while $ARGV[0] =~ /^(\w+)=(.*)/ && shift;

my $intent =  sprintf "Get a random number smaller than %s",$ARGV[0]||'max';

my $max = shift;
my $rnd = rand($max);
my $irnd = int($rnd);

if ($all || $yml) {
printf "--- # %s\n",$0;
printf "seed: %s\n",$seed;
printf "max: %s\n",$max||'1';
printf "irnd: %s\n",$irnd;
printf "rand: %s\n",$rnd;
printf "intent: %s\n",$intent;
} else {
 print $irnd;
}

1; # $Source: /my/perl/scripts/random.pl$




