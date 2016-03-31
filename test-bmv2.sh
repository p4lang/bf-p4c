#!/bin/bash

dir=$1
shift
$dir/backends/bmv2/run-bmv2-test.py $dir -a "-D__TARGET_TOFINO__ -I $dir/backends/tofino/v1_samples/p4_lib" $*
