#

echo "--- # $0"
export PATH=$PATH:$HOME/PROJDIR/bin

prog=$(which civetweb)
PREFIX=${prog%/bin/*}
CONFIG=$PREFIX/etc/civetweb.conf
echo config: $CONFIG
export WWW=${WWW:-$PREFIX/share/doc/civetweb/public_html}
echo WWW: $WWW

if [ "x$1" = 'xstart' ]; then
   if [ "x$2" = 'x-w' ]; then

export DISPLAY=${DISPLAY:-:1}
rxvt -geometry 128x18 -bg black -fg green -name civet -n Civet -title "civet web ($WWW)" -e sudo civetweb $CONFIG -listening_ports 80 -run_as_user $USER&
sleep 3
   else
   # start screen in "detached" mode.
   screen -dmS HTTPD civetweb $CONFIG
   # screen -list
   # screen -r {{sessionname}} # to reattach
   # CTRL-A CTRL-D to detach ...
   sleep 7
   fi
fi
if [ "x$1" = 'xstop' ]; then
   #screen -dmS IPFS ipfs shutdown
   echo "info: stopping httpd..."
   pkill -x -TERM civetweb
   sleep 3
fi



cd $WWW
#
echo http://yoogle.com:8088/cgi-bin/header.pl?url=https://ipfs.blockRingTM.ml/ipfs/QmSX3f5QM41mJyPwaxECpNcam8XtEhTybkPm7FB71Kybgb

exit 1;
