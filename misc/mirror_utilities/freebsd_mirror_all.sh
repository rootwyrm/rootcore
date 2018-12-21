#!/usr/local/bin/bash

export do_date=$(date +"%b %d %H:%M:%S")

log()
{
	printf '%s %s %s\n' "$do_date" "$1" "$2"
}

export GLOBAL_URL="https://download.freebsd.org/ftp/releases"
        #/$ARCH/$rel-RELEASE/$f

export RELEASES="11.2 12.0"

retrieval_loop()
{
	OUTBASE=/opt/repo/freebsd/$1
	for rel in ${RELEASES}; do
		test -d $OUTBASE/$rel-RELEASE
		if [ $? -ne 0 ]; then
			mkdir -p $OUTBASE/$rel-RELEASE
		fi
		## Retrieve the MANIFEST we will work from.
		fetch -o $OUTBASE/$rel-RELEASE/MANIFEST ${GLOBAL_URL}/$1/$rel-RELEASE/MANIFEST
		if [ $? -ne 0 ]; then
			log $1 "Failed to retrieve $rel MANIFEST."
		fi
	done

	for rel in ${RELEASES}; do
		for txz in `cat $OUTBASE/$rel-RELEASE/MANIFEST | awk '{print $1}'`; do
			test -f $OUTBASE/$rel-RELEASE/$txz
			if [ $? -eq 0 ]; then
				## Mirror it.
				fetch -m -o $OUTBASE/$rel-RELEASE/$txz ${GLOBAL_URL}/$1/$rel-RELEASE/$txz
				if [ $? -ne 0 ]; then
					log $1 "Failed to retrieve $txz"
				fi
			else
				fetch -o $OUTBASE/$rel-RELEASE/$txz ${GLOBAL_URL}/$1/$rel-RELEASE/$txz
				if [ $? -ne 0 ]; then
					log $1 "Failed to retrieve $txz"
				fi
			fi
		done
	done
}

sha256sum_check()
{
	OUTBASE=/opt/repo/freebsd/$1
	for rel in $RELEASES; do
		for x in `cat $OUTBASE/$rel-RELEASE/MANIFEST | awk '{print $1","$2}'`; do
			file=$(echo $x | cut -d , -f 1)
			csum=$(echo $x | cut -d , -f 2)
			if [[ $(sha256 -q $OUTBASE/$rel-RELEASE/$file) != $csum ]]; then
				log $1 "$OUTBASE/$rel-RELEASE/$file checksum error!"
			else
				log $1 "$OUTBASE/$rel-RELEASE/$file verified."
			fi
		done
	done
}

arm64_aarch64()
{
        export ARCH="arm64/aarch64"
        retrieval_loop $ARCH
        sha256sum_check $ARCH
}

arm64()
{
        export ARCH="arm64"
        retrieval_loop $ARCH
        sha256sum_check $ARCH
}

armv6()
{
        export ARCH="arm/armv6"
        retrieval_loop $ARCH
        sha256sum_check $ARCH
}

armv7()
{
        export ARCH="arm/armv7"
        retrieval_loop $ARCH
        sha256sum_check $ARCH
}

amd64()
{
        export ARCH="amd64"
        retrieval_loop $ARCH
        sha256sum_check $ARCH
}

i386()
{
        export ARCH="i386"
        retrieval_loop $ARCH
        sha256sum_check $ARCH
}

powerpc()
{
        export ARCH="powerpc"
        retrieval_loop $ARCH
        sha256sum_check $ARCH
}

arm64_aarch64
arm64
#armv6
#armv7
amd64
i386
powerpc
