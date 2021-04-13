#

tic=$(date +%s)
tic=1617353635
find . -name "*~*" -delete
if [ ! -e  original-timestamp.md.gpg ]; then
gpg --sign -u "Michel G. Combes" original-timestamp.md
fi
rm -rf original-timestamp.md original-timestamp.md.asc
gpg --batch -o original-timestamp.md --verify original-timestamp.md.gpg
cp -p original-timestamp.md timestamp.md
rm -f previous-timestamp.md
rm -f timestamp.txt timestamp.txt.*
rm -f wmeters.md
rm -f artifact/*
echo -n '' > info-refs.txt
echo "--- # QmLogs for timestamping" > qm.log
echo "$tic: QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n" >> qm.log
echo '0.0.0.0' > nip.txt
echo "# revs logs ..." > revs.log
echo "--- # dgit logs ..." > dgit.log
echo "$tic: QmekkpM5xEpbxGnbc9WXszVNwHDQgb2RgV7NismP3eQwMA" > dgit.log

ticns=${tic}114590162
rm -rf emptyd
mkdir emptyd
touch -t $(date +%y%m%d%H%M.%S -d @$tic) emptyd
(cd emptyd; tar zcf ../bal.tgz .)
rm -rf emptyd
qm=$(ipfs add -w bal.tgz -Q)
echo "--- # bal logs ..." > bal.log
echo "$ticns: $qm" >> bal.log
echo "$(date +"%s%N"): $qm"

pgm=$0
artifact=artifact
cp -p timestamp.md previous-timestamp.md
qm=$(ipfs add -r -w nip.txt $artifact previous-timestamp.md qm.log revs.log dgit.log bal.log $pgm --pin=true -Q)
echo qm: $qm
perl -S fullname.pl -a $qm > bot.yml
cat bot.yml




