#ifndef BF_P4C_PARDE_DIGEST_H_
#define BF_P4C_PARDE_DIGEST_H_

#include "ir/ir.h"
#include "bf-p4c/ir/thread_visitor.h"

/** Convert various primitves that need deparser digests into deparser digests + whatever
 * setup is needed to enable those digests.
 */
class Digests : public Transform {
    /* There are potentially two digests created in each thread (actually learn can only be
     * in ingress), so we start each thread with theses being nullptr, and create them on
     * first seeing something that requires the digest.  Then, when we get to the deparser,
     * we put the (nonnull) digests in the deparser, and clear them for the next thread,
     * relying on the fact that the visitor traversal visits the threads in order and visits
     * the deparser after the MAU in each thread.
     */
    IR::BFN::Digest *learn = nullptr;
    IR::BFN::Digest *mirror = nullptr;
    IR::BFN::Digest *resubmit = nullptr;
    IR::TempVar *mirror_id = nullptr;

    IR::Primitive *add_to_digest(IR::BFN::Digest *&digest, const char *name,
                                 const IR::Expression *expr) {
        if (!digest) digest = new IR::BFN::Digest(VisitingThread(this), name);
        auto list = dynamic_cast<const IR::Vector<IR::Expression> *>(expr);
        if (!list) {
            if (auto l = dynamic_cast<const IR::ListExpression *>(expr))
                list = new IR::Vector<IR::Expression>(l->components);
            else if (expr)
                list = new IR::Vector<IR::Expression>({expr});
            else
                list = new IR::Vector<IR::Expression>; }
        digest->sets.push_back(list);
        return new IR::Primitive("modify_field", digest->select,
                                 new IR::Constant(IR::Type::Bits::get(8), digest->sets.size())); }
    IR::Node *postorder(IR::Primitive *prim) override {
        if (prim->name == "digest") {
            LOG2("digest:" << prim);
            if (VisitingThread(this) == EGRESS)
                error("%s: learning not supported in egress", prim->srcInfo);
            // FIXME -- what to do with the digest 'channel' -- prim->operands[0]?
            auto ir_prim = add_to_digest(learn, "learning", prim->operands[1]);
            //
            // learn field list begins with $learning, e.g.,
            // learning:
            //   0: [$learning, meta.bd, meta.ifindex, meta.sa.32-47, meta.sa.16-31, meta.sa.0-15]
            //   select: $learning
            //
            auto l = learn->sets.back()->clone();
            l->insert(l->begin(), learn->select);  // insert $learn in field list
            learn->sets.back() = l;
            return ir_prim;
        } else if (prim->name == "clone" || prim->name == "clone3") {
            LOG2("clone:" << prim);
            auto m = prim->operands[0]->to<IR::Member>();
            if (!m || (m->member != "I2E" && m->member != "E2E"))
                BUG("Invalid clone type %s", prim->operands[0]);
            if (VisitingThread(this) == INGRESS && m->member == "E2E")
                error("%s: clone E2E not allowed in ingress pipe", prim->srcInfo);
            if (VisitingThread(this) == EGRESS && m->member == "I2E")
                error("%s: clone I2E not allowed in egress pipe", prim->srcInfo);
            // need thread local $mirror_id for ingress, egress; CreateThreadLocalInstances will do
            if (!mirror_id)
                mirror_id = new IR::TempVar(IR::Type::Bits::get(10), "$mirror_id");
            auto list = prim->operands.size() > 2 ? prim->operands[2] : nullptr;
            auto rv = new IR::Vector<IR::Primitive>;
            
            // FIXME: Not to Han.  This issue is because the V1model expects the parameter to be
            // 32 bits, when Tofino only has 10 bits for mirror id.  Thus, the converter should
            // guarantee that this argument gets converted properly
            //
            // At the same time, InstructionSelection/ActionAnalysis don't really handle IR::Cast
            // yet, resulting in a conversion from individual IR data structures to the correct
            // type.
            if (prim->operands[1] == nullptr)
                BUG("No action data for setting the mirror id");
            IR::Expression *new_aa = nullptr;
            if (auto *orig_aa = prim->operands[1]->to<IR::ActionArg>()) {
                auto act = findContext<IR::MAU::Action>();
                new_aa = new IR::ActionArg(orig_aa->srcInfo, IR::Type::Bits::get(10), act->name,
                                        orig_aa->name);
            } else if (auto *orig_constant = prim->operands[1]->to<IR::Constant>()) {
                new_aa = new IR::Constant(orig_constant->srcInfo, IR::Type::Bits::get(10),
                                          orig_constant->value);
            } else {
                BUG("Unexpected mirror id: %1%", prim->operands[1]);
            }
            rv->push_back(new IR::Primitive("modify_field", mirror_id, new_aa)); 
            rv->push_back(add_to_digest(mirror, "mirror", list));
            //
            // each field list begins with mirror_id, mirror, ..... e.g.,
            // mirror:
            //   0: [ $mirror_id, $mirror, meta.i2e_0 ]
            //   1: [ $mirror_id, $mirror, meta.i2e_1 ]
            //   .....
            //   7: [ $mirror_id, $mirror, meta.i2e_7.96-127, meta.i2e_7.64-95, .., meta.i2e_7.0-31 ]
            //   select: $mirror
            //
            auto l = mirror->sets.back()->clone();
            l->insert(l->begin(), mirror->select);  // insert $mirror in every field list
            l->insert(l->begin(), mirror_id);       // insert $mirror_id in every field list
            mirror->sets.back() = l;
            return rv;
        } else if (prim->name == "resubmit") {
            LOG2("resbumit:" << prim);
            if (VisitingThread(this) == EGRESS)
                error("%s: resubmit not supported in egress", prim->srcInfo);
            auto ir_prim = add_to_digest(resubmit, "resubmit", prim->operands[0]);
            return ir_prim; }
        return prim; }
    IR::BFN::Deparser *postorder(IR::BFN::Deparser *dp) override {
        if (learn) {
            dp->digests.addUnique(learn->name, learn);
            learn = nullptr; }
        if (mirror) {
            dp->digests.addUnique(mirror->name, mirror);
            mirror = nullptr; }
        if (resubmit) {
            dp->digests.addUnique(resubmit->name, resubmit);
            resubmit = nullptr; }
        return dp; }
};

#endif /* BF_P4C_PARDE_DIGEST_H_ */
