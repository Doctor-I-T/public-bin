#

gwurl=http://127.0.0.1:8390

#set -x
echo "--- # ${0##*/}"
pwd=$(pwd)
top=$(git rev-parse --show-toplevel)
cd $top
#if remote=$(git rev-parse --abbrev-ref @{upstream} |cut -d/ -f 1); then; false; true
if remote=$(git remote | head -1); then
echo "remote: $remote"
fi

# ---------------------------------------------------
# get the repository name !
if url=$(git remote get-url --push origin 2>/dev/null); then
echo url: $url
branch=$(git rev-parse --abbrev-ref HEAD);
if [ "x$remote" != 'x' ]; then
git config branch.$branch.remote $remote
fi
git config branch.$branch.merge refs/heads/$branch
git config pull.ff true
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
# ---------------------------------------------------

#branch=$(git rev-parse --abbrev-ref HEAD)

gitdir=$(git rev-parse --absolute-git-dir)
tic=$(date +%s)
if git rev-parse --quiet HEAD; then
gitid=$(git rev-parse --short HEAD)
echo gitid: $gitid
else
# perl -e 'printf "commit 0\0"' | ipfs add --hash sha1 --raw-leaves --cid-base base16 -Q | cut -c 10-
# sh -c 'echo -n "commit 0\0"' | openssl sha1 -r | cut -d' ' -f1
gitid=dcf5b16e76cce7425d0beaef62d79a7d10fce1f5
fi

# ---------------------------------------------------
if git log -1 2>/dev/null ; then
if git config committer.name 1>/dev/null; then
  fullname="$(git config committer.name)"
  email="$(git config committer.email)"
  user="${user%%@.*}"
  echo "fullname: $fullname"
  echo "email: $email"
  echo "user: $user"
fi
msg="$(git log -1 --pretty=format:%s HEAD --)"
fi
# ---------------------------------------------------
if ls -1 $gitdir/objects/pack/*.pack 2>/dev/null; then
  ls -1 $gitdir/objects/pack/*.pack | while read pf; do
    git unpack-objects < $pf
  done
else 
 echo no packs !
fi
# ---------------------------------------------------
# to preserve qmgit
if [ -e $top/build.sh ]; then
git restore --staged $top/build.sh
git reset $top/build.sh
fi
find $gitdir -name "*~1" -delete
cd $gitdir
rm -rf refs/remotes/*
git --bare update-server-info
# ---------------------------------------------------
qmgit=$(ipfs add -Q -r $gitdir)
# do a little clean-up ...
qmgit=$(ipfs object patch rm-link $qmgit config)
qmgit=$(ipfs object patch rm-link $qmgit hooks)
if [ -e $gitdir/index ]; then
qmgit=$(ipfs object patch rm-link $qmgit index)
fi
if [ -e $gitdir/logs ]; then
qmgit=$(ipfs object patch rm-link $qmgit logs)
fi
ipfs add -n -r --ignore=config --progress=false $(git rev-parse --git-dir) | grep -e '/config$' -e '/objects$' -e '/index$'
ipfs add -n -r --ignore=config --progress=false $(git rev-parse --git-dir) | grep -v '/'
# ---------------------------------------------------
cd $top

uri="gitea:repo:$symb"
echo uri: $uri

echo gitdir: $gitdir
echo qmgit: $qmgit

emptyd=$(ipfs object new -- unixfs-dir)
qmrepo=$(ipfs object patch add-link $emptyd $symb $qmgit)
echo qmrepo: $qmrepo

if head=$(ipfs cat /ipfs/$qmrepo/$symb/refs/heads/master); then
echo head: $head
fi
echo curl -L https://ipfs.blockring™.ml/ipfs/$qmgit/info/refs
curl -sI https://gateway.pinata.cloud/ipfs/$qmgit/info/refs | grep -i 'ipfs' 2>/dev/null &
curl -sL -m 3 ${gwurl}/ipfs/$qmrepo/$symb/info/refs

# update source remote in .git/config
echo repo: http://gitea.localhost:8080/ipfs/$qmrepo/$symb
if ! url=$(git remote get-url source 2> /dev/null); then
git remote add source http://gitea.localhost:8080/ipfs/$qmrepo/$symb
else
git remote remove source
#git remote add --mirror=fetch source http://gitea.localhost:8080/ipfs/$qmrepo/$symb
git remote add source http://gitea.localhost:8080/ipfs/$qmrepo/$symb
#git remote set-url --delete source $url
#git remote set-url --add source http://gitea.localhost:8080/ipfs/$qmrepo/$symb
#git remote set-url --delete source $(git remote get-url source)
fi
# disable push
git remote set-url --push source $gitdir
git fetch source

qm=$(ipfs add -r -Q .)
# update build if there is one
git checkout master
if [ -e $top/build.sh ]; then
 sed -e "s/^tic=[0-9][0-9]*/tic=$tic/" \
     -e "s/^qmgit=[Qbzkf1].*/qmgit=$qmgit/" \
     -e "s/^qmrepo=.*/qmrepo=$qmrepo/" \
     -e "smsg=\".*\"msg=\"$msg\"" \
     -e "s/user='.*'/user='$user'/" \
     -e "s/email='.*'/email='$email'/" \
     -e "s/fullname='.*'/fullname='$fullname'/" \
     -e "s/^qm=.*/qm=$qm/" $top/build.sh > $top/build.sh~new

 if [ ! -z $top/build.sh~new ]; then mv $top/build.sh~new $top/build.sh; fi
 git add $top/build.sh
 git commit -m "$mst\ngit clone http://127.0.0.1:8080/$qmgit $symb"
 #git push origin master
 git checkout $branch
fi
# update mutables.js if there is a tmpl
if [ -e $top/mutables.txt ]; then
 sed -e "s/^tic=.*/tic=$tic/" \
     -e "s/^qmgit=.*/qmgit=$qmgit/" \
     -e "s/^qmrepo=.*/qmrepo=$qmrepo/" \
     -e "s/user: '.*'/user: '$user'/" \
     -e "s/email='.*'/email='$email'/" \
     -e "s/fullname: '.*'/fullname: '$fullname'/" \
     -e "s/^qm=.*/qm=$qm/" $top/mutables.txt > $top/mutables.js
fi

# -------------------------------------------
# update some log ...
echo $tic: $gitid,$qmgit >> git.log
find . -name "*~1" -delete
qm=$(ipfs add -r -Q .)
echo $tic: $qm >> qm.log
# -------------------------------------------

if git config ipfs.qmgit 1>/dev/null; then
qmprv=$(git config ipfs.qmgit)
else
qmprv=QmekkpM5xEpbxGnbc9WXszVNwHDQgb2RgV7NismP3eQwMA
fi
cp -p $gitdir/config $gitdir/config~1
git config ipfs.qmgit $qmgit
git config ipfs.qmprv $qmprv

echo "cmd: |- # command to run on client..."
echo " # if you use branches"
echo " git pull --rebase=merge https://ipfs.blockring™.ml/ipfs/$qmrepo/$symb $branch"
echo " git pull --ff-only https://ipfs.blockring™.ml/ipfs/$qmrepo/$symb $branch"
echo " # or if you use modules"
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
