#!/bin/sh

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

# Install grpc for python2
sed -i 's/pip /pip2 /g' \
        /p4factory/release/target-toplevel-files/p4studio/dependencies/source/install_grpc.py
python2 /p4factory/release/target-toplevel-files/p4studio/dependencies/source/install_grpc.py \
            -os Ubuntu -ver 16.04 -si /usr/local -j8

# Install thrift for python2
sed -i 's/pip /pip2 /g' \
        /p4factory/release/target-toplevel-files/p4studio/dependencies/source/install_thrift.py
python2 /p4factory/release/target-toplevel-files/p4studio/dependencies/source/install_thrift.py \
            -os Ubuntu -ver 16.04 -k apt -j8

# Remove scapy for python3
rm -rf /usr/local/lib/python3.5/site-packages/scapy*
# Install scapy for python2
git clone --recursive https://github.com/secdev/scapy.git
cd scapy
python2 setup.py install
cd ..
rm -rf scapy

# Remove ptf (and bf-ptf) for python3
rm -rf /usr/local/lib/python3.5/site-packages/*ptf*
# Install p4lang/ptf for python2
git clone https://github.com/p4lang/ptf.git
mkdir -p /usr/local/lib/python2.7/dist-packages/
cp -rf ptf/src/* /usr/local/lib/python2.7/dist-packages/
yes | cp -rf ptf/ptf /usr/local/bin/
rm -rf ptf

if [ "$1" != "install-deps" ]; then
        # Run test
        export CTEST_OUTPUT_ON_FAILURE='true'
        echo "Running ptf test"
        cd $bfnhome/build && eval $@
fi
