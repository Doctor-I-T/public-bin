#

echo "--- # ${0##*/}"
pwd=$(pwd)
top=$(git rev-parse --show-toplevel)
dirname=${top##*/}
cd $top
symb="$(echo ${dirname} |tr [:upper:] [:lower:]).git"

if ipfs key list | grep -q $symb; then
key=$(ipfs key list -l | grep -w $symb | cut -d' ' -f 1)
else
key=$(ipfs key gen -t rsa -s 3072 $symb)
fi
echo key: $key

domain='ydentity.ml'
peerid=$(ipfs config Identity.PeerID)
eval $(perl -S fullname.pl -a $peerid | eyml)
git config ipfs.peerid $peerid
git config user.name "$fullname"
git config user.email $user@$domain

gitdir=$(git rev-parse --absolute-git-dir)
tic=$(date +%s)
gitid=$(git rev-parse --short HEAD)

if ls -1 $gitdir/objects/pack/*.pack 2>/dev/null; then
list=$(ls -1 $gitdir/objects/pack/*.pack)
git unpack-objects < $list
else 
 echo no packs !
fi
cd $gitdir
git --bare update-server-info
qm=$(ipfs add -Q -r $gitdir)

uri="gitea:repo:$symb"
uri="urn:ipns:$key"
nid=$(perl -S nid.pl $uri | xyml nid)
echo uri: $uri
echo nid: $nid
echo gitdir: $gitdir
echo qm: $qm

wrap=$(perl -S ipfswrap.pl $symb $qm)
echo wrap: $wrap
echo git: http://gitea.localhost:8080/ipns/$key/$symb
echo urn: urn:$nid:$symb

ipfs name publish --key=$symb /ipfs/$wrap

cd $top
echo $tic: $gitid,$qm >> git.log
echo $tic: $(ipfs add -r -Q .) >> qm.log

if git config ipfs.qm 1>/dev/null; then
prev=$(git config ipfs.qm)
else
prev=QmY31kpcxkxDmSLAfjaxqor5UTbNj7X384bzKjTdmMuFZg
fi
cp -p $gitdir/config $gitdir/config~1
git config ipfs.qm $qm
git config ipfs.prev $prev

exit $?;

true; # $Source: /my/shell/scripts/gitpushipfs.sh$
