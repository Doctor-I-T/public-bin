#!/usr/bin/perl


# intent:
#   take title+url from clipboard ...
#   shards bookmarks (qmrks) in timed list of urls
#   using the hash (base36) of the url
#
# usage:
#  xclip -o | perl -S qmark.pl setname


my $stamp = time()%691;
my $set = shift || sprintf 'qmark-%d',$stamp;

if ($set =~ m/PN/) {
  $ENV{IPFS_PATH} = $ENV{HOME}.'/.../ipfs/usb/PN';
  $QMARKSDIR=$ENV{HOME}.'/.../ipfs/usb/PN/qmarks';
} else {
  $ENV{IPFS_PATH} = $ENV{HOME}.'/.../ipfs/usb/QMARKS';
  $QMARKSDIR=$ENV{QMARKSDIR}||$ENV{HOME}.'/.../qmarks';
  die unless -d $QMARKSDIR;
}

my @set = ();
printf "--- # %s\n",$0;
printf "IPFS_PATH: %s\n",$ENV{IPFS_PATH};
printf "QMARKSDIR: %s\n",$QMARKSDIR;
my $i = 0;
my $p = 'qMark';
my ($url,$what) = ('https://example.com','URL Example');
local $EXEC = 'xclip -o --selection c';
open $EXEC,"$EXEC|";
while (<$EXEC>) {
   chomp;
   if (/^http/) {
      $url = $_;
      $what = $p;
      $what =~ s/\s+/ /g;
      $url =~ s/\)/%29/g;
      $what =~ s/]/%5D/g;

      $what = $. unless $what !~ m/^\s*$/;

      # command to get the content, is used as hash !
      my $hash = &khash('SHA256','curl -sL ',$url);
      my $h36 = &encode_base36($hash);
      printf "url: %s\n",$url;
      printf "h36: %s\n",$h36;
      my $key = substr($h36,0,13);
      my $shard = substr($h36,-3,2);
      my $tic = time();
      my $spot = $tic ^ 0x0000_0000;
      my $oneliner = sprintf "%s: %s.%d [%s](%s)",$key, $spot,$i,$what,$url;
      print $oneliner,"\n";
      push @set,$oneliner;
      open F,'>>',sprintf'%s/tabs-%s.qmk',$QMARKSDIR,$shard;
      printf F "%s.%d: [%s](%s)\n",$spot,$i,$what,$url;
      close F;
      $i++;
   }
   $p = $_;
}


# create qmark:

my $tic = time;
my $content = sprintf "--- #\nset: %s\n---\n## %s (%s)\n\n",$set,$set,$tic;
for my $u (@set) {
  $content .= ' - '.$u."\n";
}
$content .= "\n";
#printf "content: %s\n",$content;

die unless $content;

my $mdf = $QMARKSDIR.'/qmark.md';
if (0) {
open F,'>',$mdf;
print F $content;
close F;
}
printf "mdf: %s\n",$mdf;

my $mh = &ipfs_api('add',"$mdf",'&file=qmark',$content);
#use YAML::Syck qw(Dump); printf qq'--- # mh %s...\n',Dump($mh);
my $qm = $mh->{'Hash'};
printf "qm: %s\n",$qm;
printf "url: http://127.0.0.1:8080/ipfs/%s\n",$qm;
my $url = sprintf 'http://gateway.ipfs.io/ipfs/%s',$qm;
my $what = sprintf 'qMark %s %d items: %s',$stamp,scalar(@set),$set;
my $hash = &khash('SHA256','curl -sL ',$url);
my $h36 = &encode_base36($hash);
my $key = substr($h36,0,13);
my $shard = substr($h36,-3,2);
my $tic = time();
my $spot = $tic ^ 0x0000_0000;
my $oneliner = sprintf "%s: %s.%d [%s](%s)\n",$key, $spot,$i,$what,$url;
my $shardf = sprintf'%s/tabs-%s.qmk',$QMARKSDIR,$shard;
open F,'>>',$shardf;
printf F "%s.%d: [%s](%s)\n",$spot,$i,$what,$url;
close F;
printf "shardf: %s\n",$shardf;
$i++;


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

# -----------------------------------------------------
sub ipfs_api {
   my $api_url; # ipfs config Addresses.API
   my $buf = undef;
   if (scalar @_ > 3) {
     # usage: ipfsapi('{{cmd}}','{{arg}}','{{query-string}}',$data);
     $data = pop @_;
   }
   if ($ENV{HTTP_HOST} =~ m/heliohost/) {
      $api_url = sprintf'https://%s/api/v0/%%s?arg=%%s%%s','ipfs.blockringtm.ml';
   } else {
      my ($apihost,$apiport) = &get_apihostport();
      $api_url = sprintf'http://%s:%s/api/v0/%%s?arg=%%s%%s',$apihost,$apiport;
   }
   my $url = sprintf $api_url,@_;
   printf "X-api-url: %s\n",$url;
   my $content = '';
   use LWP::UserAgent qw();
   use MIME::Base64 qw(decode_base64);
   my $ua = LWP::UserAgent->new();
   my $realm='Restricted Content';
   # ----
   if ($api_url =~ m/blockringtm.ml/) {
      my $realm='Restricted Content';
      #my $auth64 = 'YW5vbnltb3VzOnBhc3N3b3JkCg=='; # anonymous:password
      my $auth64 = &get_auth();
      my ($user,$pass) = split':',&decode_base64($auth64);
      $ua->credentials('ipfs.blockringtm.ml:443', $realm, $user, $pass);

#     printf "X-Creds: %s:%s\n",$ua->credentials('ipfs.blockringtm.ml:443', $realm);
   }
   # ----
   my $resp;
   if (defined $data) {
     my $form = [
#       You are allowed to use a CODE reference as content in the request object passed in.
#       The content function should return the content when called. The content can be returned
#       Content => [$filepath, $filename, Content => $data ]
        'file-to-upload' => ["$filepath" => "$filename", Content => "$data" ]
     ];
     my $content = '5xx';
     $resp = $ua->post($url,$form, 'Content-Type' => "multipart/form-data;boundary=immutable-file-boundary-$$");
   } else {
     $resp = $ua->post($url); # works for IPFS > 0.5
   }
  
   if ($resp->is_success) {
#     printf "X-Status: %s<br>\n",$resp->status_line;
      $content = $resp->decoded_content;
   } else {
      printf "X-api-url: %s\n",$url;
      printf "Status: %s\n",$resp->status_line;
      $content = $resp->decoded_content;
      local $/ = "\n";
      chomp($content);
      printf "Content: '%s'\n",$content;
   }
   if ($_[0] =~ m{^(?:cat|files/read)}) {
     return $content;
   }
   use JSON qw(decode_json);
   if ($content =~ m/{/) { # }
      #printf "[DBUG] Content: %s\n",$content;
      my $resp = &decode_json($content);
      return $resp;
   } else {
      print "info: $_[0]\n" if ($dbug && ! $content);
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


1; # $Source: /my/perl/scripts/mark.pl$
