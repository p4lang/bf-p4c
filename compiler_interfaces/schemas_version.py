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

# SDE version number.

# Note added Jan. 25 2023: as per Steve Licking, this version is no longer to be incremented,
#                          not even the "patch_version".
major_version = 8
minor_version = 6
patch_version = 0

def get_code_version():
    return "%s.%s.%s" % (str(major_version),
                         str(minor_version),
                         str(patch_version))
