#!/bin/bash
# assumes that the Dockerfile will make sure that the script is at this location

# only alter system huge pages configuration in Travis CI environment (run as root)
if [ "$TRAVIS" = true ]; then
    sudo /bfn/ptf_hugepage_setup.sh >&2
fi

# Setup veths (run as root)
sudo /bfn/veth_setup.sh 34 >&2

# Start the web server; it is installed only in Jarvis for accessing generated documentation
sudo test -f /etc/init.d/apache2 && sudo /etc/init.d/apache2 start

# execute docker command
exec "$@"
