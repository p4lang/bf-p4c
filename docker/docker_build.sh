#!/bin/bash -e

# This builds the bf-p4c-compilers Docker image and expected to be executed
# from the Dockerfile with RUN.
set -e

if [[ "${CC}" == "gcc-6" || "${CXX}" == "g++-6" ]] ; then
    gcc6archive="deb http://archive.ubuntu.com/ubuntu bionic main universe"
    if ! grep -q "$gcc6archive" /etc/apt/sources.list; then
        echo -e "\n#needed for gcc6\n$gcc6archive" | sudo tee -a /etc/apt/sources.list >/dev/null
    fi
    apt update
    apt install -y g++-6
    apt clean -y
fi

if [[ "${UNIFIED_BUILD}" != true ]] ; then
    BOOTSTRAP_EXTRA_OPTS+=("--disable-unified")
fi

if [[ "${UBSAN}" == "true" ]] ; then
    BOOTSTRAP_EXTRA_OPTS+=("--enable-ubsan")
fi
if [[ "${ASAN}" == "true" ]] ; then
    BOOTSTRAP_EXTRA_OPTS+=("--enable-asan")
fi
if [[ "${UBSAN}" == "true" || "${ASAN}" == "true" ]] ; then
    # These configurations might emit additional warnings,
    # that we do not see in standard builds.
    # Do not block builds by treating them as errors.
    BOOTSTRAP_EXTRA_OPTS+=("--disable-werror")
fi

if [[ "${TOFINO_P414_TEST_ARCH_TNA}" == "true" ]] ; then
    BOOTSTRAP_EXTRA_OPTS+=("-DTOFINO_P414_TEST_ARCH=tna")
fi

# Configure the linker to strip symbols.
export LDFLAGS="-Wl,-s"

./bootstrap_bfn_compilers.sh \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_STF2PTF=OFF \
    -DINSTALL_LIBDYNHASH=OFF \
    ${BOOTSTRAP_EXTRA_OPTS[@]}

cd build
make
make install

# Clean up.
ccache -p --show-stats
rm -rf ~/.cache/* /var/cache/apt/* /var/lib/apt/lists/*
rm -rf bf-asm/walle/build/*
find . -name '*.o' -type f -delete
find . -name '*.a' -type f -delete


# Generate reference outputs for p4i if desired.
# TODO: this should not be part of build. P4i pipeline, which consumes the reference outputs,
#       should call this script inside a final docker image manually.
cd "/bfn/bf-p4c-compilers/scripts/gen_reference_outputs"
if [[ "${GEN_REF_OUTPUTS}" = "true" ]] ; then
  python3 -u gen_ref_outputs.py
fi

