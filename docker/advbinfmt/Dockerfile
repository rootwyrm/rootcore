FROM	debian:buster-slim AS qemu-user
ARG		QEMU=${QEMU:-5.1.0}
ENV		QEMU=${QEMU:-5.1.0}

LABEL   maintainer="Phillip 'RootWyrm' Jaenke <prj@rootwyrm.com>" \
        com.rootwyrm.project="advbinfmt" \
        com.rootwyrm.vcs-type="github" \
        com.rootwyrm.url="https://github.com/rootwyrm/rootcore" \
        com.rootwyrm.software="qemu" \
        com.rootwyrm.software.version="$QEMU" \
        ## OCI
        org.opencontainers.image.authors="RootWyrm" \
        org.opencontainers.image.vendor="RootWyrm" \
        org.opencontainers.image.licenses="BSD-3-Clause"

COPY [ "binfmt_update.sh", "/root/binfmt_update.sh" ]
RUN	export DEBIAN_FRONTEND=noninteractive && \
	echo "Updating apt..." ; apt-get -q -y update > /dev/null 2>&1 && \
	echo "Upgrading base..." ; apt-get -q -y upgrade > /dev/null 2>&1 && \
	apt-get -q -y install binfmt-support > /dev/null 2>&1 && \
	## autolearn packages
	dpkg --get-selections | awk '{print $1}' > /pkg.base && \
	echo "Installing build packages..." ; \
	apt-get -q -y install apt-utils > /dev/null 2>&1 && \
	dpkg-reconfigure debconf -f noninteractive ; \
    apt-get -q -y install \
    build-essential \
    git \
    libtool \
    libpixman-1-dev \
    libglib2.0-dev \
    python3 \
    wget && \
	echo "Done installing build packages..." ; \
	dpkg --get-selections | awk '{print $1}' > /pkg.build && \
	## Need to configure tzdata
	echo "Downloading qemu..." ; \
	cd /root ; wget https://download.qemu.org/qemu-${QEMU}.tar.xz && \
	tar xf qemu-${QEMU}.tar.xz && \
	cd qemu-${QEMU} && \
	echo "Building qemu..." ; \
	./configure \
	--prefix=/usr \
    --with-pkgversion=${QEMU} \
    --enable-user \
    --enable-linux-user \
    --disable-system \
    --disable-bsd-user \
    --disable-guest-agent \
    --disable-guest-agent-msi \
    --disable-pie \
    --disable-gnutls \
    --disable-nettle \
    --disable-gcrypt \
    --disable-blobs \
    --disable-brlapi \
    --disable-cap-ng \
    --disable-capstone \
    --disable-curl \
    --disable-docs \
    --disable-gtk \
    --disable-libiscsi \
    --disable-libnfs \
    --disable-mpath \
    --disable-opengl \
    --disable-iconv \
    --disable-virglrenderer \
    --disable-sdl \
    --disable-spice \
    --disable-tools \
    --disable-vte \
    --target-list="aarch64-linux-user arm-linux-user mips64-linux-user mips64el-linux-user ppc64-linux-user ppc64le-linux-user s390x-linux-user riscv64-linux-user" && \
	make -j "$(getconf _NPROCESSORS_ONLN)" && \
	make install && \
    cp /root/qemu-${QEMU}/scripts/qemu-binfmt-conf.sh /root/ && \
	cd /root && \
	rm -rf qemu-${QEMU}* 
	#&& \
    #/root/qemu-binfmt-conf.sh --debian --qemu-path=/usr && \
	#diff -u /pkg.build /pkg.base > /root/pkg.remove && \
	#rm /pkg.base /pkg.build && \
	## Now bake the pkg.remove file...
	#sed -i -e '/^\@\@/d' /root/pkg.remove ; \
	#sed -i -e '/^\-\-\-/d' /root/pkg.remove ; \
	#sed -i -e '/^\+\+\+/d' /root/pkg.remove ; \
	#sed -i -e '/ /d' /root/pkg.remove ; \
	#echo "Purging unneeded packages..." ; \
	#apt-get purge -q -y `cat /root/pkg.remove | sed -e 's/^-//g'` && \
	#apt-get autoremove -y && \
	#rm /root/pkg.remove && \
	#apt-get clean && \
	#rm -rf /var/lib/apt/lists/*_dists_*

FROM linuxkit/alpine:v0.8 AS mirror
RUN	apk add --no-cache go musl-dev
ENV GOPATH=/go PATH=$PATH:/go/bin

COPY main.go /go/src/binfmt/
RUN	go-compile.sh /go/src/binfmt

FROM scratch
ENTRYPOINT []
WORKDIR /
COPY --from=qemu-user usr/bin/qemu-* usr/bin/
COPY --from=mirror /go/bin/binfmt usr/bin/binfmt
COPY 00_linuxkit.conf etc/binfmt.d/00_linuxkit.conf
CMD ["/usr/bin/binfmt"]
