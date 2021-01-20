#!/usr/bin/perl

# intent:
#  deduplicate files using shake160 hash
#  place deduped files in an IPFS repository.


my ($red,$yellow,$green,$nc) = ("\e[31m","\e[33m","\e[32m","\e[0m");
# use alternative hashed to make so that files can be sorted out...
my $s50M = 50 * 1024 * 1024;
my $len = 160; # min 20Bytes
my $default=$ENV{HOME}.'/.../ipfs/usb/DEDUP';
my $IPFS_PATH = (exists $ENV{IPFS_PATH}) ? $ENV{IPFS_PATH} : $default;

printf "IPFS_PATH: %s\n",$IPFS_PATH;
local *LOG; open LOG,'>>','ddup.log';

printf LOG "// date: %s\n",&hdate(time);

local $| = 1;
# accept locate,du output, and yml as input format
while (<>) {
  chomp;
     $_ =~ s/^\s+//; # no heading " "
     $_ =~ s/\s+$//; # no trailing " "
  my ($ad,$file) = (undef,$_);
  if (! -e $file) {
    if (m/\s+/) { # du output
      ($ad,$file) = split(/\s+/,$_,2);
    } elsif (m/:\s*/) { # yaml format
      ($ad,$file) = split(/:\s*/,$_,2);
    }
  } 
  print "! -e $file ($ad)     \r" if (! -e $file);
  next unless -f $file; # only file ...
  next unless -r $file;
  next if -z $file;
  next if $file =~ m,$IPFS_PATH,;
  next if $file =~ m,/.git/objects,;
  next if $file =~ m,/DELETE,;
  next if $file =~ m,/bl?ackhole,;

  my ($ino,$nlink,$size,$ctime,$mtime) = (lstat($file))[1,3,7,9,10];
  if ($size > $s50M) {
    printf LOG "%s: %.3fM too big ! %s\n",$fname,$size/1024/1024,$file;
    next;
  }

  #next if $file =~ m,\.ipfs/,;
  my ($cid,$cidv) = ("\x01\x55",undef);
  my ($fname,$bname) = (&fname($file))[1,2];
  if ($bname =~ m/(?:CIQ|AF[YK])/) {
    $mhash = &decode_base32($bname);
    #printf "mhash: %s \n",unpack('H*',$mhash);
    if (substr($mhash,0,2) eq "\x12\x20") {
      $cidv = 0;
      $cid = "\x01\x70";
      #printf "cid: %s...\n",substr(unpack('H*',$cid.$mhash),0,16);
    } elsif (substr($mhash,0,1) eq "\x01") {
      $cid = substr($mhash,0,2);
      $cidv = 1;
    } else {
      printf "magic4: %s\n",unpack('H8',$mhash);
    }
  }
  if ($ad) {
    printf "%s ($ad)\n",$file;
  } else {
    printf "%s \r",$file;
  }
  my $binshake =  &shake($len,$file);
  next unless $binshake;
  if ($cidv == 0 || $cidv == 1) {
    $mhash = $cid."\x19".&varint($len/8).$binshake;
  } else {
    $mhash = "\x01\x55\x19".&varint($len/8).$binshake;
  }
  #printf "info: mh16=f%s\n",unpack'H*',$mhash;
  my $sk32 = &encode_base32($mhash);
  my $shard = substr($sk32,-3,2);
  my $zfile = sprintf'%s/blocks/%s/%s.data',$IPFS_PATH,$shard,$sk32;
  if (-e $zfile) {
    my ($zino,$znlink,$zctime,$zmtime) = (lstat($zfile))[1,3,9,10];
    next if ($ino == $zino); # same file !
    my $zetime = ($zmtime < $zctime) ? $zmtime : $zctime;
    my $etime = ($mtime < $ctime) ? $mtime : $ctime;

    if ($etime <= $zetime) { # link IPFS file to an early file
       unlink $zfile;
       link $file, $zfile;
       print LOG "ln $file $shard/$sk32.data\n";
    } else {
       if ($nlink < 4) { # if less than 4 inodes : just remove and link the file
         unlink $file;
         print LOG "rm $file\n";
       } elsif ($file =~ m/~+$/) { # already a backup : remove it 
         unlink $file;
         print LOG "rm $file\n";
       } else { # if it is new copy, rename it as a backup !
         print "// ${nlink}x $fname, (but $sk32.data older)\n";
         my $tfile = $file.'~';
            $tfile =~ s/~~$/~/;
         if (-e $file.'~') {
            my ($tino,$tnlink,$tctime,$tmtime) = (lstat($tfile))[1,3,9,10];
            if ($etime > $tfile) { # keep newest backup !
               unlink $tfile;
               rename $file, $tfile;
               print LOG "mv $file $tfile\n";
            }
         } else {
           rename $file, $tfile;
           print LOG "mv $file $tfile\n";
         }
       }
       if (! -e $file) {
       link $zfile, $file or die "failed: ln $zfile $file; # $!";
       print "${green}$sk32${nc} -> $file)\n";
       print LOG "ln $shard/$sk32.data $file\n";
       } else {
       print "-e $file : ${red}$sk32${nc}\n";
       print LOG "test -e $file\n";
       }
    } 

  } else { # create a ipfs file in $IPFS_PATH
    #print "! -e $zfile\n";
       mkdir "$IPFS_PATH/blocks/$shard" unless -d "$IPFS_PATH/blocks/$shard";
       link $file, $zfile;
       print LOG "ln $file $shard/$sk32.data\n";
       if ($ad) {
          print "$shard/$sk32.data: $fname ($ad)\n";
       } else {
          print "$shard/$sk32.data: $fname\n";
       }
  }

}
close LOG;

exit $?;

# -----------------------------------------------------
sub fname { # extract filename etc...
  my $f = shift;
  $f =~ s,\\,/,g; # *nix style !
  my $s = rindex($f,'/');
  my $fpath = '.';
  if ($s > 0) {
    $fpath = substr($f,0,$s);
  } else {
    use Cwd;
    $fpath = Cwd::getcwd();
  }
  my $file = substr($f,$s+1);

  if (-d $f) {
    return ($fpath,$file);
  } else {
  my $p = rindex($file,'.');
  my $bname = ($p>0) ? substr($file,0,$p) : $file;
  my $ext = lc substr($file,$p+1);
     $ext =~ s/\~$//;

  $bname =~ s/\s+\(\d+\)$//; # remove (1) in names ...

  return ($fpath,$file,$bname,$ext);

  }
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
sub shake {
  my $len = shift;
  use Crypt::Digest::SHAKE;
  local *F; open F,$_[0] or do { warn qq{"$_[0]": $!}; return undef };
  #binmode F unless $_[0] =~ m/\.txt/;
  my $msg = Crypt::Digest::SHAKE->new(256);
  $msg->addfile(*F);
  my $digest = $msg->done($len/8);
  return $digest;
}
# -----------------------------------------------------
sub encode_base32 {
  use MIME::Base32 qw();
  my $mh32 = uc MIME::Base32::encode($_[0]);
  return $mh32;
}
# -----------------------------------------------------
sub decode_base32 {
  use MIME::Base32 qw();
  my $bin = MIME::Base32::decode($_[0]);
  return $bin;
}
# -----------------------------------------------------
sub hdate { # return HTTP date (RFC-1123, RFC-2822) 
  my ($time,$delta) = @_;
  my $stamp = $time+$delta;
  my $tic = int($stamp);
  #my $ms = ($stamp - $tic)*1000;
  my $DoW = [qw( Sun Mon Tue Wed Thu Fri Sat )];
  my $MoY = [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )];
  my ($sec,$min,$hour,$mday,$mon,$yy,$wday) = (gmtime($tic))[0..6];
  my ($yr4,$yr2) =($yy+1900,$yy%100);

  # Mon, 01 Jan 2010 00:00:00 GMT
  my $date = sprintf '%3s, %02d %3s %04u %02u:%02u:%02u GMT',
             $DoW->[$wday],$mday,$MoY->[$mon],$yr4, $hour,$min,$sec;
  return $date;
}
# -----------------------------------------------------


1; # $Source: /my/perl/scripts/ddup.pl $

