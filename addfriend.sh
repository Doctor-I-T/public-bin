#

# TODO complete the script ...
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
ipfs files rm /my/friends/peerids.yml~ 2>/dev/null
ipfs files mv /my/friends/peerids.yml /my/friends/peerids.yml~
ipfs files cp /ipfs/$qm /my/friends/peerids.yml

# ipfs name publish --key=registration /ipfs/$qm
key=$(ipfs key list -l --ipns-base=b58mh | grep -w registration | cut -d' ' -f1)
ipfs ping QmcfHufAK9ErQ9ZKJF7YX68KntYYBJngkGDoVKcZEJyRve 2>/dev/null
ipfs name resolve $key
xdg-open http:/localhost:8080/ipns/$key/register.html
token=$(echo "I've got friends!" | ipfs add -Q )
