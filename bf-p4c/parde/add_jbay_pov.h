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
            dp = t.deparser->to<IR::BFN::Deparser>();
            parallel_visit(t.parsers);
            visit(t.mau); }
        return pipe; }
    IR::BFN::DeparserParameter *
    postorder(IR::BFN::DeparserParameter *param) override {
        param->povBit =
          new IR::BFN::FieldLVal(new IR::TempVar(IR::Type::Bits::get(1), true,
                                                 param->source->field->toString() + ".$valid"));
        return param; }
    IR::BFN::Digest *
    postorder(IR::BFN::Digest *digest) override {
        if (!digest->selector)
            return digest;
        digest->povBit =
          new IR::BFN::FieldLVal(new IR::TempVar(IR::Type::Bits::get(1), true,
                                                 digest->selector->field->toString() + ".$valid"));
        return digest; }
    static IR::Primitive* create_pov_write(const IR::Expression *povBit, bool validate) {
        return new IR::Primitive("modify_field", povBit,
            new IR::Constant(IR::Type::Bits::get(1), (unsigned)validate));
    }
    IR::Node* insert_deparser_param_pov_write(const IR::Primitive* p, bool validate) {
        auto *dest = p->operands.at(0);
        for (auto* param : dp->params) {
            if (equiv(dest, param->source->field)) {
                auto pov_write = create_pov_write(param->povBit->field, validate);
                if (validate)
                    return new IR::Vector<IR::Primitive>({ p, pov_write });
                else
                    return pov_write;
            }
        }
        return nullptr;
    }
    IR::Node* insert_deparser_digest_pov_write(const IR::Primitive* p, bool validate) {
        auto *dest = p->operands.at(0);
        for (auto& item : dp->digests) {
            auto* digest = item.second;
            if (equiv(dest, digest->selector->field)) {
                auto pov_write = create_pov_write(digest->povBit->field, validate);
                if (validate)
                    return new IR::Vector<IR::Primitive>({ p, pov_write });
                else
                    return pov_write;
            }
        }
        return nullptr;
    }
    IR::Node *postorder(IR::Primitive *p) override {
        if (p->name == "modify_field") {
            if (auto rv = insert_deparser_param_pov_write(p, true))
                return rv;
            if (auto rv = insert_deparser_digest_pov_write(p, true))
                return rv;
        } else if (p->name == "invalidate") {
            if (auto rv = insert_deparser_param_pov_write(p, false))
                return rv;
            if (auto rv = insert_deparser_digest_pov_write(p, false))
                return rv;
        }
        return p; }
    IR::Node *postorder(IR::BFN::Extract *e) override {
        for (auto* param : dp->params) {
            if (auto lval = e->dest->to<IR::BFN::FieldLVal>()) {
                if (equiv(lval->field, param->source->field))
                    return new IR::Vector<IR::BFN::ParserPrimitive>({ e,
                        new IR::BFN::Extract(param->povBit,
                                         new IR::BFN::ConstantRVal(1))
                    }); } }
        return e; }

 public:
    explicit AddJBayMetadataPOV(PhvInfo &p) : phv(p) {}
};

#endif /* BF_P4C_PARDE_ADD_JBAY_POV_H_ */
