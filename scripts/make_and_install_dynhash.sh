#! /bin/bash
# This scripts builds and installs the bf-utils library

top_dir=$(dirname $0)/..
usage() {
    echo "$0 [--branch br][--repo dir] [--install-dir dir]"
    echo "   --branch <branch> the bf-utils repo branch. Default: master."
    echo "   --repo <dir> specifies the directory for the bf-utils repo."
    echo "          If it does not exist, it clones the repo in the specified directory."
    echo "   --install-dir <dir> the directory prefix to install the library and headers."
}

install_dir=/usr/local
repo_dir=$top_dir/../bf-utils
branch=master
while [[ $# -gt 0 ]] ; do
    if [ ! -z $1 ]; then
        case $1 in
            -h|--help)
                usage;
                exit 0;
                ;;
            -i|--install-dir)
                install_dir=$2
                shift; shift;
                ;;
            -r|--repo)
                repo_dir=$2
                shift; shift;
                ;;
            -b|--branch)
                branch=$2
                shift; shift;
                ;;
            *)
                echo "Unknown option $1"
                usage
                exit 1
                ;;
        esac
    fi
done

set -e
top_repo_dir=$repo_dir
if [[ $(basename $repo_dir) == "bf-utils" ]]; then
    top_repo_dir=$(dirname $repo_dir)
fi
if [[ ! -d $repo_dir ]] ; then
    if [[ ! -d $top_repo_dir ]]; then
        mkdir -p $top_repo_dir
    fi
    cd $top_repo_dir
    repo_dir=${top_repo_dir}/bf-utils
    # Note that we intentionally do not clone recursively
    # For dynhash we do not need the third party dependencies
    git clone git@github.com:barefootnetworks/bf-utils -b $branch
    cd bf-utils
else
    cd $repo_dir
fi
git checkout $branch
git pull --ff origin master
echo "Running autogen.sh ..."
./autogen.sh > /dev/null
mkdir -p build && cd build
echo "Running configure ..."
../configure --prefix=$install_dir > /dev/null
make libdynhash.la
echo "Installing ..."
SUDO=
if [[ $(uname -s) == 'Linux' ]]; then SUDO=sudo ; fi
$SUDO mkdir -p $install_dir/lib $install_dir/include/bfutils
$SUDO cp .libs/libdynhash.a $install_dir/lib
$SUDO cp -r ../include/dynamic_hash $install_dir/include/bfutils
