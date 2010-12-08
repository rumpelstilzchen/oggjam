#/bin/sh

# (c) 2010 Roman Naumann
# License: MIT; for details, see:
#   http://www.opensource.org/licenses/mit-license.php

# oggjam downloads ogg album archives directly from jamendo and adds them to
# your completed torrent dir, so that you become a seeder. Useful, since
# jamendo ogg torrents mostly lack seeders alltogether...

# tested with transmission torrent daemon
#
# If you don't use transmission, look through the whole file,
# especially the end, where transmission is told to 'reverify' the
# torrent we downloaded. Without the last option, the
# transmission-daemon does not notice that the files are available
# already.

# requirements:
# - transmission, unzip
# - basic *nix utils: sh; sed

# $1 is album id
album_id="$1"
# $2 is "-n" if you don't want to download again (i.e. have the files already)
no_dl="$2"

# change these for your local paths
TMP="/tmp" # default on most *nix-es
TORRENT_DIR="$HOME/dlc" # preset for vuze torrent client

# you may, but need not nes. change this
tmp_dir="${TMP}/oggjam_${album_id}"

set -e # abort on error

if [ ! -n "$album_id" ]; then
	echo "error: supply album id!" && false
fi

echo "oggjam - 0.1"
echo "...creating temporary directory"
mkdir -p "$tmp_dir"

cd "$tmp_dir"
echo "...downloading album"
if [ "$no_dl" == "-n" ]; then
	echo "...no downloading due to -n cmd flag"
else
	wget -nv "http://www.jamendo.com/get/album/id/album/archiverestricted/redirect/${album_id}/?p2pnet=bittorrent&are=ogg3"
fi
zipname="$(ls *.zip | head -1)"
# extract name from {name}.zip
name="`echo "$zipname" | sed -E "s/(.*)\.zip$/\1/"`"
mkdir -p "unpacked"
echo "...extracting $zipname"
unzip -ud "unpacked" "$zipname"
echo "...moving files from $name"
mv -f "unpacked" "${TORRENT_DIR}/${name}"

echo "...removing temporary directory"
rm -rf "$tmp_dir"

echo "...reverifying torrent in transmission"
short_name="`echo "$name" | sed -E "s|(.*) -- Jamendo -.*|\1|"`"
transmission_id="`transmission-remote -l | grep "$short_name" | sed -E "s| *([0-9]*).*|\1|"`"
transmission-remote -t "$transmission_id" -v
echo "...script finished successfully!"
