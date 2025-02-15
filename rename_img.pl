#!/usr/bin/perl
# vim: ts=2 et

# The secret ingredient is always love ...
#
# usage :
#  perl -S rename_img.pl -a $root file.jpg

#--------------------------------
# -- Options parsing ...
#
my $log = 0;
my $sz = 4; # nb nibble from md6
my $skip = 1;
my $all = 0;
my $attr = 0;
my $shard = undef;
my $keep = 0;
my $remove = 0;
while (@ARGV && $ARGV[0] =~ m/^-/)
{
  $_ = shift;
  #/^-(l|r|i|s)(\d+)/ && (eval "\$$1 = \$2", next);
  if (/^-v(?:erbose)?/) { $verbose= 1; }
  elsif (/^-(\d)/) { $sz= $1; }
  elsif (/^--?l(?:og)?/) { $log= 1; }
  elsif (/^--?rm/) { $remove= 1; }
  elsif (/^--?at(?:trib)?/) { $attr= 1; }
  elsif (/^--?k(?:eep)?/) { $keep= 1; }
  elsif (/^--?s(?:hard=)?=?([\w.]*)/) { $shard= $1 ? $1 : shift; }
  elsif (/^-a$/) { $all= 1; }
  elsif (/^--?n(?:op|ame)?/) { $nop= 1; }
  elsif (/^--?all/) { $all= 1;  $skip= 0; }
  else                  { die "Unrecognized switch: $_\n"; }

}
#understand variable=value on the command line...
eval "\$$1='$2'"while $ARGV[0] =~ /^(\w+)=(.*)/ && shift;


mkdir $shard if (defined $shard && ! -d $shard);

if ($verbose) {
printf "--- # %s\n",$0;
printf "log: %s\n",$log;
printf "skip: %s\n",$skip;
printf "all: %s\n",$all;
printf "nop: %s\n",$nop;
printf "shard: %s\n",$shard;
printf "keep: %s\n",$keep;
printf "remove: %s\n",$remove;
}

local *LOG;
$log=1 if (-e '_index.log');
if ($log) {
  open LOG,'>>','_index.log';
}
local *RM;
if ($remove) {
  open RM,'>>','_removed.log';
}
my $metastore = "$ENV{HOME}/.../ipfs/usb/MUTABLES/metastore";
my $metaf = '_meta.log';
local *META;
open META,'>>',"$metaf";

my $root;
if (@ARGV) {
  $root = shift
} else {
 use Cwd qw();
 my $cwd = Cwd::getcwd;
 my $p = rindex($cwd,'/');
 $root = lc substr($cwd,$p+1); $root =~ tr/aeiou//d;
 $root = substr($root,0,3);
 printf "root: %s\n",$root if ($verbose);
}

my @list = ();
if (@ARGV) {
 @list = @ARGV;
} else {
  local *D; opendir D,'.'; @list = grep /\.(?:jpe*g|png|gif|tif|webp|eps|svg|data|blob)/io, readdir(D); closedir D;
}

foreach my $f (sort { substr($a,2) <=> substr($b,2) } @list) {
   next if ($skip && $f !~ /_/ && $f =~ /^${root}\b/);
   #printf "file: %s\n",$f; next;
   next unless ($all || $f =~ /(?:image?|^ind|download|un+amed|pimgp|maxres|hqdef|^I_[\da-f]|^f_)|^[0-9a-f_]+n?\.|^x[^a-z]/);
   #next unless ($f =~ /^(?:IMG_\d|SF-)/);
   my ($bname,$ext) = ($1,$2) if $f =~ m/(.*)\.([^\.]+)$/;
   $bname = $f unless $bname;
   $bname =~ s,^.*/,,;

   $ext =~ s/!.*//;
   $ext = 'jpg' if ($ext eq 'jpeg');
   $ext =~ tr/~//d;

   if ($ext eq 'data' || $ext eq 'blob') {
      $ext = &get_ext($f);
      printf "ext: %s\n",$ext if ($verbose);
      next unless $ext =~ /(?:jpe*g|png|gif|tif|webp|eps|svg|data|blob)/io
   }

   local *F; open F,$f or do { warn qq{"$f": $!}; next };
   binmode F unless $f =~ m/\.txt/;
   my $gitid = &githash(F);
   my $id7 = substr($gitid,0,7);
   my $md6 = &digest('MD6',F);
   my $sha2 = &digest('SHA-256',F); # use Digest !
      my @stats = lstat(F);
   my $mtime = $stats[8];
   my $etime = (sort { $a <=> $b } (@stats)[9,10])[0];
   close F;
   my $nu = hex($id7);
   my $pn = hex(substr($md6,-$sz)); # use last sz nibble (default: 16-bit)
      my $sn = hex(substr(lc$sha2,-8));
   my $word = &word($pn);
   my $cname = &word($sn);
   if ($verbose) {
      printf "sha2: %s\n",$sha2;
      printf "sha2(-6): %s\n",substr(lc$sha2,-6);
      printf "sn: %s\n",$sn;
      printf "cname: %s\n",$cname;
   }
   my $n2 = sprintf "%09u",$nu; $n2 =~ s/(....)/\1_/;
   # -----------------------------------------------
   my $attrib;
   if ($attr == 0) {
      $attrib = $root;
   } elsif ($bname =~ m/^([\w-]+)-$word$/) {
      $attrib = $1;
   } elsif ($bname =~ m/^([\w-]+)-\w+-unsplash$/) {
      $attrib = $1;
   } elsif ($bname =~ m/^([\w-]+)-\w+/) {
      $attrib = $1;
   }
   printf "attrib: %s\n",$attrib if ($verbose);
      my $ns = ($attrib) ? $attrib : $root;
   my $n = sprintf "%s-%s.%s",$ns,$word,$ext;

   my $nf;
   my $sharddir;
   if ($shard) {
      ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($etime);
      $yhour = $yday * 24 + $hour + ($min / 60 + $sec / 3600);
      $yweek=$yday/7;
      $sharddir = sprintf '%s/%4d',$shard,$year+1900;
      mkdir $sharddir unless -d $sharddir;
      $sharddir = sprintf '%s/%4d/WW%02d',$shard,$year+1900,$yweek;
      mkdir $sharddir unless -d $sharddir;
      if (&get_nbfiles($sharddir) > 512) {
         my $MoY = [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)];
         $sharddir = sprintf '%s/%4d/%s',$shard,$year+1900,$MoY->[$mon];
         mkdir $sharddir unless -d $sharddir;
         $sharddir = sprintf '%s/%4d/%s/D%03d',$shard,$year+1900,$MoY->[$mon],$yday;
         mkdir $sharddir unless -d $sharddir;
         printf "sharddir: %s\n",$sharddir if ($verbose);
      }
      $nf = sprintf '%s/%s',$sharddir,$n;
   } else {
      $nf = $n;
   } 
   unless ($nop && ! $verbose) {
      printf "word: %5s\n",$word;
      printf "%s: %-5s %-14s; %s: #%-9u PN%05u (%s)\n",$id7,$word,$f,$cname,$nu,$pn,$nf;
   } else {
      printf "%5s\n",$word;
   } 
   # -----------------------------------------------
   if ($remove) {
      unlink $f;
      printf RM "%u: %s %s\n",$etime,$gitid,$f;
      next;
   } elsif ($log) {
      printf LOG "%u: %s %s\n",$etime,$gitid,$n;
   }
   # -----------------------------------------------
   next if ($f eq $nf);
   printf META "%u: %s %s %s\n",$mtime,$gitid,$stats[7],$f;

   if (-e $nf) {
      local *F; open F,$nf or do { warn qq{"$nf": $!}; next };
      binmode F unless $nf =~ m/\.txt/;
      my $githash = &githash(F);
      if ($githash eq $gitid) {
         my $md6n = &digest('MD6',F);
         if ($md6 eq $md6n) {
            unlink $f unless $keep; # keep the previous one...
               next;
         } else {
            die  "git id collision between $f and $nf  !"
         }
      } else {
         unless ($nop) {
            printf "%s: %s\n",$gitid,$f;
            printf "%s: %s\n",$githash,$nf;
         }
         $n = sprintf "${ns}-%s.%s",$cname,$ext;
         if ($shard) {
            $nf = sprintf '%s/%s',$sharddir,$n;
         } else {
            $nf = $n;
         }
         mkdir 'dup' unless -d 'dup';
         my $i = 1;
         while (-e $nf) {
            local *F; open F,$nf or do { warn qq{"$nf": $!}; next };
            binmode F unless $nf =~ m/\.txt/;
            my $githash = &githash(F);
            if ($githash eq $gitid) {
               printf "info: -e %s %s == %s*\n",$nf,$githash,$id7 if $verbose;
               unlink $f unless $keep; # keep the previous one...
                  last;
            } else {
               $nf = sprintf "dup/${ns}-%s,%s (%u).%s",$cname,$word,$i++,$ext;
            }
         }
         next if (! -e $f);
         if (-e $nf) {
            $nf = sprintf "dup/${ns}-%s.%s",$n2,$ext;
         }
      }
   }
   unless ($nop) {
     rename $f,$nf or die "$f: $!";
   }
}

close META;
close LOG;
close RM;

#sleep 3;
exit $?;

# ---------------------------------------------------------
sub get_ext {
  my $file = shift;
  my $ext = $1 if ($file =~ m/\.([^\.]+)/);
  if (! $ext || $ext eq 'data' || $ext eq 'blob') {
    my %ext = (
    text => 'txt',
    'application/octet-stream' => 'blob',
    'application/x-perl' => 'pl'
    );
    my $type = &get_type($file);
    if (exists $ext{$type}) {
       $ext = $ext{$type};
    } else {
      $ext = ($type =~ m'/(?:x-)?(\w+)') ? $1 : 'ukn';
    }
  }
  return $ext;
}
sub get_type { # to be expended with some AI and magic ...
  my $file = shift;
  use File::Type;
  my $ft = File::Type->new();
  my $type = $ft->checktype_filename($file);
  if ($type eq 'application/octet-stream') {
    my $p = rindex $file,'.';
    if ($p>0) {
     $type = 'files/'.substr($file,$p+1); # use the extension
    }
  }
  return $type;
}
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
      $c = $n % 6;
      $n /= 6;
      $str .= $vo->[$c];
 }
 $str .= $cs->[$n];
 return $str;	
}

sub get_nbfiles {
  my $dir = shift;
  local *D; opendir D,$dir; my $n = grep !/^\./, readdir(D); closedir D;
  printf "n: %s (%s)\n",$n,$dir;
  return $n
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
