#!/bin/bash

# This script launches a process at maximum priority on a single specified
# CPU core.
# This script requires root privileges

# Usage: bash one_core 2 my_command

# Exit on any error
set -e

# Select what core to use
processor=$1
exec sudo nice -n -19 taskset --cpu-list ${processor} ${@:2:99}
