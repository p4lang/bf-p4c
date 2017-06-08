#!/bin/bash

srcdir=$1
shift
$srcdir/backends/bmv2/run-bmv2-test.py $srcdir -a -D__TARGET_TOFINO__ $*
