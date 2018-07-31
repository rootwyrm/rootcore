#!/bin/sh

## Fetch our origins.
mkdir etc
fetch https://raw.githubusercontent.com/pfsense/pfsense/caf4d7127c975d23262f26c893e5f16cc0bba9ff/src/etc/rc.carpbackup -o etc/rc.carpbackup
fetch https://raw.githubusercontent.com/pfsense/pfsense/caf4d7127c975d23262f26c893e5f16cc0bba9ff/src/etc/rc.carpmaster -o etc/rc.carpmaster

cp etc/rc.carpbackup etc/rc.carpbackup.orig
cp etc/rc.carpmaster etc/rc.carpmaster.orig

vim etc/rc.carpbackup
vim etc/rc.carpmaster

diff -u -p0 etc/rc.carpbackup.orig etc/rc.carpbackup >> patch_$(date +%d%m%Y).patch
diff -u -p0 etc/rc.carpmaster.orig etc/rc.carpmaster >> patch_$(date +%d%m%Y).patch
diff -u --new-file MUPL.md ../../MUPL.md >> patch_$(date +%d%m%Y).patch
