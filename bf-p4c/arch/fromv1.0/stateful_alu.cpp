#include "stateful_alu.h"
#include "frontends/p4-14/typecheck.h"
#include "lib/bitops.h"
#include "programStructure.h"

P4V1::StatefulAluConverter::StatefulAluConverter() {
    addConverter("stateful_alu", this);
}

const IR::Type_Extern *P4V1::StatefulAluConverter::convertExternType(
    P4V1::ProgramStructure *structure, const IR::Type_Extern *, cstring) {
    if (!has_stateful_alu) {
        has_stateful_alu = true;
        structure->include("tofino/stateful_alu.p4"); }
    return nullptr;
}

class CreateSaluApplyFunction : public Inspector {
    // These annotations will be put on the RegisterAction instance that will be
    // created to contain the apply function being created by this inspector
    IR::Annotations *annots = nullptr;
    P4V1::ProgramStructure *structure;
    const IR::Type *rtype;
    const IR::Type::Bits *utype;
    cstring math_unit_name;
    IR::BlockStatement *body;
    IR::Function *apply = nullptr;
    const IR::Expression *cond_lo = nullptr;
    const IR::Expression *cond_hi = nullptr;
    const IR::Expression *math_input = nullptr;
    const IR::Expression *pred = nullptr;
    const IR::Statement *output = nullptr;
    const Util::SourceInfo *applyLoc;
    enum expr_index_t { LO1, LO2, HI1, HI2, OUT } expr_index;
    bool saturating = false;
    bool convert_to_saturating = false;
    bool have_output = false;
    bool defer_out = false;
    bool cmpl_out = false;
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
        const IR::Expression *postorder(IR::Add *e) override {
            if (self.convert_to_saturating)
                return new IR::AddSat(e->srcInfo, e->type, e->left, e->right);
            return e; }
        const IR::Expression *postorder(IR::Sub *e) override {
            if (self.convert_to_saturating)
                return new IR::SubSat(e->srcInfo, e->type, e->left, e->right);
            return e; }
        const IR::Expression *postorder(IR::AttribLocal *attr) override {
            int idx = 0;
            IR::Path *var = nullptr;
            if (attr->name == "condition_lo") {
                if (self.cond_lo == nullptr) {
                    ::error("condition_lo used and not specified %s", *self.applyLoc);
                    return new IR::BoolLiteral(false);
                }
                return self.cond_lo;
            } else if (attr->name == "condition_hi") {
                if (self.cond_hi == nullptr) {
                    ::error("condition_hi used and not specified %s", *self.applyLoc);
                    return new IR::BoolLiteral(false);
                }
                return self.cond_hi;
            } else if (attr->name == "register_lo") {
                var = new IR::Path("in_value");
                idx = 0;
            } else if (attr->name == "register_hi") {
                var = new IR::Path("in_value");
                idx = 1;
            } else if (attr->name == "alu_lo") {
                // For complement we use the 'in_value' or input value as the
                // ordering of instructions may change the 'value'
                // E.g. set_bitc creates an action,
                // value = 1;
                // rv = ~value;
                // Due to ordering this gets transformed to
                // value = 1;
                // rv = 0; <- which is incorrect
                // By using in_value, we get,
                // value = 1;
                // rv = ~in_value;
                auto valStr = self.cmpl_out ? "in_value" : "value";
                var = new IR::Path(valStr);
                idx = 0;
                self.defer_out = true;
            } else if (attr->name == "alu_hi") {
                auto valStr = self.cmpl_out ? "in_value" : "value";
                var = new IR::Path(valStr);
                idx = 1;
                self.defer_out = true;
            } else if (attr->name == "set_bit" || attr->name == "set_bitc") {
                if (self.utype->width_bits() != 1)
                    error("%s only allowed in 1 bit registers", attr->name);
                return new IR::Constant(self.utype, 1);
            } else if (attr->name == "clr_bit" || attr->name == "clr_bitc") {
                if (self.utype->width_bits() != 1)
                    error("%s only allowed in 1 bit registers", attr->name);
                return new IR::Constant(self.utype, 0);
            } else if (attr->name == "read_bit" || attr->name == "read_bitc") {
                if (self.utype->width_bits() != 1)
                    error("%s only allowed in 1 bit registers", attr->name);
                idx = 0;
                var = new IR::Path("in_value");
            } else if (attr->name == "math_unit") {
                auto *mu = new IR::PathExpression(IR::ID(attr->srcInfo, self.math_unit_name));
                return new IR::MethodCallExpression(attr->srcInfo,
                        new IR::Member(mu, "execute"), { new IR::Argument(self.math_input) });
            } else if (attr->name == "predicate") {
                // combined_predicate is an 1-bit output equals to condition_lo | condition_hi
                // if any of the condition_lo/hi is true, then the output is 1,
                // otherwise, the output is 0. Therefore, when translating to P4-16 salu externs,
                // the output of the stateful rv is translated to constant one when the condition
                // is true, and zero if not.
                return new IR::Constant(self.utype, 1);
            } else if (attr->name == "combined_predicate") {
                WARN_CHECK(true, "combined_predicate is implemented as a 1-bit "
                        "encoding of condition_hi || condition lo, check uarch documentation "
                        "to verify the correctness");
                return new IR::Constant(self.utype, 1);
            } else {
                error("Unrecognized attribute %s", attr);
                return attr; }
            return self.makeRegFieldMember(
                    new IR::PathExpression(attr->srcInfo, self.rtype, var), idx); }

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
            applyLoc = &prop->value->srcInfo;
            cond_hi = prop->value->to<IR::ExpressionValue>()->expression->apply(rewrite);
            return false;
        } else if (prop->name == "condition_lo") {
            applyLoc = &prop->value->srcInfo;
            cond_lo = prop->value->to<IR::ExpressionValue>()->expression->apply(rewrite);
            return false;
        } else if (prop->name == "math_unit_input") {
            applyLoc = &prop->value->srcInfo;
            math_input = prop->value->to<IR::ExpressionValue>()->expression->apply(rewrite);
            if (math_input->type != utype)
                math_input = new IR::Cast(utype, math_input);
            return false;
        } else if ((prop->name == "initial_register_lo_value")
                || (prop->name == "initial_register_hi_value")) {
            if (auto ev = prop->value->to<IR::ExpressionValue>()) {
                if (auto k = ev->expression->to<IR::Constant>()) {
                    annots->addAnnotation(prop->name.toString(), ev->expression);
                    LOG5("adding annotation '" << prop->name << "' with value " << k->asInt());
                    return false; } }
            error("%s: %s must be a constant", prop->value->srcInfo, prop->name);
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
            have_output = true;
            if (expr_index != OUT) pred = nullptr;
            idx = -1;
        } else {
            return false; }
        applyLoc = &prop->value->srcInfo;
        convert_to_saturating = saturating && !predicate;
        auto e = prop->value->to<IR::ExpressionValue>()->expression->apply(rewrite);
        convert_to_saturating = false;
        if (!e) return false;
        if (predicate) {
            if (e->type != IR::Type::Boolean::get())
                e = new IR::Cast(IR::Type::Boolean::get(), e);
            pred = e;
            return false; }
        IR::Expression *dest = new IR::PathExpression(utype,
                new IR::Path(idx < 0 ? "rv" : "value"));
        if (idx >= 0)
            dest = makeRegFieldMember(dest, idx);
        else if (cmpl_out)
            e = new IR::Cmpl(e);
        const IR::Statement *instr = structure->assign(prop->srcInfo, dest, e, utype);
        LOG2("adding " << instr << " with pred " << pred);
        if (pred)
            instr = new IR::IfStatement(pred, instr, nullptr);
        if (idx < 0 && defer_out)
            output = instr;
        else
            body->push_back(instr);
        return false; }

 public:
    CreateSaluApplyFunction(IR::Annotations *annots, P4V1::ProgramStructure *s,
                            const IR::Type *rtype, const IR::Type::Bits *utype, cstring mu,
                            bool saturating)
        : annots(annots), structure(s), rtype(rtype), utype(utype), math_unit_name(mu),
          saturating(saturating),
          rewrite({ new RewriteExpr(*this), new TypeCheck }) {
        body = new IR::BlockStatement({
            new IR::Declaration_Variable("in_value", rtype),
            new IR::AssignmentStatement(new IR::PathExpression("in_value"),
                                        new IR::PathExpression("value")) });
        if (auto st = rtype->to<IR::Type_StructLike>())
            rtype = new IR::Type_Name(st->name); }
    void end_apply(const IR::Node *) {
        if (need_alu_hi)
            body->components.insert(body->components.begin(),
                    new IR::Declaration_Variable("alu_hi", utype, new IR::Constant(utype, 0)));
        auto apply_params = new IR::ParameterList({
                     new IR::Parameter("value", IR::Direction::InOut, rtype) });
        if (have_output) {
            body->components.insert(body->components.begin(),
                new IR::AssignmentStatement(new IR::PathExpression("rv"),
                                            new IR::Constant(utype, 0)));
            apply_params->push_back(new IR::Parameter("rv", IR::Direction::Out, utype)); }
        apply = new IR::Function("apply",
                                 new IR::Type_Method(IR::Type_Void::get(), apply_params), body);
        if (output && defer_out)
            body->push_back(output); }
    static const IR::Function *create(IR::Annotations *annots, P4V1::ProgramStructure *structure,
                const IR::Declaration_Instance *ext, const IR::Type *rtype,
                const IR::Type::Bits *utype, cstring math_unit_name = cstring(),
                bool saturating = false) {
        CreateSaluApplyFunction create_apply(annots, structure, rtype, utype,
                                             math_unit_name, saturating);
        // need a separate traversal here as "update" will be visited after "output"
        forAllMatching<IR::AttribLocal>(&ext->properties, [&](const IR::AttribLocal *attr) {
            if (attr->name.name.endsWith("_bitc")) { create_apply.cmpl_out = true; } });
        ext->apply(create_apply);
        return create_apply.apply; }
};

static bool usesRegHi(const IR::Declaration_Instance *salu) {
    struct scanVisitor : public Inspector {
        bool result = false;
        bool preorder(const IR::AttribLocal *attr) override {
            if (attr->name == "register_hi")
                result = true;
            return !result; }
        bool preorder(const IR::Expression *) override { return !result; }
    } scan;

    salu->properties.apply(scan);
    return scan.result;
}

class CreateMathUnit : public Inspector {
    cstring name;
    const IR::Type::Bits *utype;
    IR::Declaration_Instance *unit = nullptr;
    bool have_unit = false;
    const IR::BoolLiteral *exp_invert = nullptr;
    const IR::Constant *exp_shift = nullptr, *output_scale = nullptr;
    const IR::ExpressionListValue *table;

    bool preorder(const IR::Property *prop) {
        if (prop->name == "math_unit_exponent_invert") {
            have_unit = true;
            if (auto ev = prop->value->to<IR::ExpressionValue>())
                if ((exp_invert = ev->expression->to<IR::BoolLiteral>()))
                    return false;
            error("%s: %s must be a constant", prop->value->srcInfo, prop->name);
        } else if (prop->name == "math_unit_exponent_shift") {
            have_unit = true;
            if (auto ev = prop->value->to<IR::ExpressionValue>())
                if ((exp_shift = ev->expression->to<IR::Constant>()))
                    return false;
            error("%s: %s must be a constant", prop->value->srcInfo, prop->name);
        } else if (prop->name == "math_unit_input") {
            have_unit = true;
        } else if (prop->name == "math_unit_lookup_table") {
            have_unit = true;
            if (!(table = prop->value->to<IR::ExpressionListValue>()))
                error("%s: %s must be a list", prop->value->srcInfo, prop->name);
        } else if (prop->name == "math_unit_output_scale") {
            have_unit = true;
            if (auto ev = prop->value->to<IR::ExpressionValue>())
                if ((output_scale = ev->expression->to<IR::Constant>()))
                    return false;
            error("%s: %s must be a constant", prop->value->srcInfo, prop->name); }
        return false;
    }

 public:
    CreateMathUnit(cstring n, const IR::Type::Bits *utype) : name(n), utype(utype) {}
    void end_apply(const IR::Node *) {
        if (!have_unit) {
            unit = nullptr;
            return; }
        if (!exp_invert) exp_invert = new IR::BoolLiteral(false);
        if (!exp_shift) exp_shift = new IR::Constant(0);
        if (!output_scale) output_scale = new IR::Constant(0);
        if (!table) table = new IR::ExpressionListValue({});
        auto *tuple_type = new IR::Type_Tuple;
        for (int i = table->expressions.size(); i > 0; --i)
            tuple_type->components.push_back(utype);
        auto mutype = new IR::Type_Specialized(new IR::Type_Name("math_unit"),
                               new IR::Vector<IR::Type>({ utype, tuple_type }));
        auto *ctor_args = new IR::Vector<IR::Argument>({
            new IR::Argument(exp_invert),
            new IR::Argument(exp_shift),
            new IR::Argument(output_scale),
            new IR::Argument(new IR::ListExpression(table->expressions))
        });
        auto* externalName = new IR::StringLiteral(IR::ID("." + name));
        auto* annotations = new IR::Annotations({
                new IR::Annotation(IR::ID("name"), { externalName })
                });
        unit = new IR::Declaration_Instance(name, annotations, mutype, ctor_args);
    }
    static const IR::Declaration_Instance *create(P4V1::ProgramStructure *structure,
                const IR::Declaration_Instance *ext, const IR::Type::Bits *utype) {
        CreateMathUnit create_math(structure->makeUniqueName(ext->name + "_math_unit"), utype);
        ext->apply(create_math);
        return create_math.unit; }
};

/* FIXME -- still need to deal with the following stateful_alu properties:
        initial_register_hi_value initial_register_lo_value
        reduction_or_group
        selector_binding
        stateful_logging_mode
*/

// FIXME -- this should be a method of IR::IndexedVector, or better yet, have a
// FIXME -- replace method that doesn't need an iterator.
IR::IndexedVector<IR::Node>::iterator find_in_scope(
        IR::Vector<IR::Node> *scope, cstring name) {
    for (auto it = scope->begin(); it != scope->end(); ++it) {
        if (auto decl = (*it)->to<IR::Declaration>()) {
            if (decl->name == name) {
                return it; } }
    }
    BUG_CHECK("%s not in scope", name);
    return scope->end();
}

P4V1::StatefulAluConverter::reg_info P4V1::StatefulAluConverter::getRegInfo(
        P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext,
        IR::Vector<IR::Node> *scope) {
    reg_info rv;
    if (auto rp = ext->properties.get<IR::Property>("reg")) {
        auto rpv = rp->value->to<IR::ExpressionValue>();
        auto gref = rpv ? rpv->expression->to<IR::GlobalRef>() : nullptr;
        if ((rv.reg = gref ? gref->obj->to<IR::Register>() : nullptr)) {
            if (cache.count(rv.reg)) return cache.at(rv.reg);
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
            } else if (rv.reg->width <= 64) {
                int width = 1 << ceil_log2(rv.reg->width);
                if (width > 1 && width < 8) width = 8;
                if (width > 32 || usesRegHi(ext)) {
                    rv.utype = IR::Type::Bits::get(width/2, rv.reg->signed_);
                    cstring rtype_name = structure->makeUniqueName(ext->name + "_layout");
                    rv.rtype = new IR::Type_Struct(IR::ID(rtype_name), {
                        new IR::StructField("lo", rv.utype),
                        new IR::StructField("hi", rv.utype) });
                    auto iter = find_in_scope(scope, structure->registers.get(rv.reg));
                    if (iter != scope->end())
                        iter = scope->erase(iter);
                    scope->insert(iter, structure->convert(
                            rv.reg, structure->registers.get(rv.reg), rv.rtype));
                    scope->insert(iter, rv.rtype);
                } else {
                    rv.rtype = rv.utype = IR::Type::Bits::get(width, rv.reg->signed_); }
            } else {
                error("register %s width %d not supported for stateful_alu", rv.reg, rv.reg->width);
            }
        } else {
            error("%s reg property %s not a register", ext->name, rp);
        }
    } else {
        error("No reg property in %s", ext); }
    if (rv.reg) cache[rv.reg] = rv;
    return rv;
}

const IR::ActionProfile *P4V1::StatefulAluConverter::getSelectorProfile(
        P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext) {
    if (auto sel_bind = ext->properties.get<IR::Property>("selector_binding")) {
        auto ev = sel_bind->value->to<IR::ExpressionValue>();
        auto gref = ev ? ev->expression->to<IR::GlobalRef>() : nullptr;
        auto tbl = gref ? gref->obj->to<IR::V1Table>() : nullptr;
        if (!tbl) {
            error("%s is not a table", sel_bind);
            return nullptr; }
        auto ap = structure->action_profiles.get(tbl->action_profile);
        auto sel = ap ? structure->action_selectors.get(ap->selector) : nullptr;
        if (!sel) {
            error("No action selector for table %s", tbl);
            return nullptr; }
        return ap; }
    return nullptr;
}

const IR::Declaration_Instance *P4V1::StatefulAluConverter::convertExternInstance(
        P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext, cstring name,
        IR::IndexedVector<IR::Declaration> *scope) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "stateful_alu",
              "Extern %s is not stateful_alu type, but %s", ext, ext->type);

    auto *annots = new IR::Annotations();
    if (auto prop = ext->properties.get<IR::Property>("reduction_or_group")) {
        bool understood = false;
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            if (auto pe = ev->expression->to<IR::PathExpression>()) {
                annots->addAnnotation("reduction_or_group", new IR::StringLiteral(pe->path->name));
                understood = true;
            }
        }
        ERROR_CHECK(understood, "%s: reduction_or_group provided on %s is not understood, because",
                    "it is not a PathExpression", ext->srcInfo, name);
    }

    if (auto ap = getSelectorProfile(structure, ext)) {
        LOG2("Creating apply function for SelectorAction " << ext->name);
        LOG6(ext);
        auto satype = new IR::Type_Name("SelectorAction");
        auto bit1 = IR::Type::Bits::get(1);
        auto *ctor_args = new IR::Vector<IR::Argument>({
                new IR::Argument(new IR::PathExpression(new IR::Path(
                    structure->action_profiles.get(ap)))) });
        auto *block = new IR::BlockStatement({
            CreateSaluApplyFunction::create(annots, structure, ext, bit1, bit1) });
        auto* externalName = new IR::StringLiteral(IR::ID("." + name));
        annots->addAnnotation(IR::ID("name"), externalName);
        // 1-bit selector alu may not need a 'fake' reg property
        // see sful_sel1.p4
        if (ext->properties.get<IR::Property>("reg")) {
            auto info = getRegInfo(structure, ext, structure->declarations);
            if (info.utype) {
                auto* regName = new IR::StringLiteral(IR::ID(info.reg->name));
                annots->addAnnotation(IR::ID("reg"), regName);
            }
        }
        auto *rv = new IR::Declaration_Instance(name, annots, satype, ctor_args, block);
        return rv->apply(TypeConverter(structure))->to<IR::Declaration_Instance>();
    }
    auto info = getRegInfo(structure, ext, structure->declarations);
    if (info.utype) {
        LOG2("Creating apply function for RegisterAction " << ext->name);
        LOG6(ext);
        auto ratype = new IR::Type_Specialized(
            new IR::Type_Name("RegisterAction"),
            new IR::Vector<IR::Type>({info.rtype, IR::Type::Bits::get(32), info.utype}));
        if (info.reg->instance_count == -1) {
            ratype = new IR::Type_Specialized(
                new IR::Type_Name("DirectRegisterAction"),
                new IR::Vector<IR::Type>({info.rtype, info.utype}));
        }

        auto *ctor_args = new IR::Vector<IR::Argument>({
                new IR::Argument(new IR::PathExpression(new IR::Path(info.reg->name))) });
        auto *math = CreateMathUnit::create(structure, ext, info.utype);
        if (math)
            structure->declarations->push_back(math);
        auto *block = new IR::BlockStatement({
            CreateSaluApplyFunction::create(annots, structure, ext, info.rtype, info.utype,
                                            math ? math->name.name : cstring(),
                                            info.reg->saturating) });
        auto* externalName = new IR::StringLiteral(IR::ID("." + name));
        annots->addAnnotation(IR::ID("name"), externalName);
        auto *rv = new IR::Declaration_Instance(name, annots, ratype, ctor_args, block);
        LOG3("Created apply function: " << *rv);
        return rv->apply(TypeConverter(structure))->to<IR::Declaration_Instance>();
    }

    BUG_CHECK(errorCount() > 0, "Failed to find utype for %s", ext);
    return ExternConverter::convertExternInstance(structure, ext, name, scope);
}

const IR::Statement *P4V1::StatefulAluConverter::convertExternCall(
            P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext,
            const IR::Primitive *prim) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "stateful_alu",
              "Extern %s is not stateful_alu type, but %s", ext, ext->type);
    const IR::Attached *target = getSelectorProfile(structure, ext);
    auto rtype = IR::Type::Bits::get(1);
    bool direct = false;
    if (!target) {
        auto info = getRegInfo(structure, ext, structure->declarations);
        rtype = info.utype;
        target = info.reg;
        direct = info.reg->instance_count < 0; }
    if (!rtype) {
        BUG_CHECK(errorCount() > 0, "Failed to find rtype for %s", ext);
        return new IR::EmptyStatement(); }
    ExpressionConverter conv(structure);
    const IR::Statement *rv = nullptr;
    IR::BlockStatement *block = nullptr;
    auto extref = new IR::PathExpression(structure->externs.get(ext));
    auto method = new IR::Member(prim->srcInfo, extref, "execute");
    auto args = new IR::Vector<IR::Argument>();
    if (prim->name == "execute_stateful_alu") {
        BUG_CHECK(prim->operands.size() <= 2, "Wrong number of operands to %s", prim->name);
        if (prim->operands.size() == 2) {
            auto *idx = conv.convert(prim->operands.at(1));
            if (idx->is<IR::ListExpression>())
                error("%s%s expects a simple expression, not a %s",
                      prim->operands.at(1)->srcInfo, prim->name, idx);
            args->push_back(new IR::Argument(idx));
            if (direct)
                error("%scalling direct %s with an index", prim->srcInfo, target);
        } else if (!direct) {
            error("%scalling indirect %s with no index", prim->srcInfo, target); }
    } else if (prim->name == "execute_stateful_alu_from_hash") {
        BUG_CHECK(prim->operands.size() == 2, "Wrong number of operands to %s", prim->name);
        auto flc = structure->getFieldListCalculation(prim->operands.at(1));
        if (!flc) {
            error("%s: Expected a field_list_calculation", prim->operands.at(1));
            return nullptr; }
        block = new IR::BlockStatement;
        cstring temp = structure->makeUniqueName("temp");
        block = P4V1::generate_hash_block_statement(structure, prim, temp, conv, 2);
        args->push_back(new IR::Argument(new IR::Cast(IR::Type_Bits::get(32),
                        new IR::PathExpression(new IR::Path(temp)))));
    } else if (prim->name == "execute_stateful_log") {
        BUG_CHECK(prim->operands.size() == 1, "Wrong number of operands to %s", prim->name);
        method = new IR::Member(prim->srcInfo, extref, "execute_log");
    } else {
        BUG("Unknown method %s in stateful_alu", prim->name); }

    auto mc = new IR::MethodCallExpression(prim->srcInfo, rtype, method, args);
    if (auto prop = ext->properties.get<IR::Property>("output_dst")) {
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            auto type = ev->expression->type;
            if (ext->properties.get<IR::Property>("reduction_or_group")) {
                const IR::Expression *expr = mc;
                if (expr->type != type)
                    expr = new IR::Cast(type, expr);
                expr = new IR::BOr(conv.convert(ev->expression), expr);
                rv = structure->assign(prim->srcInfo, conv.convert(ev->expression), expr, type);
            } else {
                rv = structure->assign(prim->srcInfo, conv.convert(ev->expression), mc, type);
            }
        } else {
            error("%s: output_dst property is not an expression", prop->value->srcInfo);
            return nullptr; }
    } else {
        rv = new IR::MethodCallStatement(prim->srcInfo, mc); }
    if (block) {
        block->push_back(rv);
        rv = block; }
    return rv;
}

P4V1::StatefulAluConverter P4V1::StatefulAluConverter::singleton;
