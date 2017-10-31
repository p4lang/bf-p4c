#!/bin/bash

cd $(dirname $0)
curdir=$(basename $PWD)
topdir=$(dirname $PWD)

os_deps=${topdir}/${curdir}/install_os_deps.sh
if [ ! -x $os_deps ]; then
    echo "Can not find script to install OS dependencies: $os_deps"
    exit 1
fi

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

gitclone() {
    # arguments:
    # $1 - the repository
    # $2 - the directory name where to checkout
    # $3 - optional branch to checkout
    local branch="master"
    if [ ! -z $3 ]; then branch=$3; fi
    [ -e "$2" ] && die "$2 already exists!"
    [ ! -d "$(dirname $2)" ] && die "$(dirname $2) not a directory"
    git clone --recursive -b $branch $1 $2 || { rm -rf $2; die "can't clone $1"; }
}

echo "Using $topdir as top level directory for git repositories"
echo "Using MAKEFLAGS=${MAKEFLAGS:=-j 4}"
export MAKEFLAGS

reuse_asis=false
clean_before_rebuild=false
pull_before_rebuild=false
rebase_option=""

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

# install all necessary packages
# and set SUDO, LDCONFIG, LDLIB_EXT as appropriate for the OS
# also sets PI_clean_before_rebuild if the protobuf/grpc have been re-installed
. $os_deps


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
        $SUDO make install
    fi
popd >/dev/null

### Model dependencies that need manual build
## libcrafter
if [ ! -r /usr/local/include/crafter.h -o ! -x /usr/local/lib/libcrafter.${LDLIB_EXT} ]; then
    git clone https://github.com/pellegre/libcrafter
    cd libcrafter/libcrafter
    ./autogen.sh
    make -j4 || die "Failed to build libcrafter"
    $SUDO make install
    $SUDO $LDCONFIG
    cd ../..
    rm -rf libcrafter
else
    echo "libcrafter already installed"
fi
## libcli
if [ ! -r /usr/local/include/libcli.h -o ! -x /usr/local/lib/libcli.${LDLIB_EXT} ]; then
    git clone git@github.com:dparrish/libcli.git
    cd libcli
    make || die "Failed to build libcli"
    $SUDO make install
    $SUDO $LDCONFIG
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
        gitclone git@github.com:barefootnetworks/$name.git $name "brig-stable"
    elif $pull_before_rebuild; then
        pushd $name >/dev/null
        git pull $rebase_option origin brig-stable
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
        $SUDO make install && \
        $SUDO $LDCONFIG || \
        die "Failed to install $name"
    fi
    popd >/dev/null
    return 0
}

# build the drivers only on Linux
if [ $(uname -s) == 'Linux' ]; then
    install_bf_repo "bf-syslibs" "/usr/local/lib/libbfsys.${LDLIB_EXT}" ""
    install_bf_repo "bf-utils" "/usr/local/lib/libbfutils.${LDLIB_EXT}" ""
fi

if [ ! -d PI/.git ]; then
    gitclone git@github.com:p4lang/PI.git PI
elif $pull_before_rebuild; then
    pushd PI >/dev/null
        git pull $rebase_option origin master
    popd >/dev/null
fi
pushd PI >/dev/null
    builddir="."
    if $reuse_asis && [ -x /usr/local/lib/libpi.${LDLIB_EXT} ]; then
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
        $SUDO make install && \
        $SUDO $LDCONFIG || \
        die "Failed to install PI"
    fi
popd >/dev/null

# build the drivers only on Linux
if [ $(uname -s) == 'Linux' ]; then
    install_bf_repo "bf-drivers" "$(which bf_switchd)" "--disable-thrift --with-avago --without-kdrv --with-build-model --enable-pi"
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
        if [ $(uname -s) == 'Linux' ]; then
            config_args="--enable-runner --enable-simple-test-harness"
        else
            config_args="--enable-simple-test-harness"
        fi
        if [ ! -r Makefile ]; then
            ./autogen.sh
            ./configure $config_args
        fi
        if $clean_before_rebuild; then
            make clean
        fi
        make || die "harlyn model build failed"
        # FIXME -- should not need make install here!!!  Unless someone has previously
        # done a make install of the model, in which case cmake will get the old one
        $SUDO make install
        $SUDO $LDCONFIG
    fi
popd >/dev/null

# re-install ptf unconditionally
tmpdir=$(mktemp -d)
echo "Using $tmpdir for temporary build files"
pushd $tmpdir
gitclone https://github.com/p4lang/ptf.git ptf
cd ptf
$SUDO python setup.py install
cd ..
$SUDO rm -rf ptf
popd # tmpdir
echo "Removing $tmpdir"
rm -rf $tmpdir

if [ $(uname -s) == 'Linux' ]; then
    echo "Checking for huge pages"
    $SUDO $curdir/scripts/ptf_hugepage_setup.sh
fi
