#!/bin/bash

dir=$1
shift
$dir/backends/v12test/run-v12-sample.py $dir -a "-D__TARGET_TOFINO__ -I $dir/backends/tofino/v1_samples/p4_lib" $*
