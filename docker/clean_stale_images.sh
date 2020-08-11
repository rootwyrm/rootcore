#!/usr/bin/env bash
################################################################################
# Copyright (c) 2020-* Phillip R. Jaenke <prj@rootwyrm.com>
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
##
## This hack cleans up all my stale docker images which often run into the 
## hundreds. And Docker is absolutely terrible about cleaning up after itself.
##

IFS=$'\r\n'

## Kill totally untagged
for ut in `docker images | grep '^<none>' | awk '{print $3}'`; do
	docker rmi $ut
	if [ $? -ne 0 ]; then
		printf 'Could not remove stale image %s\n' "$ut"
	fi
done

## Now kill ones with no tag which are stale. And docker is too stupid to filter.
readarray -t docker_images < <(docker images | grep -v ^REPOSITORY)
for x in ${docker_images[@]}; do
	name=$(echo $x | awk '{print $1}')
	tag=$(echo $x | awk '{print $2}')
	hex=$(echo $x | awk '{print $3}')
	case $tag in 
		"<none>")
			printf 'Removing %s %s\n' "$name" "$hex"
			docker rmi $hex
			if [ $? -ne 0 ]; then
				printf 'Failed to remove %s %s : %s\n' "$name" "$hex" "$?"
				exit 1
			fi
			;;
		*)
			;;
	esac
done
