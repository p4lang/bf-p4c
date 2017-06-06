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
cd build
make -j N [install]
cd ..
cd build/bf-asm
make -j N [install]
cd ../..

# Dependences

Each of the submodules have dependencies. Please see the
[p4lang/p4c](p4c/README.md), [Barefoot p4c](bf-p4c/README.md), and
[Barefoot asm](bf-asm/README.md) for the different project
dependencies.
