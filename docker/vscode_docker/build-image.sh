#!/usr/bin/env bash

#
# Build a Docker image for use with Visual Studio Code remote development
#

# Target image name
DST_IMG=jarvis-ssh

# Directory for host SSH keys
SSH_KEY_DIR=~/docker_ssh_keys

usage() {
    echo "Usage: $0 [OPTION]..."
    echo "Build a Docker image for remote Visual Studio Code development"
    echo ""
    echo "Options:"
    echo "  -k, --key-dir[=DIR]  store generated SSH keys in DIR (default=~/docker_ssh_keys)"
    echo "  -i, --image[=DIR]    image name to genearate (default=jarvis-ssh)"
    echo "      --help           display this help message"
}


# Generate a host SSH key
create_key() {
    msg="$1"
    shift
    keytype="$1"
    shift

    file=$SSH_KEY_DIR/ssh_host_${keytype}_key

    echo $msg
    ssh-keygen -q -f "$file" -N '' -t "$keytype"
    ssh-keygen -l -f "$file.pub"
}


# Parse command line options
OPTIONS=`getopt -o ":k:i:h" -l "key-dir:,image:,help" -- $@`
if [ $? != 0 ] ; then
    echo "Error: invalid option(s)"
    echo ""
    usage
    exit 1
fi

eval set -- "$OPTIONS"

while true ; do
    case $1 in
        -k|--key-dir)
            SSH_KEY_DIR=$2
            shift
            ;;
        -i|--image)
            DST_IMG=$2
            shift
            ;;
        -h|--help)
            usage
            exit
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done


# Generate the docker images
set -e

TMP_KEY_DIR=`mktemp -p . -d`
echo "Copying current authorized keys..."
if [ -e ~/.ssh/authorized_keys ]; then
   cp ~/.ssh/authorized_keys $TMP_KEY_DIR/authorized_keys
fi

if [ ! -d $SSH_KEY_DIR ] ; then
    echo "Creating host SSH keys..."
    mkdir $SSH_KEY_DIR
    create_key "Creating SSH2 RSA key; this may take some time ..." rsa
    create_key "Creating SSH2 DSA key; this may take some time ..." dsa
    create_key "Creating SSH2 ECDSA key; this may take some time ..." ecdsa
    create_key "Creating SSH2 ED25519 key; this may take some time ..." ed25519
fi

for key in rsa dsa ecdsa ed25519 ; do
    for ext in "" ".pub"  ; do
        cp $SSH_KEY_DIR/ssh_host_${key}_key${ext} $TMP_KEY_DIR
    done
done

echo "Building the docker image ..."
docker build -t ${DST_IMG} . \
    --build-arg USER=${USER} \
    --build-arg UID=`id -u` \
    --build-arg GID=`id -g` \
    --build-arg KEY_DIR=${TMP_KEY_DIR}

echo "Cleaning temporary files ..." 
rm -rf $TMP_KEY_DIR
