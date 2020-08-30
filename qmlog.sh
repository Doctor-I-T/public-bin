# 

# --- # meta
#
# intention:
#  log the current directory's hash (in a qm.log file)
#  w/o push all content in IPFS' repository
#
# usage: qmlog.sh
# ---

export IPFS_PATH=$HOME/ipfs/.../MUTABLES
echo "--- ${0##*/}"
tic=$(date +%s)
qm=$(ipfs add -Q -n -r .)
if [ ! -e qm.log ]; then
  echo "# qm log for $(pwd -P)" > qm.log
fi
echo $tic: $qm
echo $tic: $qm >> qm.log


true; # $Source: /my/shell/scripts/qmlog.sh $
