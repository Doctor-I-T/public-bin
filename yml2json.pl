#!/usr/bin/perl

my $ymlf = shift;
use YAML::Syck qw(LoadFile);
my $yml = LoadFile($ymlf);

my $jsonf = shift || $ymlf; $jsonf =~ s/\.[^\.]+/.json/;

use JSON qw(encode_json);
my $json = encode_json( $yml );

if (exists $ENV{REMOTE_ADDR}) {
printf "Content-Length: %s\n",length($json);
print "Content-Type: application/json\r\n\r\n";
}
printf "%s\n",$json;


local *F; open F,'>',$jsonf;
printf F $json;
close F;

exit 1;
