FROM	ubuntu:focal
ARG		QEMU=${QEMU:-5.1.0}

LABEL	maintainer="Phillip 'RootWyrm' Jaenke <prj@rootwyrm.com>" \
		com.rootwyrm.project="advbinfmt" \
		com.rootwyrm.vcs-type="github" \
        ## OCI
        org.opencontainers.image.authors="RootWyrm" \
        org.opencontainers.image.vendor="RootWyrm" \
        org.opencontainers.image.licenses="BSD-3-Clause"

RUN	export DEBIAN_FRONTEND=noninteractive && \
	echo "Updating apt..." ; apt-get -q -y update > /dev/null 2>&1 && \
	echo "Upgrading base..." ; apt-get -q -y upgrade > /dev/null 2>&1 && \
	## autolearn packages
	dpkg --get-selections | awk '{print $1}' > /pkg.base && \
	echo "Installing build packages..." ; \
	apt-get -q -y install apt-utils > /dev/null 2>&1 && \
	dpkg-reconfigure debconf -f noninteractive ; \
	apt-get -q -y install libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev clang make wget > /dev/null 2>&1 && \
	echo "Done installing build packages..." ; \
	dpkg --get-selections | awk '{print $1}' > /pkg.build && \
	## Need to configure tzdata
	ln -fs /usr/share/zoneinfon/UTC /etc/localtime ; \
	dpkg-reconfigure -f noninteractive tzdata ; \
	echo "Downloading qemu..." ; \
	cd /root ; wget https://download.qemu.org/qemu-${QEMU}.tar.xz && \
	tar xf qemu-${QEMU}.tar.xz && \
	cd qemu-${QEMU} && \
	echo "Building qemu..." ; \
	./configure --enable-linux-user --enable-pie && \
	make && \
	make install && \
	cd /root && \
	diff -U /pkg.build /pkg.base | grep '^-' > /root/pkg.remove && \
	rm /pkg.base /pkg.build && \
	apt-get purge `cat /root/pkg.remove | sed -e 's/^-//g'` && \
	rm /root/pkg.remove && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*_dists_*

CMD	[ "sh", "-c", "update-binfmts --enable" ]
