#!/bin/sh
# assumes that the Dockerfile will make sure that the script is at this location
/bfn/ptf_hugepage_setup.sh
# execute docker command
exec "$@"
