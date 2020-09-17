#! /bin/bash

# This script replicates the directory structure for p4c with
# extensions and invokes the p4lang/p4c/bootstrap to configure the
# build environment

umask 0022
set -e

mydir=`dirname $0`
mydir=`realpath $mydir`
pushd $mydir

show_help () {
    echo >&2 "bootstrap_bfn_compiler script options"
    echo >&2 "   --no-ptf               don't use/configure ptf"
    echo >&2 "   --build-dir <dir>      build in <dir> rather than ./build"
    echo >&2 "   --build-type <type>    DEBUG RELEASE or RelWithDebInfo"
    echo >&2 "   --p4c-cpp-flags <x>    add <x> to CPPFLAGS for p4c build"
    echo >&2 "   --small-config         only builds the compiler and testing"
    echo >&2 "   --minimal-config       disable most build targets other than the compiler"
    echo >&2 "   --disable-unified      disable unified build"
    echo >&2 "   --cmake-gen <gen>      see 'cmake -h' for list of generators"
}


RUN_BOOTSTRAP_PTF=yes
builddir=${mydir}/build
buildtype=DEBUG
P4C_CPP_FLAGS=''
smallConfig=false
minimalConfig=false
disableUnified=false
otherArgs=""

while [ $# -gt 0 ]; do
    case $1 in
    --no-ptf)
        RUN_BOOTSTRAP_PTF=no
        ;;
    --build-dir)
        builddir="$2"
        shift
        ;;
    --build-type)
        buildtype="$2"
        shift
        ;;
    --p4c-cpp-flags)
        P4C_CPP_FLAGS="$2"
        shift
        ;;
    --small-config)
        smallConfig=true
        ;;
    --minimal-config)
        minimalConfig=true
        ;;
    --disable-unified)
        disableUnified=true
        ;;
    --cmake-gen)
        cmakeGen="$2"
        shift
        ;;
    -D*)
        otherArgs+=" $1"
        ;;
    *)
        echo >&2 "Invalid argument supplied"
        show_help
        exit 0
        ;;
    esac
    shift
done

# Generate the licence file.
scripts/generate-license.sh

# Check for git version: 2.11.0 does not support virtual links
git_version=`git --version | head -1 | awk '{ print $3; }'`
if [[ $git_version == "2.11.0" ]]; then
    echo "git version $git_version is broken."
    echo "Please upgrade or downgrade your git version. Recommended versions: 1.8.x, 2.7.x, > 2.14.x"
    exit 1
fi

if [ ! -r p4c/CMakeLists.txt ]; then
    git submodule update --init --recursive
fi

# bootstrap the compiler
mkdir -p p4c/extensions

pushd p4c/extensions
if [ ! -e bf-p4c ]; then ln -sf ../../bf-p4c bf-p4c; fi
if [ ! -e p4_tests ]; then ln -sf ../../p4-tests p4_tests; fi
popd # p4c/extensions

# install a git hook if the user doesn't already have one defined
function install_hook() {
    local hook=$1
    if [[ -d .git && -e scripts/hooks/$hook && ! -e .git/hooks/$hook ]]; then
        pushd .git/hooks > /dev/null
        ln -sf ../../scripts/hooks/$hook $hook
        popd > /dev/null
    fi
}
install_hook pre-commit
install_hook commit-msg

ENABLED_COMPONENTS="-DENABLE_JBAY=ON -DENABLE_EBPF=OFF -DENABLE_UBPF=OFF"
if $smallConfig ; then
    ENABLED_COMPONENTS="$ENABLED_COMPONENTS -DENABLE_BMV2=OFF \
                        -DENABLE_P4C_GRAPHS=OFF -DENABLE_GTESTS=OFF"
fi
if $minimalConfig ; then
    ENABLED_COMPONENTS="$ENABLED_COMPONENTS -DENABLE_BMV2=OFF -DENABLE_P4TEST=OFF \
                        -DENABLE_P4C_GRAPHS=OFF -DENABLE_TESTING=OFF -DENABLE_GTESTS=OFF"
fi
if $disableUnified ; then
    ENABLED_COMPONENTS+=" -DENABLE_UNIFIED_COMPILATION=OFF"
fi

mkdir -p ${builddir}
pushd ${builddir}
cmake ${mydir} -DCMAKE_BUILD_TYPE=${buildtype}\
      ${cmakeGen:+"-G${cmakeGen}"} \
      ${ENABLED_COMPONENTS} \
      -DENABLE_GMP=OFF \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=1\
      -DP4C_CPP_FLAGS="$P4C_CPP_FLAGS" $otherArgs
if [[ `uname -s` == "Linux" ]]; then
    linux_distro=$(cat /etc/os-release | grep -e "^NAME" | cut -f 2 -d '=' | tr -d "\"")
    linux_version=$(cat /etc/os-release | grep -e "^VERSION_ID" | cut -f 2 -d '=' | tr -d "\"")
    if [[ $linux_distro == "Fedora" && $linux_version == "18" ]]; then
        # For some peculiar reason, Fedora 18 refuses to see the GC_print_stats symbol
        # even though cmake detects it. So we disabe it explicitly.
        sed -e 's/HAVE_GC_PRINT_STATS 1/HAVE_GC_PRINT_STATS 0/' -i"" p4c/config.h
    fi
fi
popd # builddir

if [ "$RUN_BOOTSTRAP_PTF" == "yes" ]; then
    ${mydir}/bootstrap_ptf.sh ${builddir}
fi

mkdir -p ${builddir}/p4c/extensions/bf-p4c
ln -sf $(realpath --relative-to ${builddir}/p4c/extensions/bf-p4c ${mydir}/bf-p4c/.gdbinit) ${builddir}/p4c/extensions/bf-p4c/p4c-barefoot-gdb.gdb
mkdir -p ${builddir}/p4c/backends/bmv2/
ln -sf $(realpath --relative-to ${builddir}/p4c/backends/bmv2 ${mydir}/bf-p4c/.gdbinit) ${builddir}/p4c/backends/bmv2/p4c-bm2-ss-gdb.gdb
mkdir -p ${builddir}/p4c/backends/p4test
ln -sf $(realpath --relative-to ${builddir}/p4c/backends/p4test ${mydir}/bf-p4c/.gdbinit) ${builddir}/p4c/backends/p4test/p4test-gdb.gdb

echo "Configured for build in ${builddir}"
popd > /dev/null # $mydir
