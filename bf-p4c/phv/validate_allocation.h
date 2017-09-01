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

#ifndef TOFINO_PHV_VALIDATE_ALLOCATION_H_
#define TOFINO_PHV_VALIDATE_ALLOCATION_H_

#include "ir/visitor.h"
#include "tofino/phv/phv_fields.h"

namespace PHV {

/**
 * Validates that the PHV allocation represented by a PhvInfo object is
 * consistent with the input program and with Tofino hardware constraints.
 *
 * Some of the things this pass verifies:
 *  - Are containers correctly split between threads?
 *  - Are any PHV bits allocated to unused fields?
 *  - Are any field bits allocated more than once?
 *  - Does the allocation allow fields to be deparsed correctly?
 *
 * See the implementation for the full list of checks performed. If any problems
 * are found, they are reported as errors.
 */
class ValidateAllocation final : public Inspector {
 public:
    explicit ValidateAllocation(PhvInfo& phv, bool ignorePHVOverflow = false)
      : phv(phv), ignorePHVOverflow(ignorePHVOverflow) { }

 private:
    PhvInfo& phv;
    bool ignorePHVOverflow;

    bool preorder(const IR::Tofino::Pipe* pipe) override;
};

}  // namespace PHV

#endif /* TOFINO_PHV_VALIDATE_ALLOCATION_H_ */
