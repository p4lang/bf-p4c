/**
 * Copyright (C) 2024 Intel Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.  See the License for the specific language governing permissions
 * and limitations under the License.
 *
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef BF_UTILS_BLD_VER
#define BF_UTILS_BLD_VER "0"
#endif

#ifndef BF_UTILS_GIT_VER
#define BF_UTILS_GIT_VER "000"
#endif

#define BF_UTILS_REL_VER "9.14.0"
#define BF_UTILS_VER BF_UTILS_REL_VER "-" BF_UTILS_BLD_VER

#define BF_UTILS_INTERNAL_VER BF_UTILS_VER "(" BF_UTILS_GIT_VER ")"

const char *bf_utils_get_version(void) { return BF_UTILS_VER; }
const char *bf_utils_get_internal_version(void) {
  return BF_UTILS_INTERNAL_VER;
}
