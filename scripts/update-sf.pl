#!/bin/sh
set -e
cd ~/sf.net
rm -rf htdocs
mkdir htdocs
cd htdocs

O=~/ids/docs
cp -aL $O/static .
cp -aL $O/{v2.2,pci.ids*} .
sed <$O/index.html >index.html -e '
	s@href="/\(read\|mods\)/@href="http://pci-ids.ucw.cz/\1/@g
'

rsync -avz --delete ~/sf.net/htdocs mares,pciids@web.sourceforge.net:
