#!/bin/bash
## application/build/10.dnsdist.sh

# Copyright (C) 2015-* Phillip R. Jaenke <prj+docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMITTED WITHOUT
# EXPRESS WRITTEN CONSENT

######################################################################
## Function Import and Setup
######################################################################

. /opt/rootwyrm/lib/deploy.lib.sh

#export IFS=$'\n'
export BUILDNAME="dnsdist"

## Build
export vbpkg="dnsdist_build"
export vbpkg_content="git gcc g++ make autoconf automake openssl-dev luajit-dev fstrm-dev libsodium-dev libedit-dev boost-dev h2o-dev lmdb-dev protobuf-dev re2-dev"
## Runtime
export vrpkg="dnsdist_run"
export vrpkg_content="curl gettext openssl luajit libedit libsodium boost h2o lmdb libprotobuf libprotoc protoc re2 fstrm" 

export curl_cmd="/usr/bin/curl --tlsv1.2 --cert-status -L --silent"
export dnsdistv="1.5.0-rc2"

install_runtime()
{
	######################################################################
	## Install runtime packages first.
	######################################################################
	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Installing runtime dependencies as $vrpkg"
	/sbin/apk --no-cache add --virtual $vrpkg $vrpkg_content > /dev/null 2>&1
	CHECK_ERROR $? $vrpkg
}

install_buildpkg()
{
	######################################################################
	## Install our build packages.
	######################################################################
	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Entering build phase."
	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Installing build dependencies as $vbpkg"
	/sbin/apk --no-cache add --virtual $vbpkg $vbpkg_content > /dev/null 2>&1 
	CHECK_ERROR $? $vbpkg
}

user_dnsdist()
{
	## Need to create our user
	adduser -g "dnsdist user" -D -H -s /sbin/nologin -u 5300 dnsdist
	CHECK_ERROR $? dnsdist_user
}

build_dnsdist()
{
	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Retrieving $dnsdistv"
	if [ ! -d /usr/local/src ]; then
		mkdir /usr/local/src
	fi
	cd /usr/local/src
	$curl_cmd https://downloads.powerdns.com/releases/dnsdist-$dnsdistv.tar.bz2 > dnsdist-$dnsdistv.tar.bz2
	tar xf dnsdist-$dnsdistv.tar.bz2
	rm dnsdist-$dnsdistv.tar.bz2
	cd dnsdist-$dnsdistv
	## XXX: Work around a bug.
	mkdir ibdir

	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Configuring..."
	## Be extremely explicit.
	./configure \
		--with-lua --with-re2 --with-ebpf \
		--enable-dnstap --enable-dnscrypt --enable-dns-over-tls \
		--enable-dns-over-https --with-re2
	CHECK_ERROR $? "dnsdist_configure"
	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] configure complete."

	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Building..."
	make 
	CHECK_ERROR $? "dnsdist_build"
	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Build complete."

	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Doing make install..."
	make install
	CHECK_ERROR $? "dnsdist_install"
	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] make install complete"
}

clean_dnsdist()
{
	######################################################################
	## Clean up after ourselves, because seriously, this is batshit huge.
	######################################################################
	echo "$(date '+%b %d %H:%M:%S') [${BUILDNAME}] Cleaning up build."
	make clean
	cd /root
	rm -rf /usr/local/src/dnsdist-$dnsdistv
	CHECK_ERROR $? "dnsdist_clean_delete_source"
	/sbin/apk --no-cache del $vbpkg
	CHECK_ERROR $? "dnsdist_clean_apk"
}

install_runtime
install_buildpkg
build_dnsdist
clean_dnsdist

echo "$(date '+%b %d %H:%M:%S') [dnsdist] Build and install of $dnsdistv complete."
exit 0 
