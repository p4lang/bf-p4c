#ifndef BF_P4C_PHV_VALIDATE_ALLOCATION_H_
#define BF_P4C_PHV_VALIDATE_ALLOCATION_H_

#include "ir/visitor.h"
#include "bf-p4c/phv/phv_fields.h"

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
    explicit ValidateAllocation(PhvInfo& phv) : phv(phv) { }

 private:
    PhvInfo& phv;
    bool preorder(const IR::BFN::Pipe* pipe) override;
};

}  // namespace PHV

#endif /* BF_P4C_PHV_VALIDATE_ALLOCATION_H_ */
