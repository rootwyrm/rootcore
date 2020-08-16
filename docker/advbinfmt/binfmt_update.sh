#!/bin/bash
################################################################################
## Copyright (C) 2020-* Phillip "RootWyrm" Jaenke
## All rights reserved
##
## BSD-3-Clause
################################################################################

## This is just to make things less annoying...
if [ ! -f /root/qemu-binfmt-conf.sh ]; then
	echo "Missing qemu-binfmt-conf.sh??"
	exit 255
fi

/root/qemu-binfmt-conf.sh --debian --persistent=yes

for x in aarch64 arm mips64 mips64el ppc64 ppc64le riscv64 s390x; do
	printf 'Enabling %s...\n' "$x"
	update-binfmts --importdir /usr/share/binfmts --import qemu-${x}
done

## Show what we have.
update-binfmts --enable
update-binfmts --display | grep enabled
