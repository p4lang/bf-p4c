#! /bin/bash

function check_rapidjson_version() {
    # ARG: desired rapidjson version
    # Return: the existing version or none if not found
  local rapidjson_ver=$1
  installed_ver="none"
  if `pkg-config RapidJSON` ; then
    installed_ver=`pkg-config --modversion RapidJSON`
  fi

  echo $installed_ver
}

function build_rapidjson_from_source() {
  # ARG: rapidjson version
  local rj_ver=$1
  local rj_patch=$2
  # add packaging info
  git clone https://github.com/miloyip/rapidjson.git \
    --branch "v${rj_ver}" && \
    cd rapidjson && \
    git apply $rj_patch && \
    mkdir build && cd build && \
    cmake .. -DRAPIDJSON_BUILD_DOC=OFF \
          -DRAPIDJSON_BUILD_EXAMPLES=OFF \
          -DRAPIDJSON_BUILD_TESTS=OFF && \
    make -j $nprocs  || die "Failed to build rapidjson"
}

function install_rapidjson() {
  $SUDO make install  || die "Failed to install rapidjson"
  if [[ $linux_distro == "Ubuntu" || $linux_distro == "Debian" ]]; then
      cpack -G DEB && dpkg -i RapidJSON-dev-${rj_ver}-Linux.deb
  fi
  #if [[ $linux_distro == "Fedora" ]]; then
  #    cpack -G RPM && yum install RapidJSON-dev-${rj_ver}-Linux.rpm
  #fi
}
