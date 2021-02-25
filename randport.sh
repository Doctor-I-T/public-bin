#

NAME="${1##*/}"
if [ "x$NAME" = 'x' ]; then
if [ -e name ]; then
 NAME=$(cat name)
else 
  pwd=$(pwd -P)
  NAME=${pwd##*/}
  if [ $NAME = '.ipfs' ]; then
    NAME=$(echo $USER | tr [:lower:] [:upper:])
  fi
  echo info: NAME=$NAME
fi
fi
echo NAME: $NAME
export IPFS_PATH=.
if [ ! -e config ]; then
ipfs init
else
cp -p config config~0
fi
peerid=$(ipfs config Identity.PeerID)
repo="urn:ipns:$peerid:/IPFS_REPO/$NAME"
echo repo: $repo
sha2=$(echo -n "$repo" | openssl sha256 --hex | cut -d' ' -f 2)
echo sha2: $sha2
n16=$(echo $sha2 | cut -c3-6)
n=$((0x$n16))
p=$( expr $n \% 1000 )
swarm_port=$( expr $p + 4001 )
api_port=$( expr $p + 5001 )
gw_port=$( expr $p + 8080 )
ipfs shutdown 2>/dev/null
ipfs config Addresses.Swarm --json '["/ip4/0.0.0.0/tcp/'$swarm_port'","/ip6/::/tcp/'$swarm_port'","/ip4/0.0.0.0/udp/'$swarm_port'/quic","/ip6/::/udp/'$swarm_port'/quic"]'
ipfs config Addresses.API /ip4/0.0.0.0/tcp/$api_port
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/$gw_port
echo 'addresses: |-'
ipfs config Addresses | sed -e 's/^/  /'
echo swarm_port: $swarm_port
echo api_port: $api_port
echo gw_port: $gw_port

