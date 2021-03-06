#!/bin/sh
set -e
export CVS_RSH=ssh
cd ~/sf.net/htdocs
cvs upd -Ad

O=/var/www/html
cp -pr $O/static .
cp -p $O/usb.ids .
cp -p $O/usb.ids.gz .
cp -p $O/usb.ids.bz2 .
cp -p $O/usb-ids.diff .
cp -p $O/usbids.tgz .
sed <$O/index.html >usb-ids.html -e '
	s@href="/\(read\|mods\)/@href="http://usb-ids.gowdy.us/\1/@g
'
touch -r $O/index.html usb-ids.html

cvs ci -m 'Updating to latest version'
rsync -avz --delete ~/sf.net/htdocs gowdy,linux-usb@web.sourceforge.net:
