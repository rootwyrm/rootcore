#!/usr/bin/env bash
################################################################################
# dns_registration.sh
# One of the glorious hacks I put together for registering hosts with AD DNS 
# due to Samba bugs. Eventually we'll fix sssd 1.16 for FreeBSD. (Eventually.)
# It is strongly recommended you test first in your environment. This script
# makes certain assumptions, key among them that you have a working 'nsupdate'
# with GSSAPI support and a machine keytab. If you don't have both of these 
# things, it will not work.
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

SMBTOOL=$(which samba-tool)
SMBDNS=$(which samba_dnsupdate)
if [ -f /usr/local/bin/net ]; then
	NETTOOL=/usr/local/bin/net
else
	NETTOOL=$(which net)
fi

## Compress IPv6 helper function
compress_ipv6() {
    ip=$1

    blocks=$(echo $ip | grep -o "[0-9a-f]\+")
    set $blocks

    # compress leading zeros
    ip=$(printf "%x:%x:%x:%x:%x:%x:%x:%x\n" \
        $(hex2dec $1) \
        $(hex2dec $2) \
        $(hex2dec $3) \
        $(hex2dec $4) \
        $(hex2dec $5) \
        $(hex2dec $6) \
        $(hex2dec $7) \
        $(hex2dec $8)
    )

    # prepend : for easier matching
    ip=:$ip

    # :: must compress the longest chain
    for pattern in :0:0:0:0:0:0:0:0 \
            :0:0:0:0:0:0:0 \
            :0:0:0:0:0:0 \
            :0:0:0:0:0 \
            :0:0:0:0 \
            :0:0; do
        if echo $ip | grep -qs $pattern; then
            ip=$(echo $ip | sed "s/$pattern/::/")
            # if the substitution occured before the end, we have :::
            ip=$(echo $ip | sed 's/:::/::/')
            break # only one substitution
        fi
    done

    # remove prepending : if necessary
    echo $ip | grep -qs "^:[^:]" && ip=$(echo $ip | sed 's/://')

    echo $ip
}
## Helper Function
function hex2dec()
{
    [ "$1" != "" ] && printf "%d" "$(( 0x$1 ))"
}
## Expand IPv6 helper function
function expand_ipv6()
{
    ip=$1

    # Prepend 0 if we start with :
    echo $ip | grep -qs "^:" && ip="0${ip}"

    # Expand ::
    if echo $ip | grep -qs "::"; then
        colons=$(echo $ip | sed 's/[^:]//g')
        missing=$(echo ":::::::::" | sed "s/$colons//")
        expanded=$(echo $missing | sed 's/:/:0/g')
        ip=$(echo $ip | sed "s/::/$expanded/")
    fi

    blocks=$(echo $ip | grep -o "[0-9a-f]\+")
    set $blocks

    printf "%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x\n" \
        $(hex2dec $1) \
        $(hex2dec $2) \
        $(hex2dec $3) \
        $(hex2dec $4) \
        $(hex2dec $5) \
        $(hex2dec $6) \
        $(hex2dec $7) \
        $(hex2dec $8)
}
## Split the ARPA
function nibble_arpa_ip6()
{
    ip=$1
    bound=$2

    # Prepend 0 if we start with :
    echo $ip | grep -qs "^:" && ip="0${ip}"

    # Expand ::
    if echo $ip | grep -qs "::"; then
        colons=$(echo $ip | sed 's/[^:]//g')
        missing=$(echo ":::::::::" | sed "s/$colons//")
        expanded=$(echo $missing | sed 's/:/:0/g')
        ip=$(echo $ip | sed "s/::/$expanded/")
    fi

    blocks=$(echo $ip | grep -o "[0-9a-f]\+")
    set $blocks

    case $bound in
        48)
            printf "%04x:%04x:%04x\n" \
                $(hex2dec $1) \
                $(hex2dec $2) \
                $(hex2dec $3)
            ;;
        64)
            printf "%04x:%04x:%04x:%04x\n" \
                $(hex2dec $1) \
                $(hex2dec $2) \
                $(hex2dec $3) \
                $(hex2dec $4)
            ;;
    esac
}
## Operate on the short arpa
function ip6_short_arpa()
{
    ip=$1
    bound=$2

    # Prepend 0 if we start with :
    echo $ip | grep -qs "^:" && ip="0${ip}"

    # Expand ::
    if echo $ip | grep -qs "::"; then
        colons=$(echo $ip | sed 's/[^:]//g')
        missing=$(echo ":::::::::" | sed "s/$colons//")
        expanded=$(echo $missing | sed 's/:/:0/g')
        ip=$(echo $ip | sed "s/::/$expanded/")
    fi

    blocks=$(echo $ip | grep -o "[0-9a-f]\+")
    set $blocks

    case $bound in
        48)
            printf "%04x:%04x:%04x:%04x:%04x:%04x\n" \
                $(hex2dec $4) \
                $(hex2dec $5) \
                $(hex2dec $6) \
                $(hex2dec $7) \
                $(hex2dec $8)
            ;;
        64)
            printf "%04x:%04x:%04x:%04x\n" \
                $(hex2dec $1) \
                $(hex2dec $2) \
                $(hex2dec $3) \
                $(hex2dec $4)
            ;;
    esac
}
## Convert to IPv6 ARPA
convert_ptr_ip6()
{
    local idx s=${1//:}
    for (( idx=${#s} - 1; idx>=0; idx-- )); do
        printf '%s.' "${s:$idx:1}"
    done
    #printf 'ip6.arpa\n'
}

## Get information about the interface we have been passed
## ARGS: interface_name (e.g. vmx0)
get_interface_data()
{
	if [ -z $1 ]; then
		printf 'Did not receive interface name!\n'
		exit 2
	fi
	## First get our system data
	host=$(hostname -s)
	fqdn=$(hostname -f)
	domain=$(hostname -d)
	if [ -z $domain ] || [ $domain == '' ]; then
		printf 'Could not determine domain!\n'
		exit 1
	fi

	domain_soa=$(dig SOA $domain +short | awk '{print $1}' | sed -e 's/\.$//' | head -1)
	if [ ! -z $DEBUG ]; then
		printf 'domain: %s\n' "$domain"
		printf 'domain_soa: %s\n' "$domain_soa"
	fi

	## Assume the users knows what they're doing with the interface.
	ip4addr=$(ifconfig $1 inet | grep inet | awk '{print $2}' | head -1)
	ip4arpa=$(echo $ip4addr | awk '{print $1}' | awk -F. '{OFS="."; print $4,$3,$2,$1,"in-addr.arpa"}')
	ip4arpa_soa_name=$(dig SOA $ip4arpa_zone +short | awk '{print $1}' | sed -e 's/\.$//')
	ip4arpa_soa=$(dig A $ip4arpa_soa_name +short)
	ip4arpa_zone=$(echo $ip4addr | awk '{print $1}' | awk -F. '{OFS="."; print $3,$2,$1,"in-addr.arpa"}')
	export ip4addr
	export ip4arpa
	export ip4arpa_soa
	export ip4arpa_zone
	if [ ! -z $DEBUG ]; then
		printf 'ip4addr: %s\n' "$ip4addr"
		printf 'ip4arpa: %s\n' "$ip4arpa"
		printf 'ip4arpa_soa: %s\n' "$ip4arpa_soa"
		printf 'ip4arpa_zone: %s\n' "$ip4arpa_zone"
	fi

	## Now do the IPv6
	ip6addr=$(ifconfig $1 inet6 | grep inet6 | grep -v 'scopeid 0x1' | awk '{print $2}' | head -1)
	ip6prefix=$(ifconfig $1 inet6 | grep inet6 | grep -v 'scopeid 0x1' | awk '{print $4}' | head -1)
	ip6addrf=$(expand_ipv6 $ip6addr)
	ip6arpaf=$(convert_ptr_ip6 $ip6addrf) 
	nibble=$(nibble_arpa_ip6 $ip6addrf $ip6prefix)
	ip6arpa_zone_raw=$(convert_ptr_ip6 $nibble | sed -e 's/\.$//')
	ip6arpa_zone=$(echo ${ip6arpa_zone_raw}.ip6.arpa)
	ip6arpa_soa_name=$(dig SOA ${ip6arpa_zone} +short | awk '{print $1}' | sed -e 's/\.$//')
	ip6arpa_soa=$(dig A $ip6arpa_soa_name +short)
	ip6arpai=$(ip6_short_arpa $ip6addrf $ip6prefix)	
	ip6arpa=$(convert_ptr_ip6 $ip6arpai)

	export ip6addr
	export ip6addrf
	export ip6prefix
	export ip6arpa_zone
	export ip6arpa_soa
	if [ ! -z $DEBUG ]; then
		printf 'ip6addr: %s\n' "$ip6addr"
		printf 'ip6addrf: %s\n' "$ip6addrf"
		printf 'ip6prefix: %s\n' "$ip6prefix"
		printf 'ip6arpa_zone: %s\n' "$ip6arpa_zone"
		printf 'ip6arpa_soa: %s\n' "$ip6arpa_soa"
	fi
}

## Test the A record.
## ARGS: fqdn ip
dns_test_a()
{
	if [ -z $1 ] || [ -z $2 ]; then
		printf 'dns_test_a called with insufficient arguments!\n'
		exit 2
	fi
	## Test to see if our A record is what we expect.
	local exist_a=$(dig A $fqdn +short)
	if [ $exist_a != $ip4addr ]; then
		export UPDATE_A=true
	else
		unset UPDATE_A
	fi
}

## Test the AAAA record.
## ARGS: fqdn ip
dns_test_aaaa()
{
	if [ -z $1 ] || [ -z $2 ]; then
		printf 'dns_test_a called with insufficient arguments!\n'
		exit 2
	fi
	## Test to see if our AAAA record is what we expect.
	local exist_aaaa=$(dig AAAA $fqdn +short)
	if [ $exist_aaaa != $ip6addrf ] && [ ! -z $exist_aaaa ]; then
		export UPDATE_AAAA=true
	elif [ -z $exist_aaaa ]; then
		export INSERT_AAAA=true
	else
		unset UPDATE_AAAA
		unset INSERT_AAAA
	fi
}

## Test the PTR (in-addr.arpa) record.
## ARGS: fqdn ip
dns_test_arpa4()
{
	if [ -z $1 ] || [ -z $2 ]; then
		printf 'dns_test_arpa4 called with insufficient arguments!\n'
		exit 2
	fi
	## Test to see if our AAAA record is what we expect.
	local exist_ptr=$(dig -x $ip4addr +short | sed -e 's/\.$//')
	if [ $exist_ptr != $fqdn ] && [ ! -z $exist_ptr ]; then
		export UPDATE_ARPA4=true
	elif [ -z $exist_aaaa ]; then
		export INSERT_ARPA4=true
	else
		unset UPDATE_ARPA4
		unset INSERT_ARPA4
	fi
}

## Test the PTR (ip6.arpa) record.
## ARGS: fqdn ip
dns_test_arpa6()
{
	if [ -z $1 ] || [ -z $2 ]; then
		printf 'dns_test_arpa4 called with insufficient arguments!\n'
		exit 2
	fi
	## Test to see if our AAAA record is what we expect.
	local exist_ptr6=$(dig -x $ip6addrf +short | sed -e 's/\.$//')
	if [[ $exist_ptr6 != $fqdn ]] && [ ! -z $exist_ptr6 ]; then
		export UPDATE_ARPA6=true
	elif [ -z $exist_ptr6 ]; then
		export INSERT_ARPA6=true
	else
		unset UPDATE_ARPA6
		unset INSERT_ARPA6
	fi
}

## Generate the A/AAAA update first to create records.
nsupdate_forward()
{
	tmpfile=/tmp/$domain.reg

	printf 'server %s\n' "$domain_soa" > $tmpfile
	printf 'gsstig\n' >> $tmpfile
	printf '\n' >> $tmpfile

	if [ ! -z $UPDATE_A ] || [ ! -z $INSERT_A ]; then
		if [ $UPDATE_A == 'true' ]; then
			printf 'zone %s\n' "$domain" >> $tmpfile
			printf 'update delete %s A\n' "$fqdn" >> $tmpfile
			printf 'update add %s 3600 IN A %s\n' "$fqdn" "$ip4addr" >> $tmpfile
			printf 'send\n' >> $tmpfile
		elif [ $INSERT_A == 'true' ]; then
			printf 'zone %s\n' "$domain" >> $tmpfile
			printf 'update add %s 3600 IN A %s\n' "$fqdn" "$ip4addr" >> $tmpfile
			printf 'send\n' >> $tmpfile
		fi
	fi

	if [ -z $UPDATE_AAAA ] || [ ! -z $INSERT_AAAA ]; then
		if [ $UPDATE_AAAA = 'true' ]; then
			printf 'zone %s\n' "$domain" >> $tmpfile
			printf 'update delete %s AAAA\n' "$fqdn" >> $tmpfile
			printf 'update add %s 3600 IN A %s\n' "$fqdn" "$ip6addrf" >> $tmpfile
			printf 'send\n' >> $tmpfile
		elif [ $INSERT_AAAA = 'true' ]; then
			printf 'zone %s\n' "$domain" >> $tmpfile
			printf 'update add %s 3600 IN A %s\n' "$fqdn" "$ip6addrf" >> $tmpfile
			printf 'send\n' >> $tmpfile
		fi
	fi
	## Don't work on a null file.
	filelength=$(wc -l $tmpfile | awk '{print $1}')
	if [[ $filelength -ge 3 ]]; then
		printf 'No updates for forward records at this time.\n'
		rm $tmpfile
	else
		nsupd=$(which nsupdate)
		#$nsupd -g < $tmpfile
		if [ $? -ne 0 ]; then
			RC=$?
			printf 'nsupdate: error %s\n' "$RC"
			return $RC
		else
			echo rm $tmpfile
		fi
	fi
}

## Perform the PTR update
nsupdate_reverse()
{
	tmpfile=/tmp/$domain.reg

	if [ ! -z $UPDATE_PTR4 ] || [ ! -z $INSERT_PTR4 ]; then
		if [ $UPDATE_PTR4 == 'true' ]; then
			printf 'server %s\n' "$domain_soa" > $tmpfile
			printf 'gsstig\n' >> $tmpfile
			printf '\n' >> $tmpfile
			printf 'zone %s\n' "$domain" >> $tmpfile
			printf 'update delete %s PTR %s.\n' "$ip4arpa" "$fqdn" >> $tmpfile
			printf 'update add %s 3600 IN PTR %s.\n' "$ip4arpa" "$fqdn" >> $tmpfile
			printf 'send\n' >> $tmpfile
		elif [ $INSERT_A == 'true' ]; then
			printf 'server %s\n' "$domain_soa" > $tmpfile
			printf 'gsstig\n' >> $tmpfile
			printf '\n' >> $tmpfile
			printf 'zone %s\n' "$domain" >> $tmpfile
			printf 'update add %s 3600 IN PTR %s.\n' "$ip4arpa" "$fqdn" >> $tmpfile
			printf 'send\n' >> $tmpfile
		fi
	fi

	if [ ! -z $UPDATE_PTR6 ] || [ ! -z $INSERT_PTR6 ]; then
		if [ $UPDATE_PTR6 == 'true' ]; then
			printf 'server %s\n' "$domain_soa" > $tmpfile
			printf '\n' >> $tmpfile
			printf 'zone %s\n' "$domain" >> $tmpfile
			printf 'update delete %s PTR %s.\n' "$ip6arpat" "$fqdn" >> $tmpfile
			printf 'update add %s PTR %s.\n' "$ip6arpat" "$fqdn" >> $tmpfile
			printf 'send\n' >> $tmpfile
		elif [ $INSERT_PTR6 == 'true' ]; then
			printf 'server %s\n' "$domain_soa" > $tmpfile
			printf '\n' >> $tmpfile
			printf 'zone %s\n' "$domain" >> $tmpfile
			printf 'update add %s PTR %s.\n' "$ip6arpat" "$fqdn" >> $tmpfile
			printf 'send\n' >> $tmpfile
		fi
	fi

	if [ -f $tmpfile ]; then
		filelength=$(wc -l $tmpfile | awk '{print $1}')
		if [[ $filelength -ge 3 ]]; then
			printf 'No updates for reverse records at this time.\n'
			rm $tmpfile
		else
			nsupd=$(which nsupdate)
			#$nsupd -g < $tmpfile
			if [ $? -ne 0 ]; then
				RC=$?
				printf 'nsupdate: error %s\n' "$RC"
				return $RC
			else
				echo rm $tmpfile
			fi
		fi
	else
		printf 'No updates for reverse records at this time.\n'
	fi
}

## Do a kinit
kinit_heimdal()
{
	## Do a kinit of our machine keytab with a separate ccache
	if [ ! -f /etc/krb5.keytab ]; then
		## Check samba.
		KEYTAB=$(grep 'keytab file' /usr/local/etc/smb4.conf | cut -d = -f 2)
		if [ -z $KEYTAB ]; then
			printf 'Could not locate machine keytab!\n' 
			exit 100
		else
			export KEYTAB
		fi
	else
		export KEYTAB=/etc/krb5.keytab
	fi

	if [ -x /usr/local/bin/kinit ]; then
		kinit=/usr/local/bin/kinit
	else
		kinit=/usr/bin/kinit
	fi

	export KRB5_CCACHE=/tmp/krb5cc_dnsreg
	echo "$kinit -t $KEYTAB -c $KRB5_CCACHE ${host^^}\$@${domain^^}"
}

## Perform actual interface update
## ARGS: interface
update_interface()
{
	if [ -z $1 ]; then
		printf 'Entered update_interface with no argument!\n'
		exit 2
	fi
	## Perform interface update
	dns_test_a $fqdn $ip4addr
	dns_test_aaaa $fqdn $ip6addr
	dns_test_arpa4 $fqdn $ip4addr
	dns_test_arpa6 $fqdn $ip6addr
	nsupdate_forward
	nsupdate_reverse
}

usage()
{
	printf 'Active Directory Dynamic DNS utility\n'
	printf 'Copyright (C) 2019-* Phillip R. Jaenke, All rights reserved\n'
	printf '\n'
	printf 'Usage:\n'
	printf '%s <interface>\n' "$0"
	exit 1
}

if [ -z $1 ]; then
	usage
else
	get_interface_data $1
	update_interface $1
fi

#check_existing_dns
#kinit_heimdal
