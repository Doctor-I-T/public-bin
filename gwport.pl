#!/usr/bin/perl

my $qm = 'zz38RTafUtxY';
my ($gwhost,$gwport) = &get_gwhostport();
my $proto = ($gwport == 443) ? 'https' : 'http';
printf "gwport: %s\n",$gwport;
printf 'url: %s://%s:%s/ipfs/%s'."\n",$proto,$gwhost,$gwport,$qm;
exit $?;

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
  printf "testing: %s\n",$url;
  use LWP::UserAgent qw();;
  my $ua = LWP::UserAgent->new();
  my $resp = $ua->get($url);
  if ($resp->is_success) {
    return ($gwhost,$gwport);
  } else {
    return ('ipfs.blockringtm.ml',443);
  }
}

1; # $Source: /my/perl/scripts/gwport.pl $
