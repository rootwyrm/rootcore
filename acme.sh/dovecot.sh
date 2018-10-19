#!/bin/sh
#
# hooks/dovecot.sh
# Hook for acme.sh to install certificates for dovecot on FreeBSD.

. /etc/rc.subr
. /etc/network.subr
. /var/db/acme/hooks/dovecot.conf

log()
{
	logfile=/var/log/acme.sh.log
	if [ ! -f $logfile ]; then
		if [ ! -d /var/log/acme ]; then
			mkdir /var/log/acme
		fi
		touch $logfile
	fi
	echo "$(date) [dovecot] $1" | tee -a $logfile
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
renew_dovecot()
{
        ## Dovecot doesn't require any special handling.
        ## XXX: Does have to stop and restart due to pigeonhole
        service dovecot stop
        if [ $? -ne 0 ]; then
                log "[ERROR] Failed to stop dovecot."
                exit 1
        fi
        log "[dovecot] Stopped service successfully."

        service dovecot start
        if [ $? -ne 0 ]; then
                log "[ERROR] Failed to start dovecot."
                exit 1
        fi
        log "[dovecot] Started service successfully."
}

get_hostname
renew_dovecot
