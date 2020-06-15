FROM	alpine:3.12

## Set up our labels
LABEL	maintainer="Phillip 'RootWyrm' Jaenke <prj+docker@rootwyrm.com>"
LABEL	com.rootwyrm.product="PowerDNS dnsdist" \
		com.rootwyrm.project="dnsdist" \
		com.rootwyrm.status="" \
		com.rootwyrm.vcs-type="github" \
		com.rootwyrm.changelog-url="" \
		com.rootwyrm.nvd.release="0" \
		com.rootwyrm.nvd.version="0" \
		com.rootwyrm.nvd.update="0" \
		com.rootwyrm.nvd.update_sub="$RW_BLDHASH" \
		com.rootwyrm.nvd.build_time="$LS_BLDDATE" \
		# Label Schema
		org.label-schema.schema-version="$LS_SCHEMAVERSION" \
		org.label-schema.vendor="$LS_VENDOR" \
		org.label-schema.name="$LS_NAME" \
		org.label-schema.url="$LS_URL" \
		org.label-schema.vcs-ref="$VCS_REF" \
		org.label-schema.version="$RW_VCSHASH" \
		org.label-schema.build-date=$LS_BLDDATE

EXPOSE	53/tcp
EXPOSE	53/udp
EXPOSE	80/tcp
EXPOSE	443/tcp
EXPOSE	8053/tcp

## Create common elements
COPY [ "application/", "/opt/rootwyrm" ]
COPY [ "sv/", "/etc/sv" ]
RUN mkdir -p /opt/rootwyrm && \
	mkdir -p /usr/local/src && \
	mkdir -p /var/log/runit && \
	touch /firstboot ; \
	apk update && \
	apk upgrade && \
	export pkg_common="runit file dcron apk-cron openssl bash" && \
	apk add --no-cache $pkg_common && \
	for sv in `ls /etc/sv/`; do \
		ln -s /etc/sv/$sv /etc/service/ ;\
	done && \
	sed -i -e '/^tty*/d' /etc/inittab && \
	sed -i -e '/^# Set up*/d' /etc/inittab && \
	sed -i -e '/^::ctrlalt*/d' /etc/inittab && \
	sed -i -e '/.*salute$/d' /etc/inittab && \
	rm -rf /etc/init.d && \
	echo "$(date '+%b %d %H:%M:%S') [BUILD] phase beginning." ; \
	mkdir -p /usr/local/src && \
	mkdir -p /var/log/runit && \
	touch /firstboot && \
	for bld in `ls /opt/rootwyrm/build/ | sort`; do \
		/opt/rootwyrm/build/$bld ; \
	done && \
	echo "$(date '+%b %d %H:%M:%S') [BUILD] phase complete." 

VOLUME [ "/run" ]
VOLUME [ "/etc/dnsdist" ]

#ONBUILD CMD touch /firstboot

CMD [ "/sbin/runsvdir", "-P", "/etc/service" ]
