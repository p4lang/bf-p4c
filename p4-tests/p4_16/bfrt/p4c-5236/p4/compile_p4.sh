#!/bin/bash

# $1 is the P4 application name.
if [ -z "$1" ]; then
    echo "Missing compilation target"
    exit 1
fi

p4_app=$1
echo "Compiling P4-16 dataplane" $p4_app

compiledir=compiledir_$p4_app
compiledir=`realpath $compiledir`
rm -rf $compiledir
mkdir $compiledir
if [ -z "$compiledir" ]; then
    echo "Missing compilation directory"
    exit 1
fi

base_dir=$PWD
p4_main_file=$base_dir/$p4_app.p4
p4_app_path=$base_dir

# Prepare SDE tools 
cd $SDE/pkgsrc/p4-build/
./autogen.sh
if [ "$?" != "0" ]; then
    #echo "Failed to run autogen"
    exit 5
fi

cd $compiledir
$SDE/pkgsrc/p4-build/configure \
    P4PPFLAGS=-I$base_dir \
    P4_PATH=$p4_main_file \
    P4_NAME=$p4_app \
    P4_VERSION=p4-16 \
    P4_ARCHITECTURE=t2na \
    --prefix=$SDE_INSTALL \
    --with-tofino2 \
    --with-bf-runtime \
    --with-p4c

if [ "$?" != "0" ]; then
    #echo "Failed to run configure"
    exit 6
fi

make
if [ "$?" != "0" ]; then
    #echo "Failed to run make"
    exit 7
fi

make install
if [ "$?" != "0" ]; then
    #echo "Failed to run make install"
    exit 8
fi


