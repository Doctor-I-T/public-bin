#

echo "--- # ${0##*/}"
pwd=$(pwd)
top=$(git rev-parse --show-toplevel)
cd $top
if remote=$(git rev-parse --abbrev-ref @{upstream} |cut -d/ -f 1); then
echo "remote: $remote"
fi

# ---------------------------------------------------
# get the repository name !
if url=$(git remote get-url --push origin); then
echo url: $url
branch=$(git rev-parse --abbrev-ref HEAD);
git config branch.$branch.remote $remote
git config branch.$branch.merge refs/heads/master
git config pull.rebase false
symb=${url##*/}
else
dirname=${top##*/}
symb="$(echo ${dirname} | sed -e 's,/src,,' -e 's,/repo*/,,' |tr [:upper:] [:lower:]).git"
fi
echo symb: $symb
# ---------------------------------------------------
domain='ydentity.ml'
peerid=$(ipfs config Identity.PeerID)
eval $(perl -S fullname.pl -a $peerid | eyml)
git config ipfs.peerid $peerid
git config user.name "$fullname"
git config user.email $user@$domain

#branch=$(git rev-parse --abbrev-ref HEAD)

gitdir=$(git rev-parse --absolute-git-dir)
tic=$(date +%s)
gitid=$(git rev-parse --short HEAD)
echo gitid: $gitid

if ls -1 $gitdir/objects/pack/*.pack 2>/dev/null; then
list=$(ls -1 $gitdir/objects/pack/*.pack)
git unpack-objects < $list
else 
 echo no packs !
fi
find $gitdir -name "*~1" -delete
cd $gitdir
git --bare update-server-info
qmgit=$(ipfs add -Q -r $gitdir)
# do a little clean-up ...
qmgit=$(ipfs object patch rm-link $qmgit config)
qmgit=$(ipfs object patch rm-link $qmgit hooks)
qmgit=$(ipfs object patch rm-link $qmgit index)
qmgit=$(ipfs object patch rm-link $qmgit logs)
cd $top

uri="gitea:repo:$symb"
echo uri: $uri

echo gitdir: $gitdir
echo qmgit: $qmgit

emptyd=$(ipfs object new -- unixfs-dir)
qmrepo=$(ipfs object patch add-link $emptyd $symb $qmgit)
echo qmrepo: $qmrepo

head=$(ipfs cat /ipfs/$qmrepo/$symb/refs/heads/master)
echo head: $head
echo curl -I https://gateway.pinata.cloud/ipfs/$qmgit/info/refs 
echo curl -L https://ipfs.blockring™.ml/ipfs/$qmrepo/$symb/info/refs

# update previous remote in .git/config
echo repo: http://gitea.localhost:8080/ipfs/$qmrepo/$symb
if ! url=$(git remote get-url previous) 1> /dev/null; then
git remote add previous http://gitea.localhost:8080/ipfs/$qmrepo/$symb
else
git remote set-url --add previous http://gitea.localhost:8080/ipfs/$qmrepo/$symb
#git remote set-url --delete previous $(git remote get-url previous)
git remote set-url --delete previous $url
fi
# disable push
git remote set-url --push previous $gitdir

echo $tic: $gitid,$qmgit >> git.log
find . -name "*~1" -delete
qm=$(ipfs add -r -Q .)
echo $tic: $qm >> qm.log

if git config ipfs.qmgit 1>/dev/null; then
qmprv=$(git config ipfs.qmgit)
else
qmprv=QmekkpM5xEpbxGnbc9WXszVNwHDQgb2RgV7NismP3eQwMA
fi
cp -p $gitdir/config $gitdir/config~1
git config ipfs.qmgit $qmgit
git config ipfs.qmprv $qmprv

# update build if there is one
if [ -e $top/build.sh ]; then
 sed -e "s/^tic=[0-9][0-9]*/tic=$tic/" \
     -e "s/^qmgit=.*/qmgit=$qmgit/" \
     -e "s/^qmrepo=.*/qmrepo=$qmrepo/" \
     -e "s/^qm=.*/qm=$qm/" $top/build.sh > $top/build.sh~new
 if [ ! -z $top/build.sh~new ]; then mv $top/build.sh~new $top/build.sh; fi
 git add $top/build.sh
fi
# update mutables.js if there is a tmpl
if [ -e $top/mutables.txt ]; then
 sed -e "s/^tic=.*/tic=$tic/" \
     -e "s/^qmgit=.*/qmgit=$qmgit/" \
     -e "s/^qmrepo=.*/qmrepo=$qmrepo/" \
     -e "s/^qm=.*/qm=$qm/" $top/mutables.txt > $top/mutables.js
fi

echo "cmd: |- # command to run on client..."
echo " git pull --no-rebase https://ipfs.blockring™.ml/ipfs/$qmrepo/$symb master"
echo " # or :"
echo " git submodule set-url public https://ipfs.blockring™.ml/ipfs/$qmrepo/$symb"
echo " git submodule update public"

# ---------------------------------------------------
if ipfs key list | grep -q $symb; then
key=$(ipfs key list -l --ipns-base b58mh | grep -w $symb | cut -d' ' -f 1)
else
key=$(ipfs key gen -t rsa -s 3072 --ipns-base b58mh $symb)
fi
uri="urn:ipns:$key"
nid=$(perl -S nid.pl $uri)

echo symb: $symb
echo key: $key
echo nid: $nid
echo git: http://gitea.localhost:8080/ipns/$key/$symb
echo urn: urn:$nid:$symb
if ipath=$(ipfs name resolve $key); then
echo prev_git: http://127.0.0.1:8080$ipath/$symb
fi

# publish in ipns ...
ipfs name publish --key=$symb /ipfs/$qmrepo --ipns-base b58mh --allow-offline | sed -e 's/^/info: /'

exit $?;

true; # $Source: /my/shell/scripts/git-push-ipfs.sh$
