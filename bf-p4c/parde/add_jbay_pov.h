#ifndef BF_P4C_PARDE_ADD_JBAY_POV_H_
#define BF_P4C_PARDE_ADD_JBAY_POV_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"


/**@brief Create POV bits for JBay output metadata
 *
 * JBay requires POV bits to control output metadata as implicit PHV valid bits
 * are gone.  We create a single POV bit for each metadata in use and set the bit
 * whenever the metadata is set.
 */

class AddJBayMetadataPOV : public Transform {
    const PhvInfo &phv;
    const IR::BFN::Deparser *dp;
    bool equiv(const IR::Expression *a, const IR::Expression *b) {
        if (auto field = phv.field(a))
            return field == phv.field(b);
        return false; }
    IR::BFN::Pipe *preorder(IR::BFN::Pipe *pipe) override {
        prune();
        for (auto &t : pipe->thread) {
            visit(t.deparser);
            dp = t.deparser;
            visit(t.parser);
            visit(t.mau); }
        return pipe; }
    IR::BFN::DeparserIntrinsic *postorder(IR::BFN::DeparserIntrinsic *di) override {
        di->povBit = new IR::TempVar(IR::Type::Bits::get(1), true);
        return di; }
    IR::Node *postorder(IR::Primitive *p) override {
        if (p->name == "modify_field") {
            auto *dest = p->operands.at(0);
            for (auto &el : dp->metadata) {
                if (equiv(dest, el.second->value)) {
                    return new IR::Vector<IR::Primitive>({ p,
                        new IR::Primitive("modify_field", el.second->povBit,
                            new IR::Constant(IR::Type::Bits::get(1), 1)) }); } } }
        return p; }
    IR::Node *postorder(IR::BFN::Extract *e) override {
        for (auto &el : dp->metadata) {
            if (equiv(e->dest, el.second->value)) {
                return new IR::Vector<IR::BFN::ParserPrimitive>({ e,
                    new IR::BFN::ExtractConstant(el.second->povBit,
                        new IR::Constant(IR::Type::Bits::get(1), 1)) }); } }
        return e; }

 public:
    explicit AddJBayMetadataPOV(PhvInfo &p) : phv(p) {}
};

#endif /* BF_P4C_PARDE_ADD_JBAY_POV_H_ */
