#!/usr/bin/perl

my $tic=time();
my $key=&get_key();

my $max = undef;
my $all = 0;
our $seed = undef;
while (@ARGV && $ARGV[0] =~ m/^-/) {
  $_ = shift;
  #/^-(l|r|i|s)(\d+)/ && (eval "\$$1 = \$2", next);
  if (/^-v(?:erbose)?/) { $verbose= 1; }
  elsif (/^-a(?:ll)?/) { $all= 1; }
  elsif (/^-k(?:ey)?/) { $key= shift; }
  elsif (/^-t(?:ics?)?/) { $tic= shift; }

  elsif (/^-y(?:ml)?/) { $yml= 1; }
  else                  { die "Unrecognized switch: $_\n"; }

}
#understand variable=value on the command line...
eval "\$$1='$2'"while $ARGV[0] =~ /^(\w+)=(.*)/ && shift;

my $intent;
if (exists $ARGV[0] && $ARGV[0] =~ m/^\d+$/) {
  $max = shift;
  $intent =  sprintf "Get a random number smaller than %s",$max||'max';
} else {
  $intent =  join' ',@ARGV;
}

my $IV;
if (defined $seed) {
  $IV = $seed;
  $seed=srand($seed);
} elsif (@ARGV)  {
  my $msg = join(' ',"$tic:",@ARGV);
  $IV = &khash('SHA256',$key,length($msg),$msg);
  $seed=srand(unpack('Q',$IV));
} else {
  $seed=srand();
}


my $rnd = rand($max);
my $irnd = int($rnd);

if ($all || $yml) {
printf "--- # %s\n",$0;
printf "tic: %s\n",$tic;
printf "key: %s\n",$key;
printf "IV: %s\n",unpack'H*',$IV;
printf "seed: %s\n",$seed;
printf "max: %s\n",$max||'1';
printf "irnd: %s\n",$irnd;
printf "rand: %s\n",$rnd;
printf "intent: %s\n",$intent;
} else {
 print $irnd;
}

exit $?;

sub get_key {
   return int rand(1<<48);
}
sub khash { # keyed hash
   use Crypt::Digest qw();
   my $alg = shift;
   my $data = join'',@_;
   my $msg = Crypt::Digest->new($alg) or die $!;
      $msg->add($data);
   my $hash = $msg->digest();
   return $hash;
}
# -----------------------------------------
1; # $Source: /my/perl/scripts/random.pl$




