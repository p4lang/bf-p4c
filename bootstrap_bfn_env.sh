#!/bin/bash

confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case $response in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

die () {
    if [ $# -gt 0 ]; then
        echo >&2 "$@"
    fi
    exit 1
}

gitclone() {
    [ -e "$2" ] && die "$2 already exists!"
    [ ! -d "$(dirname $2)" ] && die "$(dirname $2) not a directory"
    git clone --recursive $1 $2 || { rm -rf $2; die "can't clone $1"; }
}

cd $(dirname $0)
curdir=$(basename $PWD)
topdir=$(dirname $PWD)

cd $topdir
found=""

for repo in behavioral-model model bf-syslibs bf-utils bf-drivers PI; do
    if [ -d $repo ]; then
        if [ -d $repo/.git ]; then
            found=$found$'\n'"$repo in $topdir/$repo"
        else
            echo >&2 "$topdir/$repo exists but is not a git repository"
            exit
        fi
    fi
done

reuse_asis=false
clean_before_rebuild=false
pull_before_rebuild=false
rebase_option=""

if [ -z "$found" ]; then
    echo >&2 "No exisiting repositories found"
else
    echo "Found:$found"
    if confirm "Rebuild these repositories before using them?"; then
        reuse_asis=false
    else
        reuse_asis=true
    fi
    if ! $reuse_asis && confirm "Pull latest changes from master?"; then
        pull_before_rebuild=true
        if confirm "Use --rebase option on pull?"; then
            rebase_option="--rebase"
        fi
    fi
    if ! $reuse_asis && confirm "Clean before rebuild?"; then
        clean_before_rebuild=true
    fi
fi

# Separate var: if protobuf / grpc are re-installed for some reason, the PI
# needs to be rebuilt from scratch
PI_clean_before_rebuild=$clean_before_rebuild

ubuntu_release=$(lsb_release -r | cut -f 2)

apt_packages="g++ git pkg-config automake libtool cmake python2.7 python cmake bison flex libboost-dev libboost-graph-dev libboost-test-dev libboost-program-options-dev libboost-system-dev libboost-filesystem-dev libboost-thread-dev libcli-dev libedit-dev libeditline-dev libevent-dev libjudy-dev libgc-dev libgmp-dev libjson0 libjson0-dev libmoose-perl libnl-route-3-dev libpcap0.8-dev libssl-dev autopoint doxygen texinfo python-scapy python-yaml python-ipaddr python-pip"

echo "Need sudo privs to install apt packages"
sudo apt-get update || die "Failed to update apt"
sudo apt-get install -y $apt_packages || die "Failed to install needed packages"
sudo pip install pyinstaller || die "Failed to install needed packages"
sudo apt-get remove -y python-thrift    # remove this broken package in case it was installed
sudo pip install thrift || die "Failed to install needed packages"  # need this one instead
sudo apt-get install -y libboost-iostreams-dev || die "Failed to update boost-iostream"

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
    sudo apt-get install -y rapidjson-dev || die "Failed to update rapidjson-dev"
fi

echo "Using $topdir as top level directory for git repositories"
echo Using MAKEFLAGS=${MAKEFLAGS:=-j 4}
export MAKEFLAGS

function version_LT() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }

tmpdir=$(mktemp --directory)
echo "Using $tmpdir for temporary build files"

echo "Checking for and installing protobuf"
if ! `pkg-config protobuf` || version_LT `pkg-config --modversion protobuf` "3.0.0"; then
    pushd $tmpdir
    sudo apt-get install -y curl unzip
    git clone https://github.com/google/protobuf
    cd protobuf
    git checkout tags/v3.2.0
    git submodule update --init --recursive
    ./autogen.sh && \
    ./configure && \
    make && \
    sudo make install && \
    sudo ldconfig || \
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
    sudo make install && \
    sudo ldconfig || \
    die "Failed to install grpc"
    cd ../
    /bin/rm -rf grpc
    PI_clean_before_rebuild=true
    popd # tmpdir
fi

sudo pip install protobuf grpcio || die "Failed to install python grpc packages"


### Behavioral Model setup
if [ ! -d behavioral-model/.git ]; then
    gitclone git@github.com:p4lang/behavioral-model.git behavioral-model
elif $pull_before_rebuild; then
    pushd behavioral-model >/dev/null
        git pull $rebase_option origin master
    popd >/dev/null
fi
pushd behavioral-model >/dev/null
    if $reuse_asis && [ -x "$(which simple_switch_CLI)" ]; then
        echo "Reusing installed $(which simple_switch_CLI) as is"
    else
        if $clean_before_rebuild || [ ! -r Makefile ]; then
            ./install_deps.sh
            ./autogen.sh
            ./configure
            if $clean_before_rebuild; then
                make clean
            fi
        fi
        make || die "BMV2 build failed"
        # p4c bmv2 tests end up using this simple_switch
        # it is a libtool wrapper script and is slow to execute the first time
        # to avoid a potential timeout in STF tests, we "warm up" here
        ./targets/simple_switch/simple_switch -h > /dev/null 2>&1
        sudo make install
    fi
popd >/dev/null

### Model dependencies that need manual build
## libcrafter
if [ ! -r /usr/local/include/crafter.h -o ! -x /usr/local/lib/libcrafter.so ]; then
    git clone https://github.com/pellegre/libcrafter
    cd libcrafter/libcrafter
    ./autogen.sh
    make -j4 || die "Failed to build libcrafter"
    sudo make install
    sudo ldconfig
    cd ../..
    rm -rf libcrafter
else
    echo "libcrafter already installed"
fi
## libcli
if [ ! -r /usr/local/include/libcli.h -o ! -x /usr/local/lib/libcli.so ]; then
    git clone git@github.com:dparrish/libcli.git
    cd libcli
    make || die "Failed to build libcli"
    sudo make install
    sudo ldconfig
    cd ..
    rm -rf libcli
else
    echo "libcli already installed"
fi

### Drivers and their dependencies

install_bf_repo () {
    name=$1
    x_path_check=$2
    configure_flags=$3
    if [ ! -d $name/.git ]; then
        gitclone git@github.com:barefootnetworks/$name.git $name
    elif $pull_before_rebuild; then
        pushd $name >/dev/null
        git pull $rebase_option origin master
        popd >/dev/null
    fi
    pushd $name >/dev/null
    builddir="."
    if $reuse_asis && [ -x "$x_path_check" ]; then
        echo "Reusing $name as is"
    else
        cd $builddir
        if [ ! -r Makefile ]; then
            ./autogen.sh
            ./configure $configure_flags
        fi
        if $clean_before_rebuild; then
            make clean
        fi
        make && \
        sudo make install && \
        sudo ldconfig || \
        die "Failed to install $name"
    fi
    popd >/dev/null
    return 0
}

install_bf_repo "bf-syslibs" "/usr/local/lib/libbfsys.so" ""
install_bf_repo "bf-utils" "/usr/local/lib/libbfutils.so" ""

if [ ! -d PI/.git ]; then
    gitclone git@github.com:p4lang/PI.git PI
elif $pull_before_rebuild; then
    pushd PI >/dev/null
        git pull $rebase_option origin master
    popd >/dev/null
fi
pushd PI >/dev/null
    builddir="."
    if $reuse_asis && [ -x /usr/local/lib/libpi.so ]; then
        echo "Reusing PI as is"
    else
        cd $builddir
        if [ ! -r Makefile ]; then
            ./autogen.sh
            ./configure --with-proto --without-internal-rpc --without-cli
        fi
        if $PI_clean_before_rebuild; then
            make clean
        fi
        make && \
        sudo make install && \
        sudo ldconfig || \
        die "Failed to install PI"
    fi
popd >/dev/null

install_bf_repo "bf-drivers" "$(which bf_switchd)" "--disable-thrift --with-avago --without-kdrv --with-build-model --enable-pi"

### Model setup
if [ ! -d model/.git ]; then
    gitclone git@github.com:barefootnetworks/model.git model
elif $pull_before_rebuild; then
    pushd model >/dev/null
        git pull $rebase_option origin master
    popd >/dev/null
fi
pushd model >/dev/null
    builddir="."
    if [ -r opt/Makefile ]; then
        builddir=opt
    elif [ -r debug/Makefile ]; then
        builddir=debug
    fi
    if $reuse_asis && [ -x $builddir/tests/simple_test_harness/simple_test_harness ]; then
        echo "Reusing built $PWD/$builddir/tests/simple_test_harness/simple_test_harness as is"
    else
        cd $builddir
        if [ ! -r Makefile ]; then
            ./autogen.sh
            ./configure --enable-runner
        fi
        if $clean_before_rebuild; then
            make clean
        fi
        make || die "harlyn model build failed"
        # FIXME -- should not need make install here!!!  Unless someone has previously
        # done a make install of the model, in which case cmake will get the old one
        sudo make install
        sudo ldconfig
    fi
popd >/dev/null

if [ ! -x "$(which ptf)" ]; then
    pushd $tmpdir
    git clone https://github.com/p4lang/ptf.git
    cd ptf
    sudo python setup.py install
    cd ..
    sudo rm -rf ptf
    popd # tmpdir
fi

echo "Checking for huge pages"
sudo $curdir/scripts/ptf_hugepage_setup.sh

echo "Removing $tmpdir"
rm -rf $tmpdir
