#!/bin/bash
# assumes that the Dockerfile will make sure that the script is at this location

# only alter system huge pages configuration in Travis CI environment (run as root)
if [ "$TRAVIS" = true ]; then
    sudo /bfn/ptf_hugepage_setup.sh >&2
fi

# p4factory installs ptf + bf_pktpy packages into global site-packages, which
# are not part of default search path
pythonpath_prefix="/usr/local/lib/python3.5/site-packages"
if [[ "$PYTHONPATH:" != "$pythonpath_prefix:"* ]]; then
    [ -z "$PYTHONPATH" ] && delim='' || delim=':'
    export PYTHONPATH="${pythonpath_prefix}${delim}${PYTHONPATH}"
fi

# Setup veths (run as root)
sudo /bfn/veth_setup.sh 34 >&2

# Start the web server; it is installed only in Jarvis for accessing generated documentation
sudo test -f /etc/init.d/apache2 && sudo /etc/init.d/apache2 start

# execute docker command
exec "$@"
