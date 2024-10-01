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

#ifndef EXTENSIONS_BF_P4C_ARCH_FROMV1_0_FIELD_LIST_H_
#define EXTENSIONS_BF_P4C_ARCH_FROMV1_0_FIELD_LIST_H_

#include "ir/ir.h"
#include "frontends/p4/fromv1.0/converters.h"
#include "bf-p4c/midend/path_linearizer.h"

namespace P4V1 {

class FieldListConverter {
    FieldListConverter();
    static FieldListConverter singleton;
 public:
    static const IR::Node *convertFieldList(const IR::Node *);
};

}  // namespace P4V1

#endif /* EXTENSIONS_BF_P4C_ARCH_FROMV1_0_FIELD_LIST_H_ */
