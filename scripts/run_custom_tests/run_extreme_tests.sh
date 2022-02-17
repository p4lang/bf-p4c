#!/bin/bash

bfnhome="/bfn/bf-p4c-compilers"

# If running in jarvis container, set bfnhome to /mnt and patch test.json
if [[ $PWD == *"mnt"* ]]; then
    bfnhome="/mnt"
    sed -i 's/bfn\/bf-p4c-compilers/mnt/g' $bfnhome/p4-tests/p4_16/customer/extreme/npb-master-ptf/tests/test.json
    sed -i 's/bfn\/bf-p4c-compilers/mnt/g' $bfnhome/p4-tests/p4_16/customer/extreme/npb-multi-prog/tests/test.json
fi

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
cd $bfnhome/build/p4c && ctest -V -R "^tofino2/.*npb-multi-prog"

# If running in jarvis container, reset test.json patch
if [[ $PWD == *"mnt"* ]]; then
    sed -i 's/mnt/bfn\/bf-p4c-compilers/g' $bfnhome/p4-tests/p4_16/customer/extreme/npb-master-ptf/tests/test.json
    sed -i 's/mnt/bfn\/bf-p4c-compilers/g' $bfnhome/p4-tests/p4_16/customer/extreme/npb-multi-prog/tests/test.json
    bfnhome="/bfn/bf-p4c-compilers"
fi
