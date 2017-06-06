#! /bin/bash

git clone --recursive git@github.com:barefootnetworks/p4c-extension-tofino bf-p4c-compilers
cd bf-p4c-compilers/
git checkout -b bf-p4c-compilers
git mv bootstrap.sh bootstrap_bfn_env.sh
mkdir bf-p4c
git mv Makefile.am README.md addconfig.ac *.cpp *.h common docs driver ir lib mau p4*include parde phv test bf-p4c
git mv .gdbinit bf-p4c
git commit -m "moves p4c-extension-tofino files into bf-p4c"
git submodule add git@github.com:p4lang/p4c.git p4c
git add .gitmodules p4c
git commit -m "adds p4lang/p4c as a submodule"
git submodule add git@github.com:barefootnetworks/p4_tests p4-tests
git add .gitmodules p4-tests
git commit -m "adds p4-tests as a submodule"
git submodule update --init --recursive
git remote add bf-asm git@github.com:barefootnetworks/tofino-asm
git fetch bf-asm
mkdir bf-asm
git merge --allow-unrelated-histories bf-asm/master
git mv *.cpp *.h jbay m4 bootstrap.sh asm-parse.ypp Makefile.am configure.ac README.md lex-yaml.l tflink tofino walle vector.c test .gitignore .gdbinit bf-asm
git commit -m "merged tofino-asm"
cat > README.md <<EOF
# Setup

This repo contains the backend for the Barefoot p4c compiler suite.
It has the following structure:

```
bf-p4c-compilers
├── p4c      -- submodule for the p4lang/p4c repo
├── bf-p4c   -- the contents of the current p4c-extension-tofino repo
├── bf-asm   -- the contents of the tofino-asm repo
└-- p4_tests -- submodule for the p4_tests repo
```

There are two scripts in the top level directory that support building
the compiler and assembler.

bootstrap_bfn_env.sh -- used to checkout and build all dependent
repositories (needs updating to the structure for this repo)

bootstrap_bfn_compilers.sh -- bootstaps the configuration for p4c
(with the Tofino extension) and assembler. The assembler build will be
integrated into the bf-p4c build at a later time.

To configure and build:
```
git clone git@github.com:barefootnetworks/bf-p4c-compilers.git
git submodule update --init --recursive
./bootstrap_bfn_compilers.sh [--prefix <path>] [--enable-doxygen-docs]
cd p4c/build
make -j N [install]
cd ../..
cd build/bf-asm
make -j N [install]
cd ../..

# Dependencies

Each of the submodules have dependencies. Please see the
[p4lang/p4c](p4c/README.md), [Barefoot p4c](bf-p4c/README.md), and
[Barefoot asm](bf-asm/README.md) for the different project
dependencies.
EOF
cat > bootstrap_bfn_compilers.sh <<EOF
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

if [ ! -d p4c ]; then
    git submodule update --init --recursive
fi

# bootstrap the compiler
mkdir -p p4c/extensions

pushd p4c
pushd extensions
ln -sf ../../bf-p4c tofino
popd
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

EOF
cat >> bf-asm/.gitignore <<EOF
Makefile.in
aclocal.m4
autom4te.cache
build
compile
config.h.in
configure
depcomp
install-sh
missing
ylwrap
EOF
cat > .gitignore <<EOF
build
EOF
git add .gitignore bf-asm/.gitignore README.md bootstrap_bfn_compilers.sh
git commit -m "adds bootstrap script and readme"
