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

# Produces LICENSE from LICENSE.in.

set -e

licenceTemplate="LICENSE.in"
licenceOutput="LICENSE"

# Change to repository root.
cd "$(realpath "$(dirname "$0")/..")"

if [[ ! -f "${licenceTemplate}" ]] ; then
  echo "${licenceTemplate} not found in $(pwd)" >&2
  exit 1
fi

sed \
  -e '/^#.*$/d'                      `# Strip comment lines.` \
  -e 's/\s*$//'                      `# Trim trailing space on each line.` \
  -e "s/@YEAR@/$(date +%Y)/g"        `# Substitute year.` \
  -e '/./,$!d'                       `# Delete blank lines at top of file.` \
  -e :a -e '/^\n*$/{$d;N;};/\n$/ba'  `# Delete blank lines at end of file.` \
  "${licenceTemplate}" \
  | fmt -w 80  `# Re-wrap to 80 columns.` \
  >"${licenceOutput}"
