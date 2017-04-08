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


curdir=$(basename $PWD)
topdir=$PWD

if [ "$curdir" = "tofino" -a "$(basename $(dirname $topdir))" = "extensions" ]; then
    p4cdir=$(dirname $(dirname $topdir))
    if [ "$(basename $p4cdir)" = "p4c" ]; then
        topdir=$(dirname $p4cdir)
    else
        echo >&2 "We're in an extensions/tofino directory, but not under p4c"
        echo >&2 "Need to rename $p4cdir to $(dirname $p4cdir)/p4c if you want bootstrap to work"
        exit 1
    fi
elif [ "$curdir" = "p4c-extension-tofino" ]; then
    topdir=$(dirname $topdir)
fi

cd $topdir
found=""

for repo in p4c tofino-asm behavioral-model model p4c-extension-tofino p4c/extensions/tofino p4c/extensions/p4_tests; do
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

apt_packages="g++ git pkg-config automake libtool python2.7 python cmake bison flex libboost-dev libboost-test-dev libboost-program-options-dev libboost-system-dev libboost-filesystem-dev libboost-thread-dev libcli-dev libedit-dev libeditline-dev libevent-dev libjudy-dev libgc-dev libgmp-dev libjson0 libjson0-dev libmoose-perl libnl-route-3-dev libpcap0.8-dev libssl-dev autopoint doxygen texinfo python-scapy python-yaml python-ipaddr python-pip"

echo "Need sudo privs to install apt packages"
sudo apt-get update || die "Failed to update apt"
sudo apt-get install -y $apt_packages || die "Failed to install needed packages"
sudo apt-get remove -y python-thrift    # remove this broken package in case it was installed
sudo pip install thrift || die "Failed to install needed packages"  # need this one instead

echo "Using $topdir as top level directory for git repositories"
echo Using MAKEFLAGS=${MAKEFLAGS:=-j 4}
export MAKEFLAGS

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
            ./configure
        fi
        if $clean_before_rebuild; then
            make clean
        fi
        make || die "harlyn model build failed"
    fi
popd >/dev/null

### Assembler setup
if [ ! -d tofino-asm/.git ]; then
    gitclone git@github.com:barefootnetworks/tofino-asm tofino-asm
elif $pull_before_rebuild; then
    pushd tofino-asm >/dev/null
        git pull $rebase_option origin master
    popd >/dev/null
fi
pushd tofino-asm >/dev/null
    if [ -r opt/Makefile ]; then
        cd opt
    elif [ -r debug/Makefile ]; then
        cd debug
    fi
    if $reuse_asis && [ -x tfas ]; then
        echo "Reusing $PWD/tfas as is"
        true
    else
        if [ ! -r Makefile ]; then
            ./bootstrap.sh
        fi
        if $clean_before_rebuild; then
            make clean
        fi
        make all || die "assembler build failed"
    fi
popd >/dev/null

### P4C setup
if [ ! -d p4c/.git ]; then
    gitclone git@github.com:p4lang/p4c.git p4c
elif $pull_before_rebuild; then
    pushd p4c >/dev/null
        git pull $rebase_option origin master
    popd >/dev/null
fi
pushd p4c >/dev/null
    git submodule sync
    git submodule update --init --recursive
    mkdir -p extensions
    cd extensions
    if [ ! -e p4_tests ]; then
        git clone git@github.com:barefootnetworks/p4_tests.git
    fi
    if [ ! -e tofino ]; then
        if [ -d ../../p4c-extension-tofino/.git ]; then
            mv ../../p4c-extension-tofino tofino
        else
            gitclone git@github.com:barefootnetworks/p4c-extension-tofino.git tofino
        fi
        if [ -d ../build ]; then
            rm -rf ../build
        fi
    else
        cd tofino
        if $pull_before_rebuild; then
            git pull $rebase_option origin master
        else
            echo "Reusing $PWD as is"
        fi
        cd ..
    fi
    cd ..
    if $reuse_asis && [ -r build/Makefile ]; then
        echo "Reusing $PWD/build as is"
    else
        if [ ! -d build ]; then
            ./bootstrap.sh
        fi
        if $clean_before_rebuild; then
            make -C build clean
        fi
        make -C build
    fi
popd >/dev/null
