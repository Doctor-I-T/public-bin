#!/usr/bin/env perl
#
# take a content and return a 32bit key and more
#
use Digest::MurmurHash qw(); # Austin Appleby (Murmur 32-bit)
our $dbug=0;
#--------------------------------
# -- Options parsing ...
#
my $sz = 4;
my $all = 0;
my $_id7 = 1;
while (@ARGV && $ARGV[0] =~ m/^-/)
{
  $_ = shift;
  #/^-(l|r|i|s)(\d+)/ && (eval "\$$1 = \$2", next);
  if (/^-a(?:ll)?/) { $all= 1; }
  elsif (/^-y(?:ml)?/) { $yaml= 1; }

  elsif (/^-(\d)?/) { $sz= $1; }
  elsif (/^-m(?:u)?/) { $_mu= 1; }
  elsif (/^-g(?:it)?/) { $_git= 1; }
  elsif (/^-(?:i(?:d)?|7)/) { $_id7= 1; }
  elsif (/^-(?:m(?:d6)?|6)/) { $_md6= 1; }
  elsif (/^-(?:m(?:d)?|5)/) { $_md5= 1; }
  elsif (/^-(?:n2|2)/) { $_n2= 1; }
  elsif (/^-p(?:n)?/) { $_pn= 1; }
  elsif (/^-w(?:ord)?/) { $_word= 1; }
  elsif (/^-l(?:oc)?/) { $_loc= 1; }
  else                  { die "Unrecognized switch: $_\n"; }

}
#--------------------------------
#understand variable=value on the command line...
eval "\$$1='$2'"while $ARGV[0] =~ /^(\w+)=(.*)/ && shift;

my $key=shift;
my $loc;
if ($key) {
 $loc = 'arg';
} else {
   $loc = (-e $key) ? $key : '-';
   local *F; open F,'<',$loc;
   local $/ = undef; $key = <F>; close F;
}
my $mu = Digest::MurmurHash::murmur_hash($key);

my $gitbin = &githash($key);
my $gitid = unpack('H*',$gitbin);
my $id7 = substr($gitid,0,7);

my $md5 = unpack'H*',&digest('MD5',$key);
my $sha1 = &digest('SHA1',$key);
my $sha2 = &digest('SHA-256',$key);
my $qm58 = &encode_base58("\x01\x55\x12\x20",$sha2);
my $md6bin = &digest('MD6',$key);
my $md6 = unpack('H*',$md6bin);
my $sn = unpack('N',substr($sha2,-4));

my $idz = substr($md6,-$sz-1,$sz); # on hexdigest

my $nu = hex($id7);
#y $pn = hex(substr($md6,-$sz-1,$sz)); # use last-to-sz sz nibble (default: 16-bit)
my $pn = hex(substr($md6,-$sz)); # use last sz nibble (default: 16-bit)


my $word = &word206($pn);
my $cname = &word3710($sn);
my $n2 = sprintf "%09u",$nu; $n2 =~ s/(....)/\1_/;

printf "--- # %s\n",$0 if ($yaml);

if ($yaml || $all) {
printf "sn: %s\n",$sn;
printf "mu: %u\n",$mu;
printf "gitid: %s\n",$gitid;
printf "id7: %s\n",$id7;
printf "id%s: %s\n",$sz,$idz;
printf "md5: %s\n",$md5;
printf "sha1: %s\n",unpack('H*',$sha1);
printf "sha2: %s\n",unpack('H*',$sha2);
printf "qm58: z%s\n",$qm58;
printf "md6: %s\n",$md6;
printf "pn: %s\n",$pn;
printf "word: %s\n",$word;
printf "cname: %s\n",$cname;
printf "n2: %s\n",$n2;
printf "loc: %s\n",$loc;
printf "key: %s\n",$key if ($loc eq 'stdin');
} else {
  my @res = ();
  if ($_mu == 1) { push @res, $mu }
  push @res, $gitid if $_git;
  push @res, $id7 if $_id7;
  push @res, $md5 if $_md5;
  push @res, $sha1 if $_sha1;
  push @res, $qm58 if $_qm58;
  push @res, $md6 if $_md6;
  push @res, $pn if $_pn;
  push @res, $word if $_word;
  push @res, $n2 if $_n2;

  my $sep = (scalar@res > 2) ? ', ' : ' - ';
  print join$sep,@res;

}

exit $?;


# ---------------------------------------------------------
sub githash {
 use Digest::SHA1 qw();
 my $msg = Digest::SHA1->new() or die $!;
    $msg->add(sprintf "blob %u\0",(lstat(F))[7]);
    $msg->add(@_);
 my $digest = $msg->digest();
 return $digest; # binay form !
}
# ---------------------------------------------------------
sub digest ($@) {
 my $alg = shift;
 my $header = undef;
 my $text = shift;
 use Digest qw();
 if ($alg eq 'GIT') {
   $header = sprintf "blob %u\0",length($text);
   $alg = 'SHA-1';
 }
 my $msg = Digest->new($alg) or die $!;
    $msg->add($header) if $header;
    $msg->add($text);
 my $digest = $msg->digest();
 return $digest; #binary form !
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
sub word206 { # 20^4 * 6^3 words (25bit worth of data ...)
 my $n = $_[0];
 my $vo = [qw ( a e i o u y )]; # 6
 my $cs = [qw ( b c d f g h j k l m n p q r s t v w x z )]; # 20
 my $str = '';
 while ($n >= 20) {
   my $c = $n % 20;
      $n /= 20;
      $str .= $cs->[$c];
   my $c = $n % 6;
      $n /= 6;
      $str .= $vo->[$c];
 }
 $str .= $cs->[$n];
 return $str;	
}
# ---------------------------------------------------------
sub word3710 { # 37^4 * 10^3 words (30bit worth of data...)
 use integer;
 my $n = $_[0];
 my $vo = [qw ( a ai au e i o oi ou u y )]; # 10
 my $cs = [qw ( b bl c cl d dl f fl g gl h j jl k kl l m n p pl q ql qu r rl s sl st t th tl v vl w x z zl )]; # 37
 my $vn = scalar(@{$vo});
 my $cn = scalar(@{$cs});
 my $an = $cn + $vn;
 #print "n: $n\n";
 #print "cn: $cn\n";
 #print "vn: $vn\n";
 #print "an: $an\n";

 my $str = '';
 if (1 && $n < $an) {
    $str = (@{$vo},@{$cs})[$n];
    print "str: $str\n";
 } else {
    $n -= $vn;
    while ($n >= $cn) {
       my $c = $n % $cn;
       $n /= $cn;
       $str .= $cs->[$c];
       #print "cs: $n -> $c -> $str\n";
       $c = $n % $vn;
       $n /= $vn;
       $str .= $vo->[$c];
       #print "vo: $n -> $c -> $str\n";

    }
    if ($n > 0) {
       $str .= $cs->[$n];
    }
 }
 return $str;
}
# ---------------------------------------------------------
1; # $Source: /my/perl/scripts/contkey.pl $
