#!/bin/sh
# assumes that the Dockerfile will make sure that the script is at this location
/bfn/ptf_hugepage_setup.sh >&2
# Setup veths
/bfn/veth_setup.sh 34 >&2
# execute docker command
exec "$@"
