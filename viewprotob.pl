#!/usr/bin/perl

my $file = shift;

local *F; open F,'<',$file;

# CAE= : 0801 = f1.t0:vi=1

# protobuf type f.t. :
#   08 => f0.t0
#   0a => f1.t2
#   12 => f2.t2
#   18 => f3.t0

# wire-types
my $wtype = { 0 => 'varint', 1 => '64-bit', 2 => 'string', 5 => '32-bit' };

# QmPa5thw8vNXH7eZqcFX8j4cCkGokfQgnvbvJw88iMJDVJ
# 00000000: 0a0e 0802 1208 6865 6c6c 6f20 210a 1808  ......hello !...
# {"Links":[],"Data":"\u0008\u0002\u0012\u0008hello !\n\u0018\u0008"}
# 0000_1010 : f1.t2 size=14 (0a0e)
# payload: 0802_1208 ... 1808
#          0000_1000 : f1.t0 varint=2 (0802)
#          0001_0010 : f2.t2 size=8 ... (1208 ...)
#          0001_1000 : f3.t0 varint=8 (1808)


my $payload = '';
my $pos = 0;
while(! eof(F)) {
 unfoldf(F);
}

exit $?;

sub unfoldf {
  local *PB = $_[0];
  my @data = ();
  my $buf = '';
  read(PB,$buf,1);
  my $c = substr($buf,0,1);
  my $z = unpack'C',$c;
  my $f = $z>>3;
  my $t = $z&0x7;
  printf "buf: %s 0x%02x ...\n",unpack('B*',$c),$z;
  if ($t == 2) {
    my $s = &readfvi(PB);
    my $size = &uvarint($s); 
    printf "hdr: f%d.t%d ",$f,$t;
    printf "size=%d (0x%s)\n",$size,unpack'H*',$s;
    read(PB,$payload,$size);
    printf "data: f.%s\n",unpack'H*',$payload;
    push @data, $payload;
    &unfold($payload);
  } else {
    printf "f%d.t%d\n",$f,$t;
  } 
}

sub unfold {
  my $buf = shift;
  while($buf) {
     my @data = ();
     my $c = substr($buf,0,1,'');
     my $z = unpack'C',$c;
     my $f = $z>>3;
     my $t = $z&0x7;
     printf ". buf: %s %02x %s\n",unpack('B*',$c),$z,unpack'H*',$buf;
     if ($t == 2) {
        my $s = &readvi($buf);
        my $size = &uvarint($s); 
        printf "  f%d.t%d ",$f,$t;
        printf "size=%d (0x%s)\n",$size,unpack'H*',$s;
        my $payload = substr($buf,0,$size,'');
        printf "  data: f.%s (%s)\n",unpack('H*',$payload),&enc($payload);
        push @data, $payload;
     } elsif ($t == 0) {
        my $vi = &readvi($buf);
        my $i = &uvarint($vi); 
        printf "  f%d.t%d ",$f,$t;
        printf "i=%d (0x%s)\n",$i,unpack'H*',$vi;
     } else {
        printf "  f%d.t%d (?)\n",$f,$t;
     } 
  }
  
}

sub enc { # replace special char with \{hex} code
 my $buf = shift;
 #$buf =~ tr/\000-\034\134\177-\377/./d;
 #$buf =~ s/\</\&lt;/g; # XML safe !
 $buf =~ s/([\000-\036\134\`\<\>\177-\377])/sprintf('\\%02x',ord($1))/eg; # \xFF-ize
 return $buf;
}

sub readvi {
  my $vi = '';
  my $n = 0x80;
  while ($n >> 7) {
   my $c = substr($_[0],0,1,'');
   $n = unpack'C',$c;
   #printf "  (vi: %s (...%s))\n",unpack('B*',$c),unpack('H*',$_[0]);
   $vi .= $c;
  }
  return $vi;
}
# -----------------------------------------------------
sub readfvi {
  local $fd = shift;
  my $vi = '';
  my $n = 0x80;
  while ($n >> 7) {
   read($fd,$c,1);
   $n = unpack'C',$c;
   $vi .= $c;
  }
  return $vi;
}
# -----------------------------------------------------
sub varint {
  my $i = shift;
  my $bin = pack'w',$i; # Perl BER compressed integer
  # reverse the order to make is compatible with IPFS varint !
  my @C = reverse unpack("C*",$bin);
  # clear msb on last nibble
  my $vint = pack'C*', map { ($_ == $#C) ? (0x7F & $C[$_]) : (0x80 | $C[$_]) } (0 .. $#C);
  return $vint;
}
# -----------------------------------------------------
sub uvarint {
  my $vint = shift;
  # reverse the order to make is compatible with perl's BER int !
  my @C = reverse unpack'C*',$vint;
  # msb = 1 except last
  my $wint = pack'C*', map { ($_ == $#C) ? (0x7F & $C[$_]) : (0x80 | $C[$_]) } (0 .. $#C);
  my $i = unpack'w',$wint;
  return $i;
}
# -----------------------------------------------------

