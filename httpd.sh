#

export WWW=${WWW:-/usr/local/share/doc/civetweb/public_html}

if [ "x$1" = 'xstart' ]; then
   if [ "x$2" = 'x-w' ]; then

export DISPLAY=${DISPLAY:-:1}
rxvt -geometry 128x18 -bg black -fg green -name civet -n Civet -title "civet web ($WWW)" -e sudo civetweb &
sleep 3
   else
   # start screen in "detached" mode.
   screen -dmS HTTPD civetweb
   # screen -list
   # screen -r {{sessionname}} # to reattach
   # CTRL-A CTRL-D to detach ...
   sleep 7
   fi
fi
if [ "x$1" = 'xstop' ]; then
   #screen -dmS IPFS ipfs shutdown
   echo "info: stopping ipfs..."
   pkill -x -TERM civetweb
   sleep 3
fi



cd $WWW
#
echo http://yoogle.com:8088/cgi-bin/header.pl?url=https://ipfs.blockRingTM.ml/ipfs/QmSX3f5QM41mJyPwaxECpNcam8XtEhTybkPm7FB71Kybgb

exit 1;
