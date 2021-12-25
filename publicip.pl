#!/usr/bin/perl
# $Id: publicip.pl,v 0.0 2018/04/08 07:23:57 michelc Exp $
#BEGIN { $SITE=$ENV{SITE}; push @INC,$SITE.'\lib' }
#
#
# TODO: rework broken part of the file...

use strict;
# $ENV{TZ} = 'PST8PDT';
my $qmDICT = 'QmT3CaqFDZWQb2aNYCHMRQYLVEHS2Z5huDFQBoTYnHoSm8';

my $what = shift;

my $nip;
my $dotip;
my $pubip;
my $dynip;

if ($what eq 'pubip') {
   $pubip = &get_publicip();
   print $pubip,"\n";
   $nip = unpack'N',pack'C4',split('\.',$pubip);
   exit $nip;
} elsif ($what eq 'dynip') {
   $dynip = &get_arecord('iphs.duckdns.org');
   print $dynip,"\n";
   $nip = unpack'N',pack'C4',split('\.',$dynip);
   exit $nip;
} elsif ($what eq 'locip') {
   $dotip = &get_localip();
   print $dotip,"\n";
   $nip = unpack'N',pack'C4',split('\.',$dotip);
   exit $nip;
} else {
   $dotip = &get_localip();
   $pubip = &get_publicip();
   $dynip = &get_arecord('iphs.duckdns.org');
}


my $ip;
if ($pubip eq '127.0.0.1' || $pubip eq '0.0.0.0') {
 $ip = $dynip;
 $nip = unpack'N',pack'C4',split('\.',$dynip);
} else {
 $ip = $pubip;
 $nip = unpack'N',pack'C4',split('\.',$pubip);
}
use Proquint qw(uint32proquint);
my $quint = &uint32proquint($nip);
my $piglat = $quint;
$piglat =~ s/\b(qu|[cgpstw]h # First syllable, including digraphs
           |[^\W0-9_aeiou])  # Unless it begins with a vowel or number
           ?([a-z]+)/        # Store the rest of the word in a variable
           $1?"$2$1ay"       # move the first syllable and add -ay
           :"$2way"          # unless it should get -way instead 
           /iegx;

my ($city,$country,$continent) = &get_city($nip);

print "--- # publicip\n";
printf "ip: %s\n",$ip;
printf "nip: %x\n",$nip;
print "dynip: $dynip\n";
print "pubip: $pubip\n";
print "city: $city, $country ($continent)\n";
print "quint: $quint\n";
print "piglat: $piglat\n";
print "dotip: $dotip\n";


# posting it ...
my $publicipfile = $ENV{WWW}.'/log/publicip.yml';
open F,'>>',$publicipfile;
print F "- ",$pubip,"\n";
close F;
if (system "which odrive 1>/dev/null 2>&1") {
system "odrive refresh $publicipfile > /dev/null";
}
my $cityfile = $ENV{WWW}.'/log/city.log';
open F,'>>',$cityfile;
printf F "%u: %s,%s\n",$^T,$city,$country;
close F;

# sightseeing:
$country =~ s/ +/+/g;
$city =~ s/ /%20/g;
printf "url: %s?q=sightseeing+near+%s,+%s\n",'https://www.google.com/search',$city,$country;
printf "url: %s?q=%s,+%s\n",'https://www.bing.com/search',$city,$country;
printf "url: %s?q=%s,+%s\n",'https://www.facebook.com/search/top/',$city,$country;

exit;

if (1) {
# host detection
my $bip = pack'C4',split(/\./,$dotip);
my $host = (gethostbyaddr($bip,2))[0];
#  $host = 'ocean';
my ($hname,$aliases,$addrtype,$length,@addrs) = gethostbyname($host);
   printf "X-Host: %s\n",$host;
   printf "X-HName: %s\n",$hname;
   printf "X-Aliases: %s\n",$aliases;
   printf "X-addrtype:%s\n",$addrtype;
   for (0 .. $length-1) {
      printf "X-addr-%u: %u.%u.%u.%u\n",$_,unpack('C4',$addrs[$_]);
   }
}
# ---------------------------------------------------------
my $ip = $ENV{REMOTE_ADDR};
my $tic= time;
printf "Server: &lt;%s\@%s&gt\n",$ENV{USER},$dotip;
print "From: &lt;michelcombes\@advancementofcivilizationeffort.org&gt; Michel Combes\n";
print "Subject: find out what is your IP-address\n";
printf "Date: %s\n",hdate($tic);
printf "IP-Address: %s\n",$ip;
print "</pre>\n";
# ---------------------------------------------------------
exit $?;

# ---------------------------------------------------------
sub hdate { # return HTTP date (RFC-1123, RFC-2822) 
  my $DoW = [qw( Sun Mon Tue Wed Thu Fri Sat )];
  my $MoY = [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )];
  my ($sec,$min,$hour,$mday,$mon,$yy,$wday) = (gmtime($_[0]))[0..6];
  my ($yr4,$yr2) =($yy+1900,$yy%100);
  # Mon, 01 Jan 2010 00:00:00 GMT

  my $date = sprintf '%3s, %02d %3s %04u %02u:%02u:%02u GMT',
             $DoW->[$wday],$mday,$MoY->[$mon],$yr4, $hour,$min,$sec;
  return $date;
}
# ---------------------------------------------------------
sub get_localip {
    use IO::Socket::INET qw();
    # making a connectionto a.root-servers.net

    # A side-effect of making a socket connection is that our IP address
    # is available from the 'sockhost' method
    my $socket = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => '198.41.0.4', # a.root-servers.net
        PeerPort    => '53', # DNS
    );

    my $local_ip = (defined $socket) ? $socket->sockhost : '127.0.0.1';

    return $local_ip;
}
# ---------------------------------------------------------
sub get_arecord {
   my $domain = shift;
   use Net::DNS;
   my $res = Net::DNS::Resolver->new();
   my $a_query = $res->search($domain);
   my $aip;
  
   #print "Website IP Address (A Record)...\n";
   if ($a_query) {
      foreach my $rr ($a_query->answer) {
          next unless $rr->type eq "A";
          #print $rr->address, "\n";
          $aip = $rr->address;
      }
  } else {
      warn "Unable to obtain A record for your website: ", $res->errorstring, "\n";
  }
  return $aip;

}
# ---------------------------------------------------------
sub get_publicip {
  use LWP::UserAgent qw();
  my $ua = LWP::UserAgent->new();
  my $url = 'http://iph.heliohost.org/cgi-bin/remote_addr.pl';
  $ua->timeout(3);
  my $resp = $ua->get($url);
  if ($resp->is_success) {
  my $content = $resp->decoded_content;
  $ip = (split("\n",$content))[0];
  } else{
   $ip = '0.0.0.0';
  }
  return $ip;

}
sub get_publicip2 {
 use LWP::UserAgent qw();
  my $ua = LWP::UserAgent->new();
  my $url = 'http://iglake.heliohost.org/cgi-bin/ip.pl?fmt=yaml';
  if (0) {
     $url = 'http://127.0.0.1:8088/cgi-bin/ip.pl?fmt=yaml';
     my ($user,$pass) = split':',&get_auth('127.0.0.1:8088', 'civet','michelc');
     $ua->credentials('127.0.0.1:8088', 'civet', $user,$pass);
  }
  $ua->timeout(7);
  my $resp = $ua->get($url);
  my $ip;
  if ($resp->is_success) {
    my $content = $resp->decoded_content;
    use YAML::Syck qw();
    my $yml = &YAML::Syck::Load($content);
    $ip = $yml->{ipaddr};
  } else {
    print STDERR $resp->status_line;
    my $content = $resp->decoded_content;
    $ip = '127.0.0.1';
  }
  return $ip;
}
# ---------------------------------------------------------

sub get_city {
  my $i = shift;
  my $list = [];
  my ($contidb,$cntrydb);
  use YAML::Syck qw(Load);
  if (defined $qmDICT) {
    my $buf = &get_ipfs_content("/ipfs/$qmDICT/cities23461.txt");
      if (ref($buf) eq 'HASH' || $buf eq '') {
        return undef;
      }
      @$list = grep !/^#/, split("\n",$buf);

     $buf = &get_ipfs_content("/ipfs/$qmDICT/conti.yml");
     $contidb = Load($buf);
     $buf = &get_ipfs_content("/ipfs/$qmDICT/country.yml");
     $cntrydb = Load($buf);

  } else {
     my $secdir = $ENV{SECTDIR} || $ENV{HOME};
     my $file = $secdir.'/etc/cities23461.txt';
     local *F; open F,'<',$file or die $!;
     local $/ = "\n"; @$list = map { chomp($_); $_ } grep !/^#/, <F>;
     close F;
     my $etc = $secdir.'/etc';
     $contidb = YAML::Syck::LoadFile("$etc/conti.yml");
     $cntrydb = YAML::Syck::LoadFile("$etc/country.yml");
  }
  my $size = scalar @$list;
  my ($city,$cntry) = split'/',$list->[$i%$size];
  my ($country,$conti) = split/;\s*/,$cntrydb->{$cntry};
  my $continent = $contidb->{$conti};
  return ($city, $country, $continent);
}

sub decode_base64m {
  use MIME::Base64 qw();
  my $bin = MIME::Base64::decode_base64($_[0]);
  return $bin;
}

sub get_auth {
   my ($host,$realm,$user) = @_;
   my $clearf = $ENV{HOME}.'/.ssh/cleartext.sec';
   return 'YW5vOm55bW91cw' unless -f $clearf;
   local *F; open F,'<',$clearf;
   while (<F>) { 
     chomp($_);
     if (m/^l/) {
        my ($auth,$h) = split'@',&decode_base63(substr($_,1)),2;
        next if $h ne $host;
        my ($u,$p,$r) = split':',$auth,3;
        next if $r ne $realm;
        next if $u ne $user;
        return &encode_base64m("$u:$p");
     }
     
   }
   close F;
   return 'YWRtaW46cGFzc3dvcmQ';

}

sub encode_base64m {
  use MIME::Base64 qw();
  my $m64 = MIME::Base64::encode_base64($_[0],'');
  return $m64;
}
  
sub decode_base63 {
  return &decode_basen($_[0],63);
} 

sub decode_basen { # n < 94
  use Math::BigInt;
  my ($s,$radix) = @_;
  my $alphab = &alphab($radix);;
  die "alphab: %uc < %d\n",length($alphab) if (length($alphab) < $radix);
  my $n = Math::BigInt->new(0);
  my $j = Math::BigInt->new(1);
  while($s ne '') {
    my $c = substr($s,-1,1,''); # consume chr from the end !
    my $i = index($alphab,$c);
    return '' if ($i < 0);
    my $w = $j->copy();
    $w->bmul($i);
    $n->badd($w);
    $j->bmul($radix);
  }
  my $h = $n->as_hex();
  # byte alignment ...
  my $d = int( (length($h)+1-2)/2 ) * 2;
  $h = substr('0' x $d . substr($h,2),-$d);
  return pack('H*',$h);
}

sub alphab {
  my $radix = shift;
  my $alphab;
  if ($radix < 12) {
    $alphab = '0123456789-';
  } elsif ($radix <= 16) {
    $alphab = '0123456789ABCDEF';
  } elsif ($radix <= 26) {
    $alphab = 'ABCDEFGHiJKLMNoPQRSTUVWXYZ';
  } elsif ($radix == 32) {
    $alphab = '0123456789ABCDEFGHiJKLMNoPQRSTUV'; # Triacontakaidecimal
    $alphab = join('',('A' .. 'Z', '2' .. '7')); # RFC 4648
    $alphab = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; # Crockfordś ![ILOU] (U:accidental obscenity)
    $alphab = 'ybndrfg8ejkmcpqxotluwisza345h769';  # z-base32 ![0lv2]

  } elsif ($radix == 36) {
    $alphab = 'ABCDEFGHiJKLMNoPQRSTUVWXYZ0123456789'; 
  } elsif ($radix <= 37) {
    $alphab = '0123456789ABCDEFGHiJKLMNoPQRSTUVWXYZ.'; 
  } elsif ($radix == 43) {
    $alphab = 'ABCDEFGHiJKLMNoPQRSTUVWXYZ0123456789 -+.$%*';
  } elsif ($radix == 58) {
    $alphab = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  } else { # n < 94
    $alphab = '-0123456789'. 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
                             'abcdefghijklmnopqrstuwvxyz'.
             q/+.@$%_,~`'=;!^[]{}()#&/.      '<>:"/\\|?*'; #
  } 
  # printf "// alphabet: %s (%uc)\n",$alphab,length($alphab);
  return $alphab;
}

# -----------------------------------------------------------------------
sub get_ipfs_content {
  my $ipath=shift;
  use LWP::UserAgent qw();
  my ($gwhost,$gwport) = &get_gwhostport();
  my $proto = ($gwport == 443) ? 'https' : 'http';
  my $url = sprintf'%s://%s:%s%s',$proto,$gwhost,$gwport,$ipath;
  printf "url: %s\n",$url if $::dbug;
  my $ua = LWP::UserAgent->new();
  my $resp = $ua->get($url);
  if ($resp->is_success) {
    my $content = $resp->decoded_content;
    return $content;
  } else {
    return undef;
  }
}
# -----------------------------------------------------------------------
sub get_gwhostport {
  my $IPFS_PATH = $ENV{IPFS_PATH} || $ENV{HOME}.'/.ipfs';
  my $conff = $IPFS_PATH . '/config';
  local *CFG; open CFG,'<',$conff or warn $!;
  local $/ = undef; my $buf = <CFG>; close CFG;
  use JSON qw(decode_json);
  my $json = decode_json($buf);
  my $gwaddr = $json->{Addresses}{Gateway};
  my (undef,undef,$gwhost,undef,$gwport) = split'/',$gwaddr,5;
      $gwhost = '127.0.0.1' if ($gwhost eq '0.0.0.0');
  my $url = sprintf'http://%s:%s/ipfs/zz38RTafUtxY',$gwhost,$gwport;
  my $ua = LWP::UserAgent->new();
  my $resp = $ua->get($url);
  if ($resp->is_success) {
    return ($gwhost,$gwport);
  } else {
    return ('ipfs.blockringtm.ml',443);
  }
}
# -----------------------------------------------------------------------
1; # vim: ts=2 sw=3 et ai ff=unix
