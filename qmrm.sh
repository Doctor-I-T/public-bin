#

# --- # meta
# intention: |-
#  remove a content from its hash (qm)
# usage: |-
#  qm=QmecLmMZDjT16C1kWPHVmCeyrv6yPvUUii2fRRyBp4zW95
#  qmrm.sh $qm
#
# ---

qm="$1"
ipfs object get $qm
ipfs pin rm $qm
bafy=$(echo $qm |  mbase -d | xyml b32)
shard=$(echo $bafy | cut -c57-58)
echo shard: $shard
afy=$(echo $bafy | cut -c2-)
echo bafy: $bafy
find /media/IPFS/*/blocks/$shard -name $afy.\* -exec rm -r {} \; -print
find ~/.ipfs/blocks/$shard -name $afy.\* -exec rm -r {} \; -print
locate $afy
ipfs block rm $qm


true; # $Source: /my/shell/scripts/qmrm.sh $

