#

basedir=$HOME/repo/gist/stampit
artifact=$basedir/artifact

tic=$(date +%s)
ns=$(date +%N)
loc="Ecublens (Switzerland)"
symb=timestamp
gistdir=gist
tsdir=.
date=$(date)
pgm=$(readlink -m $0)
echo "--- # $pgm on $date"
sed -e 's/^tsdir=.*/tsdir=./' $0 > $tsdir/${0##*/}

if [ -e playload.txt ]; then
  playload=$(perl -pn -e 's/\n/\\n/g' playload.txt)
else
  playload="$*"
fi

if ipfs key list | grep -q $symb; then
key=$(ipfs key list -l --ipns-base b58mh | grep -w $symb | cut -d' ' -f 1)
ipns=$(ipfs name resolve /ipns/$key)
else
key=$(ipfs key gen -t rsa -s 3072 --ipns-base b58mh $symb)
ipns=QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn
fi


# ------------------------------------------------------
# collect artifact ...
cd $basedir
gitdir=$(git rev-parse --absolute-git-dir)
git checkout master
url=https://www.worldometers.info/coronavirus/
if [ -e $artifact/index.html ]; then
if expr $tic -  $(stat -c '%X' $artifact/index.html) \> 1711 >/dev/null; then
 rm $artifact/index.html
fi
fi
if [ ! -e $artifact/index.html ]; then
wget $opt -P $artifact -N -nH --cut-dirs=2 -E --convert-file-only -K -p -e robots=off -B "$url" --user-agent="$ua" -a $artifact/log.txt "$url"
fi
pandoc -t html -t markdown $artifact/index.html | grep -v -e ':::' -e '^$' > wmeters.md
pandoc -t html -t plain $artifact/index.html > $artifact/wmeters.txt
gituser
git commit -a -m "artifact on $(date)"
git push
cp -p $artifact/wmeters.txt $gistdir/
# ------------------------------------------------------
cd $gistdir
gitdir=$(git rev-parse --absolute-git-dir)
git checkout gist
gituser

echo "We've got (time)stamp" | ipfs add --pin=true -q

ver=$(perl -S version -a $0 | xyml scheduled)
echo ver: $ver
gitid=$(git rev-parse --short HEAD)
echo gitid: $gitid
headid=$(cat $gitdir/HEAD | cut -d' ' -f2)
echo headid: $headid

( cd $gitdir; git --bare update-server-info )
dgit=$(ipfs add -r $gitdir -Q)

#set -e
if [ ! -e  original-timestamp.md.gpg ]; then
gpg --sign -u "Michel G. Combes" original-timestamp.md
fi
rm -f original-timestamp.md original-timestamp.md.asc
#gpg --verify original-timestamp.md.gpg
gpg --batch -o original-timestamp.md --verify original-timestamp.md.gpg
gpg --clear-sign -a -u "Michel G. Combes" original-timestamp.md

if [ ! -e nip.txt ]; then
nip=$(curl -s https://app.safewatch.care/psgi/remote_addr.txt)
echo $nip > nip.txt
echo $tic >> nip.txt
echo $$ >> nip.txt
echo $ns >> nip.txt
fi
nip=$(head -1 nip.txt)
echo nip: $nip

if [ -e timestamp.md ]; then
mv timestamp.md previous-timestamp.md
fi
qm=$(ipfs add -r -w nip.txt $artifact previous-timestamp.md qm.log revs.log dgit.log $pgm --pin=true -Q)
echo qm: $qm
perl -S fullname.pl -a $qm > bot.yml
sed -e "s/tic: .*/tic: $tic/" -e "s/ver: .*/ver: $ver/" -e "s/ns: .*/ns: $ns/" \
    -e "s,date: .*,date: $date," -e "s/nip: .*/nip: $nip/" \
    -e "s/gitid: .*/gitid: $gitid/" -e "s/dgit: .*/dgit: $dgit/" \
    -e "s/qm: .*/qm: $qm/" -e "s,ipns: .*,ipns: $ipns," \
    -e "s/user: .*/user: $USER/" -e "s/loc: .*/loc: '$loc'/" \
    -e "s|playload: .*|playload: \"$playload\"|" \
    previous-timestamp.md > timestamp.md
    pandoc --template=timestamp.md timestamp.md | pandoc -o - | sed -e "s/\`<br>\`{=html}/\n/g" > timestamp.txt 
    gpg --clear-sign -a -u "Michel G. Combes" timestamp.txt

# ------------------------------------------------------
# compute sha for .asc file
if [ -e timestamp.txt.asc.ots ]; then
    sha=$(ots info  timestamp.txt.asc.ots | cut -d' ' -f4)
    otid=$(echo $hash | cut -c-12)
    ots upgrade timestamp.txt.asc.ots
    mv -n timestamp.txt.asc.ots $tsdir/ots/timestamp-$otid.txt.asc.ots
fi
hash=$(openssl sha256 -r timestamp.txt.asc | cut -d' ' -f1)
otid=$(echo $hash | cut -c-12)
echo otid: $otid
rm -f timestamp.txt.asc.ots
ots stamp timestamp.txt.asc
cp -p timestamp.txt.asc $tsdir/signed/timestamp-$otid.txt.asc
cp -p timestamp.txt.asc.ots $tsdir/ots/timestamp-$otid.txt.asc.ots

cp -p $gitdir/info/refs info-refs.txt
# ------------------------------------------------------
qm=$(ipfs add -r -w . -Q)
echo $tic: $qm >> qm.log
eval $(perl -S fullname.pl -a $qm | eyml)
git config committer.name "$fullname"
git config committer.email "$user@$domain"
export GIT_COMMITTER_NAME="$fullname"
export GIT_COMMITTER_EMAIL="$email"


git add qm.log timestamp.txt timestamp.txt.asc timestamp.txt.asc.ots

date=$(date +%D);
time=$(date +%T);

msg="stamped at $date on $time by $fullname ($ver)"
if git commit -a -m "$msg"; then
gitid=$(git rev-parse HEAD)
git tag -f -a $ver -m "tagging $gitid on $date"
#echo gitid: ${gitid:0:9} # this is bash!
echo gitid: $gitid | cut -b 1-14
if test -e revs.log; then
echo $tic: $gitid >> revs.log
fi

# test if tag $ver exist ...
remote=$(git rev-parse --abbrev-ref @{upstream} |cut -d/ -f 1)
if git ls-remote --tags | grep "$ver"; then
git push --delete $remote "$ver"
fi
fi
git push --follow-tags origin master

# -----------------------------------------
cd $tsdir
gitdir=$(git rev-parse --absolute-git-dir)
git checkout main
git merge gist
git add ots wmeters.txt

( cd $gitdir; git --bare update-server-info )
dgit=$(ipfs add -r $gitdir -Q)
echo $tic: $dgit >> dgit.log

git commit -a -m "$msg"
echo "git push : "
branch=$(git rev-parse --abbrev-ref HEAD)
git push --follow-tags github main
rm -f bal.tgz;
tar zcf ../bal.tgz .
mv ../bal.tgz .
qm=$(ipfs add -w -r . $gitdir/info/refs -Q);
echo $(date +"%s%N"): $qm >> bal.log
ipfs name publish --key=$symb $qm --allow-offline 
# external party
pina $qm "$symb-$(date +%y%m%d%H%M.%S)"

git add bal.tgz
git commit -a -m "tar bal on $(date)"
git push github main

#git push gitlab
#git push bitbucket

# -----------------------------------------
cd $basedir
gitdir=$(git rev-parse --absolute-git-dir)
git add artifact ts gist
git checkout master
git commit -a -m "${msg}"
