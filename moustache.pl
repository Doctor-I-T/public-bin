#!/usr/bin/perl
# $Id: moustache.pl,v 1.0 2020-05-21  9:43:16 michelc Exp $
#-------------------------------------------------------
#-- Michel G. Combes                                  --
#--                                                   --
#-- All contents copyright (C) 2018, 2019, 2020       --
#-- All rights reserved                               --
#-- contact: michelc@michelium.ml                     --
#--                                                   --
#-------------------------------------------------------

# moustache 3645a @(#) MYC : 31-May-20 (MGCM) 21:12:32 - WW22 [a]
#
# Revision history :
# . 3645~ : streamline the code : split instead of extract
# . 7451~ : re-factored for pmd flow
#
# 1519026565 : Idea of moustashe preprocessor
#
our $dbug = 0;
my ($red,$nc) = ('[31m','[0m');
my @list = ();

my $HOME = $ENV{HOME} || '/home/'.$ENV{USERNAME};
#--------------------------------
# -- Options parsing ...
#
while (@ARGV && $ARGV[0] =~ m/^-/)
{
  $_ = shift;
  #/^-(l|r|i|s)(\d+)/ && (eval "\$$1 = \$2", next);
  if (/^-v(?:erbose)?/) { $verbose= 1; }
  elsif (/^-y([\w.]*)/) { push @list, $1 ? $1 : shift; }
  elsif (/^-o([\w.]*)/) { $outfile= $1 ? $1 : shift; }
  else                  { die "Unrecognized switch: $_\n"; }

}
#understand variable=value on the command line...
eval "\$$1='$2'"while $ARGV[0] =~ /^(\w+)=(.*)/ && shift;

if ($dbug) { eval "use YAML::Syck qw(Dump);" }

# load md file and replace {{.*}}
my $file = shift;
my ($fpath,$fname,$bname,$ext) = &fname($file);
printf "// [INFO]: fpath=%s\n",$fpath if $info;
if (! -e $file && $ext eq '') { # default extension is .mdx
   $ext = 'mdx';
   $fname = $bname . '.' . $ext;
   $file =$fpath . '/' . $bname . '.' . $ext;
}
# -------------------------------------------------
# get qmhash
# echo -n 'qmRCSKeywords' | ipfs add -Q -n
my $qmRCSkeywords = 'QmYEMrpMSbBuZBy3aTabtF14o8vbFoBrWjLHp7X8GndKgo';
my $content = &read_file($file);
   $content =~ s/\$qm: \w+\$/\$qm: $qmRCSkeywords\$/; # remove qm RCSKeyword !
my $qm = &ipfs_api('add',$file,$content)->{'Hash'};
# -------------------------------------------------
# get the destination file name
my $target;
if (defined $outfile) { # passed as -o option
  $target = $outfile;
} elsif ($ARGV[0]) { # passed a second arguments
  $target = $ARGV[0];
} elsif ($ext eq 'md') {
  $target = $file; $target =~ s/\.$ext/.md~/;
} else {
  $target = $file; $target =~ s/\.$ext/.md/;
}
# -------------------------------------------------
# 1) split yaml from data ...
my ($yml,$buf) = &split_yaml_from_data('page',$file);

my $global = {};
$yml->{global} = $global;
$global->{QM} = $qm;
$global->{QMID} = substr($qm,0,7);
$global->{SHORTQM} = substr($qm,0,7).'...'.substr($qm,-6);

if ($dbug) {
my $ymlf = $target; $ymlf =~ s/\.[^\.]+$//; $ymlf .= '.yml.txt';
use YAML::Syck qw(DumpFile); DumpFile($ymlf,$yml);
}

printf "yml: %s.\n",Dump($yml) if $dbug;
# DATE AND TIME
$global->{TICS} = (lstat($file))[9] || $^T;
##     0    1     2     3    4     5     6     7
#y ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday)
my ($mon,$day,$yy) = (localtime($global->{TICS}))[4,3,5];
my $yr4 = $yy + 1900;
my $LMoY = [qw( January February March April May June July August September October November December )];
$global->{DATE} = sprintf"%s %2d, %4d",$LMoY->[$mon],$day,$yr4;
$global->{HDATE} = &hdate($global->{TICS});
$global->{TODAY} = &hdate($^T);
$yml->{time}{PREVMONTH} = $LMoY->[($mon+11) % 12];
$yml->{time}{MONTH} = $LMoY->[$mon];
$yml->{time}{YR4} = $yr4;
$yml->{time}{YR2} = $yy % 100;


# DEFAULT SUBSTITUTION for YML substitution
$global->{WWW} = $ENV{WWW};
$global->{SEARCH} = 'https://seeks.hsbp.org/?language=en&engines=google,duckduckgo,qwant,ixquick,startpage&q';
$global->{SEARX} = 'https://ipfs.gc-bank.tk/ipns/searx.neocities.org/?q';
$global->{SEARXES} = 'https://searxes.danwin1210.me/?lg=en-US&search_this';
$global->{SIMIL} = 'http://www.google.com/searchbyimage?btnG=1&hl=en&image_url';
$global->{GOO} = 'http://google.com/search?bti=1&q';
$global->{DUCK} = 'http://duckduckgo.com/?q'; # <---


$global->{IPROXY} = 'http://ipns.co';

$global->{GW} = 'http://gateway.ipfs.io';
$global->{ZGW} = 'http://0.0.0.0:8080';
$global->{GCGW} = 'http://ipfs.gc-bank.tk';
$global->{'2GGW'} = 'http://ipfs.2gether.cf';
$global->{IPH} = 'http://iph.heliohost.org/IPHS';
$global->{AHE} = 'http://iph.heliohost.org/AHE';

$global->{HELIO} = 'http://iph.heliohost.org';
$global->{IPNS} = 'http://iph.heliohost.org/ipns';
$global->{IMAGES} = 'http://iph.heliohost.org/ipns/images';

$global->{SAVE} = 'https://web.archive.org/save';
$global->{GT} = 'https://translate.google.com/translate?sl=auto&tl=en&js=y&prev=_t&hl=en&ie=UTF-8&u';


# Symbols
$global->{'TM'} = '&trade;';
$global->{'SM'} = '&#8480;';
$global->{'<3'} = '&#9825;';
$global->{':)'} = '&#9786;';

# Redirects
$global->{'URL'} = 'https://www.google.com/url?q';
$global->{'URL'} = 'https://getpocket.com/redirect?url';
$global->{'URL'} = 'https://duck.co/redir/?u=';
$global->{'URL'} = 'https://ad.zanox.com/ppc/?32249347C62314846&ulp=%5B%5B%%s%5D%5D';
$global->{'FB'} = 'https://l.facebook.com/l.php?u=';
$global->{'WB'} = 'https://web.archive.org/web/';


# Maps & charts example :
# https://maps.googleapis.com/maps/api/staticmap?autoscale=2&size=600x300&maptype=roadmap&format=png&visual_refresh=true&markers=icon:https://chart.googleapis.com/chart?chst=d_bubble_icon_text_small%26chld=ski%257Cbb%257cIggy%2520L%257cffffff%257cff0000%7Cshadow:true%7CEcublens,CH
#
# maps : see [1](https://staticmapmaker.com/google/) 
$global->{MAPS} = 'https://maps.googleapis.com/maps/api/staticmap?center=45.0%2c4.0&zoom=5&size=700x500';
# https://maps.googleapis.com/maps/api/staticmap?center=Albany,+NY&zoom=3&scale=2&size=600x300
#   &maptype=roadmap&format=png&visual_refresh=true
#    &markers=size:mid%7Ccolor:0xff0000%7Clabel:1%7CAlbany,+NY
#    &markers=size:small%7Ccolor:0x2700ff%7Clabel:2%7C2nd+marker
# pins (?=%3F, &=%26, #=%23 %=%25 @=%40 "=%22 '=%27 |=%7C
# https://chart.googleapis.com/chart?chst=d_bubble_icon_text_small&chld=
# charts : see [2](https://developers.google.com/chart/infographics/docs/dynamic_icons)
$global->{CHART} = 'https://chart.googleapis.com/chart?cht=qr&chs=222x222&choe=UTF-8&chld=H&chl';

# FAVICONS 
$global->{FAVI} = 'https://www.google.com/s2/favicons?domain';

# 1) run substitution on yml keys too !
foreach my $p (reverse sort keys %{$yml->{page}}) {
   my $v = $yml->{page}{$p};
   #printf "pat: {{page.%s}} = %s \n",$p,$v;
   foreach my $k (keys %{$yml->{page}}) {
      #printf "   key: %s = %s \n",$k,$yml->{page}{$k};
      if ($yml->{page}{$k} =~ m/\{\{page\.$p\}\}/) {
         printf "{{page.%s}} -> %s\n",$p,$v;
         $yml->{page}{$k} =~ s,\{\{page\.$p\}\},$v,g;
      }
   }
}

#printf "yml.page: %s...\n",Dump($yml->{page});

# 2) flatten all include
 $buf = &includes($buf);


# 3) make substitution :
my $c = 0;
my $s = &substi($yml,$buf);
if ($s) {
  $c = $s;
  printf "c:%d (yml)\n",$c;
}

# load include file too ...
if (exists $yml->{moustache}) {
  if (ref $yml->{moustache} eq 'ARRAY') {
    push @list, @{$yml->{moustache}};
    printf "list: %s.\n",join',',@list if $dbug;
  } else {
    push @list, $yml->{moustache};
  }
} else {
  # add yml file if exists ...
  my $ymlf = $file; $ymlf =~ s/\.$ext/.yml/;
  if (-e $ymlf) {
    push @list, $ymlf;
  }

}


  foreach my $y (@list) {
     $y =~ s/\{\{([^}]+)\}\}/$yml->{$1}/g; # do subs on list elements
     while ($y =~ m/\$\{?([^\$]+?)\}?\b/g) {
       my $var = $1;
       #print "y =~ s,\${$var},$ENV{$var},\n";
       $y =~ s,\$\{?$var\}?,$ENV{$var}, if (exists $ENV{$var}); # do env subs too 
     }
     if (-e $y) {
        print " loading $y\n";
        my ($fpath,undef,$bname,$ext) = &fname($y);
            if ($y =~ n/\//) {
              $ns = $y;
              $ns =~ s/.*_//; $ns =~ tr,/,.,;
            } else {
              $ns = 'site.'.$bname;
            }
        my $yml = { $ns => &extract_yml($y) };
        printf "yml: %s.\n",Dump($yml) if $dbug;
        my $s = &substi($yml,$buf);
        if ($s) { 
           $c += $s;
           printf "c:%d (${y}'s)\n",$c;
        }
     } else {
       printf " ! -e %s\n",$y if $dbug;
     }
  }

my $keys = { keys => &get_keylist() };
#foreach (grep !/ID$/, keys %$key) { $keys->{$_.'ID'} = $keys->{$_}; # keyname alias !  }
my $s = &substi($keys,$buf);
if ($s) {
   $c += $s;
   printf "c:%d (keys's)\n",$c;
}

# put back $qm: $
if ($buf =~ m/\$qm: \w+\s?\$/) {
  $buf =~ s/\$qm: \w+\s?\$/\$qm: $qm\$/g; # remove eventual \s (! ident)
}


# 4) write file
if ($file eq $target) { # /!\ DANGEROUS 
   print "// ${red}/!\\${nc} CAUTION $target is rename to $target.out\n";
   $target .= '.out';
}
print "// moustache: -> $target\n";
open *T; open T,'>',$target;
print T $buf;
close T;



exit $?;

# -----------------------------------------------------
sub get_keylist { # TBD to upgrade to ipfs_get_api
   my $keylist = {};
   my $cmd = sprintf 'ipfs key list -l';
   local *EXEC; open EXEC,"$cmd|" or die $!;
   local $/ = "\n";
   while (<EXEC>) {
     chomp();
     my ($mhash,$key) = split(/\s+/,$_);
     $keylist->{$key.'ID'} = $mhash;
   }
   return $keylist;
   
}
# -----------------------------------------------------
sub includes { # flatten {{#include file}} code
  my $data = shift;
  for $mus (split("\}\}",$data)) { # each moustache
    if ($mus =~ m/\{\{#include\s+([^}]+)$/) { #}
      my $incf = $1;
      if (-e $incf) {
        local *F;
        open F,'<',$incf;
        local $/ = undef;
        my $buf = <F>;
        close F;
        $data =~ s/\{\{#include\s+$incf}}/$buf/; # }}
      }
      
    }
 }
 return $data;
}
# -----------------------------------------------------
sub substi { # inplace (buf) substitution ...
  my $yml = shift;
  my $bufref = \$_[0];
  my $c = 0;
  return unless (ref($yml) eq 'HASH');
  foreach my $ns (sort keys %$yml) {
    my $map = $yml->{$ns};
    if (ref($map) eq 'HASH') {
       foreach my $key (reverse sort keys %$map) {
          if ($ns eq 'global') {
            $pat = "$key";
          } else {
            $pat = "$ns\.$key";
          }
          $pat =~ s/-/\\-/g;
          $pat =~ s/([()])/\\$1/g;
          next if (ref $map->{$key} eq 'ARRAY'); # ARRAY not yet supported 
          #printf "ref: %s\n",ref($map->{$key});
          #next unless (ref $map->{$key} eq '');
          my $value = $map->{$key};
          print "{{$pat}} -> $value\n" if ($$bufref =~ m/\{\{$pat\}\}/);
          $c += $$bufref =~ s/\{\{$pat\}\}/$value/g;
       }
    }
  }
  return $c;
}

# -----------------------------------------------------
sub split_yaml_from_data {
   my $ns = shift;
   my $file = shift;
   die "! -e $file" if ! -e $file;
   local *F; open F,'<',$file or die $!;
   local $/ = "\n";
   my $isyml = 0;
   my $yml = '';
   my $buf = '';
   while (<F>) {
      tr/\r//d; # *nix style eol !
      if ($isyml == 1) {
         #if (/^([\w_\-\.]+):/ && defined $ns ) {
         #  $yml .= $ns.'.'.$_;
         #} els
         if (/^[\.\-]{3}$/) {
            $isyml = 0;
         } else {
            $yml .= $_;
         }
      } elsif (m/^---\s(?:#.*)?$/) { # might be buggy when --- inside yml separators...
         $isyml = 1;
         $yml .= $_;
      } else {
         #print "DBUG> $_" if $dbug;
         $buf .= $_;
      }
   }
   close F;

   use YAML::Syck qw(Load Dump);
   my $dump = $file.'.split.yml';
   if ( $yml ne '' ) {
      local *F; open F,'>',$dump;
      print F $yml;
      close F; 
   }
   my $meta = Load($yml);
   if (defined $meta) {
     unlink $dump unless $dbug;
   }
   return ({ $ns => $meta },$buf);
}
# -----------------------------------------------------
sub extract_yml {
   my $file = shift;
   die "! -e $file" if ! -e $file;
   local *F; open F,'<',$file or die $!;
   local $/ = "\n";
   my $isyml = 0;
   my $yml = '';
   while (<F>) {
     tr/\r//d;
      if ($isyml == 1) {
         print "DBUG> $_" if $dbug;
         $yml .= $_;
         if (/^[\.\-]{3}$/) { $isyml = 0; }
      } elsif (m/^---\s(?:#.*)?$/) { # might be buggy when --- inside yml separators...
         $isyml = 1;
      }
   }
   close F;
   $yml =~ s/[\.\-]{3}\r?\n---\s?(?:#[^\n]*)?\r?\n//gs;
   #print "YAML: \"$yml\"\n";
   use YAML::Syck qw(Load Dump);
   my $dump = $file.'.xtr.yml';
   if ( $yml ne '' ) {
      local *F; open F,'>',$dump;
      print F $yml;
      close F; 
   }
   my $data = Load($yml);
   if (defined $data) {
     unlink $dump unless $dbug;
   }
   return $data;
}
# -----------------------------------------------------
sub read_file {
  local *F; open F,'<',$_[0];
  local $/ = undef; my $buf = <F>; close F;
  return $buf;
}
# ---------------
sub write_file {
  my $file = shift;
  local *F; open F,'>',$file;
  foreach (@_) {
    print F $_;
  }
  close F;
}
# -----------------------------------------------------
sub ipfs_api {
   my $api_url;
   my $cmd = shift;
   if ($ENV{HTTP_HOST} =~ m/heliohost/) {
      $api_url = sprintf'https://%s/api/v0/%%s?arg=%%s%%s','ipfs.blockringtm.ml';
   } else {
     my ($apihost,$apiport) = &get_apihostport();
      $api_url = sprintf'http://%s:%s/api/v0/%%s?arg=%%s%%s',$apihost,$apiport;
   }
   my $url;
   my $method = 'get';
   my $data = undef;
   if ($cmd =~ m/(?:add|write)$/) {
      my $filename = shift;
      $data = shift;
      my $opt = join'',@_;
      $url = sprintf $api_url,$cmd,$filename,$opt; # name of type="file"
   } else {
     $url = sprintf $api_url,$cmd,@_; # failed -w flag !
   }
   printf "X-api-url: %s\n",$url if $dbug;
   use LWP::UserAgent qw();
   use MIME::Base64 qw(decode_base64);
   my $ua = LWP::UserAgent->new();
   if ($api_url =~ m/blockringtm\.ml/) {
      my $realm='Restricted Content';
      my $auth64 = &get_auth();
      my ($user,$pass) = split':',&decode_base64($auth64);
      $ua->credentials('ipfs.blockringtm.ml:443', $realm, $user, $pass);
#     printf "X-Creds: %s:%s\n",$ua->credentials('ipfs.blockringtm.ml:443', $realm);
   }
   my $content = '5xx';
   if (defined $data) {
      my $form = [ 'file' => "$data" ];
      $resp = $ua->post($url,$form, 'Content-Type' => "multipart/form-data;boundary=immutable-file-boundary-$$");
   } else {
     $resp = $ua->get($url);
   }
   if ($resp->is_success) {
      printf "X-Status: %s\n",$resp->status_line if $dbug;
      $content = $resp->decoded_content;
   } else { # error ... 
      print "[33m";
      printf "X-api-url: %s\n",$url;
      print "[31m";
      printf "Status: %s\n",$resp->status_line;
      $content = $resp->decoded_content;
      local $/ = "\n";
      chomp($content);
      print "[32m";
      printf "Content: %s\n",$content;
      print "[0m";
   }
   if ($content =~ m/^{/) { # }
      use JSON qw(decode_json);
      my $json = &decode_json($content);
      #printf "json: %s.\n",Dump($json) if $dbug;
      return $json;
   } else { 
      return $content;
   }
}
# -----------------------------------------------------
sub get_apihostport {
  my $IPFS_PATH = $ENV{IPFS_PATH} || $ENV{HOME}.'/.ipfs';
  my $conff = $IPFS_PATH . '/config';
  local *CFG; open CFG,'<',$conff or warn $!;
  local $/ = undef; my $buf = <CFG>; close CFG;
  use JSON qw(decode_json);
  my $json = decode_json($buf);
  my $apiaddr = $json->{Addresses}{API};
  my (undef,undef,$apihost,undef,$apiport) = split'/',$apiaddr,5;
      $apihost = '127.0.0.1' if ($apihost eq '0.0.0.0');
  return ($apihost,$apiport);
}
# -----------------------------------------------------
sub get_auth {
  my $auth = '*';
  my $ASKPASS;
  if (exists $ENV{IPMS_ASKPASS}) {
    $ASKPASS=$ENV{IPMS_ASKPASS}
  } elsif (exists $ENV{SSH_ASKPASS}) {
    $ASKPASS=$ENV{SSH_ASKPASS}
  } elsif (exists $ENV{GIT_ASKPASS}) {
    $ASKPASS=$ENV{GIT_ASKPASS}
  }
  if ($ASKPASS) { 
     use MIME::Base64 qw(encode_base64);
     local *X; open X, sprintf"%s %s %s|",${ASKPASS},'blockRing™';
     local $/ = undef; my $pass = <X>; close X;
     $auth = encode_base64(sprintf('michelc:%s',$pass),'');
     return $auth;
  } elsif (exists $ENV{AUTH}) {
     return $ENV{AUTH};
  } else {
    return 'YW5vbnltb3VzOnBhc3N3b3JkCg==';
  }
}
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
# -----------------------------------------------------
1; # $Source: /my/perl/scripts/moustache.pl,v $
