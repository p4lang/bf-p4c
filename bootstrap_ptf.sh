#! /bin/bash

# Copyright (C) 2024 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.  You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
#
# SPDX-License-Identifier: Apache-2.0

set -e

if [ $# -ne 1 ]; then
    echo "This script expects exactly one argument, the path to the build dir"
    exit 1
fi

CC=cc
mydir=`dirname $0`
cd $mydir
ptf_runner_wrapper_SRC=$1/p4c/ptf_runner_wrapper.c
ptf_runner_wrapper=$1/p4c/extensions/p4_tests/ptf_runner_wrapper
$CC $ptf_runner_wrapper_SRC -o $ptf_runner_wrapper
sudo chown root $ptf_runner_wrapper
sudo chmod u+s $ptf_runner_wrapper
