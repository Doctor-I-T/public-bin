#!/usr/bin/perl

# intent:
#    returns a short name for the passed directory name
#    it is to be use in setting PS1
# ex:
#     PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\$(perl -S sname.pl \"\$PWD\")\a\]$PS1"
# 
# see also [1](https://tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html)

#my $PS1 = $ENV{PS1}; $PS1 =~ s/\\w/\W/;
#my $PWD = $ENV{PWD};
#printf qq'PS1="%s"\n',$PS1;
#printf qq'PWD="%s"\n',$PWD;
#printf qq'sname="%s"\n',&sname($PWD);

my $sharedir=set_sharedir('mutables');
local *L; open *L,'>>',"$sharedir/sname.log";

my $dirName = shift;
my $shortName = &sname($dirName);
my $longName = &lname($dirName);
print $shortName;
printf L "%u: %s\n",time(),$longName;

close(L);
exit $?;

sub sname { # shortpath/name ... (only first letters)
  my ($file) = @_;
      $file =~ s,\\+,/,go;
  my $s = rindex($file,'/');
  my $fpath = ($s>0) ? substr($file,0,$s) : '.';
  my $fname = ($s) ? substr($file,$s+1) : $file;
  #print STDERR "p:$fpath f:$fname\n";
    $fpath =~ s/$ENV{HOME}/\~/;
  my $spath = $fpath;
    $spath =~ s,/\.,/,g;
    $spath =~ y[~/@A-Za-z0-9\.][]dc;
  #print STDERR "s:$spath\n";
    $spath =~ s,/(.)[^/]*,$1,g;
    $spath = '/'.$spath if ($fpath =~ m{^/});
  return "$spath/$fname";
}
sub lname {
  my ($file) = @_;
      $file =~ s,\\+,/,go;
  my $lname = $file;
  $lname =~ s/$ENV{HOME}/\~/;
  $lname =~ s,/home,\~,;
  return $lname;
}

sub set_sharedir {
  my $s = shift;
  my $d = (exists $ENV{SHAREDIR}) ? "$ENV{SHAREDIR}/$s" : "$ENV{HOME}/.local/share/$s";
  mkdir $d unless -d $d;
  return $d;
}
1;
