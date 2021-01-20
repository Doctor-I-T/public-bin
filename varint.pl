#!/usr/bin/env perl

print "// varint conversion ...\n";
while(1) {
my $ans = <STDIN>; chomp($ans);
if ($ans =~ /^\d+$/) {
   my $vint = &varint($ans);
   printf "vint: %s\n",unpack'H*',$vint;
} elsif ($ans =~ /^(?:0x)?([a-f0-9]+)$/) {
   my $int = &uvarint(pack'H*',$1);
   printf "int: %u, 0x%x\n",$int,$int;
} else {
  last;
}

}
exit $?;

sub varint {
  my $i = shift;
  my $bin = pack'w',$i; # Perl BER compressed integer
  # reverse the order to make is compatible with IPFS varint !
  my @C = reverse unpack("C*",$bin);
  # clear msb on last nibble
  my $vint = pack'C*', map { ($_ == $#C) ? (0x7F & $C[$_]) : (0x80 | $C[$_]) } (0 .. $#C);
  return $vint;
}
sub uvarint {
  my $vint = shift;
  # reverse the order to make is compatible with perl's BER int !
  my @C = reverse unpack'C*',$vint;
  # enforce msb = 1 except last /!\
  my $wint = pack'C*', map { ($_ == $#C) ? (0x7F & $C[$_]) : (0x80 | $C[$_]) } (0 .. $#C);
  my $i = unpack'w',$wint;
  return $i;
}
1;
