#!/usr/bin/env bash

# -------------------------------------
# Description:
# 
# This is a convenience script for running all the tests located in
# the sanity regression. If the user needs to run something else, it's 
# recommended they simply run the $SDE/run_p4_tests.sh script directly,
# or modify this script locally to fit their needs.
# -------------------------------------

if [ "$1" != "1" ] && [ "$1" != "2" ]; then
    echo "  usage: $0 <target>"
    echo "  (where target is 1 for tofino or 2 for tofino2)"
    exit 1
fi

# -------------------------------------

if [ "$2" = "" ]; then
    profile="PROFILE_STANDARD"
else
    profile=$2
fi

# -------------------------------------

status=0
path_saved=$PWD # just save off current path for use below
echo $path_saved

if [ "$profile" = "PROFILE_COPY_TO_CPU" ]; then
	test_path='/npb-dp/tests/npb/regressions/sanity_copy_to_cpu'
elif [ "$profile" = "PROFILE_EGRESS_TRANSPORT" ]; then
	test_path='/npb-dp/tests/npb/regressions/sanity_egress_transport'
else
	test_path='/npb-dp/tests/npb/regressions/sanity'
fi

# -------------------------------------

pushd $test_path
./symlinks.sh
popd

# -------------------------------------

pushd $SDE

#source ./set_sde.bash

if [ "$1" == "1" ]; then

    # tofino 1
    # --------
    
    log_path=$test_path/logs/tofino
    if [ ! -d $log_path ]; then
        mkdir -p $log_path
    else
        rm -f $log_path/*.log # remove existing logs
    fi
    
    #./run_p4_tests.sh -t $test_path --arch tofino -s test_mau_1hop_s_e.test || status=1
    ./run_p4_tests.sh -t $test_path --arch tofino || status=1
    cp ptf.log $log_path/ptf.log || status=1
    cp model_0.log $log_path/model_0.log || status=1
    
else

    # tofino 2
    # --------
    
    log_path=$test_path/logs/tofino2
    if [ ! -d $log_path ]; then
        mkdir -p $log_path
    else
        rm -r $log_path/*.log # remove existing logs
    fi

    ./run_p4_tests.sh -t $test_path --arch tofino2 -s test_mau_raw_packet.test || status=1
    #./run_p4_tests.sh -t $test_path --arch tofino2 -s test_mau_1hop_s_e.test || status=1
    #./run_p4_tests.sh -t $test_path --arch tofino2 -s test_parser_ing_cpu.test || status=1
    #./run_p4_tests.sh -t $test_path --arch tofino2 || status=1
    cp ptf.log $log_path/ptf.log || status=1
    cp model_0.log $log_path/model_0.log || status=1
    cp bf_drivers.log $log_path/bf_drivers.log || status=1

fi

popd

if [ $status -eq 0 ]; then
    echo "************************"
    echo "*** ALL TESTS PASSED ***"
    echo "************************"
else
    echo "*************************"
    echo "*** SOME TESTS FAILED ***"
    echo "*************************"
fi

exit $status
