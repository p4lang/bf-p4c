#!/bin/bash

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

HUGE_DEFAULT=192
HUGE_TO_SET=${NUM_HUGEPAGES:-${1:-$HUGE_DEFAULT}}
HUGE_KEY=vm.nr_hugepages
HUGE_ACTUAL=$(sysctl --values $HUGE_KEY)
CONF=/etc/sysctl.conf

if [[ $HUGE_TO_SET -gt $HUGE_ACTUAL ]]; then
    if grep -q "^$HUGE_KEY\>" $CONF; then
        sed -i "s/^$HUGE_KEY\>.*$/$HUGE_KEY = $HUGE_TO_SET/" $CONF
    else
        echo "$HUGE_KEY = $HUGE_TO_SET" >> $CONF
    fi
    sysctl -p /etc/sysctl.conf
fi
if [[ ! -d /mnt/huge ]]; then
    mkdir /mnt/huge
    mount -t hugetlbfs nodev /mnt/huge
    echo -e "nodev /mnt/huge hugetlbfs\n" >> /etc/fstab
fi
