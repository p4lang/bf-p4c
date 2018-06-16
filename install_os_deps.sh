#! /bin/bash

die () {
    if [ $# -gt 0 ]; then
        echo >&2 "$@"
    fi
    exit 1
}

function version_LT() {
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1";
}

SUDO=sudo
LDCONFIG=ldconfig
LDLIB_EXT=so

install_python_packages() {
    # do not upgrade pip until Ubuntu sorts out their issues
    # If you have already upgraded, do: sudo apt-get remove python-pip python-pip-whl
    # $SUDO pip install --upgrade pip
    $SUDO pip install setuptools || die "Failed to install needed packages"
    $SUDO pip install ply || die "Failed to install needed packages"
    $SUDO pip install jsl jsonschema || die "Failed to install needed packages"
    $SUDO pip install thrift || die "Failed to install needed packages"  # need this one instead
    $SUDO pip install pexpect || die "Failed to install needed packages"
}

install_linux_packages() {
    local ubuntu_release=$(lsb_release -r | cut -f 2)
    local nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)

    # please keep this list in alphabetical order
    apt_packages="automake autopoint bison curl doxygen ethtool flex g++ git \
                 libcli-dev libedit-dev libeditline-dev libevent-dev \
                 libgc-dev libgmp-dev libjson0 libjson0-dev libjudy-dev \
                 libmoose-perl libnl-route-3-dev libpcap0.8-dev libssl-dev \
                 libtool pkg-config \
                 python2.7 python python-ipaddr python-pip \
                 python-scapy python-yaml \
                 realpath rpm texinfo unzip"

    echo "Need sudo privs to install apt packages"
    $SUDO apt-get update || die "Failed to update apt"
    $SUDO apt-get install -y $apt_packages || \
        die "Failed to install needed packages"
    if [[ $ubuntu_release =~ "14.04" ]]; then
        $SUDO add-apt-repository ppa:ubuntu-toolchain-r/test
        $SUDO apt-get install -y g++-4.9
        $SUDO update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 10
        $SUDO update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 20
        $SUDO update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 10
        $SUDO update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 20
    fi

    $SUDO apt-get remove -y python-thrift    # remove this broken package in case it was installed
    install_python_packages

    install_cmake "3.5.2"
    install_boost "1.58.0"
    if ! `pkg-config RapidJSON` || version_LT `pkg-config --modversion RapidJSON` "1.1.0"; then
        install_rapidjson "1.1.0"
    fi
}

function install_cmake() {
    # ARG: cmake version
    cmake_ver=$1
    cmake_dir=$(echo ${cmake_ver} | cut -f 1-2 -d ".")
    rc=($SUDO apt-get install -y cmake=${cmake_ver})
    if [ $? != 0 ]; then
        local nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)
        cd /tmp
        wget http://www.cmake.org/files/v${cmake_dir}/cmake-${cmake_ver}.tar.gz && \
            tar zxvf cmake-${cmake_ver}.tar.gz && \
            cd cmake-${cmake_ver} && \
            mkdir build && \
            cd build && \
            cmake .. -DCMAKE_BUILD_TYPE=release && \
            make -j $nprocs && \
            cpack -G DEB && \
            $SUDO apt-get remove -y cmake cmake-data && \
            $SUDO dpkg -i cmake-${cmake_ver}-Linux-x86_64.deb || \
                die "failed to install cmake"
        cd /tmp && rm -rf /tmp/cmake-${cmake_ver}
    fi
}

function install_boost() {
    # ARG: boost_version
    # test for ubuntu version, and check if we have a local package
    local ubuntu_release=$(cat /etc/issue | awk '/Ubuntu/ {print $2 }' | cut -d "." -f 1-2)
    local debian_release=$(egrep -ic debian /etc/issue)
    if [[ $ubuntu_release =~ "14.04" ]] || [[ $debian_release =~ 1 ]]; then
        sudo apt-get install -y python-dev libbz2-dev
        b_ver=$1
        boost_ver=$(echo $b_ver | tr "." "_")
        cd /tmp
        wget http://downloads.sourceforge.net/project/boost/boost/${b_ver}/boost_${boost_ver}.tar.bz2 && \
            tar xvjf ./boost_${boost_ver}.tar.bz2 && \
            cd boost_${boost_ver} && \
            ./bootstrap.sh --prefix=/usr/local && \
            ./b2 --build-type=minimal link=shared runtime-link=shared variant=release && \
            $SUDO ./b2 install --build-type=minimal variant=release \
                  link=shared runtime-link=shared || \
                die "failed to install boost"
        cd /tmp && rm -rf boost_${boost_ver}
    else
        boost_libs="libboost-dev libboost-graph-dev libboost-test-dev libboost-program-options-dev libboost-system-dev libboost-filesystem-dev libboost-iostreams-dev libboost-thread-dev"
        $SUDO apt-get install -y ${boost_libs}
    fi

}

function install_rapidjson() {
    # ARG: rapidjson version
    local rj_ver=$1
    # test for ubuntu version, and check if we have a local package
    local ubuntu_release=$(lsb_release -r | cut -f 2)
    # rapidjson is not available on Ubuntu 14.04 and too old on Ubuntu 16.04,
    # so we build from source
    if [[ $ubuntu_release =~ "16.04" ]]; then
        $SUDO apt-get remove -y rapidjson-dev
    fi
    if [[ $ubuntu_release =~ "14.04" || $ubuntu_release =~ "16.04" ]]; then
        build_rapidjson_from_source ${rj_ver} && \
        $SUDO apt-get remove -y rapidjson-dev && \
        $SUDO dpkg -i /tmp/RapidJSON-dev-${rj_ver}-Linux.deb || \
            die "failed to install rapidjson"
    else
        $SUDO apt-get install -y rapidjson-dev || \
            die "Failed to update rapidjson-dev"
    fi
}

function build_rapidjson_from_source() {
    # ARG: rapidjson version
    local rj_ver=$1
    local nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)
    local builddir=$(mktemp --directory -t rjson_XXXXXX)
    cd $builddir
    # add packaging info
    cat > rj.patch <<EOF
diff --git a/CMakeLists.txt b/CMakeLists.txt
index ceda71b1..21acee18 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -171,3 +171,18 @@ INSTALL(FILES
     \${CMAKE_CURRENT_BINARY_DIR}/\${PROJECT_NAME}ConfigVersion.cmake
     DESTINATION "\${CMAKE_INSTALL_DIR}"
     COMPONENT dev)
+
+# create a debian package
+set (CPACK_GENERATOR "DEB")
+set (CPACK_PACKAGE_NAME "\${PROJECT_NAME}-dev")
+set (CPACK_PACKAGE_VERSION_MAJOR \${LIB_MAJOR_VERSION})
+set (CPACK_PACKAGE_VERSION_MINOR \${LIB_MINOR_VERSION})
+set (CPACK_PACKAGE_VERSION_PATCH \${LIB_PATHC_VERSION})
+set (CPACK_PACKAGE_VERSION "\${LIB_VERSION_STRING}")
+set (CPACK_PACKAGE_CONTACT "THL A29 Limited")
+set (CPACK_PACKAGE_VENDOR "THL A29 Limited")
+set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "RapidJSON")
+set (CPACK_PACKAGE_DESCRIPTION "RapidJSON")
+set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
+include (CPack)
+
EOF
    git clone --recursive https://github.com/miloyip/rapidjson.git \
        --branch "v${rj_ver}" && \
        cd rapidjson && \
        git apply ../rj.patch && \
        mkdir build && cd build && \
        cmake .. -DRAPIDJSON_BUILD_DOC=OFF \
              -DRAPIDJSON_BUILD_EXAMPLES=OFF \
              -DRAPIDJSON_BUILD_TESTS=OFF && \
        make -j $nprocs && \
        cpack -G DEB && \
        cp RapidJSON-dev-${rj_ver}-Linux.deb /tmp && \
        cd /tmp && \
        rm -rf $builddir || die "Failed to build rapidjson"
}

install_macos_packages() {
    SUDO=
    LDCONFIG=:
    LDLIB_EXT=dylib
    # check for brew and install if not available
    if [ -z $(which brew) ]; then
	xcode-select --install
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    brew_packages="autoconf automake bison bdw-gc boost ccache cmake coreutils doxygen dpkg flex gcc5 git gmp graphviz libtool openssl pkg-config python rapidjson"
    # libedit-dev libeditline-dev libevent-dev libjudy-dev libjson0 libjson0-dev libmoose-perl libnl-route-3-dev libpcap0.8-dev
    brew install $brew_packages || die "Failed to install brew packages"
    # force to use the newer installed bison
    brew link --force bison
    # brew installs python and pip with suffix 2
    ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
    ln -sf /usr/local/bin/pip2 /usr/local/bin/pip
    install_python_packages
    pip install scapy pyyaml ipaddr
}

function install_protobuf() {
    tmpdir=$(mktemp -d)
    echo "Using $tmpdir for temporary build files"

    echo "Checking for and installing protobuf"
    if ! `pkg-config protobuf` || version_LT `pkg-config --modversion protobuf` "3.0.0"; then
        pushd $tmpdir
        git clone https://github.com/google/protobuf
        cd protobuf
        git checkout tags/v3.2.0
        git submodule update --init --recursive
        ./autogen.sh && \
        ./configure && \
        make && \
        $SUDO make install && \
        $SUDO $LDCONFIG || \
            die "Failed to install protobuf"
        cd ../
        /bin/rm -rf protobuf
        PI_clean_before_rebuild=true
        popd # tmpdir
    fi

    echo "Checking for and installing grpc"
    if ! `pkg-config grpc++` || version_LT `pkg-config --modversion grpc++` "1.3.0"; then
        pushd $tmpdir
        git clone https://github.com/google/grpc.git
        cd grpc
        git checkout tags/v1.3.2
        git submodule update --init --recursive
        make && \
        $SUDO make install && \
        $SUDO $LDCONFIG || \
                die "Failed to install grpc"
        cd ../
        /bin/rm -rf grpc
        PI_clean_before_rebuild=true
        popd # tmpdir
    fi
    $SUDO pip install protobuf grpcio || die "Failed to install python grpc packages"

    echo "Removing $tmpdir"
    rm -rf $tmpdir
}


# the main routine
if [ $(uname -s) == 'Darwin' ]; then
    install_macos_packages
else
    install_linux_packages
fi
install_protobuf
