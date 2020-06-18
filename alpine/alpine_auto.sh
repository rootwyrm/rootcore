#!/bin/sh
################################################################################
# Alpine Auto-Installer for RPi4
# Copyright 2020-* Phillip R. Jaenke, All rights reserved
#
# BSD 4-Clause License
################################################################################

setup-alpine

apk add chrony e2fsprogs
service chronyd restart
mount /dev/mmcblk0p2 /mnt
mount -o remount,rw /media/mmcblk0p1

setup-disk -m sys /mnt

## Clean up certain files.
rm -f /media/mmcblk0p1/boot/*
rm /mnt/boot/boot
mv /mnt/boot/* /media/mmcblk0p1/boot/
rm -Rf /mnt/boot
mkdir /mnt/media/mmcblk0p1
mkdir /mnt/boot
#cd /mnt ; ln -s media/mmcblk0p1/boot boot

## Fix fstab
echo "/dev/mmcblk0p1 /media/mmcblk0p1 vfat defaults 0 0" >> /etc/fstab
echo "tmpfs /tmp tmpfs rw,size=512m 0 0" >> /etc/fstab
echo "" >> /etc/fstab
echo "## Modloop" >> /etc/fstab
echo "/media/mmcblk0p1/boot /boot none defaults,bind 0 0" >> /etc/fstab

## Fix the cmdline.txt
sed -i '/$/ s,$, root-\/dev\/mmcblk0p2,' /media/mmcblk0p1/cmdline.txt
