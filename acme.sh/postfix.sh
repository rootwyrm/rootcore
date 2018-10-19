#!/bin/sh
#
# hooks/postfix.sh
# Hook for acme.sh to install certificates for Postfix on FreeBSD.

. /etc/rc.subr
. /etc/network.subr
. /var/db/acme/hooks/postfix.conf

log()
{
	logfile=/var/log/acme.sh.log
	if [ ! -f $logfile ]; then
		if [ ! -d /var/log/acme ]; then
			mkdir /var/log/acme
		fi
		touch $logfile
	fi
	echo $(date) [postfix] $1 | tee -a $logfile
}

get_hostname()
{
	if [ ! -z ${override_hostname} ]; then
		hostname=${override_hostname}
	elif [ -z ${hostname} ]; then
		hostname=$(hostname -f)
	fi
}

## XXX: Needs to be named this way.
renew_postfix()
{
	## Postfix requires special handling.
	if [ ! -d /usr/local/etc/postfix/ssl ]; then
		log "[ERROR] /usr/local/etc/postfix/ssl missing."
		exit 1
	fi
	if [ ! -d /var/db/acme/certs/${hostname} ]; then
		log "[ERROR] /var/db/acme/certs/${hostname} does not exist."
		exit 1
	fi

	local src=/var/db/acme/certs/${hostname}
	local dst=/usr/local/etc/postfix/ssl

	cp -f $src/*.cer $dst/
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy $src/*.cer to $dst/"
		exit 1
	fi
	log "Copied new certificate to $dst"
	cp -f $src/*.key $dst/
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy $src/*.key to $dst/"
		exit 1
	fi
	log "Copied new key to $dst"

	## Restart, not reload.
	service postfix restart
	if [ $? -ne 0 ]; then
		log "[ERROR] Failed to restart postfix."
		exit 1
	fi
	log "Restarted successfully."
}

