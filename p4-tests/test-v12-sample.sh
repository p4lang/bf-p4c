#!/bin/bash

srcdir=$1
execdir=$(dirname $0)
shift
$srcdir/backends/p4test/run-p4-sample.py $srcdir -a "-D__TARGET_TOFINO__ -I $execdir/p4_tests/p4_lib" $*
