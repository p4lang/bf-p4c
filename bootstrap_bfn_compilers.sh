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

set -e

mydir=`dirname $0`
cd $mydir

if [ ! -r p4c/Makefile.am ]; then
    git submodule update --init --recursive
fi

# bootstrap the compiler
mkdir -p p4c/extensions

pushd p4c/extensions
if [ ! -e tofino ]; then ln -sf ../../bf-p4c tofino; fi
if [ ! -e p4_tests ]; then ln -sf ../../p4-tests p4_tests; fi
popd # p4c/extensions

mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=DEBUG $*

cd p4c
if [ ! -e p4c-tofino-gdb.gdb ]; then ln -sf ../../bf-p4c/.gdbinit p4c-tofino-gdb.gdb; fi
if [ ! -e p4c-bm2-ss-gdb.gdb ]; then ln -sf ../../bf-p4c/.gdbinit p4c-bm2-ss-gdb.gdb; fi

echo "Configured for build in build"
