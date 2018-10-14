#! /bin/bash

set -e

topdir=$(dirname $0)/..
builddir=build.release
set -x
if [[ $(uname -s) == 'Linux' ]]; then
    parallel_make=`cat /proc/cpuinfo | grep processor | wc -l`
    enable_static="-DENABLE_STATIC_LIBS=ON"
else
    parallel_make=8
    enable_static=""
fi

install_prefix=/usr/local
if [ "$1" == "--install-prefix" ]; then
    if [ -z "$2" ]; then
        echo "Error: Install prefix has to be specified"
        echo "Usage: ./scripts/package_p4c_for_tofino.sh --install-prefix <install_prefix>"
        exit 1
    fi
    install_prefix="$2"
    shift; shift;
fi

$topdir/bootstrap_bfn_compilers.sh --no-ptf --build-dir $builddir \
                                   -DCMAKE_BUILD_TYPE=RELEASE \
                                   -DCMAKE_INSTALL_PREFIX=$install_prefix \
                                   -DENABLE_BMV2=OFF -DENABLE_EBPF=OFF \
                                   -DENABLE_P4TEST=OFF -DENABLE_P4C_GRAPHS=OFF \
                                   $enable_static \
                                   -DENABLE_BAREFOOT_INTERNAL=OFF \
                                   -DENABLE_TESTING=OFF -DENABLE_GTESTS=OFF
cd $builddir
make -j $parallel_make package

echo "Success!"
exit 0
