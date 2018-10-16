#!/bin/sh
#
# hooks/mysql.sh
# Hook for acme.sh to install certificates for MySQL/Maria/Percona on FreeBSD.

. /etc/rc.subr
. /etc/network.subr

log()
{
	logfile=/var/log/acme.sh.log
	if [ ! -f $logfile ]; then
		if [ ! -d /var/log/acme ]; then
			mkdir /var/log/acme
		fi
		touch $logfile
	fi
	echo $(date) [mysql] $1 | tee -a $logfile
}

get_hostname()
{
	if [ -z ${hostname} ]; then
		hostname=$(hostname -f)
	fi
	if [ ! -z ${override_hostname} ]; then
		hostname=${override_hostname}
	fi
	## XXX: Needs some additional sanity checking for LB/jail use.
}

## XXX: Needs to be named this way.
## XXX: Doesn't support profiles yet. :(
renew_mysql()
{
	if [ ! -d ${mysql_dbdir} ]; then
		log "[ERROR] Unable to determine mysql_dbdir directory."
		exit 1
	fi
	## XXX: Doesn't support profiles yet.
	if [ ! -d /var/db/acme/certs/${hostname} ]; then
		log "[ERROR] /var/db/acme/certs/${hostname} does not exist."
		exit 1
	fi
	
	local src=/var/db/acme/certs/${hostname}
	local mysql_dst=${mysql_dbdir}
	
	if [ ! -d $mysql_dst ]; then
		log "[ERROR] mysql_dbdir ${mysql_dbdir} does not exist!"
	fi

	/bin/cp -f $src/*.cer $mysql_dst/
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy ${src}/*.cer to ${mysql_dst}/"
		exit 1
	fi
	log "Copied new certificate to $mysql_dst"
	/bin/cp -f $src/*.key $mysql_dst/
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy ${src}/*.key to ${mysql_dst}/"
		exit 1
	fi
	log "Copied new key to $mysql_dst"
	## Fix permissions.
	/usr/sbin/chown -R ${mysql_user}:${mysql_user} $dst/*

	service mysql-server restart
	if [ $? -ne 0 ]; then
		log "[ERROR] Failed to restart MySQL."
	fi
	log "Restarted service successfully."
}

get_hostname
renew_mysql
