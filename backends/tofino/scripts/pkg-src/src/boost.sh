#! /bin/bash

function check_boost_version() {
    # ARG: desired boost version
    # Return: the existing version or none if not found
  local b_ver=$1
  local boost_ver=$(echo $b_ver | tr "." "_")
  installed_ver="none"

  if [ -f /usr/local/include/boost/version.hpp ]; then
    installed_ver=$(grep -m 1 "define BOOST_LIB_VERSION" /usr/local/include/boost/version.hpp | cut -d ' ' -f 3 | tr -d '"')
  fi
  echo $installed_ver
}

function build_boost_from_source() {
    # ARG: desired boost version
  local boost_ver=$1

  wget http://downloads.sourceforge.net/project/boost/boost/${b_ver}/boost_${boost_ver}.tar.bz2 && \
    tar xvjf ./boost_${boost_ver}.tar.bz2 && \
    cd boost_${boost_ver} && \
    ./bootstrap.sh --prefix=/usr/local && \
    ./b2 --build-type=minimal link=shared runtime-link=shared variant=release && \
    $SUDO ./b2 install --build-type=minimal variant=release link=shared runtime-link=shared || \
        die "failed to install boost"
}
