#ifndef TOFINO_PARDE_DIGEST_H_
#define TOFINO_PARDE_DIGEST_H_

#include "ir/ir.h"
#include "tofino/ir/thread_visitor.h"

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
    IR::Tofino::Digest *learn = nullptr;
    IR::Tofino::Digest *mirror = nullptr;
    IR::TempVar *mirror_id = nullptr;
    gress_t mirror_id_gress = INGRESS;

    IR::Primitive *add_to_digest(IR::Tofino::Digest *&digest, const char *name,
                                 const IR::Expression *expr) {
        if (!digest) digest = new IR::Tofino::Digest(VisitingThread(this), name);
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
            return add_to_digest(learn, "learning", prim->operands[1]);
        } else if (prim->name == "clone" || prim->name == "clone3") {
            LOG2("clone:" << prim);
            auto m = prim->operands[0]->to<IR::Member>();
            if (!m || (m->member != "I2E" && m->member != "E2E"))
                BUG("Invalid clone type %s", prim->operands[0]);
            if (VisitingThread(this) == INGRESS && m->member == "E2E")
                error("%s: clone E2E not allowed in ingress pipe", prim->srcInfo);
            if (VisitingThread(this) == EGRESS && m->member == "I2E")
                error("%s: clone I2E not allowed in egress pipe", prim->srcInfo);
            // need $mirror_id for ingress and another for egress
            if (!mirror_id || mirror_id_gress != VisitingThread(this)) {
                std::string name = cstring::to_cstring(VisitingThread(this)) + "::" + "$mirror_id";
                mirror_id = new IR::TempVar(IR::Type::Bits::get(10), name.c_str());
                mirror_id_gress = VisitingThread(this);
            }
            auto list = prim->operands.size() > 2 ? prim->operands[2] : nullptr;
            auto rv = new IR::Vector<IR::Primitive>;
            rv->push_back(new IR::Primitive("modify_field", mirror_id, prim->operands[1]));
            rv->push_back(add_to_digest(mirror, "mirror", list));
            auto l = mirror->sets.back()->clone();
            l->insert(l->begin(), mirror_id);  // insert $mirror_id in every field list
            mirror->sets.back() = l;
            return rv; }
        return prim; }
    IR::Tofino::Deparser *postorder(IR::Tofino::Deparser *dp) override {
        if (learn) {
            dp->digests.addUnique(learn->name, learn);
            learn = nullptr; }
        if (mirror) {
            dp->digests.addUnique(mirror->name, mirror);
            mirror = nullptr; }
        return dp; }
};

#endif /* TOFINO_PARDE_DIGEST_H_ */
