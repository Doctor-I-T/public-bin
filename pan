#

# publish a note ...
file="${1%.*}"
if [ -e _page.html ]; then
option="--template=_page.html"
list=_page.html
fi
pandoc -s -t html -o_$file.html $option $*
qmi=$(ipfs add -q _$file.html)
qm=$(ipfs add -Q -w -r _page.html img style.css);
qm=$(ipfs object patch add-link $qm "index.html" $qmi)

echo url: http://127.0.0.1:8080/ipfs/$qm
echo url: https://gateway.pinata.cloud/ipfs/$qm
#xdg-open _$file.html
exit


qmset='QmZkPjvYBxgNZeKCXZxFj5GBrSB7TUfNDHL8FnnzQXYWDU'
dir=11248
if [ -e _site ]; then
  dir=_$dir
fi
if ! test -d $dir; then
ipfs get $qmset -o $dir
fi
cp -p $0 $dir/pan
if test -d .git; then git add $dir/pan; fi

file="$1"
bname=${file%.*}
perl -S moustache.pl $dir/default.html $dir/default.htm~
perl -S moustache.pl $file $bname.md~
pandoc -t html -f markdown --template=$dir/default.htm~ -o $bname.htm~ $bname.md~
cp -p $bname.md~ $dir/$bname.md
cp -p $bname.htm~ $dir/index.html
qm=$(ipfs add -Q -r $dir)
echo "- $qm" >> $dir/pan.yml
qmlive=$(ipfs add -Q -r $dir)

echo http://127.0.0.1:8080/ipfs/$qmlive
echo http://yoogle.com:8080/ipfs/$qmlive
echo https://cloudflare-ipfs.com/ipfs/$qmlive
echo https://ipfs.blockringtm.ml/ipfs/$qmlive
xdg-open $dir/index.html
#curl -I https://ipfs.blockringtm.ml/ipfs/$qm &
#sleep 1; rm -rf $dir/
rm $bname.*~

# publish its' on note for logging purpose ...
time=$(date +%T)
date=$(date +%D)
msg="a note is posted at [$qmshort] @$time"
cat > $dir/posted.txt <<EOT
---
title: Post a note (#PaN): $qmshort on $date 
subtitle: a note from $USER 
preview: envelop.jpg
bgimg: water.jpg
hero: books.jpg
thumbnail: notes.jpg
---
![stamp](img/poststamp.png)
$qmshort PaN*ote* on $date

$msg

--&nbsp;<br>
~$USER (https://$yoogle.com:8080/ipfs/$qmlive)

[$qmshort]: https://gateway.ipfs.io/ipfs/$qmlive
EOT
# TODO: continue pandoc for the posted.txt file etc...
if test -d .git; then
  git add $dir/posted.txt
  git commit -a -m "$msg" $dir
fi

