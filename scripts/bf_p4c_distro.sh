#! /bin/bash
# Usage: bf_p4c_distro.sh <workspace_dir> <p4c_version> [bf-p4c-compilers branch]

set -e

[ -z $1 ] && exit "Specify the build directory"
[ -z $2 ] && exit "Specify p4c version"

bf_p4c_branch=master
if [[ ! -z $3 ]]; then
    bf_p4c_branch=$3
fi

WORKSPACE=$1
P4C_VERSION=$2

cd $WORKSPACE
git clone --recursive git@github.com:barefootnetworks/bf-p4c-compilers -b $bf_p4c_branch

# prepare the source to set the version number
P4C_TOFINO_SHA=`git --git-dir $WORKSPACE/bf-p4c-compilers/.git log --oneline -n 1 | cut -f 1 -d " "`
P4LANG_SHA=`git --git-dir $WORKSPACE/bf-p4c-compilers/p4c/.git log --oneline -n 1 | cut -f 1 -d " "`
cd $WORKSPACE/bf-p4c-compilers
sed -i -e "s/P4C_TOFINO_VERSION.*/P4C_TOFINO_VERSION \"${P4C_VERSION} (${P4C_TOFINO_SHA})\"/" bf-p4c/version.h
sed -i -e "s/__version__ = .*/__version__ = '${P4C_VERSION} (${P4LANG_SHA})'/g" p4c/tools/driver/p4c_src/__init__.py
cd $WORKSPACE

$WORKSPACE/bf-p4c-compilers/scripts/p4c_build_for_arch.sh "$WORKSPACE" x86_64-apple-darwin ${P4C_VERSION}
docker run --rm -v ${WORKSPACE}:/tmp/p4c-build -w /tmp/p4c-build \
       p4c-tofino:ubuntu16.04 \
       /tmp/p4c-build/bf-p4c-compilers/scripts/p4c_build_for_arch.sh /tmp/p4c-build x86_64-linux-gnu ${P4C_VERSION}

# package
cd $WORKSPACE/install
tar jcvf p4c-${P4C_VERSION}-pre-release.tar.bz2 p4c-${P4C_VERSION}
