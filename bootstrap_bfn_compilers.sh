#! /bin/bash
# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script replicates the directory structure for p4c with
# extensions and invokes the p4lang/p4c/bootstrap to configure the
# build environment

umask 0022
set -e

mydir=`dirname $0`
mydir=`realpath $mydir`
pushd $mydir

RUN_BOOTSTRAP_PTF=yes
if [ "$1" == "--no-ptf" ]; then
    RUN_BOOTSTRAP_PTF=no
    shift
fi

builddir=${mydir}/build
if [ "$1" == "--build-dir" ]; then
    builddir="$2"
    shift; shift;
fi

P4C_CPP_FLAGS=''
if [ "$1" == "--p4c-cpp-flags" ]; then
    P4C_CPP_FLAGS="$2"
    shift; shift;
fi

# git version check - 2.11.0 doesn't work
installed_git_ver=$(git --version | cut -f 3 -d " ")
if [[ $installed_git_ver == *"2.11.0"* ]]; then
    echo "Installed git version is not suitable: $installed_git_ver"
    echo "Upgrade to a different version of git and rerun script"
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

# install the commit-msg hook if the user doesn't already have one defined
if [[ -d .git && -e scripts/hooks/commit-msg && ! -e .git/hooks/commit-msg ]]; then
    pushd .git/hooks > /dev/null
    ln -sf ../../scripts/hooks/commit-msg commit-msg
    popd > /dev/null
fi

mkdir -p ${builddir}
pushd ${builddir}
cmake ${mydir} -DCMAKE_BUILD_TYPE=DEBUG -DENABLE_JBAY=ON \
      -DENABLE_EBPF=OFF \
      -DP4C_CPP_FLAGS="$P4C_CPP_FLAGS" $*
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
ln -sf ${mydir}/bf-p4c/.gdbinit ${builddir}/p4c/extensions/bf-p4c/p4c-barefoot-gdb.gdb
mkdir -p ${builddir}/p4c/backends/bmv2/
ln -sf ${mydir}/bf-p4c/.gdbinit ${builddir}/p4c/backends/bmv2/p4c-bm2-ss-gdb.gdb
mkdir -p ${builddir}/p4c/backends/p4test
ln -sf ${mydir}/bf-p4c/.gdbinit ${builddir}/p4c/backends/p4test/p4test-gdb.gdb

echo "Configured for build in ${builddir}"
popd > /dev/null # $mydir
