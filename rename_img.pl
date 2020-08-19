#!/usr/bin/perl
# vim: ts=2 et

# The secret ingredient is always love ...


my $all = 0;
if ($ARGV[0] eq '-a') {
 $all=1;
 shift;
}

my $root;
if (@ARGV) {
  $root = shift
} else {
 use Cwd qw();
 my $cwd = Cwd::getcwd;
 my $p = rindex($cwd,'/');
 $root = lc substr($cwd,$p+1); $root =~ tr/aeiou//d;
 $root = substr($root,0,3);
 printf "root: %s\n",$root;
}

local *D; opendir D,'.'; my @content = grep /\.(?:jpe*g|png|gif|tif|webp)/io, readdir(D); closedir D;
foreach my $f (sort { substr($a,2) <=> substr($b,2) } @content) {
  next if ($f =~ /^${root}\b/);
  next unless ($all || $f =~ /(?:image?|download|un+amed|pimgp|maxres|hqdef|^I_[\da-f]|^f_)|^[0-9a-f_]+n?\.|^x[^a-z]/);
  #next unless ($f =~ /^(?:IMG_\d|SF-)/);
  my ($bname,$ext) = ($1,$2) if $f =~ m/(.*)\.([^\.]+)$/;
      $bname = $fname unless $bname;
  $ext = 'jpg' if ($ext eq 'jpeg');
  $ext =~ tr/~//d;

  local *F; open F,$f or do { warn qq{"$f": $!}; next };
  binmode F unless $f =~ m/\.txt/;
  my $id7 = substr(&githash(F),0,7);
  my $md6 = &digest('MD6',F);
  close F;
  my $nu = hex($id7);
  my $pn = hex(substr($md6,-4)); # 16-bit
  my $word = &word($pn);
  printf "%s: %s #%u PN%05u (%s)\n",$id7,$f,$nu,$pn,$word;
  my $n2 = sprintf "%09u",$nu; $n2 =~ s/(....)/\1_/;
  my $n = sprintf "$root-%s.%s",$word,$ext;
  next if ($f eq $n);
  if (-e $n) {
	  mkdir 'dup' unless -d 'dup';
    $n = sprintf "dup/${root}-%s.%s",$n2,$ext;
    if (-e $n) {
    $n = sprintf "dup/${root}-%s (2).%s",$n2,$ext;
    }
  }
  rename $f,$n or die "$f: $!"
}

sleep 3;
exit $?;

# ---------------------------------------------------------
sub githash {
 use Digest::SHA1 qw();
 local *F = shift; seek(F,0,0);
 my $msg = Digest::SHA1->new() or die $!;
    $msg->add(sprintf "blob %u\0",(lstat(F))[7]);
    $msg->addfile(*F);
 my $digest = lc( $msg->hexdigest() );
 return $digest; #hex form !
}
# ---------------------------------------------------------
sub digest ($@) {
 my $alg = shift;
 my $header = undef;
 use Digest qw();
 local *F = shift; seek(F,0,0);
 if ($alg eq 'GIT') {
   $header = sprintf "blob %u\0",(lstat(F))[7];
   $alg = 'SHA-1';
 }
 my $msg = Digest->new($alg) or die $!;
    $msg->add($header) if $header;
    $msg->addfile(*F);
 my $digest = uc( $msg->hexdigest() );
 return $digest; #hex form !
}
# ---------------------------------------------------------
sub word { # 20^4 * 6^3 words (25bit worth of data ...)
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
# "I see human intelligence consuming machine intelligence, not the other
# way around.  Humans are a different sort of intelligence. Our intelligence
# is so interconnected. The brain is so incredibly interconnected with
# itself, so interconnected with all the cells in our body, and has
# co-evolved with language and society and everything around it."
# 
# ~ David Ferrucci, IBM's lead researcher on Watson
# ---------------------------------------------------------
1; # $Source: /my/perl/scripts/rename_img.pl $
