#!/bin/bash

set -x
srcdir=$1
execdir=$(dirname $0)
shift
$srcdir/backends/bmv2/run-bmv2-test.py $srcdir -a "-D__TARGET_TOFINO__ -I $execdir/v1_samples/p4_lib" $*
