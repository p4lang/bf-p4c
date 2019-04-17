# Setup

This repo contains the backend for the Barefoot p4c compiler suite.
It has the following structure:

```
bf-p4c-compilers
├── p4c      -- submodule for the p4lang/p4c repo
├── bf-p4c   -- the contents of the old p4c-extension-tofino repo
├── bf-asm   -- the contents of the old tofino-asm repo
└-- p4_tests -- submodule for the p4_tests repo
```

There are two scripts in the top level directory that support building
the compiler and assembler.

bootstrap_bfn_env.sh -- used to checkout and build all dependent
repositories and install dependent packages

- some systems may see issues with conflicts between different versions
  of libproto.so -- when running the above bootstrap_bfn_env.sh script you
  may see warnings about conflicting libproto.so versions followed by
  incomprehensible linking errors.  To fix this you need to remove the
  symlinks/static libs for the old versions of libproto so only the newer
  ones will be used by the linker.  On Ubuntu 16.04 you need:
```
    $ cd /usr/lib/x86_64-linux-gnu
    $ sudo mkdir old
    $ sudo mv libproto*.so old
    $ sudo mv libproto*.a old
```
- you may choose to remove the files rather than just moving them, but DO NOT
  remove the versioned .so files (libprotobuf.so.9.0.1 and others), as doing
  so will break your system.

bootstrap_bfn_compilers.sh -- bootstraps the configuration for p4c
(with the Tofino extension) and assembler.

To configure and build:
```
git clone --recursive git@github.com:barefootnetworks/bf-p4c-compilers.git
cd bf-p4c-compilers
./bootstrap_bfn_env.sh
./bootstrap_bfn_compilers.sh [--prefix <path>] [--enable-doxygen-docs]
cd build
make -j N [check] [install]
```

# Dependencies

Each of the submodules have dependencies. Please see the
[p4lang/p4c](p4c/README.md), [Barefoot p4c](bf-p4c/README.md), and
[Barefoot asm](bf-asm/README.md) for the different project
dependencies.
