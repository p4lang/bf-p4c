/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "bf-p4c/common/check_header_alignment.h"
#include "bf-p4c/common/machine_description.h"
#include "frontends/p4/typeMap.h"

#include "ir/ir.h"

namespace BFN {

bool CheckHeaderAlignment::preorder(const IR::Type_Header* header) {
    auto canonicalType = typeMap->getTypeType(header, true);
    ERROR_CHECK(canonicalType->width_bits() % 8 == 0,
                "%1% requires byte-aligned headers, but header %2% is not "
                "byte-aligned", Description::ModelName, header->name);
    return false;
}

}  // namespace BFN
