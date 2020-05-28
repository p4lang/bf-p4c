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

  # Set up Intel proxies.
  export http_proxy='http://proxy-dmz.intel.com:911'
  export https_proxy='http://proxy-dmz.intel.com:912'
  export ftp_proxy='http://proxy-dmz.intel.com:21'
  export socks_proxy='proxy-dmz.intel.com:1080'
  export no_proxy='intel.com,*.intel.com,localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12'
  export ALL_PROXY='socks5://proxy-us.intel.com'
fi
