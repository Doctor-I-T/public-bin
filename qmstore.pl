#!/usr/bin/perl

my $file = shift;


local *F; open F,$file or do { die qq{"$f": $!}; exit };
binmode F unless $file =~ m/\.txt/;
local $/ = undef; my $playload = <F>;
close F;

my $data = &qmcontainer($playload);
my $hash = &khash('SHA256',$data);
my $mhash = "\x12\x20".substr($hash,0,256/8);
my $qm = &encode_base58($mhash);
my $ciq = &encode_base32($mhash);
my $bafy = lc&encode_base32("\x01\x70".$mhash);
my $shard = substr($ciq,-3,2);

printf "mhash: f%s\n",unpack'H*',$mhash;
printf "qm: %s\n",$qm;
printf "ciq: %s\n",$ciq;
printf "bafy: b%s\n",$bafy;

my $IPFS_PATH = (defined $ENV{IPFS_PATH}) ? $ENV{IPFS_PATH} : $ENV{HOME}.'/.ipfs';
printf qq'IPFS_PATH: %s\n',$IPFS_PATH;

my $blockf = sprintf "%s/blocks/%s/%s.data",$IPFS_PATH,$shard,$ciq;
my $status = &write_file($blockf,$data);

printf qq'ls -l "%s"\n',$blockf;
printf qq'ipfs files stat /ipfs/B%s\n',$ciq;
printf qq'url: http://127.0.0.1:8080/ipfs/%s\n',$qm;

exit $?;







# ---------------------------------------------------------
sub write_file {
  my $f = shift;
  my $data =shift;
  #return 251 if (! -w $f);
  local *F; open F,'>',$f or do { warn $!; return 251; };
  binmode F;
  print F $data;
  close F;
  return $?;
}
# ---------------------------------------------------------
sub qmcontainer {
   my $msg = shift;
   my $msize = length($msg);
   my $payload = sprintf '%s%s',pack('C',(1<<3|0)),&varint(2); #f1.t0 : 2 (file type)
      $payload .= sprintf '%s%s%s',pack('C',(2<<3|2)),&varint($msize),$msg; # f2.t2: msg
      $payload .= sprintf '%s%s',pack('C',(3<<3|0)),&varint($msize); # f3.t0: msize
   my $data = sprintf "%s%s%s",pack('C',(1<<3|2)),&varint(length($payload)),$payload; # f1.t2
   return $data;
}
# ---------------------------------------------------------
sub varint {
  my $i = shift;
  my $bin = pack'w',$i; # Perl BER compressed integer
  # reverse the order to make is compatible with IPFS varint !
  my @C = reverse unpack("C*",$bin);
  # clear msb on last nibble
  my $vint = pack'C*', map { ($_ == $#C) ? (0x7F & $C[$_]) : (0x80 | $C[$_]) } (0 .. $#C);
  return $vint;
}
# ---------------------------------------------------------
sub khash { # keyed hash
   use Crypt::Digest qw();
   my $alg = shift;
   my $data = join'',@_;
   my $msg = Crypt::Digest->new($alg) or die $!;
      $msg->add($data);
   my $hash = $msg->digest();
   return $hash;
}
# ---------------------------------------------------------
sub encode_base58 { # btc
  use Math::BigInt;
  use Encode::Base58::BigInt qw();
  my $bin = join'',@_;
  my $bint = Math::BigInt->from_bytes($bin);
  my $h58 = Encode::Base58::BigInt::encode_base58($bint);
  $h58 =~ tr/a-km-zA-HJ-NP-Z/A-HJ-NP-Za-km-z/;
  return $h58;
}
# ---------------------------------------------------------
sub encode_base36 {
  use Math::BigInt;
  use Math::Base36 qw();
  my $n = Math::BigInt->from_bytes(shift);
  my $k36 = Math::Base36::encode_base36($n,@_);
  #$k36 =~ y,0-9A-Z,A-Z0-9,;
  return $k36;
}
# ---------------------------------------------------------
sub encode_base32 {
  use MIME::Base32 qw();
  my $mh32 = uc MIME::Base32::encode($_[0]);
  return $mh32;
}
# ---------------------------------------------------------




1; # $Source: /my/perl/scripts/qmstore.pl$

