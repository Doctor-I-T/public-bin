#!/usr/bin/perl
# $Id: stamp.pl,v 1.7 2006/11/08 05:11:16 michel Exp $
BEGIN { $SITE=$ENV{SITE}; push @INC,$SITE.'\lib'; }
# --
# ww 330q @(#) SPG : 14-Jan-99 (MGCO) 18:56:17 - WW3 [q]
#
my $_1yr = 8765.81277; # hours in a year (~ 365.25 * 24 = 8766)
my $_1mo = 8765.81277/12;
my $_1d = 8765.81277/365.25; # hours in a year (~ 365.25 * 24 = 8766)

my %birthday = ( 'epoch' => 0,
	'me' => 2250300-3600*$_1yr,
	'collen' => 10845660-3600*$_1yr, # 5/06/1969 @ ??:00

	'seraphina' => 1171338900, # 2/12/2007 @ 19:55
	'sebastien' => 1240603500, # 4/24/2009 @ 13:05
	'1striage' => 1154901600, # 8/06/2006 @ 15:00
	'sabrina' => 128642400, # 1/28/1974 @ 14:00


);

# -------------------------------------------------------
# User Identification ...
$uid = $>;
if (-e '/dev/null') {
$user = (getpwuid($uid))[0] || $uid;
$gecos = (getpwuid($uid))[6] || $uid;
} else {
$user = lc($ENV{USERNAME}) || $uid;
$gecos = uc(substr($user,0,2));
}
($fullname= $gecos) =~ s/,([^,]*).*$//;
$dpt = $1;
@org = split(' ',$dpt);
$ORG = $org[1] . $org[2] || 'GQU';
my ($fname,$mname,$lname) = split(' ',$fullname,3);
if (! defined $lname) {
  $lname = $mname; $mname = 'G.';
}
my $sname = $lname; $sname =~ y/aeiou//d;
my $MSGID = uc substr(substr($fname,0,1) . substr($mname,0,1) . $sname,0,4);
# -------------------------------------------------------

# -- Options parsing ...
while (@ARGV && $ARGV[0] =~ m/^-/)
{
    $arg = shift(@ARGV);

    $quiet = 1,       next if $arg =~ m/^-[qs]$/;
    $what = $1 ? "$1" : shift || 'name', next if $arg =~ m/^--?w(?:hat)?+(\w+)?$/;
    $human = 1,       next if $arg =~ m/^-d$/;
    $mail = 1,        next if $arg =~ m/^-m(?:ail)?$/;
    $log = 1,        next if $arg =~ m/^-l(?:og)?$/;
    $release = 1,    next if $arg =~ m/^--?r(?:el(?:ease)?)?$/i;
    $ident = 1,      next if $arg =~ m/^--?ident$/i;
    $id = 1,         next if $arg =~ m/^-i(?:d)?$/i;
    $rcs = $1 ? "$1" : shift || 'file.txt', next if $arg =~ m/^--?r(?:cs)?+(\.*)?$/;
    $cvs = 1,        next if $arg =~ m/^--?c(?:vs)?$/;
    $http = 1,        next if $arg =~ m/^-h(?:ttp|tml?)?$/;
    $tag= $1 ? "t$1" : shift || 'tag', next if $arg =~ m/^-t(\w+)?$/;
    $touch = 1,       next if $arg =~ m/^--?u(?:time)?$/;
    $touch = 1,       next if $arg =~ m/^--?to(?:uch)?$/;
    $event = $1 ? $1 : shift || 'me',  next if $arg =~ m/^--?a(?:ge)?+(\w+)?$/;
    $usage = 1,       next if $arg =~ m/^--?h(?:elp)?$/;

}
#understand variable=value on the command line...
eval "\$$1=$2"while $ARGV[0] =~ /^(\w+)=(.*)/ && shift;
$verbose = ($quiet) ? 0 : 1;

printf "gecos: %s\n",$gecos if $dbug;
print "User: $fullname ($MSGID) $ORG\n" if $dbug;

@DoW = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
@MoY = ('Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec');
use Time::Local qw/timelocal/; # require "timelocal.pl";

if ($tag) { $ENV{TZ} = 'PST8PDT'; }

$tic= time;
($sec,$min,$hour,$mday,$mon,$yy) = (localtime($tic))[0..5];
$mon++;
$year ||= $yy;

if ($#ARGV < 0) {
  affiche($tic);
}
while (@ARGV) {
  $date= shift;
  shift if ($ARGV[0] eq '@');
  if ($ARGV[0] =~ m/\:/) { $time = shift; }
  elsif ($ARGV[0] =~ m/\./) { $time = shift; $time =~ y/./:/;}
  else { $time ||= "$hour:$min:00"; }
  ($hour,$min,$sec) = split ':', $time;

  printf "%s at $time ?\n", $date if $dbug;
  if ($date =~ m|/|) { # date of form 07/28/97 (US style)
     ($mon,$mday,$year) = split '/', $date;
     if ($mon > 12) {
        if ($year > 31) { # date of form 28/7/1997 (FR style)
          ($mday,$mon,$year) = split '/', $date;
        } else { # date of form 1997/7/28 (EU style)
          ($year,$mon,$mday) = split '/', $date;
        }
     }
     $year ||= $yy;
     $tic= timelocal($sec,$min,$hour,$mday,$mon-1,$year);
  }
  elsif ($date =~ m|\.|) { # date of form 28.07.97 (Swiss style)
     ($mday,$mon,$year) = split '\.', $date;
     if ($mon > 12) { # date of form 7.28.97 (US style)
        ($mon,$mday,$year) = split '\.', $date;
     }
     $year ||= $yy;
     $year += 100 if ($year < $yy);
     #$yr4 = $year + 1900 if ($year < 70);
     $tic= timelocal($sec,$min,$hour,$mday,$mon-1,$year);
  }
  elsif ($date =~ m|\d-\d|) { # date of form 2020-04-15 03:56:24
    ($year,$mon,$mday) = split '-', $date;
    $tic= timelocal($sec,$min,$hour,$mday,$mon-1,$year);
  }
  elsif ($date =~ /^W*H(\d+.*)/) {
    eval "\$yhour=$1";
    if ($yhour != int($yhour)) { $sec = 0; $min = 0; }
    $tic= $yhour * 3600 + timelocal($sec,$min,0,1,0,$year);
  }
  elsif ($date =~ /^W*D(\d+.*)/) {
    eval "\$yday=$1 - 1";
    $tic= $yday * 24 * 3600 + timelocal($sec,$min,$hour,1,0,$year);
  }
  elsif ($date =~ /W+(\d+.*)/) {
    eval "\$yweek=$1 - 1";
    $tic= $ week * 7 * 24 * 3600 + timelocal($sec,$min,$hour,1,0,$year);
  }
  elsif ($date =~ /W*M(\d+.*)/) {
    eval "\$mon=$1 - 1";
    $tic= timelocal($sec,$min,$hour,1,$mon,$year);
  }
  elsif ($date =~ /(\d{4})\.(\d{2})\.(\d{2})\.(\d{2})\.(\d{2})\.(\d{2})/) {
    ($year,$mon,$mday,$hour,$min,$sec) = ($1,$2,$3,$4,$5,$6);
    $tic= timegm($sec,$min,$hour,$mday,$mon-1,$year);
  } else {
    eval "\$tic= $date";
  }
  affiche($tic);
}

sub affiche {
  my $time=$_[0];
  my $sec = $min = 0.0;

  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
   $yhour = $yday * 24 + $hour + ($min / 60 + $sec / 3600);
   $yweek=$yday/7;
   my $dim = ($mon>10) ? 31 : # days in month
             (localtime(timelocal(0,0,0,1,$mon+1,$year) - 24*3600) )[3];
   my $period = $dim * 24; # 8765.81277 / 12;
   $rev_id = int($yweek) <<2;
   $low_id = int(($wday+($hour/24)+$min/(24*60))*4/6); # frequency : 4/6
   my $revision = ($rev_id + $low_id) / 100;
   my $version = sprintf '%.1f.%d',int($rev_id/10)/10,$rev_id%10+$low_id;
  if ($tag =~ /t(\d+)$/o) {
    $f=int(0.99999-log($1/3600)/log(10));
    $d=4+$f+1;
    #printf "dbug> $d $f\n";
    printf "%0$d.0${f}f\n",
         $yday * 24 + $hour + ($min / 60 + $sec / 3600),
  } elsif ($tag =~ /(?:pof|rel)/io) {
    printf "%02x\n",$rev_id + $low_id;
  } elsif ($tag =~ /week/io) {
    printf "WW%02d.%s\n",
         $yweek+1,
         chr(ord('A')+$low_id);
  } elsif ($tag =~ /id/io) {
    my $tod = ($time-1)%(24*3600); # time of the day
    my $d16 = int( ($time-1)/(24*3600) ) & 0xFFFF; # 16-bit date
    my $mstamp = int( ($yhour/$period - int($yhour/$period) ) * 10000);
    my $hstamp = sprintf '%03.1f',$yhour; $hstamp =~ tr/\./H/;
    printf "%u 0x%08X tod:%5u d16:%4X\n",$time,$time,$tod,$d16;
    printf "S-%-4s ID%02d-%-5s M%03u WW%02d.%s (%03X on %04X)\n",
         &base36(int($yhour/$_1yr * 36**4)), # 18 sec accuracy
         $year%100,
         $hstamp, # 6 min. accuracy
	 $mstamp, # 45 min. accuracy
         $yweek+1,
         chr(ord('A')+$low_id), # 16hr accuracy
         &thash($time),&hday($time);

  } elsif ($tag =~ /txn/io) {
   # Dave's special tag ...
   $pday0 = 292 -1;                # initial week for cm
   $pday1 = 320 -1;                # change of release pace !
   $pday2 = 375;                   # 1st Mon of 1999
   $PGday = 30+365;                # PG Date ...
   $pday = $yday;
   $pday += 365 if ($pday < $pday0);
   #----------------------------------------------------------
   if ($pday <= $pday1) {
     $rday = ($pday-$pday0)%7;
     $rel = int(($pday-$pday0)/7);
   } elsif ($pday <= $pday2) {
     $rday = ($pday-$pday1)%14;
     $rel = int(($pday-$pday1)/14) + int(($pday1-$pday0)/7);
   } elsif ($pday <= $PGday) {
     $rday = ($pday-$pday2)%7;
     $rel = int(($pday-$pday2)/7) + int(($pday2-$pday1)/14) + int(($pday1-$pday0)/7);
   } else {
     $rday = $pday-$PGday;
     $rel = int(($PGday-$pday2)/7) + int(($pday2-$pday1)/14) + int(($pday1-$pday0)/7);
   }
#  printf "pday = %d, %d :  rel=%d\n",$pday,$pday-$pday2,int(($pday-$pday2)/7) + int(($pday2-$pday1)/14) + int(($pday1-$pday0)/7);;
   #----------------------------------------------------------
    if ($rday == 0) { 
      printf "0.%d.0\n",$rel
    } elsif ($human) {
      printf "0.%d.%d_%02d%02d%02d\n",
             $rel,
             $rday,
             $year,$mon+1,$mday;
    } else {
      printf "0.%d.%04d\n",$rel,$yday * 24 + $hour;
    }
  } elsif ($tag) {
    printf "%6.01f %5.2f%%\n",
         $yhour,           # 5 digit: 6 minutes accuracy
	 100*$yhour/$_1yr, # 5 digit: 5 minutes 15 seconds
	                   # 4 digit: 52 minutes, 3 digit: 8hr 46min
	 ;
  } elsif ($event) {
    $birth = $birthday{$event} || $birthday{epoch};
    my $age = ($time - $birth)/3600;
    printf "%s: %08u; %02d days, %02d months, %.2fyo\n",$event,$time - $birth,
           $age / $_1d, $age / $_1mo, $age/$_1yr;
  } elsif ($touch) { # [[CC]YY]MMDDhhmm[.ss]
    printf "touch -t %02d%02d%02d%02d%02d.%02d\n",
         $year%100,$mon+1,$mday,$hour,$min,$sec;
  } elsif ($http) {
    printf "%3s %2d %02d:%02d %3s %4d\n",
           $DoW[$wday],$MoY[$mon],$mday,$hour,$min,$ENV{'TZ'},
           ($year < 70) ? $year + 2000 : $year + 1900;
  } elsif ($mail) {
    printf "From %s %3s %3s %2d %02d:%02d %3s %4d\n",
         'myself', $DoW[$wday],$MoY[$mon],$mday,$hour,$min,$ENV{'TZ'},
         ($year < 70) ? $year + 2000 : $year + 1900;
    printf "Date: %3s %3s %2d %02d:%02d %3s %4d\n",
         $DoW[$wday],$MoY[$mon],$mday,$hour,$min,$ENV{TZ},$year+1900;
  } elsif ($log) {
    printf "M4GC:%08X\t%4d.%02d.%02d.%02d.%02d.%02d\n",$time,
       $year+1900,$mon+1,$mday,$hour,$min,$sec;
  } elsif ($release) {
       my $_1yrs = 365.25 * 24 * 3600;
       my $birth = 1630501740; # D244 15:09 Sep,1  - W35
       my $age = ( $time - $birth ) / (1641392221 - $birth); # using 'late-time'
       my $rweek=($yday+&fdow($time))/7;
       my $rel_id = int($rweek) * 4;
       my $low_id = int(($wday+($hour/24)+$min/(24*60))*4/7);
       my $revision = ($rev_id + $low_id) / 100;
       my $major = $rel_id;
       my $rev = $low_id;
       printf 'v%d.%.1f.%d',int($age),int($major/10)/10,$major%10+$rev;

  } elsif ($cvs) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
    printf "date\t%4d.%02d.%02d.%02d.%02d.%02d\n",
       $year+1900,$mon+1,$mday,$hour,$min,$sec;
    printf "commitid\t%04x%08x%04x\n",$$,$time,int rand(0x10000);
  } elsif ($ident) {
    my $fullname = "Michel C.";
    my $gecos = 'z...'; # TBD
    my $user = $ENV{USER};
    my $domain = 'eottm.ml';
    my $TZ = $ENV{TZ}; ## TODO extract TZ from system
    printf "%s (%s) <%s@%s> %u %s\n",$fullname,$gecos,$user,$domain,$tic,$TZ;
  } elsif ($id) {
    printf "ID:%4s\n",
         &base36(int($yhour/$_1yr * 36**4)), # 18 sec accuracy
  } elsif ($rcs) {
    printf qq'# \$Id: %s,v %s %-4d-%d-%02d %-2d:%02d:%02d %s Exp \$\n',
     $rcs, $version,$year+1900,$mon+1,$mday,$hour,$min,$sec,$ENV{USER};
  } elsif ($what) {
    printf "# %s %d%s @(%s) %s : %-02d-%s-%02d (%s) %-2d:%02d:%02d - WW%2d [%s]\n",
     $what,$yhour, chr(ord('a')+$low_id),'#',$ORG,
     $mday,$MoY[$mon],$year%100,$MSGID,
     $hour,$min,$sec,
     $yweek+1,chr(ord('a')+$low_id)
  } else {
  printf "WH%-7.02f WD%5.01f WW%02d.%s WM%02d S-%s M%04u 0x%02X\n",
         $yhour,
         $yday+1 + ($hour + (($min + $sec / 60) / 60 )) / 24,
         $yweek+1,
         chr(ord('a')+$low_id),
         $mon+1,
         &base36(int($yhour/$_1yr * 36**4)), # 18 sec accuracy
         int( ($yhour/$dim/24 - int($yhour/$dim/24) ) * 10000),
         $rev_id + $low_id unless $human;
  printf "%s %2d/%02d/%02d : %d,%X (D%-3d %2d:%02d %3s,%-2d - W%-2d)\n",
         $DoW[$wday],
         $mon+1,$mday,$year%100, 
         $time, $time, $yday+1, $hour,$min,
         $MoY[$mon],$mday,
         $yweek+1 if $verbose;
  }
}

#print "PROMPT= $ENV{PROMPT}\n" if exists $ENV{PROMPT};
sub base36 {
  use integer;
  my ($n) = @_;
  my $e = '';
  return('0') if $n == 0;
  while ( $n ) {
    my $c = $n % 36;
    $e .=  ($c<=9)? $c : chr(0x37 + $c); # 0x37: upercase, 0x57: lowercase
    $n = int $n / 36;
  }
  return scalar reverse $e;
}

sub thash { # 12-bit time hash (period 1hr 8min)
  my ($tic) = @_;
  my $tod = ($tic-1)%(24*3600); # 16.4-bit time of the day
  use Digest::MurmurHash; # Austin Appleby (Murmur 32-bit)
  my $digest = Digest::MurmurHash::murmur_hash(pack'N',$tod);
  return  ($digest ^ ($digest>>10) ^ ($digest>>20)) & 0xFFF; # 12-bit
}

sub hday { # hash of the day
  my ($tic) = @_;
  my $day = int ( ($tic-1)/(24*3600) ); # 16-bit date
  use Digest::MurmurHash; # Austin Appleby (Murmur 32-bit)
  my $digest = Digest::MurmurHash::murmur_hash(pack'N',$day);
  return ($digest>>16 ^ $digest) & 0xFFFF; # period ; 179yr
  #return  ($digest ^ ($digest>>10) ^ ($digest>>20)) & 0xFFF; # period 11yr
  
}

sub fdow { # first day of first week (WW01)...
   my $tic = shift;
   use Time::Local qw(timelocal);
   ##     0    1     2    3    4     5     6     7
   #y ($sec,$min,$hour,$day,$mon,$year,$wday,$yday)
   my $year = (localtime($tic))[5]; my $yr4 = 1900 + $year ;
   my $first = timelocal(0,0,0,1,0,$yr4);
   $fdow = (localtime($first))[6];
   #printf "1st: %s -> fdow: %s\n",&hdate($first),$fdow;
   return $fdow;
}



do{$|=1;print "Press any key to continue ...";local$_=<STDIN>} unless defined $ENV{SHLVL} ;
exit $?;

1;
