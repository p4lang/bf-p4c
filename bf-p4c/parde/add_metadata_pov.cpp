#include "add_metadata_pov.h"

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"

#if HAVE_FLATROCK
std::map<cstring, std::set<cstring>> AddMetadataPOV::flatrock_dprsr_param_with_pov({
    {
        "ingress_intrinsic_metadata_for_tm_t",
        {
            "mirror_bitmap",    // FIXME: should this be mirror_cos?
            "mcast_grp_a",
            "mcast_grp_b",
            "ucast_egress_port",
        }
    },
});

bool AddMetadataPOV::is_deparser_parameter_with_pov(const IR::BFN::DeparserParameter *param) {
    if (const auto *member = param->source->field->to<IR::Member>()) {
        if (const auto *chr = member->expr->to<IR::ConcreteHeaderRef>()) {
            cstring name = member->member;
            cstring type_name;
            if (const auto *ts = chr->type->to<IR::Type_Struct>())
                type_name = ts->name;
            else if (const auto *th = chr->type->to<IR::Type_Header>())
                type_name = th->name;
            return flatrock_dprsr_param_with_pov.count(type_name) &&
                   flatrock_dprsr_param_with_pov.at(type_name).count(name);
        }
    }
    return false;
}

#endif  /* HAVE_FLATROCK */

bool AddMetadataPOV::equiv(const IR::Expression *a, const IR::Expression *b) {
    if (auto field = phv.field(a)) return field == phv.field(b);
    return false;
}

IR::BFN::Pipe *AddMetadataPOV::preorder(IR::BFN::Pipe *pipe) {
    prune();
    for (auto &t : pipe->thread) {
        visit(t.deparser);
        dp = t.deparser->to<IR::BFN::Deparser>();
        parallel_visit(t.parsers);
        visit(t.mau);
    }
    return pipe;
}

IR::BFN::DeparserParameter *AddMetadataPOV::postorder(IR::BFN::DeparserParameter *param) {
#if HAVE_FLATROCK
    if (Device::currentDevice() == Device::FLATROCK && !is_deparser_parameter_with_pov(param))
        return param;
#endif  /* HAVE_FLATROCK */
    param->povBit = new IR::BFN::FieldLVal(new IR::TempVar(
        IR::Type::Bits::get(1), true, param->source->field->toString() + ".$valid"));
#if HAVE_FLATROCK
    // Flatrock: want to keep the POV bits, even if the field is optimized away
    if (Device::currentDevice() == Device::FLATROCK)
        param->sourceReq = false;
#endif /* HAVE_FLATROCK */
    return param;
}

IR::BFN::Digest *AddMetadataPOV::postorder(IR::BFN::Digest *digest) {
    if (!digest->selector) return digest;
    digest->povBit = new IR::BFN::FieldLVal(new IR::TempVar(
        IR::Type::Bits::get(1), true, digest->selector->field->toString() + ".$valid"));
    return digest;
}

IR::MAU::Primitive *AddMetadataPOV::create_pov_write(const IR::Expression *povBit, bool validate) {
    return new IR::MAU::Primitive("modify_field", povBit,
                                  new IR::Constant(IR::Type::Bits::get(1), (unsigned)validate));
}

IR::Node *AddMetadataPOV::insert_deparser_param_pov_write(const IR::MAU::Primitive *p,
                                                          bool validate) {
    auto *dest = p->operands.at(0);
    for (auto *param : dp->params) {
#if HAVE_FLATROCK
        if (Device::currentDevice() == Device::FLATROCK && !is_deparser_parameter_with_pov(param))
            continue;
#endif
        if (equiv(dest, param->source->field)) {
            auto pov_write = create_pov_write(param->povBit->field, validate);
            if (validate)
                return new IR::Vector<IR::MAU::Primitive>({p, pov_write});
            else
                return pov_write;
        }
    }
    return nullptr;
}

IR::Node *AddMetadataPOV::insert_deparser_digest_pov_write(const IR::MAU::Primitive *p,
                                                           bool validate) {
    auto *dest = p->operands.at(0);
    for (auto &item : dp->digests) {
        auto *digest = item.second;
        if (equiv(dest, digest->selector->field)) {
            auto pov_write = create_pov_write(digest->povBit->field, validate);
            if (validate)
                return new IR::Vector<IR::MAU::Primitive>({p, pov_write});
            else
                return pov_write;
        }
    }
    return nullptr;
}

IR::Node *AddMetadataPOV::postorder(IR::MAU::Primitive *p) {
    if (p->name == "modify_field") {
        if (auto rv = insert_deparser_param_pov_write(p, true)) return rv;
        if (auto rv = insert_deparser_digest_pov_write(p, true)) return rv;
    } else if (p->name == "invalidate") {
        if (auto rv = insert_deparser_param_pov_write(p, false)) return rv;
        if (auto rv = insert_deparser_digest_pov_write(p, false)) return rv;
    }
    return p;
}

IR::Node *AddMetadataPOV::postorder(IR::BFN::Extract *e) {
    for (auto *param : dp->params) {
        if (auto lval = e->dest->to<IR::BFN::FieldLVal>()) {
            if (equiv(lval->field, param->source->field))
                return new IR::Vector<IR::BFN::ParserPrimitive>(
                    {e, new IR::BFN::Extract(param->povBit, new IR::BFN::ConstantRVal(1))});
        }
    }
    return e;
}
