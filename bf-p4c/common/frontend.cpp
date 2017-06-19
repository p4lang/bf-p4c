#include "frontend.h"
#include "frontends/p4-14/typecheck.h"

const IR::Type_Extern *Tofino::ExternConverter::convertExternType(
        const IR::Type_Extern *ext, cstring name) {
    if (ext->name == "stateful_alu") {
        if (!has_stateful_alu) {
            has_stateful_alu = true;
            structure->include("tofino/stateful_alu.p4");
        }
        name = "stateful_alu_14";
    } else {
        warning("Unrecognized extern_type %s", ext); }
    return P4V1::ExternConverter::convertExternType(ext, name);
}

class InsertSaluRegCasts : public Transform {
    const IR::Type *regtype;
    const IR::Node *postorder(IR::AttribLocal *l) {
        if (l->name == "register_hi" || l->name == "register_lo") {
            return new IR::Cast(regtype, getOriginal<IR::AttribLocal>()); }
        return l;
    }
    const IR::Node *postorder(IR::Constant *c) {
        // re-infer the types of all constants from context, as it may have changed
        // FIXME -- probably only want this for constants that did not have an explicit
        // FIXME -- type originally, but we have no good way of knowing.
        c->type = new IR::Type_InfInt;
        return c; }
 public:
    explicit InsertSaluRegCasts(const IR::Type *rt) : regtype(rt) {}
};

const IR::Declaration_Instance *Tofino::ExternConverter::convertExternInstance(
        const IR::Declaration_Instance *ext, cstring name) {
    auto *clone = ext->clone();
    auto *et = clone->type->to<IR::Type_Extern>();
    BUG_CHECK(et, "Extern %s is not extern type, but %s", ext, ext->type);
    if (structure->extern_remap.count(et))
        et = structure->extern_remap.at(et);
    clone->name = name;
    clone->type = new IR::Type_Name(new IR::Path(structure->extern_types.get(et)));
    const IR::Node *rv = clone;
    if (et->name == "stateful_alu_14") {
        const IR::Type::Bits *utype = nullptr;
        bool dual = false;
        if (auto rp = clone->properties.get<IR::Property>("reg")) {
            auto rpv = rp->value->to<IR::ExpressionValue>();
            auto gref = rpv ? rpv->expression->to<IR::GlobalRef>() : nullptr;
            if (auto reg = gref ? gref->obj->to<IR::Register>() : nullptr) {
                if (reg->layout) {
                    auto *layout = structure->types.get(reg->layout);
                    if (!layout) {
                        error("No type named %s", reg->layout);
                    } else if (auto st = layout->to<IR::Type_Struct>()) {
                        auto nfields = st->fields.size();
                        if (nfields < 1 || nfields > 2 ||
                            !(utype = st->fields.at(0)->type->to<IR::Type::Bits>()) ||
                            (nfields > 1 && utype != st->fields.at(1)->type))
                            utype = nullptr;
                        if (!utype)
                            error("%s not a valid register layout for stateful_alu", reg->layout);
                        else if (nfields > 1)
                            dual = true;
                    } else {
                        error("%s is not a struct type", reg->layout);
                    }
                } else if (reg->width == 1 || reg->width == 8 ||
                           reg->width == 16 || reg->width == 32) {
                    utype = IR::Type::Bits::get(reg->width, reg->signed_);
                } else if (reg->width == 64) {
                    // Some (broken?) test programs use width 64 when they really mean 2x32
                    utype = IR::Type::Bits::get(32, reg->signed_);
                    dual = true;
                } else {
                    error("register %s width %d not supported for stateful_alu", reg, reg->width);
                }
            } else {
                error("%s reg property %s not a register", clone->name, rp);
            }
        } else {
            error("No reg property in %s", clone);
        }
        if (utype)
            rv = rv->apply(InsertSaluRegCasts(utype))->apply(TypeCheck());
    }
    return rv->apply(P4V1::TypeConverter(structure))->to<IR::Declaration_Instance>();
}

