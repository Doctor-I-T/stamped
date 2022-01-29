#

STAMPDIR=$HOME/repo/gist/stampit

export IPFS_PATH=$HOME/.../ipfs/usb/STAMPED
ipfs add "$@" | perl -S stamped.pl >> $STAMPDIR/stamped.log
msg=$(tail -1 $STAMPDIR/stamped.log | cut -d' ' -f-2)
cd $STAMPDIR
sh publish.sh "$msg"

