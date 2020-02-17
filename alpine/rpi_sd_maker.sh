#/bin/bash
################################################################################
# 
# Copyright (c) 2020-* Phillip R. Jaenke <prj@rootwyrm.com>. 
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, 
#    this list of conditions and the following disclaimer in the documentation 
#    and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software 
#    must display the following acknowledgement:
#    This product includes software developed by Phillip R. Jaenke.
# 4. Neither the name of the copyright holder nor the names of its contributors 
#    may be used to endorse or promote products derived from this software 
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDER "AS IS" AND ANY EXPRESS OR 
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
# EVENT SHALL COPYRIGHT HOLDER BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
#
################################################################################
# This tool makes an SD card ready for Alpine Linux

ALPINE_MAJOR=3
ALPINE_MINOR=11
ALPINE_UPDATE=3
ALPINE_URL=http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR}.${ALPINE_MINOR}/releases/aarch64/alpine-rpi-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz

if [ -z $1 ]; then
	echo "Need to specify the devide shortname (e.g. sdf)"
	exit 1
else
	DEVICE=/dev/$1
fi

parted -s $DEVICE mklabel msdos
# Ensure we're aligned properly.
parted -s $DEVICE mkpart primary fat32 1 512MB
parted -s $DEVICE set 1 boot on
mkfs.vfat -n "BOOT" ${DEVICE}1

mount -t vfat ${DEVICE}1 /mnt

if [ -f /tmp/alpine-rpi-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz ]; then
	rm -f /tmp/alpine-rpi-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz
fi	
curl $ALPINE_URL > /tmp/alpine-rpi-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz
tar xzvf /tmp/alpine-rpi-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz -C /mnt --no-same-owner

## Work around bug.
echo "enable_uart=1" >> /mnt/usercfg.txt

## Now add our actual system partition
parted -s $DEVICE mkpart primary ext4 512MB 100%
mkfs.ext4 -L alpine ${DEVICE}2

## Now write the magical auto-installation script to the partition before
## unmounting it.
cat << EOF > /mnt/alpine_auto.sh
#!/bin/sh
################################################################################
# Alpine Auto-Installer for RPi3+
# Copyright (C) 2020-* Phillip R. Jaenke <prj@rootwyrm.com>
################################################################################

setup-alpine

apk update
apk add chrony e2fsprogs 
service chronyd restart
mount /dev/mmcblk0p2 /mnt
setup-disk -m sys /mnt
mount -o remount,rw /media/mmcblk0p1

## Clean up certain files
rm -f /media/mmcblk0p1/boot/*
rm /mnt/boot/boot
mv /mnt/boot/* /media/mmcblk0p1/boot/
rm -Rf /mnt/boot
mkdir /mnt/media/mmcblk0p1

ln -s /media/mmcblk0p1/boot /mnt/boot

echo "/dev/mmcblk0p1	/media/mmcblk0p1	vfat	defaults	0 0" >> /mnt/etc/fstab
sed -i '/cdrom/d' /mnt/etc/fstab
sed -i '/floppy/d' /mnt/etc/fstab

sed -i 's/^/root=\/dev\/mmcblk0p2 /' /media/mmcblk0p1/cmdline.txt

echo "Complete!"
EOF
chmod +x /mnt/alpine_auto.sh

#umount /mnt
echo "SD Card ready for use."
