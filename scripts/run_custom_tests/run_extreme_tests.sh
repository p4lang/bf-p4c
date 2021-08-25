#!/bin/sh

bfnhome="/bfn/bf-p4c-compilers"

# Install scapy v2.4.0
git clone --recursive -b v2.4.0 https://github.com/secdev/scapy.git
cd scapy
python setup.py install
cd ..
rm -rf scapy

# Patch scapy
echo "Patching scapy with additional protocol modules"
shome=$(pip show scapy | grep Location | sed -e 's/^Location://')
cp $bfnhome/scripts/run_custom_tests/patches/scapy/*.py $shome/scapy/contrib/

# Patch ptf
echo "Patching ptf so it loads new scapy protocol modules"
cat $bfnhome/scripts/run_custom_tests/patches/ptf/packet-patch.py >> /usr/local/lib/python2.7/site-packages/ptf/packet.py
sed -i 's/sequence_number/seqence_number/g' /usr/local/lib/python2.7/site-packages/ptf/testutils.py

# Run test
export CTEST_OUTPUT_ON_FAILURE='true'
[ -z "$PYTHONPATH" ] && delim='' || delim=':'
export PYTHONPATH="/usr/local/lib/python2.7/site-packages/ptf${delim}${PYTHONPATH}"
echo "Running ptf test"
cd $bfnhome/build/p4c && ctest -R "^tofino2/.*npb-master-ptf"
