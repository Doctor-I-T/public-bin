#!/usr/bin/perl

# usage:
#  perl -S ipfswrap.pl name hash

my $name = shift;
my $hash = shift;
printf "--- # %s\n",$0;
printf "name: %s\n",$name;
printf "hash: %s\n",$hash;
my $qm = &ipfswrap($name,$hash);
printf "qm: %s\n",$qm;
exit $?;


sub ipfswrap {
  my ($name,$hash) = @_;
  my $empty = 'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn';
  my $args = sprintf'&arg=%s&arg=%s',$name,$hash;
  my $obj = &ipms_get_api('object/patch/add-link',$empty,$args);
  my $wqm = $obj->{Hash};
  return $wqm;
}


# -----------------------------------------------------
# call ipfs API
# usage:
# $resp = &ipms_get_api('cmd','arg1','arg2');
#
sub ipms_get_api {
   use JSON qw(decode_json);
# ipms config Addresses.API
#  (assumed gateway at /ip4/127.0.0.1/tcp/5001/...)
   my $api_url;
   if ($ENV{HTTP_HOST} =~ m/heliohost/) {
      $api_url = sprintf'https://%s/api/v0/%%s?arg=%%s%%s','ipfs.blockringtm.ml';
   } else {
     my ($apihost,$apiport) = &get_apihostport();
      $api_url = sprintf'http://%s:%s/api/v0/%%s?arg=%%s%%s',$apihost,$apiport;
   }
   my $url = sprintf $api_url,@_; # failed -w flag !
#  printf "X-api-url: %s\n",$url;
   my $content = '';
   use LWP::UserAgent qw();
   use MIME::Base64 qw(decode_base64);
   my $ua = LWP::UserAgent->new();
   my $realm='Restricted Content';
   if ($ENV{HTTP_HOST} =~ m/heliohost/) {
      my $auth64 = &get_auth();
      my ($user,$pass) = split':',&decode_base64($auth64);
      $ua->credentials('ipfs.blockringtm.ml:443', $realm, $user, $pass);

#     printf "X-Creds: %s:%s\n",$ua->credentials('ipfs.blockringtm.ml:443', $realm);
   }
   my $resp = $ua->post($url); # for IPFS > 0.5
   if ($resp->is_success) {
#     printf "X-Status: %s\n",$resp->status_line;
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
   if ($_[0] =~ m{^(?:cat|files/read)}) {
     return $content;
     if (0) {
	$content =~ s/"/\\"/g;
	$content =~ s/\x0a/\\n/g;
	$content = sprintf'{"content":"%s"}',$content;
	printf "Content: %s\n",$content;
     }
   }
   if ($content =~ m/^{/) { # }
      my $json = &decode_json($content);
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


1;
