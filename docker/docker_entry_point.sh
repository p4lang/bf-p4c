#!/bin/sh
# assumes that the Dockerfile will make sure that the script is at this location
/bfn/ptf_hugepage_setup.sh
# Setup veths
/bfn/veth_setup.sh 34
# execute docker command
exec "$@"
