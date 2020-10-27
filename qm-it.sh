#

if [ "x$1" = 'x-n' ]; then
 nolog=1; shift;
fi
tic=$(date +%s)
d="${1%/}"
if [ "$d" = '.' -o "$d" = '' ]; then
  n=qm
  d=.
else
  n="${d##*/}"
fi
if [ ! -e $n.log ]; then
  echo "--- # $n qm log file" > $n.log
fi
pl=$(ipfs add -Q --dereference-args -r "$d/")
echo playload: $pl
mt=$(ipfs add -Q $n.log)
echo mutable: $mt
qm=$(ipfs object patch add-link $pl $n.log $mt)
km=$(echo $qm | base36 -d)
echo url: http://$km.ipfs.localhost:8080/
echo url: https://gateway.ipfs.io/ipfs/$qm
echo qm: $qm
if [ "x$nolog" = 'x' ]; then
  echo $tic: $qm >> $n.log
fi
echo "$n.log: |-"
tail -1 $n.log | sed -e 's/^/  /';

true;
