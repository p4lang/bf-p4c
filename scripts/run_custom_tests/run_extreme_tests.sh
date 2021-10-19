#!/bin/sh

bfnhome="/bfn/bf-p4c-compilers"

# Configure PTF to run with python2
sed -i "s/'python3'\(.*PTF\)/'python2'\1/g" $bfnhome/p4-tests/ptf_runner.py

# Clear out CC and CXX (use local compilers instead of distcc)
unset CC CXX

# Install python2
apt update && apt install -y python python-pip python-yaml

# Install grpc for python2
sed -i 's/pip /pip2 /g' \
        /p4factory/release/target-toplevel-files/p4studio/dependencies/source/install_grpc.py
python2 /p4factory/release/target-toplevel-files/p4studio/dependencies/source/install_grpc.py \
            -os Ubuntu -ver 16.04 -si /usr/local -j8

# Remove scapy for python3
rm -rf /usr/local/lib/python3.5/site-packages/scapy*
# Install scapy v2.4.0 for python2
git clone --recursive -b v2.4.0 https://github.com/secdev/scapy.git
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
cp -rf ptf/ptf /usr/local/bin/
rm -rf ptf

# Patch scapy
echo "Patching scapy with additional protocol modules"
cp $bfnhome/scripts/run_custom_tests/patches/scapy/*.py /usr/local/lib/python2.7/dist-packages/scapy/contrib/

# Patch ptf
echo "Patching ptf so it loads new scapy protocol modules"
cat $bfnhome/scripts/run_custom_tests/patches/ptf/packet-patch.py >> /usr/local/lib/python2.7/dist-packages/ptf/packet.py
sed -i 's/sequence_number/seqence_number/g' /usr/local/lib/python2.7/dist-packages/ptf/testutils.py

# Run test
export CTEST_OUTPUT_ON_FAILURE='true'
[ -z "$PYTHONPATH" ] && delim='' || delim=':'
export PYTHONPATH="/usr/local/lib/python2.7/dist-packages/ptf${delim}${PYTHONPATH}"
echo "Running ptf test"
cd $bfnhome/build/p4c && ctest -R "^tofino2/.*npb-master-ptf"
