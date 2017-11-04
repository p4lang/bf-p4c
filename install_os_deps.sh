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
    $SUDO pip install --upgrade pip
    $SUDO pip install setuptools || die "Failed to install needed packages"
    $SUDO pip install ply || die "Failed to install needed packages"
    $SUDO pip install pyinstaller==3.2.1 || die "Failed to install needed packages"
    $SUDO pip install thrift || die "Failed to install needed packages"  # need this one instead
}

install_linux_packages() {
    ubuntu_release=$(lsb_release -r | cut -f 2)
    nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)
    gcc_ver=""
    if [[ $ubuntu_release =~ "14.04" ]]; then
        sudo add-apt-repository ppa:ubuntu-toolchain-r/test
        gcc_ver="-4.9"
        # need a way to install boost libraries
        boost_libs=""
    else
        boost_libs="libboost-dev libboost-graph-dev libboost-test-dev libboost-program-options-dev libboost-system-dev libboost-filesystem-dev libboost-iostreams-dev libboost-thread-dev"
    fi

    apt_packages="g++${gcc_ver} git pkg-config automake cmake curl python2.7 python bison flex ${boost_libs} libtool libcli-dev libedit-dev libeditline-dev libevent-dev libjudy-dev libgc-dev libgmp-dev libjson0 libjson0-dev libmoose-perl libnl-route-3-dev libpcap0.8-dev libssl-dev autopoint doxygen texinfo python-scapy python-yaml python-ipaddr python-pip rpm realpath unzip"

    echo "Need sudo privs to install apt packages"
    $SUDO apt-get update || die "Failed to update apt"
    $SUDO apt-get install -y $apt_packages || die "Failed to install needed packages"
    if [[ $ubuntu_release =~ "14.04" ]]; then
        $SUDO update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 10
        $SUDO update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 20
        $SUDO update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 10
        $SUDO update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 20

    fi

    $SUDO apt-get remove -y python-thrift    # remove this broken package in case it was installed
    install_python_packages

    if [[ $ubuntu_release =~ "14.04" ]]; then
        # install cmake 3.5.2
        cmake_ver=3.5.2
        cd /tmp
        wget http://www.cmake.org/files/v3.5/cmake-${cmake_ver}.tar.gz && \
        tar zxvf cmake-${cmake_ver}.tar.gz && \
        cd cmake-${cmake_ver} && \
        mkdir build && \
        cd build && \
        cmake .. -DCMAKE_BUILD_TYPE=release && \
        make -j $nprocs
        cpack -G DEB && \
        $SUDO apt-get remove -y cmake cmake-data && \
        $SUDO dpkg -i cmake-${cmake_ver}-Linux-x86_64.deb || \
        die "failed to install cmake"
        cd /tmp && rm -rf /tmp/cmake-${cmake_ver}

        # boost libs
        sudo apt-get install -y python-dev libbz2-dev
        boost_ver=1_58_0
        cd /tmp
        wget http://downloads.sourceforge.net/project/boost/boost/1.58.0/boost_${boost_ver}.tar.bz2 && \
        tar xvjf ./boost_${boost_ver}.tar.bz2 && \
        cd boost_${boost_ver} && \
        ./bootstrap.sh --prefix=/usr/local && \
        ./b2 --build-type=minimal link=shared runtime-link=shared variant=release && \
        sudo ./b2 install --build-type=minimal link=shared runtime-link=shared variant=release || \
        die "failed to install boost"
        cd /tmp && rm -rf boost_${boost_ver}
    fi

    # rapidjson is not available on Ubuntu 14.04 and too old on Ubuntu 16.04,
    # so we build from source
    if [[ $ubuntu_release =~ "16.04" ]]; then
        $SUDO apt-get remove -y rapidjson-dev
    fi
    builddir=$(mktemp --directory -t rjson_XXXXXX)
    cd $builddir && \
        git clone --recursive https://github.com/miloyip/rapidjson.git --branch "v1.1.0" && \
        cd rapidjson && \
        mkdir build && cd build && \
        cmake .. && \
        make -j $nprocs && \
        $SUDO make install && \
        cd /tmp && \
        rm -rf $builddir || die "Failed to install rapidjson"
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
