#!/bin/sh
######################################################################
# Update local RPZ Files on change
######################################################################

## Read rpzconfig from $1
if [ -z $1 ]; then
	echo "FATAL: Did not provide RPZ Config File"
	exit 1
fi
rpzconfig=$1

if [ ! -f /opt/rpz/functions.rpz ]; then
	echo "FATAL: Unable to load functions."
	exit 255
else
	. /opt/rpz/functions.rpz
fi

soadomain=$(grep '^soadomain' $rpzconfig | awk '{print $2}')
rpzrawdir=$(grep '^rpzrawdir' $rpzconfig | awk '{print $2}')
rpzoutdir=$(grep '^rpzoutdir' $rpzconfig | awk '{print $2}')
localdir=$(grep '^localdir' $rpzconfig | awk '{print $2}')
tempdir=/tmp/rpz.local

log "Beginning rebuild of local zones..." m

if [ ! -d $tempdir ]; then
	mkdir $tempdir
fi

## Use rpzconfig file to determine classes.
class0=$(grep '^class' $rpzconfig | grep '0' | grep 'local' | awk '{print $3}')
bind_header_generate $tempdir/class0.zone $soadomain
class0map=$(grep 'RULE' $localdir/$class0 | cut -d : -f 2)
## Most Specific goes first...
echo ";; Individual Hosts" >> $tempdir/class0.zone
cat $localdir/$class0 | awk '{print $1}' | grep -v "#" | grep -v RULE | grep "^[^\.]*\.[^\.]*\." | \
	while read line ; \
		do \
			## CAUTION: ^v^i (indent) not space!
			echo "$line	$class0map" ; \
		done >> $tempdir/class0.zone
echo ";; Complete Domains" >> $tempdir/class0.zone
cat $localdir/$class0 | awk '{print $1}' | grep -v "#" | grep -v RULE | grep -v "^[^\.]*\.[^\.]*\." | \
	while read line ; \
		do \
			## CAUTION: ^v^i (indent) not space!
			echo "$line	$class0map" ; \
			echo "*.$line	$class0map" ; \
		done >> $tempdir/class0.zone
if [ -f $rpzoutdir/local.$class0 ]; then
	mv $rpzoutdir/local.$class0 $rpzoutdir/local.$class0'.last'
fi
mv $tempdir/class0.zone $rpzoutdir/local.$class0

class1=$(grep '^class' $rpzconfig | grep '1' | grep 'local' | awk '{print $3}')
bind_header_generate $tempdir/class1.zone $soadomain
class1map=$(grep 'RULE' $localdir/$class1 | cut -d : -f 2)
## Most Specific goes first...
echo ";; Individual Hosts" >> $tempdir/class1.zone
cat $localdir/$class1 | awk '{print $1}' | grep -v "#" | grep -v RULE | grep "^[^\.]*\.[^\.]*\." | \
	while read line ; \
		do \
			## CAUTION: ^v^i (indent) not space!
			echo "$line	$class1map" ; \
		done >> $tempdir/class1.zone
echo ";; Complete Domains" >> $tempdir/class1.zone
cat $localdir/$class1 | awk '{print $1}' | grep -v '^#' | grep -v RULE | grep -v "^[^\.]*\.[^\.]*\." | \
	while read line ; \
		do \
			## CAUTION: ^v^i (indent) not space!
			echo "$line	$class1map" ; \
			echo "*.$line	$class1map" ; \
		done >> $tempdir/class1.zone
if [ -f $rpzoutdir/local.$class1 ]; then
	mv $rpzoutdir/local.$class1 $rpzoutdir/local.$class1'.last'
fi
mv $tempdir/class1.zone $rpzoutdir/local.$class1

class2=$(grep 'class' $rpzconfig | grep '2' | grep 'local' | awk '{print $3}')
bind_header_generate $tempdir/class2.zone $soadomain
class2map=$(grep 'RULE' $localdir/$class2 | cut -d : -f 2)
## Most Specific goes first...
echo ";; Individual Hosts" >> $tempdir/class2.zone
cat $localdir/$class2 | awk '{print $1}' | grep -v '^#' | grep -v RULE | grep "^[^\.]*\.[^\.]*\." | \
	while read line ; \
		do \
			## CAUTION: ^v^i (indent) not space!
			echo "$line	$class2map" ; \
		done >> $tempdir/class2.zone
echo ";; Complete Domains" >> $tempdir/class2.zone
cat $localdir/$class2 | awk '{print $1}' | grep -v '^#' | grep -v RULE | grep -v "^[^\.]*\.[^\.]*\." | \
	while read line ; \
		do \
			## CAUTION: ^v^i (indent) not space!
			echo "$line	$class2map" ; \
			echo "*.$line	$class2map" ; \
		done >> $tempdir/class2.zone
if [ -f $rpzoutdir/local.$class2 ]; then
	mv $rpzoutdir/local.$class2 $rpzoutdir/local.$class2'.last'
fi
mv $tempdir/class2.zone $rpzoutdir/local.$class2

class3=$(grep 'class' $rpzconfig | grep '3' | grep 'local' | awk '{print $3}')
bind_header_generate $tempdir/class3.zone $soadomain
class3map=$(grep 'RULE' $localdir/$class3 | cut -d : -f 2)
## Most Specific goes first...
echo ";; Individual Hosts" >> $tempdir/class3.zone
cat $localdir/$class3 | awk '{print $1}' | grep -v "#" | grep -v RULE | grep "^[^\.]*\.[^\.]*\." | \
	while read line ; \
		do \
			## CAUTION: ^v^i (indent) not space!
			echo "$line	$class3map" ; \
		done >> $tempdir/class3.zone
echo ";; Complete Domains" >> $tempdir/class3.zone
cat $localdir/$class3 | awk '{print $1}' | grep -v '^#' | grep -v RULE | grep -v "^[^\.]*\.[^\.]*\." | \
	while read line ; \
		do \
			## CAUTION: ^v^i (indent) not space!
			echo "$line	$class3map" ; \
			echo "*.$line	$class3map" ; \
		done >> $tempdir/class3.zone
if [ -f $rpzoutdir/$class3 ]; then
	mv $rpzoutdir/local.$class3 $rpzoutdir/local.$class3'.last'
fi
mv $tempdir/class3.zone $rpzoutdir/local.$class3

for class in 0 1 2 3; do
	bind_reload_zone class"$class".rpz
	if [ $? -ne 0 ]; then
		log "update.local.sh: error reloading zone class"$class".rpz" w
	fi
done

## Fix ownership
for file in `ls $rpzoutdir/local.*`; do
	/usr/sbin/chown bind:bind $file
done
