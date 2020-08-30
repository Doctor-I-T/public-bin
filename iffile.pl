#!/usr/bin/perl

while (<>) {
 chomp;
 if (-f $_ && -w $_) {
   print $_,"\n";
 }
}

exit $?;
1; # $Source: /my/perl/scripts/iffile.pl $
