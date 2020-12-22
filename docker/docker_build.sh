#!/bin/bash

# This builds the bf-p4c-compilers Docker image and expected to be executed
# from the Dockerfile with RUN. The behaviour of this script is determined
# primarily by the BUILD_FOR and IMAGE_TYPE environment variables, as well as a
# couple of other boolean environment variables, described below.
#
# This script expects a copy of the bf-p4c-compilers repository to reside in
# ${BF_P4C_COMPILERS}, configured below.
#
# NB: When executed from the Dockerfile with RUN, all ENV and ARG variables
#     will be visible to this script.

# Exit if we encounter any errors.
set -e

# === CONFIGURATION ===========================================================

BFN=/bfn
BF_P4C_COMPILERS="${BFN}/bf-p4c-compilers"

# List of supported build modes, selected by BUILD_FOR.
BUILD_MODES=(
  "glass"    # builds a glass image
  "jarvis"   # builds a jarvis image
  "release"  # builds a release image
  "tofino"   # builds an image for CI
)

# List of supported image types, selected by IMAGE_TYPE.
IMAGE_TYPES=(
  "non-unified"
  "release"
  "test"
)

# List of environment variables expected to contain either "true" or "false".
BOOLEAN_VARS=(
  "BUILD_GLASS"      # whether to build the glass compiler
  "GEN_REF_OUTPUTS"  # whether to generate reference outputs for p4i
)

# === PACKAGE LISTS ===========================================================

# Dependencies for the p4c compiler.
export P4C_DEPS="autoconf \
                 automake \
                 bison \
                 build-essential \
                 curl \
                 distcc \
                 flex \
                 g++-6 \
                 libboost1.67-dev \
                 libfl-dev \
                 libatomic-ops-dev
                 libgmp-dev \
                 libssl-dev \
                 libtool \
                 python-dev \
                 python-pip \
                 python3-pip \
                 unzip"

# P4 runtime dependencies.
export P4C_RUNTIME_DEPS="cpp \
                         cmake \
                         ethtool \
                         libgmp10 \
                         libgmpxx4ldbl \
                         libnl-genl-3-dev \
                         libnl-route-3-dev \
                         libssl1.0.0 \
                         pkg-config \
                         psmisc \
                         python-ipaddr \
                         python-scapy \
                         python-setuptools \
                         python-yaml \
                         sudo \
                         tcpdump \
                         libgoogle-perftools-dev \
                         libxml-simple-perl \
                         doxygen \
                         aspell"

# Required python3 packages.
export PYTHON3_DEPS="Cython \
                     distro \
                     ipaddr \
                     jsl \
                     jsonschema \
                     packaging \
                     pexpect \
                     ply==3.9 \
                     prettytable \
                     pyinstaller \
                     pyroute2 \
                     pyyaml \
                     scapy \
                     texttable \
                     xlsxwriter \
                     pysubnettree \
                     ctypesgen"

# Packages for jarvis image.
export DEV_PKGS="vim \
                 gdb \
                 telnet \
                 ninja \
                 tmux"

# Packages for release image
export REL_PKGS="wget"

# === HELPER FUNCTIONS =======================================================

function contains() {
  local n=$#
  local query="${!n}"
  for (( i=1; i<$#; i++ )) ; do
    [[ "${!i}" == "${query}" ]] && return 0
  done

  return 1
}

function WORKDIR() {
  mkdir -p "$1"
  cd "$1"
}

# === MAIN BODY ===============================================================

# Sanitize input.
{
  echo "Building ${IMAGE_TYPE} image for ${BUILD_FOR}"

  # Check ${BUILD_FOR}.
  if ! contains "${BUILD_MODES[@]}" "${BUILD_FOR}" ; then
    echo "Unrecognized build: ${BUILD_FOR}" >&2
    exit 1
  fi

  # Check ${IMAGE_TYPE}.
  if ! contains "${IMAGE_TYPES[@]}" "${IMAGE_TYPE}" ; then
    echo "Unrecognized image type: ${IMAGE_TYPE}" >&2
    exit 1
  fi

  # Check boolean variables.
  for x in "${BOOLEAN_VARS[@]}" ; do
    if ! contains "true" "false" "${!x}" ; then
      echo "Variable ${x} must be either \"true\" or \"false\"" >&2
      exit 1
    fi
  done
}

# Set apt to be non-interactive.
export DEBIAN_FRONTEND=noninteractive

# Clean up default instance of libboost1.58 from base Ubuntu image.
apt-get --purge remove -y 'libboost*-dev'

# Configure apt repositories and update apt.
add-apt-repository ppa:ubuntu-toolchain-r/test
add-apt-repository ppa:mhier/libboost-latest
apt-get update

# Install packages.
apt-get install -y ${P4C_DEPS} ${P4C_RUNTIME_DEPS}
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 10
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 20
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 10
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-6 20

# Install more packages.
case "${BUILD_FOR}" in
jarvis)
  apt-get install -y ${DEV_PKGS}
  ;;
release)
  apt-get install -y ${REL_PKGS}
  ;;
esac

# Download, configure, build GC with large config
WORKDIR /tmp
{
  curl -o gc-7.4.2.tar.gz https://hboehm.info/gc/gc_source/gc-7.4.2.tar.gz
  tar -xvf gc-7.4.2.tar.gz
  cd gc-7.4.2
  ./autogen.sh && ./configure --enable-large-config --enable-cplusplus --enable-shared
  make -$MAKEFLAGS && make install -$MAKEFLAGS
  ldconfig
}

# Download, configure, build, and install Boost if needed.
WORKDIR /tmp
if [[ "${BUILD_FOR}" == "release" ]] ; then
  BOOST='boost_1_67_0'
  BOOST_TARBALL="${BOOST}.tar.bz2"
  wget http://downloads.sourceforge.net/project/boost/boost/1.67.0/"${BOOST_TARBALL}"
  tar xjf "${BOOST_TARBALL}"

  cd "${BOOST}"
  ./bootstrap.sh --prefix=/usr/local
  ./b2 -$MAKEFLAGS --build-type=minimal variant=release
  ./b2 install -$MAKEFLAGS --build-type=minimal variant=release

  cd /tmp
  rm -rf "${BOOST}" "${BOOST_TARBALL}"
fi

# Download and install Z3.
WORKDIR /tmp
{
  Z3='z3-4.8.7-x64-ubuntu-16.04'
  Z3_ZIP="${Z3}.zip"
  curl -L --noproxy "*" \
    https://artifacts-bxdsw.sc.intel.com/repository/generic/third-party/"${Z3_ZIP}" -o "${Z3_ZIP}"
  unzip "${Z3_ZIP}"

  cd "${Z3}"
  cp bin/libz3.a /usr/local/lib/
  cp bin/libz3.so /usr/local/lib/
  cp bin/z3 /usr/local/bin/
  cp include/*.h /usr/local/include/

  cd /tmp
  rm -rf "${Z3}" "${Z3_ZIP}"
}

# Clear out CC and CXX.
#   * These apparently cause pip to build its packages incorrectly: some
#     packages (e.g., pysubnettree) use CC where they should use CXX.
#
#   * CC and CXX are set by Dockerbuild to enable distcc. We wish to build the
#     compiler locally anyway.
unset CC CXX

# Dependencies for testing.
apt-get install -y net-tools
pip install --upgrade pip
pip install jsl pexpect crc16 crcmod simplejson tenjin ipaddress packaging prettytable pysubnettree ctypesgen

# Install ply 3.9 for compatibility with p4c-tofino
pip install ply==3.9

# Install jsonschema 2.6 for compatibility with pyinstaller
pip install jsonschema==2.6

# Install python3 packages
pip3 install --upgrade pip
pip3 install ${PYTHON3_DEPS}

# Configure the linker to strip symbols.
export LDFLAGS="-Wl,-s"

# Copy scripts into ${BFN}.
{
  cd "${BF_P4C_COMPILERS}"
  cp scripts/ptf_hugepage_setup.sh \
     docker/docker_entry_point.sh \
     p4-tests/p4testutils/veth_setup.sh \
     "${BFN}"
  cd -
}

# Configure distcc to just use localhost for building the Docker image.
echo localhost > /etc/distcc/hosts

# Build and install bf-p4c-compilers.
WORKDIR "${BF_P4C_COMPILERS}"
if [[ "${BUILD_FOR}" == "tofino" ]] ; then
  if [[ "${IMAGE_TYPE}" == "non-unified" ]] ; then
    disable_unified="--disable-unified"
  else
    disable_unified=
  fi

  /usr/local/bin/ccache --zero-stats
  ./bootstrap_bfn_compilers.sh \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_STF2PTF=OFF \
    -DINSTALL_LIBDYNHASH=OFF \
    ${disable_unified}

  cd build
  make
  make install
elif [[ "${BUILD_FOR}" == "release" ]] ; then
  /usr/local/bin/ccache --zero-stats
  ./scripts/package_p4c_for_tofino.sh --build-dir build
elif [[ "${BUILD_FOR}" == "glass" ]] ; then
  /usr/local/bin/ccache --zero-stats
  ./bootstrap_bfn_compilers.sh \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DINSTALL_LIBDYNHASH=OFF \
    -DENABLE_STF2PTF=OFF \
    -DENABLE_STATIC_LIBS=ON \
    -DENABLE_BAREFOOT_INTERNAL=OFF \
    -DENABLE_GTESTS=OFF
fi

# Clean up.
WORKDIR "${BF_P4C_COMPILERS}"
case "${BUILD_FOR}" in
tofino|release|glass)
  /usr/local/bin/ccache -p --show-stats
  apt-get autoremove --purge -y
  rm -rf ~/.cache/* ~/.ccache/* /var/cache/apt/* /var/lib/apt/lists/*
  rm -rf bf-asm/walle/build/*
  find . -name '*.o' -type f -delete
  find . -name '*.a' -type f -delete
  ;;
esac

# Build and install glass if desired.
WORKDIR "${BF_P4C_COMPILERS}/glass/p4-hlir"
if [[ "${BUILD_GLASS}" == "true" ]] ; then
  pip install -r requirements.txt
  python setup.py install

  WORKDIR "${BF_P4C_COMPILERS}/glass"
  python setup.py install
fi

# Generate reference outputs for p4i if desired.
WORKDIR "${BF_P4C_COMPILERS}/scripts/gen_reference_outputs"
if [[ "${GEN_REF_OUTPUTS}" = "true" ]] ; then
  python -u gen_ref_outputs.py || true  # Allow this to fail.
fi

if [[ "${BUILD_FOR}" == "jarvis" ]] ; then
  WORKDIR "${BF_P4C_COMPILERS}"

  # Set up ccache.
  install -D -o root -g root -m 0644 docker/ccache.conf /etc/ccache.conf
  install -D -o root -g root -m 0644 \
    docker/ccache.conf /usr/local/etc/ccache.conf

  # Configure distcc hosts.
  install -D -o root -g root -m 0644 docker/distcc_hosts.conf /etc/distcc/hosts
fi

# Clean up git history.
WORKDIR "${BF_P4C_COMPILERS}"
rm -rf .git

# Remove bf-p4c-compilers if desired.
WORKDIR "${BFN}"
if [[ "${BUILD_FOR}" == "jarvis" || "${IMAGE_TYPE}" == "release" ]] ; then
  rm -rf "${BF_P4C_COMPILERS}"
fi

# Free up space on the image.
apt-get autoremove -y
apt-get clean -y
apt-get autoclean -y

