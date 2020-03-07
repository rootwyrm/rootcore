#!/bin/bash
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
# CAUTION: Assumes you already have bash installed. (Obviously.)

ntp_url="http://www.eecis.udel.edu/~ntp/ntp_spool/ntp4/ntp-4.2/ntp-4.2.8p14.tar.gz"
ntp_version="4.2.8p14"

ntp_build_dir="/usr/src/ntp-${ntp_version}"

if [ ! -d /usr/src ]; then
	mkdir -p /usr/src
fi
wget $ntp_url -o /usr/src/ntp-${ntp_version}.tar.gz
tar xfpz /usr/src/ntp-${ntp_version}.tar.gz -C /usr/src/

## Virtual build package
ntp_vb_pkg="make gcc g++ openssl-dev libevent-dev readline-dev linux-headers"
## Virtual run package
ntp_vr_pkg="openssl ca-certificates-cacert libevent readline"

## Set our baseline configuration arguments...
CONFIG_ARGS="--prefix=/usr/local --enable-thread-support --with-crypto --enable-autokey --enable-bug-1243-fix --enable-bug-3020-fix --enable-bug3527-fix --enable-getifaddrs=yes"

# Figure out if we have samba.
if [ -f /usr/bin/samba-tool ]; then
	CONFIG_ARGS+="--enable-ntp-signd"
	ntp_pkg_vb+="samba-dev"
	ntp_pkg_vr+="samba-dc"
fi
## Figure out if we'll use IPv6
if [[ $(sysctl -n net.ipv6.conf.all.disable_ipv6) = 0 ]]; then
	CONFIG_ARGS+="--enable-ipv6"
fi

## Install our virtuals
apk add --virtual ntp_runtime $ntp_vr_pkg
apk add --virtual ntp_vb_pkg $ntp_vb_pkg


## We need to do some things special for Alpine here.
cd $ntp_build_dir
./configure $CONFIG_ARGS
make
make install

## Install our default config at /etc
cat << EOF > /etc/ntp.conf
# Default NTP configuration for Alpine Linux
 
# Set the target and limit for adding servers configured via pool statements
# or discovered dynamically via mechanisms such as broadcast and manycast.
# Ntpd automatically adds maxclock-1 servers from configured pools, and may
# add as many as maxclock*2 if necessary to ensure that at least minclock
# servers are providing good consistant time.
#
tos minclock 3 maxclock 6

# Use the public NTP.org pools; enable iburst for faster initial sync
pool 0.pool.ntp.org iburst
# If you want to use a geographically closer pool, change the CC here to
# your country code (e.g. us, ca, es), comment the above pool, then uncomment 
# this one.
#pool 0.CC.pool.ntp.org

# By default, only allow time queries and block all other requests
# from unauthenticated clients.
restrict default limited kod nomodify notrap noquery nopeer
restrict source  limited kod nomodify notrap noquery
# The following settings allow unrestricted access from the localhost
restrict 127.0.0.1
restrict ::1

# If a server loses sync with all upstream servers, NTP clients
# no longer follow that server. The local clock can be configured
# to provide a time source when this happens, but it should usually
# be configured on just one server on a network. For more details see
# http://support.ntp.org/bin/view/Support/UndisciplinedLocalClock
# The use of Orphan Mode may be preferable.
#
#server 127.127.1.0
#fudge 127.127.1.0 stratum 10

# See http://support.ntp.org/bin/view/Support/ConfiguringNTP#Section_6.14.
# for documentation regarding leapfile. Updates to the file can be obtained
# from ftp://time.nist.gov/pub/ or ftp://tycho.usno.navy.mil/pub/ntp/.
# Use either leapfile in /etc/ntp or periodically updated leapfile in /var/db.
#
#leapfile "/etc/ntp/leap-seconds"
leapfile "/usr/local/share/ntp/leap-seconds.list"
EOF

if [ ! -x /usr/bin/wget ]; then
	## User might not want it, so do it temporarily.
	apk add wget
	wget -o /usr/local/share/ntp/leap-seconds.list ftp://ftp.nist.gov/pub/time/leap-seconds.list
	apk del wget
else
	wget -o /usr/local/share/ntp/leap-seconds.list ftp://ftp.nist.gov/pub/time/leap-seconds.list
fi

## Install our openrc script
cat << EOF > /etc/init.d/ntpd
#!/sbin/openrc-run
# Copyright (c) 2020-* Phillip R. Jaenke
#
# This is an OpenRC script for ntpd on Alpine Linux

description="Starts the NTPD service"

NTPD_FLAGS=""
NTPD_CONFIGFILE="/etc/ntp.conf"
NTPD_PIDFILE="/run/ntpd/ntpd.pid"

depend()
{
	provide clock
	after bootmisc hwdrivers modules
	keyword -docker -lxc -jail -prefix -systemd-nspawn -vserver
}

start_pre() {
	checkpath --file "/etc/ntp.conf"
	checkpath --directory "/run/ntpd"
}

start() {
	ebegin "Starting ntpd"
	eindent
	/usr/local/bin/ntpd
	eoutdent
	return $ret
}

stop() {
	ebegin "Stopping ntpd"
	eindent
	kill -9 $(cat /run/ntpd/ntpd.pid)
	eoutdent
	return 0
}
EOF
chmod +x /etc/init.d/ntpd

## Disable any other clocks.
for cs in chronyd openntpd sntpc; do
	rc-update del $cs
done
rc-update add ntpd

## Clean up our build package
apk del ntpd_vb_pkg
