#!/bin/bash

# This script measures passed in process
# The process in run with maximum priority on passed in core
# This script requires root privileges

# Usage: bash measure_process.sh 1 my_command

# Get path to this script to execute scripts in this directory
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"
# Run time process on max privilege mesuring passed in command
bash ${SCRIPT_PATH}/run_on_one_core.sh $1 time -f "BENCHMARK_TIME:%e#" "$2"
