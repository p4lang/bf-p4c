#!/usr/bin/env bash

set -e

echo "Copying the current authorezed keys ..."
rm -rf ssh
mkdir ssh
if [ -e ~/.ssh/authorized_keys ]; then
   cp ~/.ssh/authorized_keys ssh
fi

echo "Building the docker image ..."
docker build -t jarvis-ssh .

echo "Cleaning temporal files ..." 
rm -rf ssh
