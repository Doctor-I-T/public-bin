#!/usr/bin/perl


my $mode = 'queue';

# take a list of dir ...

my $nodes = loadList();
my $leaves = [];

# tree traversal ...
# Store the root node in Container
# While (there are nodes in Container)
#    N = Get the "next" node from Container
#    Store all the children of N in Container
#    Do some work on N

while (@$nodes) {

  # shift = queue -> breath traversal
  # pop = stack -> depth traversal
  my $n = ($mode eq 'queue') ? shift @$nodes : pop @$nodes;
  my @leaves = ();
  printf "node: %s\n",$n;
  if (-d $n) {
    my $children = &content($n);
    foreach my $c (@$children) {
      # ----------------------------
      if (-d $c) {
        push @$nodes, $c;
      } elsif (-f $c) {
        push @leaves, $c
      }
      # ----------------------------
    }
  } elsif (-f $n) {
    push @leaves, $n;
  }
  &process(@leaves);
  push @$leaves, @leaves;
}


exit $?;

sub process {
 printf "nbl: %d\n",scalar(@_);
 foreach my $f (@_) {
   my $b = substr($f,1+rindex($f,'/',length($f)-1));
   printf "f: %s -> %s\n",$f,$b;
   rename $f, $b unless -e $b;
 }
 print ".\n";
}
sub content {
  local *D; opendir D,$_[0];
  my $content;
  @$content = map { "$_[0]/$_"; } grep !/^..?$/, readdir(D);
  closedir D;
  return $content;
}

sub loadList {
  my $list = [];
  my %seen=();
  while (<>) {
    chomp;
    my $f;
    # ---------------------------------
    if (-e $_) {
      $f = $_; $a = $.;
    # ---------------------------------
    } elsif (m/([^:]+):\s+(.*)/) { # format n: file
      my ($a,$f) = ($1,$2);
    }
    # ---------------------------------
    push @$list, $f unless $seen{$f}++;
  }
  return $list;
}
