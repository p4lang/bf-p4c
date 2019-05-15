#ifndef BF_P4C_PHV_CHECK_UNALLOCATED_H_
#define BF_P4C_PHV_CHECK_UNALLOCATED_H_

#include <sstream>
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"

/** Until we support backtracking, all fields (including temporary fields) must
 * be created before PHV allocation.  This pass checks for fields that may have
 * been created afterwards and do not have a PHV allocation.
 */
class CheckForUnallocatedTemps : public PassManager {
    /** Produce the set of fields that are not fully allocated to PHV containers.
     *
     * @param unallocated Unallocated fields are added to this set.
     */
    static ordered_set<PHV::Field *>
    collect_unallocated_fields(const PhvInfo &phv, const PhvUse &uses, const ClotInfo& clot) {
        ordered_set<PHV::Field*> unallocated;

        for (auto& field : phv) {
            if (!uses.is_referenced(&field))
                continue;

            if (clot.allocated(&field))
                continue;

            // XXX(hanw): padding does not need phv allocation
            if (field.is_ignore_alloc())
                continue;

            // If this field is an alias source, then we need to check the allocation of the alias
            // destination too. If that destination is allocated to CLOTs, we will not find an
            // allocation for that field here. So, we need a special check here.
            auto* aliasDest = phv.getAliasDestination(&field);
            if (aliasDest != nullptr)
                if (clot.allocated(aliasDest)) continue;

            bitvec allocatedBits;
            field.foreach_alloc([&](const PHV::Field::alloc_slice& slice) {
                bitvec sliceBits(slice.field_bit, slice.width);
                allocatedBits |= sliceBits; });

            bitvec allBitsInField(0, field.size);
            if (allocatedBits != allBitsInField) unallocated.insert(&field);
        }

        return unallocated;
    }

    struct RejectTemps : public Inspector {
        const PhvInfo &phv;
        const PhvUse &uses;
        const ClotInfo &clot;

        RejectTemps(const PhvInfo& phv, const PhvUse &uses, const ClotInfo& clot) :
            phv(phv), uses(uses), clot(clot) { }

        const IR::Node *apply_visitor(const IR::Node *n, const char *name = 0) override {
            if (name)
                LOG1(name);

            ordered_set<PHV::Field *> unallocated = collect_unallocated_fields(phv, uses, clot);
            if (unallocated.size()) {
                std::stringstream ss;
                for (auto* f : unallocated)
                    ss << f << std::endl;
                BUG("Fields added after PHV allocation:\n%1%", ss.str()); }

            return n;
        }

        bool preorder(const IR::Member *e) override {
            if (!phv.field(e))
                BUG("Field added after PHV allocation: %1%", e->toString());
            return false;
        }

        bool preorder(const IR::TempVar *v) override {
            if (!phv.field(v))
                BUG("TempVar added after PHV allocation: %1%", v->toString());
            return false;
        }
    };

 public:
    CheckForUnallocatedTemps(const PhvInfo &phv, PhvUse &uses, const ClotInfo& clot) {
        addPasses({
            &uses,
            new RejectTemps(phv, uses, clot) });
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
    bool preorder(const IR::Primitive *) override { return false; }

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
