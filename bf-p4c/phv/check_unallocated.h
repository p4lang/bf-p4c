#ifndef BF_P4C_PHV_CHECK_UNALLOCATED_H_
#define BF_P4C_PHV_CHECK_UNALLOCATED_H_

#include "ir/ir.h"
#include "bf-p4c/phv/check_fitting.h"

/** Until we support backtracking, all fields (including temporary fields) must
 * be created before PHV allocation.  This pass checks for fields that may have
 * been created afterwards and do not have a PHV allocation.
 */
class CheckForUnallocatedTemps : public PassManager {
    struct RejectTemps : public Inspector {
        const PhvInfo& phv;
        const PhvUse &uses;

        RejectTemps(const PhvInfo& phv, const PhvUse &uses) : phv(phv), uses(uses) { }
        const IR::Node *apply_visitor(const IR::Node *n, const char *name = 0) override {
            if (name)
                LOG1(name);

            ordered_set<PHV::Field *> unallocated =
                CheckFitting::collect_unallocated_fields(phv, uses);
            if (unallocated.size()) {
                BUG("Fields added after PHV allocation");
                for (auto f : unallocated)
                    BUG("%1%", f->name); }

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
    CheckForUnallocatedTemps(const PhvInfo &phv, PhvUse &uses) {
        addPasses({
            &uses,
            new RejectTemps(phv, uses) });
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
