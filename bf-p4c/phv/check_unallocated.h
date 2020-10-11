#ifndef BF_P4C_PHV_CHECK_UNALLOCATED_H_
#define BF_P4C_PHV_CHECK_UNALLOCATED_H_

#include <sstream>
#include "ir/ir.h"
#include "bf-p4c/mau/table_placement.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_analysis.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"

/** If any fields (tempvars) were created after PHV allocation, we need to rerun
 * allocation from scratch (currently) to get those field allocated.  It would be
 * be better to do incremental allocation.
 */
class CheckForUnallocatedTemps : public PassManager {
    const PhvInfo &phv;
    const PhvUse &uses;
    const ClotInfo &clot;
    ordered_set<PHV::Field*> unallocated_fields;

    /** Produce the set of fields that are not fully allocated to PHV containers.
     */
    void collect_unallocated_fields() {
        unallocated_fields.clear();
        for (auto& field : phv) {
            if (!uses.is_referenced(&field))
                continue;

            if (clot.fully_allocated(&field))
                continue;

            // XXX(hanw): padding does not need phv allocation
            if (field.is_ignore_alloc())
                continue;

            // If this field is an alias source, then we need to check the allocation of the alias
            // destination too. If that destination is allocated to CLOTs, we will not find an
            // allocation for that field here. So, we need a special check here.
            auto* aliasDest = phv.getAliasDestination(&field);
            if (aliasDest != nullptr)
                if (clot.fully_allocated(aliasDest)) continue;

            bitvec allocatedBits;
            field.foreach_alloc([&](const PHV::AllocSlice& slice) {
                bitvec sliceBits(slice.field_slice().lo, slice.width());
                allocatedBits |= sliceBits;
            });

            // Account for bits allocated to CLOTs, both for this field and for its alias (if any).
            for (auto f : (const PHV::Field*[2]) {&field, aliasDest}) {
                if (!f) continue;
                for (auto entry : *clot.slice_clots(f)) {
                    auto slice = entry.first;
                    auto range = slice->range();
                    bitvec sliceBits(range.lo, range.size());
                    allocatedBits |= sliceBits;
                }
            }

            bitvec allBitsInField(0, field.size);
            if (allocatedBits != allBitsInField) unallocated_fields.insert(&field);
        }
    }

 public:
    CheckForUnallocatedTemps(const PhvInfo &phv, PhvUse &uses, const ClotInfo& clot,
                             PHV_AnalysisPass *phv_alloc)
    : phv(phv), uses(uses), clot(clot) {
        addPasses({
            &uses,
            new VisitFunctor([this]() { collect_unallocated_fields(); }),
            new PassIf([this]() { return !unallocated_fields.empty(); }, {
                phv_alloc,
                new VisitFunctor([]() { throw TablePlacement::RedoTablePlacement(); })
            })
        });
    }
};

/** XXX(cole): At some point in the backend, all operations should be converted
 * to ALU instructions or SALU instructions---that is, other kinds of
 * IR::Operation should no longer be present.  This is not currently true for
 * the following reasons:
 *
 * - SALU instructions can perform limited operations on their final operand,
 *   such as negation.  This is encoded as a unary operation on a register.
 * - Equality operators persist in gateways after GatewayOpt.
 */
struct CheckForNonprimitiveOperations : public Inspector {
    bool preorder(const IR::Member *) override { return false; }
    bool preorder(const IR::MAU::Primitive *) override { return false; }

    bool preorder(const IR::Operation_Unary *op) override {
        dump(op);
        BUG("Unary operator present after instruction selection: %1%", op->toString());
    }

    bool preorder(const IR::Operation_Binary *op) override {
        dump(op);
        BUG("Binary operator present after instruction selection: %1%", op->toString());
    }

    bool preorder(const IR::Operation_Ternary *op) override {
        dump(op);
        BUG("Ternary operator present after instruction selection: %1%", op->toString());
    }

    bool preorder(const IR::Operation *op) override {
        dump(op);
        BUG("Nonprimitive operator present after instruction selection: %1%", op->toString());
    }
};



#endif /* BF_P4C_PHV_CHECK_UNALLOCATED_H_ */
