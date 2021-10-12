#!/bin/bash
# assumes that the Dockerfile will make sure that the script is at this location

# only alter system huge pages configuration in Travis CI environment
if [ "$TRAVIS" = true ]; then
    /bfn/ptf_hugepage_setup.sh >&2
fi

# Setup veths
/bfn/veth_setup.sh 34 >&2

# Environment variable PKTPY allows switching between PTF with scapy or PTF with bf-pktpy.
[ -z "$PYTHONPATH" ] && delim='' || delim=':'
export PYTHONPATH="/usr/local/lib/python2.7/site-packages${delim}${PYTHONPATH}"
if [ "${PKTPY,,}" = "true" ]; then
    echo "PTF: Using bf-ptf with bf-pktpy"
    export PYTHONPATH="/usr/local/lib/python2.7/site-packages/bf-ptf:${PYTHONPATH}"
else
    echo "PTF: Using p4lang/ptf with scapy"
fi

# Start the web server; it is installed only in Jarvis for accessing generated documentation
test -f /etc/init.d/apache2 && /etc/init.d/apache2 start

# execute docker command
exec "$@"
