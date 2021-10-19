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
  "glass"                  # builds a glass image
  "jarvis"                 # builds a jarvis image
  "jenkins-intermediate"   # builds an intermediate image for CI
  "jenkins-final"          # finishes building an image for CI
  "release"                # builds a release image
  "tofino"                 # builds an image for CI (use jenkins-* if you want to use ccache)
)

# List of supported image types, selected by IMAGE_TYPE.
IMAGE_TYPES=(
  "non-unified"
  "release"
  "test"
)

# List of environment variables expected to contain either "true" or "false".
BOOLEAN_VARS=(
  "BUILD_GLASS"                # whether to build the glass compiler
  "GEN_REF_OUTPUTS"            # whether to generate reference outputs for p4i
  "TOFINO_P414_TEST_ARCH_TNA"  # whether to test P4-14 programs for Tofino with
                               #   TNA architecture
)

# === PACKAGE LISTS ===========================================================

# Dependencies for the p4c compiler.
export P4C_DEPS="autoconf \
                 automake \
                 bison \
                 build-essential \
                 ccache \
                 curl \
                 distcc \
                 flex \
                 g++-6 \
                 graphviz \
                 libboost1.67-dev \
                 libfl-dev \
                 libatomic-ops-dev
                 libgmp-dev \
                 libssl-dev \
                 libtool \
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
                     ply \
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
                 tmux \
                 apache2"

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

# Clear out CC and CXX.
#   * These apparently cause pip to build its packages incorrectly: some
#     packages (e.g., pysubnettree) use CC where they should use CXX.
#
#   * CC and CXX are set by Dockerbuild to enable distcc. We wish to build the
#     compiler locally anyway.
unset CC CXX

# Install dependencies and configure the build environment.
if [[ "${BUILD_FOR}" != 'jenkins-final' ]] ; then
  # Clean up default instance of libboost1.58 from base Ubuntu image.
  apt-get --purge remove -y 'libboost*' || true

  # Configure apt repositories and update apt.
  add-apt-repository -y ppa:ubuntu-toolchain-r/test
  add-apt-repository -y ppa:mhier/libboost-latest
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
    ./autogen.sh
    ./configure --enable-large-config --enable-cplusplus --enable-shared
    make -$MAKEFLAGS
    make install -$MAKEFLAGS
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
    curl -L --noproxy "*" -o "${Z3_ZIP}" \
      https://artifacts-bxdsw.sc.intel.com/repository/generic/third-party/"${Z3_ZIP}"
    unzip "${Z3_ZIP}"

    cd "${Z3}"
    cp bin/libz3.a /usr/local/lib/
    cp bin/libz3.so /usr/local/lib/
    cp bin/z3 /usr/local/bin/
    cp include/*.h /usr/local/include/

    cd /tmp
    rm -rf "${Z3}" "${Z3_ZIP}"
  }

  # Dependencies for testing.
  apt-get install -y net-tools

  # Upgrade to pip==20.3.4 - newer versions don't support python3.5
  pip3 install --upgrade pip==20.3.4
  # Install python3 packages
  pip3 install ${PYTHON3_DEPS}

  # Copy scripts into ${BFN}.
  {
    cd "${BF_P4C_COMPILERS}"
    cp scripts/ptf_hugepage_setup.sh \
       scripts/ptf_env_setup.sh \
       p4-tests/p4testutils/veth_setup.sh \
       docker/docker_entry_point.sh \
       "${BFN}"
    cd -
  }

  # Configure distcc to just use localhost for building the Docker image.
  echo localhost > /etc/distcc/hosts

  if [[ "${BUILD_FOR}" == "jenkins-intermediate" ]] ; then
    WORKDIR "${BF_P4C_COMPILERS}"

    # Set up ccache.
    install -D -o root -g root -m 0644 \
      docker/jenkins-ccache.conf /etc/ccache.conf
    install -D -o root -g root -m 0644 \
      docker/jenkins-ccache.conf /usr/local/etc/ccache.conf
  fi
fi  # Done installing dependencies and configuring build environment.

# Configure the linker to strip symbols.
export LDFLAGS="-Wl,-s"

# Finish here if we're just building the intermediate image for Jenkins. The
# "jenkins-final" build type will pick up from here.
if [[ "${BUILD_FOR}" == "jenkins-intermediate" ]] ; then
  exit 0
fi

# Build and install bf-p4c-compilers.
WORKDIR "${BF_P4C_COMPILERS}"
if [[ "${BUILD_FOR}" == "jenkins-final" || "${BUILD_FOR}" == "tofino" ]] ; then
  if [[ "${IMAGE_TYPE}" == "non-unified" ]] ; then
    disable_unified="--disable-unified"
  else
    disable_unified=
  fi
  if [[ "${TOFINO_P414_TEST_ARCH_TNA}" == "true" ]] ; then
    DTOFINO_P414_TEST_ARCH="-DTOFINO_P414_TEST_ARCH=tna"
  else
    DTOFINO_P414_TEST_ARCH=
  fi

  ./bootstrap_bfn_compilers.sh \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_STF2PTF=OFF \
    -DINSTALL_LIBDYNHASH=OFF \
    ${DTOFINO_P414_TEST_ARCH} \
    ${disable_unified}

  cd build
  make
  make install
elif [[ "${BUILD_FOR}" == "release" ]] ; then
  ccache --zero-stats
  ./scripts/package_p4c_for_tofino.sh --build-dir build
elif [[ "${BUILD_FOR}" == "glass" ]] ; then
  ccache --zero-stats
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
jenkins-final|tofino|release|glass)
  ccache -p --show-stats
  apt-get autoremove --purge -y
  rm -rf ~/.cache/* /var/cache/apt/* /var/lib/apt/lists/*
  rm -rf bf-asm/walle/build/*
  find . -name '*.o' -type f -delete
  find . -name '*.a' -type f -delete
  ;;
esac
case "${BUILD_FOR}" in
tofino|release|glass)
  rm -rf ~/.ccache/*
  ;;
esac

# Build and install glass if desired.
WORKDIR "${BF_P4C_COMPILERS}/glass/p4-hlir"
if [[ "${BUILD_GLASS}" == "true" ]] ; then
  apt-get update
  apt-get install -y python-dev python-pip \
                     python-ipaddr python-scapy python-setuptools python-yaml
  apt-get autoremove --purge -y
  rm -rf ~/.ccache/* ~/.cache/* /var/cache/apt/* /var/lib/apt/lists/*

  pip2 install --upgrade pip==20.3.4
  pip install jsl pexpect crc16 crcmod simplejson tenjin ipaddress packaging \
              prettytable pysubnettree ctypesgen ply==3.9 jsonschema==2.6

  pip install -r requirements.txt
  python setup.py install

  WORKDIR "${BF_P4C_COMPILERS}/glass"
  python setup.py install
fi

# Generate reference outputs for p4i if desired.
WORKDIR "${BF_P4C_COMPILERS}/scripts/gen_reference_outputs"
if [[ "${GEN_REF_OUTPUTS}" = "true" ]] ; then
  python3 -u gen_ref_outputs.py
fi

if [[ "${BUILD_FOR}" == "jarvis" ]] ; then
  WORKDIR "${BF_P4C_COMPILERS}"

  # Set up ccache.
  install -D -o root -g root -m 0644 docker/ccache.conf /etc/ccache.conf
  install -D -o root -g root -m 0644 \
    docker/ccache.conf /usr/local/etc/ccache.conf

  # Configure distcc hosts.
  install -D -o root -g root -m 0644 docker/distcc_hosts.conf /etc/distcc/hosts

  # Create and adjust Apache configuration files at first startup.
  /etc/init.d/apache2 start
  sed -i $'/Global configuration$/{n;n;a ServerName localhost\\n\n}' /etc/apache2/apache2.conf
  install -o root -g root -m 0644 docker/favicon.ico /var/www/html/favicon.ico
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
