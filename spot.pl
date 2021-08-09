#!/usr/bin/perl
BEGIN { our $rel='QmUWQiJ4j9rFBJh15GtVymqo7qSbJCpZjBs9fCE92yAXSK';
   if (! defined $ENV{SITE} || ! -e $ENV{SITE}.'/lib/IPMS.pm') {
      if (! -e  "$ENV{HOME}/.../gqtools/$rel") {
         printf "// installing gqtools ...";
         system "ipfs get -o $ENV{HOME}/.../gqtools/$rel /ipfs/$rel 2>/dev/null" or die $!;
         print "\n.\n";
      }
      $ENV{SITE} = "$ENV{HOME}/.../gqtools/$rel";
   }
}
#BEGIN {
#my $rootdir = __FILE__; $rootdir =~ s,[^/]*$,..,;
#our $libdir = $rootdir.'/lib';
#}

# -----------------------------------------------------------------
use lib "$ENV{SITE}/lib";
use IPMS qw(get_spot mfs_copy mfs_append ipms_get_api ipms_post_api);
my $dbug=0;
#understand variable=value on the command line...
eval "\$$1='$2'"while $ARGV[0] =~ /^(\w+)=(.*)/ && shift;
if ($dbug) {
 eval "use YAML::Syck qw(Dump);";
}
# -----------------------------------------------------------------


# get you space and time location (memory drop point)
my $time = int($^T / 61) * 59; # in the past as < $^T
my $spot = &get_spot($time,@ARGV);
printf "spot: %s\n",$spot;

# archive the spot !
my $spotdata = sprintf <<"EOT",$ENV{USER},$^T,$spot, join',',@ARGV;
--- # spot for %s
tic: %s
spot:%s
argv: [%s]
EOT
my $mh = &ipms_post_api('add','spot.yml',$spotdata);
my $qm = $mh->{Hash};
printf "qm: %s\n",$qm;
&mfs_copy("/ipfs/$qm",'/etc/spot.yml');
my $etc = &ipms_get_api('files/stat','/etc');
printf "etc: %s\n",$etc->{Hash};
my $mh = &mfs_append("$etc->{Hash}: /etc",'/.brings/published/brindex.log');
printf "mh: %s.\n",YAML::Syck::Dump($mh) if $dbug;

exit $?;
1;
