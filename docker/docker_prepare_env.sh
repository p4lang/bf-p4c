#!/bin/bash

# This builds the bf-p4c-compilers Docker image and expected to be executed
# from the Dockerfile with RUN. The behaviour of this script is determined
# by a couple of other boolean environment variables, described below.
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

# List of environment variables expected to contain either "true" or "false".
BOOLEAN_VARS=(
  "BUILDING_IN_CI"
)

# === PACKAGE LISTS ===========================================================

# Dependencies for the p4c compiler.
export P4C_DEPS="autoconf \
                 automake \
                 bison \
                 build-essential \
                 ccache \
                 curl \
                 flex \
                 lld \
                 graphviz \
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
                         libssl1.1 \
                         pkg-config \
                         psmisc \
                         sudo \
                         tcpdump \
                         libgoogle-perftools-dev \
                         libxml-simple-perl \
                         doxygen \
                         aspell \
                         wget"

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

# === HELPER FUNCTIONS =======================================================

function contains() {
  local n=$#
  local query="${!n}"
  for (( i=1; i<$#; i++ )) ; do
    [[ "${!i}" == "${query}" ]] && return 0
  done

  return 1
}

# === MAIN BODY ===============================================================

cd "${BF_P4C_COMPILERS}"

# Sanitize input.
for x in "${BOOLEAN_VARS[@]}" ; do
if ! contains "true" "false" "${!x}" ; then
  echo "Variable ${x} must be either \"true\" or \"false\"" >&2
  exit 1
fi
done

# Set apt to be non-interactive.
export DEBIAN_FRONTEND=noninteractive

# Install dependencies and configure the build environment.
apt-get update

# Install packages.
apt-get install -y ${P4C_DEPS} ${P4C_RUNTIME_DEPS}

pushd /tmp
{
    curl -o gc-7.6.4.tar.gz https://hboehm.info/gc/gc_source/gc-7.6.4.tar.gz
    tar -xvf gc-7.6.4.tar.gz
    cd gc-7.6.4
    ./autogen.sh
    ./configure --enable-large-config --enable-cplusplus --enable-shared
    make -$MAKEFLAGS
    make install -$MAKEFLAGS
    ldconfig
}
popd


# Dependencies for benchmarks
apt-get install -y time

# Dependencies for testing.
apt-get install -y net-tools

# Install python3 packages
pip3 install ${PYTHON3_DEPS}

# workaround for two mismatched python3 installations in p4factory
python3.8 -m pip install --force-reinstall pyinstaller jsonschema packaging jsl

# Copy scripts into ${BFN}.
cp scripts/ptf_hugepage_setup.sh \
    p4-tests/p4testutils/veth_setup.sh \
    docker/docker_entry_point.sh \
    "${BFN}"

if [[ "${BUILDING_IN_CI}" == "true" ]] ; then
  # Set up ccache.
  install -D -o root -g root -m 0644 \
    docker/jenkins-ccache.conf /etc/ccache.conf
  install -D -o root -g root -m 0644 \
    docker/jenkins-ccache.conf /usr/local/etc/ccache.conf
fi

# Free up space on the image.
apt-get autoremove -y
apt-get clean -y

