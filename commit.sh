#

# intent: auto-commit ...

date=$(date +%Y-%m-%d)
ver=$(perl -S version -a $0 | xyml scheduled)
echo ver: $ver
commit_msg()
{
qm=$(git status -v -uno | ipfs add -Q -pin=false)
ns=$(perl -S nid.pl "urn:ipfs:$qm")
msg=$(cat <<EOM
auto-commit $ver ns:$ns ($date)
top: $gittop
`git status -s -b -uno --ignore-submodules=untracked`
parent: $gitid
`git --no-pager status -v -b --ignore-submodules=untracked | grep -e '^index ' | sed -e 's/^index/ /'`
changes: http://localhost:8080/ipfs/$qm
EOM
)
echo "msg: |-"
echo "$msg" | sed -e 's/^/  /'
echo '.'
}
# ---------------------------------------------------------------------
git pull
gittop=$(git rev-parse --show-toplevel) && echo top: $gittop
gitid=$(git rev-parse --short HEAD)
gituser
commit_msg
git commit -a -uno -m "$msg" --author=$USER

git tag -f -a $ver -m "tagging $gitid on $date"
# test if tag $ver exist ...
remote=$(git rev-parse --abbrev-ref @{upstream} |cut -d/ -f 1)
if git ls-remote --tags | grep "$ver"; then
  git push --delete $remote "$ver"
fi
echo "git push : "
git push --follow-tags $remote $branch
echo .
# ---------------------------------------------------------------------
true;

