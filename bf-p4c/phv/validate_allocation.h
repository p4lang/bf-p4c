#ifndef BF_P4C_PHV_VALIDATE_ALLOCATION_H_
#define BF_P4C_PHV_VALIDATE_ALLOCATION_H_

#include "bf-p4c/phv/fieldslice_live_range.h"
#include "ir/ir.h"
#include "ir/visitor.h"
#include "lib/symbitmatrix.h"
#include "phv_fields.h"

class PhvInfo;
class ClotInfo;

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
    ValidateAllocation(PhvInfo& phv, const ClotInfo& clot,
                       const PHV::FieldSliceLiveRangeDB& physical_liverange)
        : phv(phv), clot(clot), physical_liverange(physical_liverange) {}

    void set_physical_liverange_overlay(bool enable) { physical_liverange_overlay = enable; }

 private:
    PhvInfo& phv;
    const ClotInfo& clot;
    const PHV::FieldSliceLiveRangeDB& physical_liverange;
    bool physical_liverange_overlay = false;

    SymBitMatrix mutually_exclusive_field_ids;
    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::Digest* digest) override;
    bool preorder(const IR::BFN::Pipe* pipe) override;
    bool preorder(const IR::BFN::DeparserParameter* dp) override;

    /// @returns total number of container bits used for POV bit allocation in @p gress.
    size_t getPOVContainerBytes(gress_t gress) const;
};

}  // namespace PHV

#endif /* BF_P4C_PHV_VALIDATE_ALLOCATION_H_ */
