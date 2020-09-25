#!/usr/bin/perl

# --- meta:
# purpose: script to compute namespace identifier for uri
#
# usage: perl -S nid.pl urn:domain:space-uniq-name-within-domain
#
# details: |-
#  an uri is an uniq ressource identifier used
#  to create the name space id
#
#  requirement space-uniq-name-within-domain need to be permanent and global !
#
#  it is a sort of permanent global address for the namespace
#
#  ex: urn:ipns:QmdHmC48ipAsKSQcaJZ4X6b48b5mxtN5NjNEVrLbTGF8Un
#  ---

my $yml = 0;
if ($ARGV[0] eq '-y') {
  $yml=1;
  shift;
}

my $uri = shift;

my $nid = &get_nid($uri);
if ($yml) {
   printf "--- %s\n",$0;
   printf "nid: %s\n",$nid;
} else {
   print $nid;
}
exit $?;

# ----------------------------------
# namespace id: 13 char of base36(sha256)
# 13 is chosen to garantie uniqness
# over a population of 2^64 nodes
sub get_nid {
 my $s = shift;
 my $sha2 = &khash('SHA256',$s);
 my $ns36 = &encode_base36($sha2);
 my $nid = substr($ns36,0,13);
 return lc $nid;
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
# ----------------------------------
sub encode_base36 {
  use Math::BigInt;
  use Math::Base36 qw();
  my $n = Math::BigInt->from_bytes(shift);
  my $k36 = Math::Base36::encode_base36($n,@_);
  #$k36 =~ y,0-9A-Z,A-Z0-9,;
  return $k36;
}
# ----------------------------------

1; # $Source: /my/perl/scripts/nid.pl $

