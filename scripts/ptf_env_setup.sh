#!/bin/bash

# Prepare new prefix to $PYTHONPATH
# Common prefix
pythonpath_prefix="/usr/local/lib/python3.5/site-packages"
if [[ "$PYTHONPATH:" = "$pythonpath_prefix:"* ]]; then
    # $pythonpath_prefix is already a prefix of $PYTHONPATH
    pythonpath_prefix=""
fi
# Environment variable PKTPY allows switching between p4lang/ptf with scapy or bf-ptf with bf-pktpy.
if [ "${PKTPY,,}" != "false" ]; then
    # Prepend bf-ptf-specific prefix
    [ -z "$pythonpath_prefix" ] && delim='' || delim=':'
    pythonpath_prefix="/usr/local/lib/python3.5/site-packages/bf-ptf${delim}${pythonpath_prefix}"
    if [[ "$PYTHONPATH:" = "$pythonpath_prefix:"* ]]; then
        # $pythonpath_prefix is already a prefix of $PYTHONPATH
        pythonpath_prefix=""
    fi
fi

# Set new $PYTHONPATH
if [ ! -z "$pythonpath_prefix" ]; then
    if [ "${PKTPY,,}" = "false" ]; then
        echo "PTF: Using p4lang/ptf with scapy  (to use bf-ptf with bf-pktpy instead, run 'export PKTPY=True && . $(readlink -f $BASH_SOURCE)')"
    else
        echo "PTF: Using bf-ptf with bf-pktpy  (to use p4lang/ptf with scapy instead, run 'export PKTPY=False && . $(readlink -f $BASH_SOURCE)')"
    fi
    [ -z "$PYTHONPATH" ] && delim='' || delim=':'
    export PYTHONPATH="${pythonpath_prefix}${delim}${PYTHONPATH}"
fi
