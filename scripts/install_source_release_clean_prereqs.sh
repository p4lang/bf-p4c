#!/bin/sh

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

# Install prerequisites for source_release_clean.py

SCRIPT_DIR=$(dirname $(readlink -f "$0"))

mkdir -p "$SCRIPT_DIR/_deps"

# Fetch the prerequeisites
cd "$SCRIPT_DIR/_deps"

CPPP_REPO="https://git.sr.ht/~breadbox/cppp"
if [ ! -d cpp ] ; then
    git clone ${CPPP_REPO}

    cd cppp
    make -j 4
    cd ..
fi

