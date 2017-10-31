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

    apt_packages="g++ git pkg-config automake libtool cmake curl python2.7 python cmake bison flex libboost-dev libboost-graph-dev libboost-test-dev libboost-program-options-dev libboost-system-dev libboost-filesystem-dev libboost-iostreams-dev libboost-thread-dev libcli-dev libedit-dev libeditline-dev libevent-dev libjudy-dev libgc-dev libgmp-dev libjson0 libjson0-dev libmoose-perl libnl-route-3-dev libpcap0.8-dev libssl-dev autopoint doxygen texinfo python-scapy python-yaml python-ipaddr python-pip unzip"

    echo "Need sudo privs to install apt packages"
    $SUDO apt-get update || die "Failed to update apt"
    $SUDO apt-get install -y $apt_packages || die "Failed to install needed packages"
    $SUDO apt-get remove -y python-thrift    # remove this broken package in case it was installed
    install_python_packages

    # rapidjson is not available on Ubuntu 14.04, so we build from source
    if [[ $ubuntu_release =~ "14.04" ]]; then
        builddir=$(mktemp --directory -t rjson_XXXXXX)
        cd $builddir && \
            git clone --recursive https://github.com/miloyip/rapidjson.git --branch "v1.1.0" && \
            cd rapidjson && \
            mkdir build && cd build && \
            cmake .. && \
            make install && \
            cd /tmp && \
            rm -rf $builddir || die "Failed to install rapidjson"
    else
        $SUDO apt-get install -y rapidjson-dev || die "Failed to update rapidjson-dev"
    fi
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
