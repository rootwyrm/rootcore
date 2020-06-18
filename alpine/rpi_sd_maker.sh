#/bin/bash -x
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

CHROOT=/alpine

## alt 3.10.4 aarch64
ALPINE_MAJOR=3
ALPINE_MINOR=11
ALPINE_UPDATE=6
case $3 in 
	uboot)
		export ALPINE_URL=http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR}.${ALPINE_MINOR}/releases/aarch64/alpine-uboot-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz
		export RELFILE=/tmp/alpine-uboot-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz
		;;
	*)
		export ALPINE_URL=http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR}.${ALPINE_MINOR}/releases/aarch64/alpine-rpi-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz
		export RELFILE=/tmp/alpine-rpi-${ALPINE_MAJOR}.${ALPINE_MINOR}.${ALPINE_UPDATE}-aarch64.tar.gz
		;;
esac

## RPI firmware doesn't like /boot, also sometimes doesn't like ini-style 
## layout, so we have to fix up the boot partition. 
function fix_boot_partition()
{
	echo "NYI"
}

## Set up and mount our chroot
function alpine_chroot()
{
	if [ ! -d $CHROOT ]; then
		mkdir $CHROOT
	fi
	mount $1 $CHROOT
	if [ $? -ne 0 ]; then
		echo "Error mounting SD to chroot"
		exit 1
	fi
	
	if [ ! -d $CHROOT/boot ]; then
		mkdir $CHROOT/boot
	fi
	mount $2 $CHROOT/boot
	if [ $? -ne 0 ]; then
		echo "Error mounting SD boot partition to chroot"
		exit 1
	fi
}

## Create our partitions a very, very specific way.
function sd_create_partition()
{
	if [ -z $1 ]; then
		echo "Called sd_create_partition without device shortname"
		exit 1
	else
		DEVICE=/dev/$1
	fi

	if [ -b ${DEVICE}1 ]; then
		printf 'SD has existing contents, not overwriting.\n'
		exit 1
	fi

	parted -s $DEVICE mklabel msdos
	parted -s $DEVICE mkpart primary fat32 1 512MB
	mkfs.vfat -n "BOOT" ${DEVICE}1
	parted -s $DEVICE -- set 1 boot on

	parted -s $DEVICE mkpart primary ext4 512MB 100%
	mkfs.ext4 -L "alpine" ${DEVICE}2

	alpine_chroot ${DEVICE}2 ${DEVICE}1
}

## Download the Alpine release.
function alpine_fetch()
{
	# Delete every time just for convenience right now.
	if [ -f $RELFILE ]; then
		rm $RELFILE
	fi

	curl $ALPINE_URL > $RELFILE
	if [ $? -ne 0 ]; then
		RC=$?
		printf 'Download of release failed! - error %s\n' "$RC"
		printf 'Tried %s\n' "$ALPINE_URL"
		exit $RC
	fi
	## Also check the checksum.
	curl ${ALPINE_URL}.sha256 > ${RELFILE}.sha256
	SHA256_SOURCE=$(cat ${RELFILE}.sha256 | awk '{print $1}')
	SHA256_RESULT=$(sha256sum ${RELFILE} | awk '{print $1}')
	if [[ $SHA256_SOURCE != $SHA256_RESULT ]]; then
		printf 'Downloaded file does not match checksum!\n'
		exit 255
	fi
}

## Do our initial extraction.
function rpi_extract()
{
	if [ ! -d $CHROOT/boot ]; then
		printf 'Entered rpi_extract without a mounted SD card??\n'
		exit 2
	fi

	tar xzvf $RELFILE -C $CHROOT/boot --no-same-owner
	if [ $? -ne 0 ]; then
		RC=$?
		printf 'Error extracting $RELFILE ! - error %s\n' "$RC"
		exit $RC
	fi
}

## Simple usercfg fixup
function rpi_usercfg()
{
	echo "enable_uart=1" >> $CHROOT/boot/usercfg.txt
}

## Fix Alpine booting; the rpi does not like the subdirectory!
function rpi_fixboot()
{
	sed -i -e 's,boot/,,g' $CHROOT/boot/config.txt
	cp $CHROOT/boot/boot/* $CHROOT/boot/
}

function alpine_auto()
{
## Now write the magical auto-installation script to the partition before
## unmounting it.
cat << EOF > /alpine/alpine_auto.sh
!/bin/sh
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

cd /mnt ; ln -s media/mmcblk0p1/boot boot
cd /root

echo "/dev/mmcblk0p1	/media/mmcblk0p1	vfat	defaults	0 0" >> /mnt/etc/fstab
sed -i '/cdrom/d' /mnt/etc/fstab
sed -i '/floppy/d' /mnt/etc/fstab

## Insert the root device correctly.
sed -i '/$/ s,$, root=\/dev\/mmcblk0p2,' /media/mmcblk0p1/cmdline.txt

echo "Complete!"
EOF
chmod +x /mnt/alpine_auto.sh
}
#umount /mnt

if [ -z $1 ]; then
	printf 'Need to provide device short-name (e.g. sdf)!\n'
	exit 1
fi
alpine_fetch
sd_create_partition $1
rpi_extract
rpi_usercfg
rpi_fixboot
#alpine_auto

umount /alpine/boot
umount /alpine

echo "SD Card ready for use."
