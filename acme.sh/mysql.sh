#!/bin/sh
#
# hooks/mysql.sh
# Hook for acme.sh to install certificates for MySQL/Maria/Percona on FreeBSD.

. /etc/rc.subr
. /etc/network.subr
. /var/db/acme/hooks/mysql.conf

log()
{
	logfile=/var/log/acme.sh.log
	if [ ! -f $logfile ]; then
		if [ ! -d /var/log/acme ]; then
			mkdir /var/log/acme
		fi
		touch $logfile
	fi
	echo "$(date) [mysql] $1" | tee -a $logfile
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
## XXX: Doesn't support profiles yet. :(
renew_mysql()
{
	if [ -z ${mysql_dbdir} ]; then
		log "[ERROR] mysql_dbdir is unset!"
		exit 255
	elif [ ! -d ${mysql_dbdir} ]; then
		log "[ERROR] mysql_dbdir directory ${mysql_dbdir} does not exist."
		exit 255
	fi
	## XXX: Doesn't support profiles yet.
	if [ ! -d /var/db/acme/certs/${hostname} ]; then
		log "[ERROR] /var/db/acme/certs/${hostname} does not exist."
		exit 1
	fi
	
	local src=/var/db/acme/certs/${hostname}
	
	/bin/cp -f $src/*.cer $mysql_dbdir/
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy ${src}/*.cer to ${mysql_dbdir}/"
		exit 1
	fi
	log "Copied new certificate to $mysql_dbdir"
	/bin/cp -f $src/*.key $mysql_dbdir/
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy ${src}/*.key to ${mysql_dbdir}/"
		exit 1
	fi
	log "Copied new key to $mysql_dbdir"
	## Fix permissions.
	/usr/sbin/chown -R ${mysql_user}:${mysql_group} ${mysql_dbdir}/*cer
	/usr/sbin/chown -R ${mysql_user}:${mysql_group} ${mysql_dbdir}/*key

	service mysql-server restart
	if [ $? -ne 0 ]; then
		log "[ERROR] Failed to restart MySQL."
	fi
	log "Restarted service successfully."
}

get_hostname
renew_mysql
