#!/usr/bin/env perl

# intent:
#   find out possible letters at 3rd or 6th spot in IPFS mhashes 

use YAML::Syck qw(Dump);
use lib $ENV{HOME}.'/repo/gitea/site/lib';
use UTIL qw(encode_base58 encode_base58f encode_base32 hash1);

my $n0 = int rand(0xFFFF_FFFF);
my $i = 0;
my %kqm = ();
my %kb2 = ();
my %kdj = ();
while (1) {
my $s = pack'N',$n0 + $i;
my $qmbin= "\x12\x20".hash1('SHA256',$s);
my $zdj = "\x01\x70\x12\x20".hash1('SHA256',$s);
my $zb2 = "\x01\x55\x12\x20".hash1('SHA256',$s);
my $sh1 = "\x01\x55\x11\x14".hash1('SHA1',$s);

my $qm58 = &encode_base58($qmbin);
my $qm58f = &encode_base58f($qmbin);
my $ciq =  &encode_base32($qmbin);
my $zd58 = &encode_base58($zdj);
my $bafy =  &encode_base32($zdj);
my $zb58 = &encode_base58($zb2);
my $bafk =  &encode_base32($zb2);

my $sh58 = &encode_base58($sh1);
my $sh58f = &encode_base58f($sh1);

my $kern = substr($qm58,0,3); $kqm{$kern}++;
   $kern = substr($qm58f,0,3); $kqf{$kern}++;
   $kern = substr($zd58,0,5); $kdj{$kern}++;
   $kern = substr($zb58,0,5); $kb2{$kern}++;
   $kern = substr($sh58,0,5); $k83{$kern}++;
   $kern = substr($sh58f,0,5); $k83f{$kern}++;
   $kern = substr($sh58,-1); $kll{$kern}++;

   if ($i++ > 116) {

      if (! $kqm{$kern}) {
         my $shard = substr($ciq,-3,2);
         printf "i: %u\n",$i;
         printf "qm:   %s\n",$qm58;
         printf "qmf:  %s\n",$qm58f;
         printf "CIQ:  b%s\n",$ciq;
         printf "zdj:  z%s\n",$zd58;
         printf "bafy: b%s\n",lc$bafy;
         printf "zb2:  z%s\n",$zb58;
         printf "bafk: b%s\n",lc$bafk;
         printf "sha1: z%s\n",$sh58;
         printf "sh1f: z%s\n",$sh58f;
         printf "shard: /%s/\n",$shard;
      }

      last if (scalar(keys %kll) == 58);
   }
}


printf "kll: [%s]\n",join',',sort map { substr($_,-1) } keys %kll;
printf "kqm: [%s]\n",join',',sort map { substr($_,2,1) } keys %kqm;
printf "kqf: [%s]\n",join',',sort map { substr($_,2,1) } keys %kqf;
printf "zb2: [%s]\n",join',',sort map { substr($_,-1) } keys %kb2;
printf "zdj: [%s]\n",join',',sort map { substr($_,-1) } keys %kdj;
printf "z83: [%s]\n",join',',sort map { substr($_,-1) } keys %k83;
printf "z8f: [%s]\n",join',',sort map { substr($_,-1) } keys %k83f;

#printf "kb2: %s.\n",Dump(\%kb2);
#printf "k83 %s.\n",Dump(\%k83);
#printf "kqf %s.\n",Dump(\%kqf);



exit $?;

1;
