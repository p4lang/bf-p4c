#!/bin/bash -e

bfnhome="/bfn/bf-p4c-compilers"

# If running in jarvis container, set bfnhome to /mnt and patch test.json
if [[ $PWD == *"mnt"* ]]; then
    bfnhome="/mnt"
    sed -i 's/bfn\/bf-p4c-compilers/mnt/g' $bfnhome/p4-tests/p4_16/internal/customer/extreme/npb-master-ptf/tests/test.json
    sed -i 's/bfn\/bf-p4c-compilers/mnt/g' $bfnhome/p4-tests/p4_16/internal/customer/extreme/npb-multi-prog/tests/test.json
    sed -i 's/bfn\/bf-p4c-compilers/mnt/g' $bfnhome/p4-tests/p4_16/internal/customer/extreme/npb-folded-pipe/tests/test.json
    sed -i 's/bfn\/bf-p4c-compilers/mnt/g' $bfnhome/p4-tests/p4_16/internal/customer/extreme/p4c-5244/tests/test.json
fi

# Remove scapy for python3
rm -rf /usr/local/lib/python3.8/site-packages/scapy*
# Install scapy v2.4.0 for python2
git clone --recursive -b v2.4.0 https://github.com/secdev/scapy.git
cd scapy
# Somehow the pkg_resources module used in scapy's install cannot handle versions like 0.23ubuntu1
# of dist_info. I did not manage to find a way to reliably and nice replace either of these modules,
# so just spoof the version so that pkg_resources does not fail. We don't care if this does not
# pass, as that would suggest the version on this OS.
sed -i 's/ubuntu/./' /usr/lib/python3/dist-packages/distro_info-*.egg-info/PKG-INFO || true
python3 setup.py install
cd ..
rm -rf scapy

# Patch scapy
echo "Patching scapy with additional protocol modules"
shome=$(pip show scapy | grep Location | sed -e 's/^Location://')
cp $bfnhome/scripts/run_custom_tests/patches/scapy/*.py $shome/scapy/contrib/

# Patch ptf
echo "Patching ptf so it loads new scapy protocol modules"
cat $bfnhome/scripts/run_custom_tests/patches/ptf/packet-patch.py >> /usr/local/lib/python3.8/site-packages/ptf/packet.py
sed -i 's/sequence_number/seqence_number/g' /usr/local/lib/python3.8/site-packages/ptf/testutils.py

# Run test
export CTEST_OUTPUT_ON_FAILURE='true'
echo "Running ptf test"
# The PTF tests are flaky. The PTF test fails intermittently even with the
# same tofino binary. According to model logs, it seems the first deviation
# happens after a different value is read from a register, so maybe it really is
# some race-condition during test setup.
export RERUN_PTF_ON_FAILURE=1
cd $bfnhome/build/p4c && ctest -R "^tofino2/.*(npb-master-ptf|npb-multi-prog|npb-folded-pipe|p4c-5244)"

# If running in jarvis container, reset test.json patch
if [[ $PWD == *"mnt"* ]]; then
    sed -i 's/mnt/bfn\/bf-p4c-compilers/g' $bfnhome/p4-tests/p4_16/internal/customer/extreme/npb-master-ptf/tests/test.json
    sed -i 's/mnt/bfn\/bf-p4c-compilers/g' $bfnhome/p4-tests/p4_16/internal/customer/extreme/npb-multi-prog/tests/test.json
    sed -i 's/mnt/bfn\/bf-p4c-compilers/g' $bfnhome/p4-tests/p4_16/internal/customer/extreme/npb-folded-pipe/tests/test.json
    sed -i 's/mnt/bfn\/bf-p4c-compilers/g' $bfnhome/p4-tests/p4_16/internal/customer/extreme/p4c-5244/tests/test.json
    bfnhome="/bfn/bf-p4c-compilers"
fi
