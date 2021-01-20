#!/usr/bin/perl
#
# purpose: give a short name to a hash


my $arg;
if ($ARGV[0]) {
  $arg = shift;
} else {
local $/ = undef;
$arg = <STDIN>;
local $/ = "\n";
chomp $arg;
}
my $bin;
my $cidv,$mhash;
   if ($arg =~ m/^Qm/) {
      $cidv = 0;
      $mhash = &decode_base58($arg);
      $bin = pack('H*','0170'). &decode_base58($arg);
   } elsif ($arg =~ m/^z/) { # decode multiformat ...
      $cidv = 1;
      $bin = &decode_base58(substr($arg,1));
      $mhash = substr($bin,2);
   } elsif ($arg =~ m/^b/i) {
      $bin = &decode_base32(substr($arg,1));
      $cidv = unpack'C',substr($bin,0,1);
      $mhash = ($cidv == 1) ? substr($bin,2) : $bin;
   } elsif ($arg =~ m/^f/i) {
      $bin = pack('H*',substr($arg,1));
      $cidv = unpack'C',substr($bin,0,1);
      $mhash = ($cidv == 1) ? substr($bin,2) : $bin;
   } elsif ($arg =~ m/^k/i) {
      $bin = &decode_base36(substr($arg,1));
      $cidv = unpack'C',substr($bin,0,1);
      $mhash = ($cidv == 1) ? substr($bin,2) : $bin;
   } elsif ($arg =~ m/^([um])/) {
      $arg =~ tr{-_}{+/} if ($1 eq 'u');
      $bin = &decode_base64m(substr($arg,1));
      $cidv = unpack'C',substr($bin,0,1);
      $mhash = ($cidv == 1) ? substr($bin,2) : $bin;
   } elsif ($arg =~ m/^9/i) {
      $bin = &decode_base10(substr($arg,1));
      $cidv = unpack'C',substr($bin,0,1);
      $mhash = ($cidv == 1) ? substr($bin,2) : $bin;
   } else {
      $arg =~ tr/IlO0/iLoo/;
      $bin = &decode_base58($arg);
      $cidv = unpack'C',substr($bin,0,1);
      $mhash = ($cidv == 1) ? substr($bin,2) : $bin;
   }


my $url = 'http://127.0.0.1:5001/api/v0/dag/get?arg='.$arg;
my $content = &post_url($url);
my $md6;
my $sz = 4;
if ($content !~ m'404') {
  $md6 = unpack'H*',&khash('MD6',$content);
} else {
  $md6 = unpack'H*',&khash('MD6',$bin);
}
my $pn = hex(substr($md6,-$sz-1,$sz)); # use last-to-sz sz nibbles (default: 16-bit)


my $binp = $bin; $binp =~ tr/\000-\034\134\177-\377/./;
my $qm = &encode_base58($mhash);
my $qm36 = &encode_base36($mhash);
my $quint = &hex2quint(unpack'H*',$mhash);
my $n = unpack'N',substr("\x00"x4 . $bin,-5,4);
my $q = unpack'L',substr("\x00"x8 . $bin,-9,8);
my $word5 = &word5($n);
my $word206 = &word206($pn);
my $word3710 = &word3710($q);

printf "n: %s\n",$n;
printf "pn: %s\n",$pn;
printf "q: %s\n",$q;
printf "arg: %s\n",$arg;
printf "url: %s\n",$url;
printf "content: |-\n%s\n",&indent(' 'x2,$content);
printf "content64: %s\n",&encode_base64m($content,'');
printf "md6: %s\n",$md6;
printf "b16: %s\n",unpack'H*',$bin;
printf "qm: %s\n",$qm;
printf "qm36: %s\n",$qm36;
printf "quint: %s\n",$quint;
printf "word5: %s\n",$word5;
printf "word206: %s\n",$word206;
printf "word3710: %s\n",$word3710;

exit $?;
# -----------------------------------------------------------------------
sub post_url {
   my $url = shift;
   use LWP::UserAgent qw();
   my $ua = LWP::UserAgent->new();
   my $resp = $ua->post($url);
   warn "Couldn't get $url" unless defined $resp;
   return $resp->decoded_content();
}

# -----------------------------------------------------------------------
sub khash { # keyed hash
   use Digest qw();
   my $alg = shift;
   my $data = join'',@_;
   my $msg = Digest->new($alg) or die $!;
      $msg->add($data);
   my $hash = $msg->digest();
   return $hash;
}
# -----------------------------------------------------------------------
# 7c => 31b worth of data ... (similar density than hex)
sub word5 { # 20^4 * 26^3 words (4.5bit per letters)
 use integer;
 my $n = $_[0];
 my $vo = [qw ( a e i o u y )]; # 6
 my $cs = [qw ( b c d f g h j k l m n p q r s t v w x z )]; # 20
 my $a = ord($vo->[0]);
 my $odd = 0; # (($n % 26) < 20) ? 1 : 0; # /!\ this mean there 1 collision for each n
 my $str = '';
 while ($n > 0) {
   if ($odd) {
   my $c = $n % 20;
   #print "c: $c, n: $n\n";
      $n /= 20;
      $str .= $cs->[$c];
      $odd=0;
   } elsif(1) {
   my $c = $n % 26;
      $n /= 26;
      $str .= chr($a+$c);
      $odd=1;
   #} else {
   #my $c = $n % 6;
   #   $n /= 6;
   #   $str .= $vo->[$c];
   #   odd=undef;
   }
 }
 return $str;
}
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

sub word206 { # 20^4 * 6^3 words (25bit worth of data ...)
 my $n = $_[0];
 my $vo = [qw ( a e i o u y )]; # 6
 my $cs = [qw ( b c d f g h j k l m n p q r s t v w x z )]; # 20
 my $str = '';
 while ($n >= 20) {
   my $c = $n % 20;
      $n /= 20;
      $str .= $cs->[$c];
      $c = $n % 6;
      $n /= 6;
      $str .= $vo->[$c];
 }
 $str .= $cs->[$n];
 return $str;	
}
# -----------------------------------------------------------------------
sub hex2quint {
  return join '-', map { u16toq ( hex('0x'.$_) ) } $_[0] =~ m/(.{4})/g;
}
sub u16toq {
   my $n = shift;
   #printf "u2q(%04x) =\n",$n;
   my $cons = [qw/ b d f g h j k l m n p r s t v z /]; # 16 consonants only -c -q -w -x
   my $vow = [qw/ a i o u  /]; # 4 wovels only -e -y
   my $s = '';
      for my $i ( 1 .. 5 ) { # 5 letter words
         if ($i & 1) { # consonant
            $s .= $cons->[$n & 0xF];
            $n >>= 4;
            #printf " %d : %s\n",$i,$s;
         } else { # vowel
            $s .= $vow->[$n & 0x3];
            $n >>= 2;
            #printf " %d : %s\n",$i,$s;
         }
      }
   #printf "%s.\n",$s;
   return scalar reverse $s;
}
# -----------------------------------------------------
sub encode_base64m {
  use MIME::Base64 qw();
  my $b64 = MIME::Base64::encode_base64($_[0],'');
  return $b64;
}
sub encode_base58 { # btc
  use Math::BigInt;
  use Encode::Base58::BigInt qw();
  my $bin = join'',@_;
  my $bint = Math::BigInt->from_bytes($bin);
  my $h58 = Encode::Base58::BigInt::encode_base58($bint);
  $h58 =~ tr/a-km-zA-HJ-NP-Z/A-HJ-NP-Za-km-z/;
  return $h58;
}
sub encode_base36 {
  use Math::BigInt;
  use Math::Base36 qw();
  my $n = Math::BigInt->from_bytes(shift);
  my $k36 = Math::Base36::encode_base36($n,@_);
  #$k36 =~ y,0-9A-Z,A-Z0-9,;
  return $k36;
}
# -----------------------------------------------------
sub decode_base10 {
  use Math::BigInt;
  my $bint = $_[0];
  my $bin = Math::BigInt->new($bint)->as_bytes();
  return $bin;
}
sub decode_base32 {
  use MIME::Base32 qw();
  my $bin = MIME::Base32::decode($_[0]);
  return $bin;
}
sub decode_base36 {
  use Math::BigInt;
  use Math::Base36 qw();
  #$k36 = uc($_[0])
  #$k36 =~ y,A-Z0-9,0-9A-Z;
  my $n = Math::Base36::decode_base36($_[0]);
  my $bin = Math::BigInt->new($n)->as_bytes();
  return $bin;
}
sub decode_base58 {
  use Math::BigInt;
  use Encode::Base58::BigInt qw();
  my $s = $_[0];
  # $e58 =~ tr/a-km-zA-HJ-NP-Z/A-HJ-NP-Za-km-z/;
  $s =~ tr/A-HJ-NP-Za-km-z/a-km-zA-HJ-NP-Z/;
  my $bint = Encode::Base58::BigInt::decode_base58($s);
  my $bin = Math::BigInt->new($bint)->as_bytes();
  return $bin;
}
sub decode_base64m {
  use MIME::Base64 qw();
  my $bin = MIME::Base64::decode_base64($_[0]);
  return $bin;
}
# -----------------------------------------------------
sub indent {
  my $lead = shift;
  my $buf = shift;
  local $/ = "\n";
  $buf =~ s/^/$lead/mg;
  return $buf;
}

#
1; # --------------------------------------------------------------------
