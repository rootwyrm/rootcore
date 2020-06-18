#!/usr/bin/env bash
################################################################################
# Copyright (C) 2019-2020 Phillip R. Jaenke <prj+alpine@rootwyrm.com>
# All rights reserved
################################################################################
# This Software is for Non-Commercial Use ONLY
# ABSOLUTELY NO WARRANTIES EXPRESSED OR IMPLIED

frr_release="7.2.1"

## Build frr from git on Alpine and clean up after ourselves.
vbpkg_name="frr_build"
vbpkg_contents="autoconf automake gcc g++ json-c-dev python3-dev readline-dev"
vrpkg_name="frr_run"
vrpkg_contents="jsonc python3 readline"

apk add --virtual $vbpkg_name $vbpkg_contents

## URL
https://github.com/FRRouting/frr/releases/download/frr-${frr_release}/frr-${frr_release}.tar.gz

## Configure routine...
./configure --prefix=/usr/local

