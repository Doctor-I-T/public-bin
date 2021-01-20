# 

# --- # meta
#
# intention:
#  log the current directory's hash (in a qm.log file)
#  w/o push all content in IPFS' repository
#
# usage: qmlog.sh
# ---

export IPFS_PATH=$HOME/.../ipfs/repo/MUTABLES
filestore=$IPFS_PATH/filestore
echo "--- ${0##*/}"
tic=$(date +%s)
pwd=$(pwd -L);
dname=$(dirname $pwd)
bname=$(basename $pwd)
uri="uri:$(hostname):$dname"
echo uri: $uri/$bname
nid=$(perl -S nid.pl $uri)
urn="urn:$nid/$bname"
echo urn: $urn
if [ ! -e qm.log ]; then
  echo "# qm log for $urn" > qm.log
fi
qm=$(ipfs add -Q -n -r .)
echo $tic: $qm
echo $tic: $qm >> qm.log
mut=$(ipfs add -Q qm.log)
record="$tic: $mut, $urn"
if ipfs files stat --hash "/.../mutables/$nid/$bname.log" 1>/dev/null 2>&1; then
ipfs files read "/.../mutables/$nid/$bname.log"  > $filestore/mut-$nid-$bname.log
else
echo "# mutable for urn:$nid/$bname" > $filestore/mut-$nid-$bname.log
fi
echo $record >> $filestore/mut-$nid-$bname.log
ipfs files write --create=1 --parents=1 "/.../mutables/$nid/$bname.log" $filestore/mut-$nid-$bname.log


apiaddr=$(json_xs -f json -t string -e '$_ = $_->{Addresses}{API}' < $IPFS_PATH/config)
apiport=$(echo $apiaddr | cut -d'/' -f 5-)
api_url=$(echo $apiaddr/api/v0 | sed -e 's,/ip4/,http://,' -e 's,/tcp/,:,')
echo url: http://127.0.0.1:$apiport/webui/#/files/.../mutables/$nid


exit;


qmempty=$(ipfs object new unixfs-dir)
qm=$(ipfs object patch rm-link $qm 'qm.log')
qm=$(ipfs object patch add-link $qm 'qm.log' $mut)
qmmut=$(ipfs object patch add-link $qmempty $bname $qm)

true; # $Source: /my/shell/scripts/qmlog.sh $
