#!/bin/sh
######################################################################
## Automatic Updater for domains
######################################################################

## Read rpzconfig from $1
if [ -z $1 ]; then
	echo "FATAL: Did not provide RPZ Config File"
	exit 1
fi
rpzconfig=$1

if [ ! -f /opt/rootwyrm/rpz/functions.rpz ]; then
	echo "FATAL: Could not load functions"
	exit 255
else
	. /opt/rootwyrm/rpz/functions.rpz
fi

#. /usr/local/etc/rpz/lib/functions.rpz
#. /root/tools/bind/functions.rpz
#. $rpzconfig

soadomain=$(grep 'soadomain' $rpzconfig | awk '{print $2}')
rpzrawdir=$(grep 'rpzrawdir' $rpzconfig | awk '{print $2}')
rpzoutdir=$(grep 'rpzoutdir' $rpzconfig | awk '{print $2}')
autodir=$(grep 'autodir' $rpzconfig | awk '{print $2}')
#confdir=$(echo '$1' | rev | cut -d/ -f-2 | rev)
tempdir=/tmp/rpz.auto
if [ ! -d $tempdir ]; then
	mkdir $tempdir
	if [ $? -ne 0 ]; then
		log "FATAL: Directory structure is broken!" e 1
	fi
fi

#if [ ! -f $autodir/rpz.auto.conf ]; then
#	log "FATAL: Could not load $autodir/rpz.auto.conf" e 2
#fi
#if [ -f $autodir/rpz.auto.conf ]; then
#	rpzurls=$confdir/rpz.auto.conf
#else
#	rpzurls=/opt/rpz/rpz.auto.conf
#fi
rpzurls=/opt/rootwyrm/rpz/rpz.auto.conf

## Fetch and Checksum Loop
for class in `grep 'class' $rpzconfig | grep 'auto' | awk '{print $2}'`; do
	for url in `grep "^$class" $rpzurls | cut -d , -f 2`; do
		## Have to store in $autodir for -m to work.
		fetch -q -m -o $autodir/`cat $rpzurls | grep "^$class,$url" | cut -d , -f 4` \
			`cat $rpzurls | grep "^$class,$url" | cut -d , -f 3`
	done
	for file in `grep "^$class" $rpzurls | cut -d , -f 4`; do
		# XXX: This is pretty hackish for now.
		#if [ csum_check '$file'.md5 $file -ne 0 ]; then
		#	csum_generate $file overwrite
		#fi
		csum_generate $autodir/$file 
	done
done

## Clean up files in advance.
if [ -f $tempdir/auto.[a-z,0-9] ]; then
	for stale in `ls $tempdir/auto.pre.*`; do
		rm $stale
	done
fi
unset stale
if [ -f $tempdir/[a-z,0-9].sort ]; then
	for stale in `ls $tempdir/*.sort`; do
		rm $stale
	done 
fi
unset stale

for class in `grep 'class' $rpzconfig | grep 'auto' | awk '{print $2}'`; do
	for cnum in 0 1 2 3 4; do
		cnumtmp=$tempdir/auto.pre.$cnum
		touch $cnumtmp
		if [ $? -ne 0 ]; then
			log "AUTO: Class Processing: Could not create temp file." e 10
		fi
		for finput in `grep "^$cnum" $rpzurls | cut -d , -f 4`; do
			## XXX: Process files here.
			for fmethod in `grep "^$cnum" $rpzurls | cut -d , -f 5`; do
				case $fmethod in 
					[Hh][Oo][Ss][Tt])
						tf_hostfile_to_domain $autodir/$finput $cnumtmp 
						;;
					[Dd][Oo][Mm][Aa][Ii][Nn])
						## Do nothing fancy.
						#tf_hostfile_domain $autodir/$finput $cnumtmp $rule
						cat $autodir/$finput | grep -v '^#' | awk '{print $1}' >> $cnumtmp
						;;
				esac
			done
		done
	done
done

## This is a bit messy but the best way to do it
for class in `grep 'class' $rpzconfig | grep 'auto' | awk '{print $2}'`; do
	## XXX: Doesn't work thanks to stuff like '.com.au' and '.co.uk'!!
	#for cnum in 0 1 2 3 4; do
	#	cnumtmp=/tmp/rpz/auto.pre.$cnum
	#	posttmp=/tmp/rpz/auto.$cnum
	#	## Ugh, such a pain in the ass, this...
	#	cat $cnumtmp | grep '^[^\.]*\.[^\.]*\.' | rev | cut -d . -f 1,2 | rev >> /tmp/rpz/$$."$cnum".sort
	#done
	for cnum in 0 1 2 3 4; do
		for sort in `ls $tempdir/auto.pre."$cnum"`; do
			$(uniq -i -u $sort > $tempdir/"$cnum".sorted)
		done
	done
done
## Clean up afterward.
#rm /tmp/rpz/*.sort

for class in `grep 'class' $rpzconfig | grep 'auto' | awk '{print $2}'`; do
	## We're already aggregated soooo...
	#if [ -s /tmp/rpz/"$class".sorted ]; then
	#	rm /tmp/rpz/"$class".sorted
	#else
		outputfile=$rpzoutdir/`grep 'class' $rpzconfig | grep 'auto' | grep "$class" | awk '{print $3}'`
		## Move file out of the way.
		if [ -f $outputfile ]; then
			mv $outputfile "$outputfile".last
		fi
		bind_header_generate $outputfile $soadomain
		if [ $? -ne 0 ]; then
			log "FATAL: Error occurred in bind_header_generate" e 1
		fi
		rule=$(echo $(grep "^$class" $rpzurls | cut -d , -f 6 | head -1))
		tf_domain_to_rpz $tempdir/"$class".sorted $outputfile $rule
	#fi
done

## Fix permissions before reload.
/usr/sbin/chown bind:bind $rpzoutdir/*.rpz

## Reload zones
for zonefile in `grep 'class' $rpzconfig | grep 'auto' | awk '{print $3}'`; do
	bind_reload_zone $zonefile 
	if [ $? -ne 0 ]; then
		RC=$?
		log "CONTROL: bind_reload zone: $zonefile failed with RC $RC" w
	fi
done
