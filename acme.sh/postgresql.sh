#!/bin/sh
#
# hooks/postgresql.sh
# Hook for acme.sh to install certificates for PostgreSQL on FreeBSD.
# NOTE: Installs both server AND client certificates (which are handled
# differently). BOTH are REQUIRED. Failure to have an appropriate client
# certificate WILL result in insecure or failed connections.

. /etc/rc.subr
. /etc/network.subr
. /var/db/acme/hooks/postgresql.conf

log()
{
	logfile=/var/log/acme.sh.log
	if [ ! -f $logfile ]; then
		if [ ! -d /var/log/acme ]; then
			mkdir /var/log/acme
		fi
		touch $logfile
	fi
	echo $(date) [postgresql] $1 | tee -a $logfile
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
renew_postgresql()
{
	if [ -z ${postgresql_data} ]; then
		log "[ERROR] Unable to determine postgresql_data directory."
		exit 255
	elif [ ! -d ${postgresql_data} ]; then
		log "[ERROR] PostgreSQL data directory ${postgresql_data} does not exist!"
		exit 255
	fi
	## XXX: Doesn't support profiles yet.
	if [ ! -d /var/db/acme/certs/${hostname} ]; then
		log "[ERROR] /var/db/acme/certs/${hostname} does not exist."
		exit 1
	fi
	PGHOME=$(grep postgres /etc/passwd | cut -d : -f 6)

	local src=/var/db/acme/certs/${hostname}
	local pgs_dst=${PGHOME}/ssl
	
	local pgc_crt=${PGHOME}/.postgresql/postgresql.crt
	local pgc_key=${PGHOME}/.postgresql/postgresql.key

	if [ ! -d $pgs_dst ]; then
		mkdir $pgs_dst
		if [ $? -ne 0 ]; then
			log "[ERROR] Could not create $pgs_dst"
			exit 1
		fi
		/usr/sbin/chown postgres:postgres $pgs_dst
		if [ $? -ne 0 ]; then
			log "[ERROR] Could not chown $pgs_dst to postgres user."
			exit 1
		fi
	fi

	/bin/cp -f $src/*.cer $pgs_dst/
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy ${src}/*.cer to ${pgs_dst}/"
		exit 1
	fi
	log "Copied new certificate to $pgs_dst"
	/bin/cp -f $src/*.key $pgs_dst/
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy ${src}/*.key to ${pgs_dst}/"
		exit 1
	fi
	log "Copied new key to $pgs_dst"
	## Fix permissions.
	/usr/sbin/chown -R postgres:postgres ${pgs_dst}/*
	/bin/chmod 0600 ${pgs_dst}/*cer
	/bin/chmod 0600 ${pgs_dst}/*key

	## Now handle the client certificate or replication won't use SSL.
	if [ ! -d $PGHOME/.postgresql ]; then
		log "[ERROR] $PGHOME/.postgresql does not exist!"
		exit 1
	fi
	/bin/cp -f $src/${hostname}.cer ${pgc_crt}
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy ${src}/${hostname}.cer to ${pgc_crt}"
		exit 1
	fi
	/bin/cp -f $src/${hostname}.key ${pgc_key}
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to copy ${src}/${hostname}.key to ${pgc_key}"
		exit 1
	fi

	/usr/sbin/chown postgres:postgres ${pgc_crt} 
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to set permissions on ${pgc_crt}"
		exit 1
	fi
	/usr/sbin/chown postgres:postgres ${pgc_key}
	if [ $? -ne 0 ]; then
		log "[ERROR] Unable to set permissions on ${pgc_key}"
		exit 1
	fi
	/bin/chmod 0600 ${pgc_crt}
	/bin/chmod 0600 ${pgc_key}

	service postgresql restart
	if [ $? -ne 0 ]; then
		log "[ERROR] Failed to restart postgresql."
		exit 1
	fi
	log "Restarted service successfully."
}

get_hostname
renew_postgresql
