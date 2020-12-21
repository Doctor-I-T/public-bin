#!/usr/bin/perl

# intent:
#   change the sname.log file into a dot file
#   to view at the graph and the trajectory...


use YAML::XS qw(Dump);

my $snlog = &set_sharedir('mutables').'/sname.log';
my $cachedir = &set_cachedir('sname');

printf "--- # %s\n",$0;
printf "snlog: %s\n",$snlog;
printf "cachedir: %s\n",$cachedir;
local *L; open L,'<',$snlog or warn $!;

my $pos = undef;
my $pn = 0;
my %seen = ();
my $sn = 0;

my $nn = 0;
my %nid = ('//' => 'n1');
my %map = ();
my %label = ();

my @traj = ();
my @edges = ();
while(<L>) {
  next if /^#/;
  chomp;
  my $d = $_;
     $d =~ s/\~/$ENV{HOME}/;
  if ($traj[-1] ne $d) { # suppress doubles !
    push @traj, $d;
  } else {
    next;
  }
  if (! $seen{$d}++) {
    $sn++;
    my $did = "d$sn";
    printf "d: %s (%s)\n",$d,$did;
    my @v = split('/',$d);
    my @ids = ();
    my $p = '';
    my $pid = undef;
    foreach (@v[0..$#v]) {
       $p .= $_.'/';
       if (! exists $nid{$p}) {
         $nn++;
         $nid = "n$nn";
         #printf "  p: %s (%s)\n",$p,$nid;
         $nid{$p} = $nid;
         if ($pid) {
            # see [1](https://graphviz.org/doc/info/attrs.html#k:arrowType)
            push @edges,sprintf '"%s" -> "%s" [weight=3 dir = "back", arrowtail = "dot"]',$pid, $nid;
         }
       } else {
         $nid = $nid{$p};
       }
       push @ids, $nid;
       if (! exists $map{$nid}) {
          $map{$nid} = $p;
          $sname{$nid} = &sname($p);
          $label{$nid} = $_ || 'root';
       }
       $pid = $nid; # memorize parent !
    }
  }

  if ($pos) {
    $pn++;
    push @hops,sprintf '"%s" -> "%s" [concentrate=true weight=1 constraint=true label="%d" style="dashed"]',$pos, $nid{"$d/"},$pn;
  }
  $pos = $nid{"$d/"};
  
}

#printf "--- # nid %s...\n",Dump(\%nid);
#printf "--- # map %s...\n",Dump(\%map);
#printf "--- # label %s...\n",Dump(\%label);
printf "--- # traj %s...\n",Dump(\@traj);

# create dot file:
open DF,'>',"$cachedir/sname.dot";
print DF "digraph snames { concentrate=false\n";
print DF " rank=source;\n";

print DF "n1;\n";

foreach (@hops) {
 print DF $_,"\n";
}

foreach (keys %map) {
  printf DF qq'"%s" ["label"="%s"]\n',$_,$label{$_};
}
print DF "\n";
foreach (@edges) {
 print DF $_,"\n";
}

printf DF qq'"nx" [rank="max" label="You are here" shape=rectangle color=red]\n',$pos;
printf DF qq'"nx" -> "%s" [color=blue weight=0 constraint=false]\n',$pos;

print DF "}\n";
close DF;

system "cd $cachedir; dot -Tpng sname.dot -o sname.png";


exit $?;

sub sname { # shortpath/name ... (only first letters)
  my ($file) = @_;
      $file =~ s,\\+,/,go;
  my $s = rindex($file,'/');
  my $fpath = ($s>0) ? substr($file,0,$s) : '.';
  my $fname = ($s) ? substr($file,$s+1) : $file;
  #print "p:$fpath f:$fname\n";
  my $spath = $fpath;
    $spath =~ y[~/@A-Za-z0-9][]dc;
    #$spath =~ s,/(.)[^/]*,\1,g;
    $spath =~ s,/(.)[^/]*,\1,g;
    $spath = '/'.$spath if ($fpath =~ m{^/});
  return "$spath/$fname";
}


sub set_cachedir {
  my $s = shift;
  my $d = (exists $ENV{CACHEDIR}) ? "$ENV{CACHEDIR}/$s" : "$ENV{HOME}/.cache/$s";
  mkdir $d unless -d $d;
  return $d;
}
sub set_sharedir {
  my $s = shift;
  my $d = (exists $ENV{SHAREDIR}) ? "$ENV{SHAREDIR}/$s" : "$ENV{HOME}/.local/share/$s";
  mkdir $d unless -d $d;
  return $d;
}

1;

