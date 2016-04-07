#!/bin/bash

srcdir=$1
execdir=$(dirname $0)
shift
$srcdir/backends/v12test/run-v12-sample.py $srcdir -a "-D__TARGET_TOFINO__ -I $execdir/v1_samples/p4_lib" $*
