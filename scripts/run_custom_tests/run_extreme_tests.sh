#!/bin/sh

bfnhome="/bfn/bf-p4c-compilers"

# Remove scapy for python3
rm -rf /usr/local/lib/python3.5/site-packages/scapy*
# Install scapy v2.4.0 for python2
git clone --recursive -b v2.4.0 https://github.com/secdev/scapy.git
cd scapy
python3 setup.py install
cd ..
rm -rf scapy

# Patch scapy
echo "Patching scapy with additional protocol modules"
shome=$(pip show scapy | grep Location | sed -e 's/^Location://')
cp $bfnhome/scripts/run_custom_tests/patches/scapy/*.py $shome/scapy/contrib/

# Patch ptf
echo "Patching ptf so it loads new scapy protocol modules"
cat $bfnhome/scripts/run_custom_tests/patches/ptf/packet-patch.py >> /usr/local/lib/python3.5/site-packages/ptf/packet.py
sed -i 's/sequence_number/seqence_number/g' /usr/local/lib/python3.5/site-packages/ptf/testutils.py

# Run test
export CTEST_OUTPUT_ON_FAILURE='true'
echo "Running ptf test"
cd $bfnhome/build/p4c && ctest -V -R "^tofino2/.*npb-master-ptf"
