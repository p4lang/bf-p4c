#! /bin/bash

set -e

topdir=$(dirname $0)/..
builddir=build.release
# set -x
if [[ $(uname -s) == 'Linux' ]]; then
    parallel_make=`cat /proc/cpuinfo | grep processor | wc -l`
    enable_static="-DENABLE_STATIC_LIBS=ON"
else
    parallel_make=8
    enable_static=""
fi

usage() {
    echo $1
    echo "Usage: ./scripts/package_p4c_for_tofino.sh <optional arguments>"
    echo "   --build-dir <builddir>"
    echo "   --install-prefix <install_prefix>"
    echo "   --barefoot-internal"
    echo "   --enable-cb"
    echo "   -j <numjobs>"
}


install_prefix=/usr/local
barefoot_internal="-DENABLE_BAREFOOT_INTERNAL=OFF"
enable_cb="-DENABLE_CLOUDBREAK=OFF"
enable_fr="-DENABLE_FLATROCK=OFF"
while [ $# -gt 0 ]; do
    case $1 in
        --build-dir)
            if [ -z "$2" ]; then
                usage "Error: Build dir has to be specified"
                exit 1
            fi
            builddir="$2"
            shift;
            ;;
        --install-prefix)
            if [ -z "$2" ]; then
                usage "Error: Install prefix has to be specified"
                exit 1
            fi
            install_prefix="$2"
            shift;
            ;;
        --barefoot-internal)
            barefoot_internal="-DENABLE_BAREFOOT_INTERNAL=ON"
            ;;
        --enable-cb)
            enable_cb="-DENABLE_CLOUDBREAK=ON"
            ;;
        --enable-fr)
            enable_fr="-DENABLE_FLATROCK=ON"
            ;;
	-j)
            parallel_make="$2"
            shift;
            ;;
        -h|--help)
            usage ""
            exit 0
            ;;
    esac
    shift
done

# Add copyright headers to all BFN/Intel source files before building and
# packaging, so that we can easily avoid touching files from P4.org.
#
# Do this by adding headers to everything except p4c/ and p4-tests/.
"${topdir}/scripts/packaging/copyright-stamp" "${topdir}"

$topdir/bootstrap_bfn_compilers.sh --build-dir $builddir \
                                   -DCMAKE_BUILD_TYPE=RELEASE \
                                   -DCMAKE_INSTALL_PREFIX=$install_prefix \
                                   -DENABLE_BMV2=OFF -DENABLE_EBPF=OFF -DENABLE_UBPF=OFF \
                                   -DENABLE_P4TEST=OFF -DENABLE_P4C_GRAPHS=OFF \
                                   -DENABLE_DOXYGEN=OFF \
                                   $enable_cb $enable_fr \
                                   $enable_static \
                                   $barefoot_internal \
                                   -DENABLE_GTESTS=OFF \
                                   -DENABLE_WERROR=OFF
cd $builddir
make -j $parallel_make package

echo "Success!"
exit 0
