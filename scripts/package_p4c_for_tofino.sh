#! /bin/bash

set -e

topdir=$(dirname $0)/..
builddir=build.release
parallel_make=4
$topdir/bootstrap_bfn_compilers.sh --no-ptf  --build-dir $builddir \
                                   -DCMAKE_BUILD_TYPE=RELEASE \
                                   -DCMAKE_INSTALL_PREFIX=/usr/local \
                                   -DENABLE_JBAY=OFF -DENABLE_BMV2=OFF \
                                   -DENABLE_EBPF=OFF -DENABLE_P4TEST=OFF \
                                   -DENABLE_P4C_GRAPHS=ON
cd $builddir
make -j $parallel_make package

# verify that the package has no JBay references
pushd _CPack_Packages/Linux/DEB/p4c-compilers-*
jbay_refs=$(strings usr/local/bin/p4c-barefoot | grep -i jbay | c++filt)
if [ $? == 0 ] ; then
    echo "Need to remove all JBay references from bf-p4c sources"
    echo $jbay_refs
    exit 1
fi
jbay_other=$(grep -ri jbay *)
if [ $? == 0 ] ; then
    echo "Please remove all JBay references from:"
    echo "$jbay_other"
    exit 1
fi
popd

echo "Success!"
exit 0
