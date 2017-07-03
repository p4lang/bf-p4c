#include "frontend.h"
#include "frontends/p4-14/typecheck.h"

const IR::Type_Extern *Tofino::ExternConverter::convertExternType(
        const IR::Type_Extern *ext, cstring name) {
    if (ext->name == "stateful_alu") {
        if (!has_stateful_alu) {
            has_stateful_alu = true;
            structure->include("tofino/stateful_alu.p4");
        }
        return nullptr;
    } else {
        warning("Unrecognized extern_type %s", ext); }
    return P4V1::ExternConverter::convertExternType(ext, name);
}

class CreateSaluApplyFunction : public Inspector {
    const IR::Type *rtype;
    const IR::Type::Bits *utype;
    IR::BlockStatement *body;
    const IR::Expression *cond_lo = nullptr;
    const IR::Expression *cond_hi = nullptr;
    const IR::Expression *pred = nullptr;
    const IR::Statement *output = nullptr;
    enum expr_index_t { LO1, LO2, HI1, HI2, OUT } expr_index;
    bool defer_out = false;
    bool need_alu_hi = false;
    PassManager rewrite;

    IR::Expression *makeRegFieldMember(IR::Expression *e, int idx) {
        if (auto st = rtype->to<IR::Type_Struct>()) {
            for (auto f : st->fields)
                if (--idx < 0)
                    return new IR::Member(e, f->name);
            idx = 1; }
        if (idx > 0) {
            need_alu_hi = true;
            e = new IR::PathExpression(utype, new IR::Path("alu_hi")); }
        return e; }

    class RewriteExpr : public Transform {
        CreateSaluApplyFunction &self;
        const IR::Expression *preorder(IR::Cast *c) override {
            if (c->expr->is<IR::AttribLocal>()) return c->expr;
            return c; };
        const IR::Expression *preorder(IR::Constant *c) override {
            // re-infer the types of all constants from context, as it may have changed
            // FIXME -- probably only want this for constants that did not have an explicit
            // FIXME -- type originally, but we have no good way of knowing.
            // If we fix P4_14 typechecking to understand externs, need for this goes away
            c->type = new IR::Type_InfInt;
            return c; }
        const IR::Expression *postorder(IR::AttribLocal *attr) override {
            int idx = 0;
            if (attr->name == "condition_lo") {
                BUG_CHECK(self.cond_lo, "condition_lo not specified");
                return self.cond_lo;
            } else if (attr->name == "condition_hi") {
                BUG_CHECK(self.cond_hi, "condition_hi not specified");
                return self.cond_hi;
            } else if (attr->name == "register_lo") {
                idx = 0;
            } else if (attr->name == "register_hi") {
                idx = 1;
            } else if (attr->name == "alu_lo") {
                idx = 0;
                self.defer_out = true;
            } else if (attr->name == "alu_hi") {
                idx = 1;
                self.defer_out = true;
            } else {
                BUG("Unrecognized AttribLocal %s", attr);
                return attr; }
            return self.makeRegFieldMember(
                    new IR::PathExpression(attr->srcInfo, self.utype, new IR::Path("value")),
                    idx); }

     public:
        explicit RewriteExpr(CreateSaluApplyFunction &self) : self(self) {}
    };

    bool preorder(const IR::Property *prop) {
        // DANGER -- we rely on the fact that we use a map (not ordered_map) for
        // properties, so they will always be processed in alphabetic order.
        LOG4("CreateSaluApply visiting prop " << prop);
        bool predicate = false;
        int idx = 0;
        if (prop->name == "condition_hi") {
            cond_hi = prop->value->to<IR::ExpressionValue>()->expression->apply(rewrite);
            return false;
        } else if (prop->name == "condition_lo") {
            cond_lo = prop->value->to<IR::ExpressionValue>()->expression->apply(rewrite);
            return false;
        } else if (prop->name == "update_lo_1_predicate") {
            expr_index = LO1;
            predicate = true;
        } else if (prop->name == "update_lo_2_predicate") {
            expr_index = LO2;
            predicate = true;
        } else if (prop->name == "update_hi_1_predicate") {
            expr_index = HI1;
            predicate = true;
        } else if (prop->name == "update_hi_2_predicate") {
            expr_index = HI2;
            predicate = true;
        } else if (prop->name == "output_predicate") {
            expr_index = OUT;
            predicate = true;
        } else if (prop->name == "update_lo_1_value") {
            if (expr_index != LO1) pred = nullptr;
            idx = 0;
        } else if (prop->name == "update_lo_2_value") {
            if (expr_index != LO2) pred = nullptr;
            idx = 0;
        } else if (prop->name == "update_hi_1_value") {
            if (expr_index != HI1) pred = nullptr;
            idx = 1;
        } else if (prop->name == "update_hi_2_value") {
            if (expr_index != HI2) pred = nullptr;
            idx = 1;
        } else if (prop->name == "output_value") {
            if (expr_index != OUT) pred = nullptr;
            idx = -1;
        } else {
            return false; }
        auto e = prop->value->to<IR::ExpressionValue>()->expression->apply(rewrite);
        if (predicate) {
            pred = e;
            return false; }
        IR::Expression *dest = new IR::PathExpression(utype,
                new IR::Path(idx < 0 ? "rv" : "value"));
        if (idx >= 0)
            dest = makeRegFieldMember(dest, idx);
        IR::Statement *instr = new IR::AssignmentStatement(prop->srcInfo, dest, e);
        LOG2("adding " << instr << " with pred " << pred);
        if (pred)
            instr = new IR::IfStatement(pred, instr, nullptr);
        if (idx < 0 && defer_out)
            output = instr;
        else
            body->push_back(instr);
        return false; }

 public:
    IR::Function *apply;
    CreateSaluApplyFunction(const IR::Type *rtype, const IR::Type::Bits *utype)
    : rtype(rtype), utype(utype), rewrite({ new RewriteExpr(*this), new TypeCheck }) {
        body = new IR::BlockStatement;
        apply = new IR::Function("apply", new IR::Type_Method(
                                 IR::Type_Void::get(), new IR::ParameterList({
                                     new IR::Parameter("value", IR::Direction::InOut, rtype),
                                     new IR::Parameter("rv", IR::Direction::Out, utype) })),
                                 body);
    }
    void end_apply(const IR::Node *) {
        if (need_alu_hi)
            body->components.insert(body->components.begin(),
                                    new IR::Declaration_Variable("alu_hi", utype));
        if (output && defer_out)
            body->push_back(output);
    }
};

/* FIXME -- still need to deal with the following stateful_alu properties:
        initial_register_hi_value initial_register_lo_value
        math_unit_exponent_invert math_unit_exponent_shift math_unit_input
        math_unit_lookup_table math_unit_output_scale
        reduction_or_group
        selector_binding
        stateful_logging_mode
*/

Tofino::ExternConverter::reg_info Tofino::ExternConverter::getRegInfo(
        const IR::Declaration_Instance *ext) {
    reg_info rv;
    if (auto rp = ext->properties.get<IR::Property>("reg")) {
        auto rpv = rp->value->to<IR::ExpressionValue>();
        auto gref = rpv ? rpv->expression->to<IR::GlobalRef>() : nullptr;
        if ((rv.reg = gref ? gref->obj->to<IR::Register>() : nullptr)) {
            if (rv.reg->layout) {
                rv.rtype = structure->types.get(rv.reg->layout);
                if (!rv.rtype) {
                    error("No type named %s", rv.reg->layout);
                } else if (auto st = rv.rtype->to<IR::Type_Struct>()) {
                    auto nfields = st->fields.size();
                    if (nfields < 1 || nfields > 2 ||
                        !(rv.utype = st->fields.at(0)->type->to<IR::Type::Bits>()) ||
                        (nfields > 1 && rv.utype != st->fields.at(1)->type))
                        rv.utype = nullptr;
                    if (!rv.utype)
                        error("%s not a valid register layout for stateful_alu", rv.reg->layout);
                } else {
                    error("%s is not a struct type", rv.reg->layout);
                }
            } else if (rv.reg->width == 1 || rv.reg->width == 8 ||
                       rv.reg->width == 16 || rv.reg->width == 32) {
                rv.rtype = rv.utype = IR::Type::Bits::get(rv.reg->width, rv.reg->signed_);
            } else if (rv.reg->width == 64) {
                // Some (broken?) test programs use width 64 when they really mean 2x32
                rv.utype = IR::Type::Bits::get(32, rv.reg->signed_);
                rv.rtype = new IR::Type_Struct(IR::ID(ext->name + "_layout"), {
                    new IR::StructField("lo", rv.utype),
                    new IR::StructField("hi", rv.utype) });
            } else {
                error("register %s width %d not supported for stateful_alu", rv.reg, rv.reg->width);
            }
        } else {
            error("%s reg property %s not a register", ext->name, rp);
        }
    } else {
        error("No reg property in %s", ext);
    }
    return rv;
}

const IR::Declaration_Instance *Tofino::ExternConverter::convertExternInstance(
        const IR::Declaration_Instance *ext, cstring name) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et, "Extern %s is not extern type, but %s", ext, ext->type);
    if (et->name == "stateful_alu") {
        auto info = getRegInfo(ext);
        if (info.utype) {
            LOG2("Creating apply function for register_action " << ext->name);
            auto ratype = new IR::Type_Specialized(new IR::Type_Name("register_action"),
                                   new IR::Vector<IR::Type>({ info.rtype, info.utype }));
            auto *block = new IR::BlockStatement;
            auto *rv = new IR::Declaration_Instance(name, ratype,
                new IR::Vector<IR::Expression>({
                    new IR::PathExpression(new IR::Path(info.reg->name)) }),
                block);
            CreateSaluApplyFunction create_apply(info.rtype, info.utype);
            ext->apply(create_apply);
            block->components.push_back(create_apply.apply);
            return rv->apply(P4V1::TypeConverter(structure))->to<IR::Declaration_Instance>();
        }
    }
    return P4V1::ExternConverter::convertExternInstance(ext, name);
}

const IR::Statement *Tofino::ExternConverter::convertExternCall(
        const IR::Declaration_Instance *ext, const IR::Primitive *prim) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et, "Extern %s is not extern type, but %s", ext, ext->type);
    if (et->name == "stateful_alu") {
        auto info = getRegInfo(ext);
        BUG_CHECK(prim->name == "execute_stateful_alu",
                  "Unknown method %s in stateful_alu", prim->name);
        P4V1::ExpressionConverter conv(structure);
        auto extref = new IR::PathExpression(structure->externs.get(ext));
        auto method = new IR::Member(prim->srcInfo, extref, "execute");
        auto args = new IR::Vector<IR::Expression>();
        for (unsigned i = 1; i < prim->operands.size(); ++i)
            args->push_back(conv.convert(prim->operands.at(i)));
        auto mc = new IR::MethodCallExpression(prim->srcInfo, info.utype, method, args);
        if (auto prop = ext->properties.get<IR::Property>("output_dst")) {
            if (auto ev = prop->value->to<IR::ExpressionValue>()) {
                return structure->assign(prim->srcInfo, conv.convert(ev->expression), mc,
                                         ev->expression->type);
            } else {
                error("%s: output_dst property is not an expression", prop->value->srcInfo); }
        } else {
            return new IR::MethodCallStatement(prim->srcInfo, mc); }
    }
    return P4V1::ExternConverter::convertExternCall(ext, prim);
}
