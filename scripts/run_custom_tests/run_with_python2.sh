#!/bin/bash -e

bfnhome="/bfn/bf-p4c-compilers"

# Configure PTF to run with python2
sed -i "s/'python3'\(.*PTF\)/'python2'\1/g" $bfnhome/p4-tests/ptf_runner.py
sed -i "/\s*os.environ\['PYTHONPATH'\].*os.path.join(testdir, site_pkg, device)/a \    os.environ['PYTHONPATH'] += \":\" + os.path.join(testdir, 'lib', 'python2.7', 'site-packages', device+'pd')\n\    os.environ['PYTHONPATH'] += \":\" + os.path.join(testdir, 'lib', 'python2.7', 'site-packages', device)" $bfnhome/p4-tests/ptf_runner.py
sed -i "/\s*os.environ\['PYTHONPATH'\].*os.path.join(testdir, site_pkg)/a \    os.environ['PYTHONPATH'] += \":\" + os.path.join(testdir, 'lib', 'python2.7', 'site-packages')" $bfnhome/p4-tests/ptf_runner.py

# Clear out CC and CXX (use local compilers instead of distcc)
unset CC CXX


# Install python2
apt update && apt install -y python python-pip python-yaml
pip2 install ipaddress crc16

pushd $bfnhome/scripts/run_custom_tests/p4studio_dependencies

echo Installing grpc...
# Install grpc for python2
sed -i 's/pip /pip2 /g' install_grpc.py
python install_grpc.py -os Ubuntu -ver 16.04 -si /usr/local -j8

echo Installing thrift...
# Install thrift for python2
sed -i 's/pip /pip2 /g' install_thrift.py
python install_thrift.py -os Ubuntu -ver 16.04 -si /usr/local -k apt -j8

popd # p4studio_dependencies

pip2 install ptf scapy

if [ "$1" != "install-deps" ]; then
        # Run test
        export CTEST_OUTPUT_ON_FAILURE='true'
        echo "Running ptf test"
        cd $bfnhome/build && eval $@
fi
