#ifndef BF_P4C_PHV_VALIDATE_ALLOCATION_H_
#define BF_P4C_PHV_VALIDATE_ALLOCATION_H_

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
    ValidateAllocation(PhvInfo& phv, const ClotInfo& clot, ordered_set<cstring>& f)
        : phv(phv), clot(clot), doNotPrivatize(f) { }

 private:
    PhvInfo& phv;
    const ClotInfo& clot;

    SymBitMatrix mutually_exclusive_field_ids;
    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::Digest* digest) override;
    bool preorder(const IR::BFN::Pipe* pipe) override;

    /// List of all privatized fields that cause PHV allocation to fail; grows monotonically every
    /// time PHV allocation fails because of privatization, until every privatizable field is
    /// included.
    ordered_set<cstring>& doNotPrivatize;

    /// Checks if privatization needs to be rolled back and chooses one of two mechanisms
    /// (replacement of uses of privatized fields or backtracking) to roll it back.
    void checkAndThrowPrivatizeException(
            const std::map<PHV::Container, std::vector<PHV::AllocSlice>>& allocations) const;

    /// returns true if a backtrack exception must be thrown, instead of invoking UndoPrivatization.
    bool throwBacktrackException(
            const std::map<PHV::Container, std::vector<PHV::AllocSlice>>& allocations) const;

    /// returns total number of container bits used for POV bit allocation in @gress.
    size_t getPOVContainerBytes(gress_t gress) const;
};

}  // namespace PHV

#endif /* BF_P4C_PHV_VALIDATE_ALLOCATION_H_ */