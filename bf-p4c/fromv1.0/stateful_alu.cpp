#include "stateful_alu.h"
#include "frontends/p4-14/typecheck.h"

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
    P4V1::ProgramStructure *structure;
    const IR::Type *rtype;
    const IR::Type::Bits *utype;
    cstring math_unit_name;
    IR::BlockStatement *body;
    IR::Function *apply;
    const IR::Expression *cond_lo = nullptr;
    const IR::Expression *cond_hi = nullptr;
    const IR::Expression *math_input = nullptr;
    const IR::Expression *pred = nullptr;
    const IR::Statement *output = nullptr;
    enum expr_index_t { LO1, LO2, HI1, HI2, OUT } expr_index;
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
            } else if (attr->name == "math_unit") {
                auto *mu = new IR::PathExpression(IR::ID(attr->srcInfo, self.math_unit_name));
                return new IR::MethodCallExpression(attr->srcInfo,
                        new IR::Member(mu, "execute"), { self.math_input });
            } else if (attr->name == "predicate") {
                return new IR::Constant(self.utype, 1);
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
        } else if (prop->name == "math_unit_input") {
            math_input = prop->value->to<IR::ExpressionValue>()->expression->apply(rewrite);
            if (math_input->type != utype)
                math_input = new IR::Cast(utype, math_input);
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
    CreateSaluApplyFunction(P4V1::ProgramStructure *s, const IR::Type *rtype,
                            const IR::Type::Bits *utype, cstring mu)
    : structure(s), rtype(rtype), utype(utype), math_unit_name(mu),
      rewrite({ new RewriteExpr(*this), new TypeCheck }) {
        body = new IR::BlockStatement({
            new IR::AssignmentStatement(new IR::PathExpression("rv"),
                                        new IR::Constant(utype, 0)) });
        if (auto st = rtype->to<IR::Type_StructLike>())
            rtype = new IR::Type_Name(st->name);
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
            // FIXME -- should initialize to 0 to avoid warnings about uninitialized values?
            // FIXME -- doing so causes a redundant assgnment of 0 which may cause asm
            // FIXME -- failure due to too many instructions in the stateful action.
        if (output && defer_out)
            body->push_back(output); }
    static const IR::Function *create(P4V1::ProgramStructure *structure,
                const IR::Declaration_Instance *ext, const IR::Type *rtype,
                const IR::Type::Bits *utype, cstring math_unit_name) {
        CreateSaluApplyFunction create_apply(structure, rtype, utype, math_unit_name);
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
        bool preorder(const IR::Property *prop) override {
            if (prop->name == "update_hi_1_value" || prop->name == "update_hi_1_value")
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
        auto *ctor_args = new IR::Vector<IR::Expression>({
            exp_invert, exp_shift, output_scale, new IR::ListExpression(table->expressions)
        });
        unit = new IR::Declaration_Instance(name, mutype, ctor_args);
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
IR::IndexedVector<IR::Declaration>::iterator find_in_scope(
        IR::IndexedVector<IR::Declaration> *scope, cstring name) {
    for (auto it = scope->begin(); it != scope->end(); ++it) {
        if ((*it)->name == name)
            return it; }
    BUG_CHECK("%s not in scope", name);
    return scope->end();
}

P4V1::StatefulAluConverter::reg_info P4V1::StatefulAluConverter::getRegInfo(
        P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext,
        IR::IndexedVector<IR::Declaration> *scope) {
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
            } else if (rv.reg->width == 1 || rv.reg->width == 8 || rv.reg->width == 16 ||
                       rv.reg->width == 32 || rv.reg->width == 64) {
                if (rv.reg->width == 64 || (rv.reg->width > 8 && usesRegHi(ext))) {
                    rv.utype = IR::Type::Bits::get(rv.reg->width/2, rv.reg->signed_);
                    cstring rtype_name = structure->makeUniqueName(ext->name + "_layout");
                    rv.rtype = new IR::Type_Struct(IR::ID(rtype_name), {
                        new IR::StructField("lo", rv.utype),
                        new IR::StructField("hi", rv.utype) });
                    scope->replace(find_in_scope(scope, structure->registers.get(rv.reg)),
                        structure->convert(rv.reg, structure->registers.get(rv.reg), rv.rtype));
                    structure->declarations->push_back(rv.rtype);
                } else {
                    rv.rtype = rv.utype = IR::Type::Bits::get(rv.reg->width, rv.reg->signed_); }
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

const IR::Declaration_Instance *P4V1::StatefulAluConverter::convertExternInstance(
        P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext, cstring name,
        IR::IndexedVector<IR::Declaration> *scope) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "stateful_alu",
              "Extern %s is not stateful_alu type, but %s", ext, ext->type);
    auto info = getRegInfo(structure, ext, scope);
    if (info.utype) {
        LOG2("Creating apply function for register_action " << ext->name);
        auto ratype = new IR::Type_Specialized(new IR::Type_Name("register_action"),
                               new IR::Vector<IR::Type>({ info.rtype, info.utype }));
        auto *ctor_args = new IR::Vector<IR::Expression>({
                new IR::PathExpression(new IR::Path(info.reg->name)) });
        auto *math = CreateMathUnit::create(structure, ext, info.utype);
        if (math) {
            structure->declarations->push_back(math);
            ctor_args->push_back(new IR::PathExpression(new IR::Path(math->name))); }
        auto *block = new IR::BlockStatement({
            CreateSaluApplyFunction::create(structure, ext, info.rtype, info.utype,
                                            math ? math->name.name : cstring()) });
        auto *rv = new IR::Declaration_Instance(name, ratype, ctor_args, block);
        return rv->apply(TypeConverter(structure))->to<IR::Declaration_Instance>();
    }
    BUG("Failed to find utype for %s", ext);
    return ExternConverter::convertExternInstance(structure, ext, name, scope);
}

const IR::Statement *P4V1::StatefulAluConverter::convertExternCall(
            P4V1::ProgramStructure *structure, const IR::Declaration_Instance *ext,
            const IR::Primitive *prim) {
    auto *et = ext->type->to<IR::Type_Extern>();
    BUG_CHECK(et && et->name == "stateful_alu",
              "Extern %s is not stateful_alu type, but %s", ext, ext->type);
    auto info = getRegInfo(structure, ext, nullptr);
    ExpressionConverter conv(structure);
    const IR::Statement *rv = nullptr;
    IR::BlockStatement *block = nullptr;
    auto extref = new IR::PathExpression(structure->externs.get(ext));
    auto method = new IR::Member(prim->srcInfo, extref, "execute");
    auto args = new IR::Vector<IR::Expression>();
    if (prim->name == "execute_stateful_alu") {
        BUG_CHECK(prim->operands.size() <= 2, "Wrong number of operands to %s", prim->name);
        if (prim->operands.size() == 2)
            args->push_back(conv.convert(prim->operands.at(1)));
    } else if (prim->name == "execute_stateful_alu_from_hash") {
        BUG_CHECK(prim->operands.size() == 2, "Wrong number of operands to %s", prim->name);
        auto pe = prim->operands.at(1)->to<IR::PathExpression>();
        auto flc = pe ? structure->field_list_calculations.get(pe->path->name) : nullptr;
        if (!flc) {
            error("%s: Expected a field_list_calculation", prim->operands.at(1));
            return nullptr; }
        auto ttype = IR::Type_Bits::get(flc->output_width);
        auto algo = new IR::TypeNameExpression(structure->v1model.algorithm.Id());
        block = new IR::BlockStatement;
        cstring temp = structure->makeUniqueName("temp");
        block->push_back(new IR::Declaration_Variable(temp, ttype));
        args->push_back(new IR::PathExpression(new IR::Path(temp)));
        args->push_back(new IR::Member(algo, flc->algorithm));
        args->push_back(new IR::Constant(ttype, 0));
        args->push_back(conv.convert(flc->input_fields));
        args->push_back(new IR::Constant(IR::Type_Bits::get(flc->output_width + 1),
                                         1 << flc->output_width));
        block->push_back(new IR::MethodCallStatement(new IR::MethodCallExpression(
                new IR::PathExpression(structure->v1model.hash.Id()), args)));
        args = new IR::Vector<IR::Expression>();
        args->push_back(new IR::Cast(IR::Type_Bits::get(32),
                        new IR::PathExpression(new IR::Path(temp))));
    } else if (prim->name == "execute_stateful_log") {
        BUG_CHECK(prim->operands.size() == 1, "Wrong number of operands to %s", prim->name);
        method = new IR::Member(prim->srcInfo, extref, "execute_log");
    } else {
        BUG("Unknown method %s in stateful_alu", prim->name); }
    auto mc = new IR::MethodCallExpression(prim->srcInfo, info.utype, method, args);
    if (auto prop = ext->properties.get<IR::Property>("output_dst")) {
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            rv = structure->assign(prim->srcInfo, conv.convert(ev->expression), mc,
                                     ev->expression->type);
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
