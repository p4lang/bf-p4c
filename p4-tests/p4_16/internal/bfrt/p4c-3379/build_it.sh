#!/usr/bin/env bash

# ----------------------------------------------------------------------------
#
# Notes:
#
# P4C       - the path to the P4 compiler
#
# P4FLAGS   - the options to be passed to the P4 compiler
#
# P4PPFLAGS - the options to be passed to the C preprocessor as it is being invoked by P4C
#
# P4JOBS    - the maximum number of parallel threads that can be run by P4 compiler
#
# P4_PATH   - the path to the main file of the program that should be compiled
#
# P4_NAME   - the name of the program (default is the basename of the file)
#
# P4_PREFIX - the program name to be used when generating PD APIs (default is P4_NAME
#
# ----------------------------------------------------------------------------

if [ "$1" != "1" ] && [ "$1" != "2" ]; then
    echo "  usage: $0 <target>"
    echo "  (where target is 1 for tofino or 2 for tofino2)"
    exit 1
fi

# -------------------------------------

if [ "$2" = "" ]; then
	profile="PROFILE_STANDARD"
else
    profile=$2
fi

# -------------------------------------

set -e # exit this script on any error

top_saved='npb' # name of your top-level p4 program
echo $top_saved

path_saved=$PWD # just save off current path for use below
echo $path_saved

# -------------------------------------

# rm -rf $SDE/build/p4-examples/$top_saved # uncomment me to do a clean build
# mkdir -p $SDE/build/p4-examples/$top_saved
# pushd $SDE/build/p4-examples/$top_saved

rm -rf /npb-dp/build/$top_saved
mkdir -p /npb-dp/build/$top_saved
pushd /npb-dp/build/$top_saved

echo --------------------------------------------------------------------------------
echo configure
echo --------------------------------------------------------------------------------


if [ "$1" == "1" ]; then

    echo "target=tofino"
    $SDE/pkgsrc/p4-build/configure \
    	--prefix=$SDE_INSTALL \
    	--with-tofino \
    	--with-p4c \
    	P4_NAME=$top_saved \
    	P4_PATH=$path_saved/"$top_saved.p4" \
    	P4_VERSION=p4-16 \
    	P4_ARCHITECTURE=tna \
    	P4JOBS=4 \
    	P4PPFLAGS=-I$path_saved \
    	P4FLAGS="--verbose 3 -g --create-graphs --parser-timing-reports --p4runtime-files p4info.txt --p4runtime-force-std-externs --auto-init-metadata -D $profile"

else

    echo "target=tofino2"
    $SDE/pkgsrc/p4-build/configure \
    	--prefix=$SDE_INSTALL \
    	--with-tofino2 \
    	--with-p4c \
    	P4_NAME=$top_saved \
    	P4_PATH=$path_saved/"$top_saved.p4" \
    	P4_VERSION=p4-16 \
    	P4_ARCHITECTURE=t2na \
    	P4JOBS=4 \
    	P4PPFLAGS=-I$path_saved \
    	P4FLAGS="--verbose 3 -g --create-graphs -Xp4c=-Tclot_info:6 --parser-timing-reports --p4runtime-files p4info.txt --p4runtime-force-std-externs --auto-init-metadata -D $profile"
fi

echo --------------------------------------------------------------------------------
echo make clean
echo --------------------------------------------------------------------------------

make clean

echo --------------------------------------------------------------------------------
echo make
echo --------------------------------------------------------------------------------

make -j 4 P4FLAGS="--verbose 3 -g --create-graphs -Xp4c=-Tclot_info:6 --parser-timing-reports --p4runtime-files p4info.txt --p4runtime-force-std-externs --auto-init-metadata -D $profile"

echo --------------------------------------------------------------------------------
echo make install
echo --------------------------------------------------------------------------------

make install

# echo --------------------------------------------------------------------------------
# echo package build artifacts
# echo --------------------------------------------------------------------------------
# 
# if [ "$1" == "1" ]; then
#     $path_saved/package_it.sh 1
# else
#     $path_saved/package_it.sh 2
# fi

popd
