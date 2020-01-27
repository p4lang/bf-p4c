#!/bin/sh
# assumes that the Dockerfile will make sure that the script is at this location

# only alter system huge pages configuration in Travis CI environment
if [ "$TRAVIS" = true ]; then
    /bfn/ptf_hugepage_setup.sh >&2
fi
# Setup veths
/bfn/veth_setup.sh 34 >&2
# execute docker command
exec "$@"
