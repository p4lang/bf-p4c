#! /bin/sh
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

if [ ! -d p4c ]; then
    git submodule update --init --recursive
fi

# bootstrap the compiler
mkdir -p p4c/extensions
ln -sf bf-p4c p4c/extensions/tofino
pushd p4c
./bootstrap.sh $*
popd
ln -s p4c/build build

# bootstrap and configure the assembler
pushd bf-asm
autoreconf -i
mkdir -p build && cd build
../configure $*
popd
pushd p4c/build
ln -sf ../../bf-asm/build bf-asm
popd

echo "Configured for build: p4c in build, bf-asm in build/bf-asm"
