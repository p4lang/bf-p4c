#!/bin/sh
# assumes that the Dockerfile will make sure that the script is at this location

if [ "${BUILD_FOR}" = "jarvis" ]; then
  # Clean up the environment a bit.
  #
  # The image's environment has been polluted by a parent image. Dockerfile
  # lets you set environment variables to be have empty values, but that is
  # different from removing them altogether. This matters especially for
  # ccache-related variables.
  unset CCACHE_MAXSIZE
  unset CCACHE_MEMCACHED_CONF
  unset CCACHE_MEMCACHED_ONLY

  # Set things up for distcc.
  export CC="distcc gcc"
  export CXX="distcc g++"
fi

# only alter system huge pages configuration in Travis CI environment
if [ "$TRAVIS" = true ]; then
    /bfn/ptf_hugepage_setup.sh >&2
fi

# Setup veths
/bfn/veth_setup.sh 34 >&2

# execute docker command
exec "$@"
