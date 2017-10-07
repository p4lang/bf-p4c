#ifndef BF_P4C_PHV_VALIDATE_ALLOCATION_H_
#define BF_P4C_PHV_VALIDATE_ALLOCATION_H_

#include "ir/visitor.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/symbitmatrix.h"

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
    ValidateAllocation(const PhvInfo& phv, const SymBitMatrix& mutually_exclusive_field_ids)
        : phv(phv), mutually_exclusive_field_ids(mutually_exclusive_field_ids) { }

 private:
    const PhvInfo& phv;
    const SymBitMatrix& mutually_exclusive_field_ids;
    bool preorder(const IR::BFN::Pipe* pipe) override;
};

class ValidateActions final : public MauInspector {
 private:
    const PhvInfo &phv;
    bool stop_compiler;
    bool phv_alloc;
    bool ad_alloc;
    bool warning_found = false;
    bool preorder(const IR::MAU::Action *act) override;
    void end_apply() override;

 public:
    explicit ValidateActions(const PhvInfo &p, bool sc, bool pa, bool ad)
        : phv(p), stop_compiler(sc), phv_alloc(pa), ad_alloc(ad) {}
};

}  // namespace PHV

#endif /* BF_P4C_PHV_VALIDATE_ALLOCATION_H_ */
