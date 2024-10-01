#!/bin/bash

srcdir=$1
shift
$srcdir/backends/p4test/run-p4-sample.py $srcdir -a -D__TARGET_TOFINO__ $*
