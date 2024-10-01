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

SCRIPT_DIR=$(realpath "$(dirname "$0")")

SCHEMAS_DIR=$(realpath "$SCRIPT_DIR/../compiler_interfaces/schemas")

OUTPUT=""
if [ $# -ge 1 ]; then
    OUTPUT="$1"
    rm -f "$OUTPUT"
    touch "$OUTPUT" || exit $?
fi

for schema in $(basename -s ".py" "$SCHEMAS_DIR"/*.py); do
    version=$(python3 << END
import sys

sys.path.append("$SCHEMAS_DIR")

try:
    from $schema import get_schema_version
except ImportError:
    sys.exit(1)

print(get_schema_version())
END
)
    if [ $? -eq 0 ]; then
        schema_version=$(printf "%-20s : %s\n" "$schema" "$version")

        if [ "$OUTPUT" != "" ]; then
            echo "$schema_version" >> "$OUTPUT"
        else
            echo "$schema_version"
        fi
    fi
done