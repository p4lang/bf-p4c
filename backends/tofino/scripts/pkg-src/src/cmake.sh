#! /bin/bash

function check_cmake_version() {
    # ARG: desired cmake version
    # Return: the existing version or none if not found
  local cmake_ver=$1
  installed_ver="none"

  cmake --version > /dev/null 2>&1
  if [ $? == 0 ]; then
    installed_ver=$(cmake --version | cut -f 3 -d " ")
  fi

  echo $installed_ver
}

function build_cmake_from_source() {
    # ARG: desired cmake version
  local cmake_ver=$1
  local cmake_dir=$(echo ${cmake_ver} | cut -f 1-2 -d ".")
  wget http://www.cmake.org/files/v${cmake_dir}/cmake-${cmake_ver}.tar.gz && \
    tar zxvf cmake-${cmake_ver}.tar.gz && \
    cd cmake-${cmake_ver} && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=release && \
    make -j $nprocs || die "Failed to build cmake ${cmake_ver}"
}
