#

# usage:
# addfriend.sh ${peerkey} ${nickname}

peerkey="$1"
nickname="$2"
peerid=$(ipfs config Identity.PeerID)
if [ ! -d $HOME/.cache/mychelium ]; then mkdir -p $HOME/.cache/mychelium; fi
peeridsf=$HOME/.cache/mychelium/peerids.yml

ipfs files read /my/friends/peerids.yml | perl -pn -e 's/\r\n/\n/g' > $peeridsf
eval $(perl -S fullname.pl -a ${peerkey}| eyml)
nickname=${nickname:-$user}
cat <<EOT >> $peeridsf
$nid:
  nickname: "$nickname"
  fullname: "$fullname"
  trust: '0'
  peerkey: ${peerkey}
  email: "${email}"
  peerid: ${peerid}
EOT

qm=$(ipfs add -Q $peeridsf)
echo url: http://localhost:8080/ipfs/$qm
