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

#ifndef BF_P4C_PARDE_PHASE0_H_
#define BF_P4C_PARDE_PHASE0_H_

#include <utility>
#include <vector>

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/hex.h"

std::ostream& operator<<(std::ostream& out, const IR::BFN::Phase0* p0);

#endif /* BF_P4C_PARDE_PHASE0_H_ */
