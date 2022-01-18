#!/bin/bash

# Prepare new prefix to $PYTHONPATH
# Common prefix
pythonpath_prefix="/usr/local/lib/python3.5/site-packages"
if [[ "$PYTHONPATH:" = "$pythonpath_prefix:"* ]]; then
    # $pythonpath_prefix is already a prefix of $PYTHONPATH
    pythonpath_prefix=""
fi

# Set new $PYTHONPATH
if [ ! -z "$pythonpath_prefix" ]; then
    if [ "${PKTPY,,}" = "false" ]; then
        echo "PTF: Using scapy as packet manipulator module  (to use bf-pktpy instead, run 'export PKTPY=True && . $(readlink -f $BASH_SOURCE)')"
    else
        echo "PTF: Using bf-pktpy as packet manipulator module  (to use scapy instead, run 'export PKTPY=False && . $(readlink -f $BASH_SOURCE)')"
    fi
    [ -z "$PYTHONPATH" ] && delim='' || delim=':'
    export PYTHONPATH="${pythonpath_prefix}${delim}${PYTHONPATH}"
fi
