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
my %nid = ('/' => 'n0');
my %map = ('n0' => '/');
my %label = ('n0' => 'root');

my %edges = ();

my $prevd;
my @traj = ();
my @edges = ();
while(<L>) {
  next if /^#/;
  chomp;
  my ($ts,$d) = (split(/:\s+/,$_,2));
  #printf "ts: %s (%s)\n",$ts,$d;
  
  if ($d eq '~') {
   # skip transitional "~"
   if ($prevd ne '~') {
     $prevd = $d;
     next;
   }
  }
  $prevd = $d;
  $d =~ s,\~,$ENV{HOME},;
  if ($traj[-1] ne $d) { # suppress doubles !
    push @traj, $d;
  } else {
    next;
  }
  if (! $seen{$d}++) {
    $sn++;
    my $did = "d$sn";
    printf "d: %s (%s)\n",$d,$did;
    
    my $pnid;
    my $p = &physical($d);
    for my $c ($p, $d) {
       my @v = split('/',$c); shift @v;
       my @ids = ();
       my $n = '';
       $pnid = 'n0'; # parent node id;
       foreach (@v) {
          $n .= '/'.$_;
          $nid = &get_nid($n);
          push @ids, $nid;
          if (! exists $map{$nid}) {
             $map{$nid} = $n;
             $sname{$nid} = &sname($n);
             $label{$nid} = $_ || 'root';
          }
          if ($pnid) {
             if (! $edges{"$pnid-$nid"}++) {
                # see [1](https://graphviz.org/doc/info/attrs.html#k:arrowType)
                push @edges,sprintf '"%s" -> "%s" [weight=4 dir = "back", arrowtail = "dot"]',$pnid, $nid;
             }
          }
          $pnid = $nid; # memorize parent !
       }
    }

    if ($p ne $d) {
        print " - d: $d ($pnid)\n";
      if (exists $nid{$p}) {
        my $pid = $nid{$p};
        print " - p: $p ($pid)\n";
        if (! $edges{"$pid-$pnid"}++) {
           push @edges,sprintf '"%s" -> "%s" [style=dotted color=cyan weight=1 dir="both", arrow = "dot"]',$pid, $pnid;
        }
      }
    }
  }

  if ($pos) {
    $pn++;
    push @hops,sprintf '"%s" -> "%s" [concentrate=true weight=3 constraint=true label="%d" taillabel="%d" style="dashed"]',$pos, $nid{"$d"},$pn,$pn;
  }
  $pos = $nid{"$d"};
  
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
printf DF qq'"nx" -> "%s" [color=blue taillabel="%d" weight=0 constraint=false]\n',$pos,$pn;

print DF "}\n";
close DF;

system "cd $cachedir; dot -Tpng sname.dot -o sname.png";


exit $?;

sub get_nid {
   my $d = shift;
   if (exists $nid{$d}) {
      return $nid{$d};
   } else {
      $nn++;
      $nid = "n$nn";
      $nid{$d} = $nid;
      printf "  n: %s nid:%s\n",$d,$nid;
      return $nid;
   }
}
sub bname {
  my ($file) = @_;
      $file =~ s,\\+,/,go;
      $file =~ s,/$,,o;
  my $s = rindex($file,'/');
  my $bname = ($s) ? substr($file,$s+1) : $file;
  return $bname;
}

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

sub physical {
   my $d = shift;
   my @p = split('/',$d); shift@p;
   #printf "\@p: [%s]\n",join',',@p;
   my $flag = 0;
   my $path = '';
   foreach my $p (@p) {
      my $l = "$path/$p";
      #print "l: $l\n";
      if (-l "$l") {
         $flag++;
         my $link = readlink($l);
         print "link: $l -> $link\n";
         if ($link =~ m,^/,) {
            $path = "$link"
         } else {
            $path .= "/$link"
         }
      } else {
         $path .= "/$p";
      }
   }
   $path .= '/' if $d =~ m,/$,;
   printf " p: %s\n",$path if $flag;
   return $path;
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

