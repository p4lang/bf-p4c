#! /bin/bash

set -e

topdir=$(dirname $0)/..
builddir=build.release
parallel_make=4
$topdir/bootstrap_bfn_compilers.sh --no-ptf  --build-dir $builddir \
                                   -DCMAKE_BUILD_TYPE=RELEASE \
                                   -DCMAKE_INSTALL_PREFIX=/usr/local \
                                   -DENABLE_JBAY=OFF -DENABLE_BMV2=ON \
                                   -DENABLE_EBPF=OFF -DENABLE_P4TEST=OFF \
                                   -DENABLE_P4C_GRAPHS=ON
cd $builddir
# make tofino the default target for p4c
sed -i -e "/os.environ\['P4C_14_INCLUDE_PATH/a os.environ['P4C_DEFAULT_TARGET'] = 'tofino'" p4c/p4c

make -j $parallel_make package

# verify that the package has no JBay references
set +e
pushd _CPack_Packages/Linux/DEB/p4c-compilers-*
p4c_bin=$(find . -name p4c-barefoot)
echo $p4c_bin
jbay_refs=$(strings $p4c_bin | c++filt | grep -i jbay)
if [[ -n $jbay_refs ]] ; then
    echo "Need to remove all JBay references from bf-p4c sources"
    echo $jbay_refs
    exit 1
fi
jbay_other=$(grep -ri jbay *)
if [[ -n $jbay_other ]] ; then
    echo "Please remove all JBay references from:"
    echo "$jbay_other"
    exit 1
fi
popd

echo "Success!"
exit 0
