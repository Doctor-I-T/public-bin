#!/usr/bin/perl


# intent:
#   shards bookmarks (qmrks) in timed list of urls
#   using the hash (base36) of the url

if (@ARGV) {
$QMARKSDIR=shift;
} else {
$QMARKSDIR=$ENV{QMARKSDIR}||'../qmarks';
}


die unless -d $QMARKSDIR;

printf "--- # %s\n",$0;
my $i = 0;
my $p = 'qMark';
my ($url,$what) = ('https://example.com','URL Example');
while (<STDIN>) {
   chomp;
   if (/^http/) {
      $url = $_;
      $what = $p;
      $what =~ s/\s+/ /g;
      $url =~ s/\)/%29/g;
      $what =~ s/]/%5D/g;
   
      # command to get the content !
      my $hash = &khash('SHA256','curl -sL ',$url);
      my $h36 = &encode_base36($hash);
      my $key = substr($h36,0,13);
      my $shard = substr($h36,-3,2);
      my $tic = time();
      printf "%s.%d: [%s](%s)\n",$tic,$i,$what,$url;
      open F,'>>',sprintf'%s/tabs-%s.qmk',$QMARKSDIR,$shard;
      printf F "%s.%d: [%s](%s)\n",$tic,$i,$what,$url;
      close F;
      $i++;
   }
   $p = $_;
}

exit $?;


sub khash { # keyed hash
   use Crypt::Digest qw();
   my $alg = shift;
   my $data = join'',@_;
   my $msg = Crypt::Digest->new($alg) or die $!;
      $msg->add($data);
   my $hash = $msg->digest();
   return $hash;
}
sub encode_base36 {
  use Math::BigInt;
  use Math::Base36 qw();
  my $n = Math::BigInt->from_bytes(shift);
  my $k36 = Math::Base36::encode_base36($n,@_);
  #$k36 =~ y,0-9A-Z,A-Z0-9,;
  return $k36;
}



1; # $Source: /my/perl/scripts/mark.pl$
