#include <cmath>
#include "stateful_alu.h"
#include "bf-p4c/common/ir_utils.h"
#include "ir/pattern.h"

const Device::StatefulAluSpec &TofinoDevice::getStatefulAluSpec() const {
    static const Device::StatefulAluSpec spec = {
        /* .CmpMask = */ false,
        /* .CmpUnits = */ { "lo", "hi" },
        /* .MaxSize = */ 32,
        /* .MaxDualSize = */ 64,
        /* .OutputWords = */ 1,
        /* .DivModUnit = */ false,
    };
    return spec;
}

#if HAVE_JBAY
const Device::StatefulAluSpec &JBayDevice::getStatefulAluSpec() const {
    static const Device::StatefulAluSpec spec = {
        /* .CmpMask = */ true,
        /* .CmpUnits = */ { "cmp0", "cmp1", "cmp2", "cmp3" },
        /* .MaxSize = */ 128,
        /* .MaxDualSize = */ 128,
        /* .OutputWords = */ 4,
        /* .DivModUnit = */ true,
    };
    return spec;
}
#endif

bool IR::MAU::StatefulAlu::alu_output() const {
    for (auto act : Values(instruction))
        for (auto inst : act->action)
            if (inst->name == "output")
                return true;
    return false;
}

std::ostream &operator<<(std::ostream &out, CreateSaluInstruction::LocalVar::use_t u) {
    static const char *use_names[] = { "NONE", "ALUHI", "MEMLO", "MEMHI", "MEMALL" };
    if (u < sizeof(use_names)/sizeof(use_names[0]))
        return out << use_names[u];
    else
        return out << "<invalid " << u << ">"; }
std::ostream &operator<<(std::ostream &out, CreateSaluInstruction::etype_t e) {
    static const char *names[] = { "NONE", "MINMAX_IDX", "IF", "VALUE", "OUTPUT", "MATCH" };
    if (e < sizeof(names)/sizeof(names[0]))
        return out << names[e];
    else
        return out << "<invalid " << int(e) << ">"; }

static bool is_address_output(const IR::Expression *e) {
    if (auto *r = e->to<IR::MAU::SaluReg>())
        return r->name == "address";
    return false;
}

static bool is_learn(const IR::Expression *e) {
    if (auto *r = e->to<IR::MAU::SaluReg>())
        return r->name == "learn";
    return false;
}

/// Check a name to see if it is a reference to an argument of RegisterAction::apply,
/// or a reference to the local var we put in alu_hi.
/// or a reference to a copy of an in argument
/// If so, process it as an operand and return true
bool CreateSaluInstruction::applyArg(const IR::PathExpression *pe, cstring field) {
    LOG4("applyArg(" << pe << ", " << field << ") etype = " << etype);
    assert(dest == nullptr || !islvalue(etype));
    IR::Expression *e = nullptr;
    int idx = 0, field_idx = 0;
    if (locals.count(pe->path->name.name)) {
        auto &local = locals.at(pe->path->name.name);
        if (islvalue(etype))
            dest = &local;
        switch (local.use) {
        case LocalVar::NONE:
            // if this becomes a real instruction (not an elided copy), this
            // local will become alu_hi, so fall through
        case LocalVar::ALUHI:
        case LocalVar::MEMHI:
            field_idx = 1;
            break;
        case LocalVar::MEMLO:
        case LocalVar::MEMALL:
            break;
        default:
            BUG("invalide use in CreateSaluInstruction::LocalVar %s %d", local.name, local.use); }
    } else {
        if (!params) return false;
        if (islvalue(etype))
            output_index = 0;
        for (auto p : params->parameters) {
            if (p->name == pe->path->name) {
                break; }
            if (islvalue(etype) && param_types->at(idx) == param_t::OUTPUT)
                ++output_index;
            ++idx; }
        if (size_t(idx) >= params->parameters.size()) return false;
        BUG_CHECK(size_t(idx) < param_types->size(), "param index out of range"); }
    if (field_idx == 0 && field && regtype->is<IR::Type_StructLike>()) {
        for (auto f : regtype->to<IR::Type_StructLike>()->fields) {
            if (f->name == field)
                break;
            ++field_idx; }
        BUG_CHECK(field_idx < 2, "bad field name in register layout"); }
    cstring name = field_idx ? "hi" : "lo";
    switch (param_types->at(idx)) {
    case param_t::VALUE:        /* inout value; */
        if (islvalue(etype)) {
            // alu_lo cannot be used as a synthetic local var as it is always
            // written back to the memory. In non-dual mode, alu_hi is not
            // written back, so it can be used as a local temp for a computation
            // to be output on the action bus
            // Therefore in some cases we can have a destination local which
            // assigns to ALUHI. E.g. sampling_cntr in stful.p4
            // Creating action sampling_alu_0[1596727] for stateful table .sampling_cntr
            // void apply(inout bit<32> value, out bit<32> rv) {
            //   bit<32> alu_hi_0/alu_hi <== Local Value for alu_hi
            //   bit<32> in_value_12/in_value
            //   rv = 0;
            //   in_value_12/in_value = value;
            //   alu_hi_0/alu_hi = 1; <== Local Value set
            //   if (value >= 10) {
            //     value = 1; }
            //   if (in_value_12/in_value < 10) {
            //     value = in_value_12/in_value + 1; }
            //   if (in_value_12/in_value >= 10 || ig_intr_md_for_tm.copy_to_cpu != 0) {
            //     rv = alu_hi_0/alu_hi; <== Local Value used for return value
            //     }
            // }
            // In this case dest->use is LocalVar::NONE, so we also check for
            // this value and set alu_write accordingly
            if (!dest || dest->use == LocalVar::ALUHI || dest->use == LocalVar::NONE)
                alu_write[field_idx] = true;
            etype = VALUE; }
        if (!opcode) opcode = "alu_a";
        if (etype == OUTPUT)
            name = (alu_write[field_idx] ? "alu_" : "mem_") + name;
        e = new IR::MAU::SaluReg(pe->type, name, field_idx > 0);
        break;
    case param_t::OUTPUT:       /* out rv; */
        if (islvalue(etype))
            etype = OUTPUT;
        else
            error("Reading out param %s in %s not supported", pe, action_type_name);
        if (output_index > Device::statefulAluSpec().OutputWords)
            error("Only %d stateful output%s supported", Device::statefulAluSpec().OutputWords,
                  Device::statefulAluSpec().OutputWords > 1 ? "s" : "");
        if (!opcode) opcode = "output";
        break;
    case param_t::HASH:         /* in digest */
        if (islvalue(etype)) {
            error("Writing in param %s in %s not supported", pe, action_type_name);
            return false; }
        e = new IR::MAU::SaluReg(pe->type, "phv_" + name, field_idx > 0);
        break;
    case param_t::LEARN:        /* in learn */
        if (islvalue(etype)) {
            error("Writing in param %s in %s not supported", pe, action_type_name);
            return false; }
        e = new IR::MAU::SaluReg(pe->type, "learn", false);
        break;
    case param_t::MATCH:        /* out match */
        if (!islvalue(etype)) {
            error("Reading out param %s in %s not supported", pe, action_type_name);
            return false; }
        etype = MATCH;
        if (!opcode) opcode = "#match";
        break;
    default:
        return false; }

    if (e) {
        if (negate)
            e = new IR::Neg(e);
        LOG4("applyArg operand: " << e);
        operands.push_back(e); }
    return true;
}

bool CreateSaluInstruction::preorder(const IR::Function *func) {
    static std::vector<param_t>         empty_params;
    BUG_CHECK(!action && !params, "Nested function?");
    cstring name = reg_action->name;
    if (func->name != "apply") {
        name += "$" + func->name;
        if (func->name == "overflow") {
            if (salu->overflow)
                error("%s: Conflicting overflow function for Register", func->srcInfo);
            else
                salu->overflow = name; }
        if (func->name == "underflow") {
            if (salu->underflow)
                error("%s: Conflicting underflow function for Register", func->srcInfo);
            else
                salu->underflow = name; } }
    param_types = &function_param_types.at(std::make_pair(action_type_name, func->name));
    LOG3("Creating action " << name << "[" << func->id << "] for stateful table " << salu->name);
    LOG5(func);
    action = new IR::MAU::SaluAction(func->srcInfo, name, func);
    action->annotations = reg_action->annotations;
    outputs.clear();
    onebit = nullptr;
    onebit_cmpl = false;
    salu->instruction.addUnique(name, action);
    params = func->type->parameters;
    return true;
}

void CreateSaluInstruction::postorder(const IR::Function *func) {
    BUG_CHECK(params == func->type->parameters, "recursion failure");
    if (cmp_instr.size() > Device::statefulAluSpec().CmpUnits.size())
        error("%s: %s %s.%s needs %d comparisons; only %d possible", func->srcInfo,
              action_type_name, reg_action->name, func->name, cmp_instr.size(),
              Device::statefulAluSpec().CmpUnits.size());
    if (onebit) {
        action->action.push_back(onebit);
        LOG3("  add " << *action->action.back()); }
    for (auto &kv : output_address_subword_predicate) {
        // JBAY-2631: we now put the predicate controlling the subword bit into salu_mathtable,
        // but we hide that in the assembler, just specifying the predicate here as 'lmatch'
        auto &output = outputs[kv.first];
        BUG_CHECK(is_address_output(output->operands.back()), "not address output?");
        output->operands.push_back(new IR::MAU::SaluFunction(kv.second, "lmatch")); }
    for (auto *instr : outputs) {
        if (instr) {
            action->action.push_back(instr);
            LOG3("  add " << *action->action.back()); } }
    if (math.valid) {
        if (salu->math.valid && !(math == salu->math))
            error("%s: math unit incompatible with %s", reg_action->srcInfo, salu);
        else
            salu->math = math; }
    if (math_function && !math_function->expr)
        error("%s: math unit requires math_input", reg_action->srcInfo);
    int alu_hi_use = salu->dual || salu->width > 64 ? 1 : 0;
    for (auto &local : Values(locals))
        if (local.use == LocalVar::ALUHI)
            alu_hi_use++;
    if (alu_hi_use > 1)
        error("%s: too many locals in RegisterAction", func->srcInfo);
    params = nullptr;
    action = nullptr;
}

void CreateSaluInstruction::doAssignment(const Util::SourceInfo &srcInfo) {
    auto *old_predicate = predicate;
    if (etype == IF && operands.empty() && pred_operands.size() == 1) {
        // output of conditional expression -- output constant 1 with the predicate
        predicate = pred_operands[0];
        if (old_predicate)
            predicate = new IR::LAnd(old_predicate, predicate);
        etype = OUTPUT;
        operands.push_back(new IR::Constant(1)); }
    BUG_CHECK(operands.size() > (etype < OUTPUT), "recursion failure");
    if (dest && dest->use != LocalVar::ALUHI) {
        BUG_CHECK(etype == VALUE, "assert failure");
        LocalVar::use_t use = LocalVar::NONE;
        if (auto src = operands.back()->to<IR::MAU::SaluReg>()) {
            if (dest->pair) {
                use = LocalVar::MEMALL;
            } else if (src->hi) {
                use = LocalVar::MEMHI;
            } else {
                use = LocalVar::MEMLO; }
        } else {
            use = LocalVar::ALUHI; }
        if (use == LocalVar::NONE || (dest->use != LocalVar::NONE && dest->use != use))
            error("%s: %s %s too complex", srcInfo, action_type_name, reg_action->name);
        dest->use = use;
        LOG3("local " << dest->name << " use " << dest->use); }
    if (!dest || dest->use == LocalVar::ALUHI)
        createInstruction();
    predicate = old_predicate;
    assignDone = true;
}

bool CreateSaluInstruction::preorder(const IR::AssignmentStatement *as) {
    BUG_CHECK(operands.empty(), "recursion failure");
    etype = NONE;
    dest = nullptr;
    opcode = cstring();
    visit(as->left, "left");
    BUG_CHECK(operands.size() == (etype < OUTPUT) || ::errorCount() > 0, "recursion failure");
    assignDone = false;
    if (islvalue(etype))
        error("Can't assign to %s in RegisterAction", as->left);
    else
        visit(as->right);
    if (::errorCount() == 0 && !assignDone)
        doAssignment(as->srcInfo);
    operands.clear();
    return false;
}

static const IR::Expression *negatePred(const IR::Expression *e) {
    if (auto a = e->to<IR::LAnd>())
        return new IR::LOr(e->srcInfo, negatePred(a->left), negatePred(a->right));
    if (auto a = e->to<IR::LOr>())
        return new IR::LAnd(e->srcInfo, negatePred(a->left), negatePred(a->right));
    if (auto a = e->to<IR::LNot>())
        return a->expr;
    return new IR::LNot(e);
}

bool CreateSaluInstruction::preorder(const IR::IfStatement *s) {
    BUG_CHECK(operands.empty() && pred_operands.empty(), "recursion failure");
    etype = IF;
    dest = nullptr;
    visit(s->condition, "condition");
    BUG_CHECK(operands.empty() && pred_operands.size() == 1, "recursion failure");
    etype = NONE;
    auto old_predicate = predicate;
    auto new_predicate = pred_operands.at(0);
    pred_operands.clear();
    predicate = old_predicate ? new IR::LAnd(old_predicate, new_predicate) : new_predicate;
    visit(s->ifTrue, "ifTrue");
    new_predicate = negatePred(new_predicate);
    predicate = old_predicate ? new IR::LAnd(old_predicate, new_predicate) : new_predicate;
    visit(s->ifFalse, "ifFalse");
    predicate = old_predicate;
    return false;
}

bool CreateSaluInstruction::preorder(const IR::Mux *mux) {
    struct {
        etype_t                         etype;
        LocalVar                        *dest;
        IR::Vector<IR::Expression>      operands;
    } save_state = { etype, dest, operands };
    etype = IF;
    dest = nullptr;
    operands.clear();
    visit(mux->e0, "e0");
    BUG_CHECK(operands.empty() && pred_operands.size() == 1, "recursion failure");
    auto old_predicate = predicate;
    auto new_predicate = pred_operands.at(0);
    pred_operands.clear();
    predicate = old_predicate ? new IR::LAnd(old_predicate, new_predicate) : new_predicate;
    etype = save_state.etype;
    dest = save_state.dest;
    operands = save_state.operands;
    visit(mux->e1, "e1");
    doAssignment(mux->srcInfo);
    new_predicate = negatePred(new_predicate);
    predicate = old_predicate ? new IR::LAnd(old_predicate, new_predicate) : new_predicate;
    etype = save_state.etype;
    dest = save_state.dest;
    operands = save_state.operands;
    visit(mux->e2, "e2");
    doAssignment(mux->srcInfo);
    predicate = old_predicate;
    return false;
}

bool CreateSaluInstruction::preorder(const IR::PathExpression *pe) {
    if (!applyArg(pe, cstring())) {
        if (negate)
            operands.push_back(new IR::Neg(pe));
        else
            operands.push_back(pe);
        LOG4("Path operand: " << operands.back()); }
    return false;
}

bool CreateSaluInstruction::preorder(const IR::Constant *c) {
    if (etype == IF && c->value == 0)
        return false;
    if (negate)
        c = (-*c).clone();
    LOG4("Constant operand: " << c);
    operands.push_back(c);
    return false;
}
bool CreateSaluInstruction::preorder(const IR::Member *e) {
    if (auto pe = e->expr->to<IR::PathExpression>()) {
        if (applyArg(pe, e->member))
            return false; }
    if (negate)
        operands.push_back(new IR::Neg(e));
    else
        operands.push_back(e);
    LOG4("Member operand: " << operands.back());
    return false;
}

/* check that a slice is essentially just a cast to the correct size */
static bool checkSlice(const IR::Slice *sl, unsigned width) {
    return sl->getL() == 0 && sl->getH() == width - 1;
}

bool CreateSaluInstruction::preorder(const IR::Slice *sl) {
    bool keep_slice = false;
    if (etype == NONE) {
        if (!checkSlice(sl, salu->alu_width()))
            error("%scan only output entire %d-bit ALU output from %s", sl->srcInfo,
                  salu->alu_width(), reg_action->toString());
    } else if (etype == MINMAX_IDX) {
        // Magic constant 4 is log_2(memory word size in bytes)
        if (!checkSlice(sl, 4 - minmax_width))
            error("%s%s index output can only write to bottom %d bits of output", sl->srcInfo,
                  minmax_instr->name, 4 - minmax_width);
    } else {
        if (!checkSlice(sl, salu->alu_width()))
            error("%scan only read %d-bit slices in %s ALU", sl->srcInfo,
                  salu->alu_width(), reg_action->toString());
        keep_slice = true; }
    visit(sl->e0, "e0");
    if (keep_slice) {
        if (operands.back() == sl->e0)
            operands.back() = sl;
        else
            operands.back() = new IR::Slice(sl->srcInfo, operands.back(), sl->e1, sl->e2); }
    return false;
}

static double mul(double x) { return x; }
static double sqr(double x) { return x*x; }
static double rsqrt(double x) { return 1.0/sqrt(x); }
static double div(double x) { return 1.0/x; }
static double rsqr(double x) { return 1.0/x*x; }

static double (*fn[2][3])(double) = { { sqrt, mul, sqr }, { rsqrt, div, rsqr } };
// fn_max is max(fn(x)) for the x value range we need ([4/8, 15/8] for shift == -1,
// [8/8, 15/8] for shift >= 0)
static double fn_max[2][3] = { { 1.36930639376291528364, 1.875, 3.515625 },
                               { 1.41421356237309504880, 1.0, 1.0 } };


bool CreateSaluInstruction::preorder(const IR::Primitive *prim) {
    cstring method;
    if (auto p = prim->name.find('.'))
        method = p + 1;
    if (prim->name == "math_unit.execute" || prim->name == "MathUnit.execute") {
        BUG_CHECK(prim->operands.size() == 2, "typechecking failure");
        visit(prim->operands.at(1), "math_input");
        operands.back() = new IR::MAU::SaluFunction(prim->srcInfo, operands.back(), "math_table");
        LOG4("Math Unit operand: " << operands.back());
        auto gref = prim->operands.at(0)->to<IR::GlobalRef>();
        auto mu = gref ? gref->obj->to<IR::Declaration_Instance>() : nullptr;
        BUG_CHECK(mu, "typechecking failure?");
        math.valid = true;
        unsigned i = mu->arguments->size()-1;
        BUG_CHECK(i >= 1 && i <= 3, "typechecking failure");
        if (auto k = mu->arguments->at(0)->expression->to<IR::BoolLiteral>()) {
            math.exp_invert = k->value;
            if (auto k = mu->arguments->at(1)->expression->to<IR::Constant>())
                math.exp_shift = k->asInt();
            BUG_CHECK(i == 3, "typechecking failure");
        } else if (auto m = mu->arguments->at(0)->expression->to<IR::Member>()) {
            BUG_CHECK(i < 3, "typechecking failure");
            if (m->member == "MUL") {
                math.exp_shift = 0;
                math.exp_invert = false;
            } else if (m->member == "SQR") {
                math.exp_shift = 1;
                math.exp_invert = false;
            } else if (m->member == "SQRT") {
                math.exp_shift = -1;
                math.exp_invert = false;
            } else if (m->member == "DIV") {
                math.exp_shift = 0;
                math.exp_invert = true;
            } else if (m->member == "RSQR") {
                math.exp_shift = 1;
                math.exp_invert = true;
            } else if (m->member == "RSQRT") {
                math.exp_shift = -1;
                math.exp_invert = true;
            } else {
                BUG("Invalid MathUnit ctor arg %s", m); }
        } else {
            BUG("Invalid MathUnit ctor arg %s", mu->arguments->at(0)); }
        if (auto data = mu->arguments->at(i)->expression->to<IR::ListExpression>()) {
            BUG_CHECK(i >= 2, "typechecking failure");
            if (auto k = mu->arguments->at(i-1)->expression->to<IR::Constant>())
                math.scale = k->asInt();
            i = 16 - data->components.size();
            BUG_CHECK(i == 0 || i == 4 || i == 8, "Wrong number of MathUnit values");
            for (auto e : data->components) {
                if (auto k = e->to<IR::Constant>())
                    math.table[i] = k->asInt();
                ++i; }
        } else if (auto k = mu->arguments->at(i)->expression->to<IR::Constant>()) {
            BUG_CHECK(i == 1, "typechecking failure");
            double val = k->asUint64() * fn_max[math.exp_invert][math.exp_shift + 1];
            // choose the largest possible scale such that all table entries will be < 256
            math.scale = floor(log2(val)) - 7;
            if (math.scale > 31) {
                warning("%sMathUnit scale overflow %d, capping at 31", mu->srcInfo, math.scale);
                math.scale = 31; }
            val = k->asUint64() * pow(2.0, -math.scale);
            for (i = math.exp_shift >= 0 ? 8 : 4; i < 16; ++i) {
                math.table[i] = rint(fn[math.exp_invert][math.exp_shift + 1](i/8.0) * val);
                if (math.table[i] > 255)
                    math.table[i] = 255; }
        } else {
            error("%s is not a %s", mu->arguments->at(i)->expression,
                  i > 1 ? "list expression" : "constant"); }
    } else if (method == "address") {
        operands.push_back(new IR::MAU::SaluReg(prim->type, "address", false));
        address_subword = 0;
        if (prim->operands.size() == 2) {
            auto k = prim->operands.at(1)->to<IR::Constant>();
            if (!k || (k->value != 0 && k->value != 1))
                error("%s argument must be 0 or 1", prim);
            else
                address_subword = k->asInt(); }
    } else if (method == "predicate") {
        operands.push_back(new IR::MAU::SaluReg(prim->type, "predicate", false));
        if (salu->pred_shift > 0) {
            if (salu->pred_comb_shift == 0) {
                warning("conflicting predicate output use in %s, upper bits of "
                        "flag output will be non-zero", salu);
            } else {
                error("%sconflicting use of predicate output in %s", prim->srcInfo, salu); } }
        salu->pred_shift = 0;
    } else if (method == "min8" || method == "max8" || method == "min16" || method == "max16") {
        minmax_width = (method == "min16" || method == "max16") ? 1 : 0;
        if (etype != OUTPUT) {
            error("%s can only write to an ouput", prim);
            return false; }
        auto *saved_predicate = predicate;
        auto saved_output_index = output_index;
        etype = VALUE;
        predicate = nullptr;
        opcode = method;
        BUG_CHECK(prim->operands.size() >= 3, "typechecking failure");
        visit(prim->operands[2], "mask");
        if (minmax_instr) {
            if (!operands.equiv(minmax_instr->operands))
                error("%s: only one min/max operation possible in a stateful alu");
        } else {
            minmax_instr = createInstruction(); }
        operands.clear();
        if (prim->operands.size() == 4) {
            etype = MINMAX_IDX;
            dest = nullptr;
            opcode = cstring();
            visit(prim->operands[3], "index");
            BUG_CHECK(operands.size() == 0 || ::errorCount() > 0, "recursion failure");
            operands.push_back(new IR::MAU::SaluReg(prim->type, "minmax_index", false));
            createInstruction();
            operands.clear(); }
        output_index = saved_output_index;
        predicate = saved_predicate;
        etype = OUTPUT;
        operands.push_back(new IR::MAU::SaluReg(prim->type, "minmax", false));
    } else {
        error("%s: expression too complex for RegisterAction", prim->srcInfo); }
    return false;
}

static std::map<cstring, cstring> negate_op = {
    { "equ", "neq" }, { "neq", "equ" },
    { "geq.s", "lss.s" }, { "geq.u", "lss.u" },
    { "grt.s", "leq.s" }, { "grt.u", "leq.u" },
    { "leq.s", "grt.s" }, { "leq.u", "grt.u" },
    { "lss.s", "geq.s" }, { "lss.u", "geq.u" },
};

static bool equiv(const IR::Expression *a, const IR::Expression *b) {
    if (*a == *b) return true;
    if (typeid(*a) != typeid(*b)) return false;
    if (auto ma = a->to<IR::Member>()) {
        auto mb = b->to<IR::Member>();
        return ma->member == mb->member && equiv(ma->expr, mb->expr); }
    if (auto na = a->to<IR::Neg>()) {
        auto nb = b->to<IR::Neg>();
        return equiv(na->expr, nb->expr); }
    if (auto pa = a->to<IR::PathExpression>()) {
        auto pb = b->to<IR::PathExpression>();
        return pa->path->name == pb->path->name; }
    if (auto ka = a->to<IR::Constant>()) {
        auto kb = b->to<IR::Constant>();
        return ka->value == kb->value; }
    return false;
}

const IR::Expression *CreateSaluInstruction::reuseCmp(const IR::MAU::Instruction *cmp,
                                                            int idx) {
    if (operands.size() + 1 != cmp->operands.size()) return nullptr;
    for (unsigned i = 0; i < operands.size(); ++i)
        if (!equiv(operands.at(i), cmp->operands.at(i+1)))
            return nullptr;
    auto name = Device::statefulAluSpec().cmpUnit(idx);
    if (!name.startsWith("cmp")) name = "cmp" + name;
    if (opcode == cmp->name)
        return new IR::MAU::SaluCmpReg(name, idx);
    if (negate_op.at(opcode) == cmp->name)
        return new IR::LNot(new IR::MAU::SaluCmpReg(name, idx));
    return nullptr;
}

bool CreateSaluInstruction::preorder(const IR::Operation::Relation *rel, cstring op, bool eq) {
    if (etype == OUTPUT && operands.empty()) {
        // output a boolean condition directly -- change it into IF setting value to 1
        etype = IF; }
    if (etype == IF) {
        Pattern::Match<IR::Expression> e1, e2;
        Pattern::Match<IR::Constant> k;
        if (((e1 & k) == e2).match(rel) && !k->fitsUint() && !k->fitsInt()) {
            // FIXME -- wide "neq" can be done with tmatch too?
            opcode = "tmatch";
            visit(rel->left, "left");
            visit(rel->right, "right");
        } else {
            opcode = op;
            if (!eq) {
                auto t = rel->left->type->to<IR::Type::Bits>();
                opcode += (t && t->isSigned) ? ".s" : ".u"; }
            visit(rel->left, "left");
            negate = !negate;
            visit(rel->right, "right");
            negate = !negate; }
        BUG_CHECK(etype == IF, "etype changed?");
        int idx = 0;
        for (auto cmp : cmp_instr) {
            if (auto inst = reuseCmp(cmp, idx++)) {
                LOG4("Relation reuse pred_operand: " << inst);
                pred_operands.push_back(inst);
                operands.clear();
                return false; } }
        cstring name = Device::statefulAluSpec().cmpUnit(idx);
        operands.insert(operands.begin(), new IR::MAU::SaluCmpReg(name, idx));
        cmp_instr.push_back(createInstruction());
        if (!name.startsWith("cmp")) name = "cmp" + name;
        pred_operands.push_back(new IR::MAU::SaluCmpReg(name, idx));
        LOG4("Relation pred_operand: " << pred_operands.back());
        operands.clear();
    } else {
        error("%s: expression in stateful alu too complex", rel->srcInfo); }
    return false;
}

void CreateSaluInstruction::postorder(const IR::LNot *e) {
    if (etype == IF) {
        if (operands.size() == 1 && is_learn(operands.back())) {
            operands.back() = new IR::LNot(e->srcInfo, operands.back());
            return; }
        BUG_CHECK(pred_operands.size() == 1 || ::errorCount() > 0, "recursion failure");
        if (pred_operands.size() < 1) return;  // can only happen if there has been an error
        pred_operands.back() = new IR::LNot(e->srcInfo, pred_operands.back());
        LOG4("LNot rewrite pred_opeands: " << pred_operands.back());
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo); }
}
void CreateSaluInstruction::postorder(const IR::LAnd *e) {
    if (etype == IF) {
        if (pred_operands.size() == 1) return;  // to deal with learn -- not always correct
        BUG_CHECK(pred_operands.size() == 2 || ::errorCount() > 0, "recursion failure");
        if (pred_operands.size() < 2) return;  // can only happen if there has been an error
        auto r = pred_operands.back();
        pred_operands.pop_back();
        pred_operands.back() = new IR::LAnd(e->srcInfo, pred_operands.back(), r);
        LOG4("LAnd rewrite pred_opeands: " << pred_operands.back());
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo); }
}
void CreateSaluInstruction::postorder(const IR::LOr *e) {
    if (etype == IF) {
        if (pred_operands.size() == 1) return;  // to deal with learn -- not always correct
        BUG_CHECK(pred_operands.size() == 2 || ::errorCount() > 0, "recursion failure");
        if (pred_operands.size() < 2) return;  // can only happen if there has been an error
        auto r = pred_operands.back();
        pred_operands.pop_back();
        pred_operands.back() = new IR::LOr(e->srcInfo, pred_operands.back(), r);
        LOG4("LOr rewrite pred_opeands: " << pred_operands.back());
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo); }
}

bool CreateSaluInstruction::preorder(const IR::Add *e) {
    switch (etype) {
    case IF:
        return true;
    case VALUE:
        opcode = "add";
        return true;
    default:
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }
}
bool CreateSaluInstruction::preorder(const IR::AddSat *e) {
    if (etype == VALUE) {
        opcode = isSigned(e->type) ? "sadds" : "saddu";
        return true;
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }
}

bool CreateSaluInstruction::preorder(const IR::Sub *e) {
    switch (etype) {
    case IF:
        visit(e->left, "left");
        negate = !negate;
        visit(e->right, "right");
        negate = !negate;
        return false;
    case VALUE:
        opcode = "sub";
        return true;
    default:
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }
}
bool CreateSaluInstruction::preorder(const IR::SubSat *e) {
    if (etype == VALUE) {
        opcode = isSigned(e->type) ? "ssubs" : "ssubu";
        return true;
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }
}

bool CreateSaluInstruction::preorder(const IR::BAnd *e) {
    if (etype == VALUE) {
        if (e->left->is<IR::Cmpl>())
            opcode = "andca";
        else if (e->right->is<IR::Cmpl>())
            opcode = "andcb";
        else
            opcode = "and";
        return true;
    } else if (etype == IF && Device::statefulAluSpec().CmpMask) {
        return true;
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }
}
void CreateSaluInstruction::postorder(const IR::BAnd *e) {
    if (etype == IF) {
        if (operands.size() < 2) return;  // can only happen if there has been an error
        if (opcode == "tmatch") return;  // separate operands
        auto r = operands.back();
        operands.pop_back();
        if (!r->is<IR::Constant>()) {
            if (!operands.back()->is<IR::Constant>())
                error("%s: mask operand must be a constant", r->srcInfo);
            std::swap(r, operands.back()); }
        operands.back() = new IR::BAnd(e->srcInfo, operands.back(), r);
        LOG4("BAnd rewrite opeands: " << operands.back()); }
}
bool CreateSaluInstruction::preorder(const IR::BOr *e) {
    if (etype == VALUE) {
        if (e->left->is<IR::Cmpl>())
            opcode = "orca";
        else if (e->right->is<IR::Cmpl>())
            opcode = "orcb";
        else
            opcode = "or";
        return true;
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }
}
bool CreateSaluInstruction::preorder(const IR::Concat *e) {
    if (etype == VALUE) {
        // FIXME -- assume it can be implemented by an or?
        if (e->left->is<IR::Cmpl>())
            opcode = "orca";
        else if (e->right->is<IR::Cmpl>())
            opcode = "orcb";
        else
            opcode = "or"; }
    return true;
}
bool CreateSaluInstruction::preorder(const IR::BXor *e) {
    if (etype == VALUE) {
        if (e->left->is<IR::Cmpl>() || e->right->is<IR::Cmpl>())
            opcode = "xnor";
        else
            opcode = "xor";
        return true;
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }
}
void CreateSaluInstruction::postorder(const IR::Cmpl *e) {
    static const std::map<cstring, cstring> complement = {
        { "alu_a", "nota" }, { "alu_b", "notb" }, { "andca", "orcb" }, { "andcb", "orca" },
        { "and", "nand" }, { "nand", "and" }, { "nor", "or" }, { "nota", "alu_a" },
        { "notb", "alu_b" }, { "orca", "andcb" }, { "orcb", "andca" }, { "or", "nor" },
        { "sethi", "setz" }, { "setz", "sethi" }, { "xnor", "xor" }, { "xor", "xnor" } };
    if (etype == OUTPUT && regtype->width_bits() == 1) {
        onebit_cmpl = true;
        return; }
    if (complement.count(opcode))
        opcode = complement.at(opcode);
    else if (etype != VALUE)
        error("%s: expression too complex for stateful alu", e->srcInfo);
}
void CreateSaluInstruction::postorder(const IR::Concat *e) {
    if (operands.size() < 2) return;  // can only happen if there has been an error
    if (etype == VALUE) return;  // done in preorder
    if (etype == IF) {
        auto r = operands.back();
        operands.pop_back();
        if (r->is<IR::Constant>()) {
            // FIXME -- dropped constant needed in hash function
            LOG4("concant dropping low bit constant " << r);
            return; }
        if (operands.back()->is<IR::Constant>()) {
            // FIXME -- dropped constant needed in hash function
            LOG4("concant dropping high bit constant " << operands.back());
            operands.back() = r;
            return; } }
    error("%s: expression too complex for stateful alu", e->srcInfo);
}

bool CreateSaluInstruction::divmod(const IR::Operation::Binary *e, cstring op) {
    if (etype == OUTPUT && operands.empty() && Device::statefulAluSpec().DivModUnit) {
        auto *saved_predicate = predicate;
        etype = VALUE;
        predicate = nullptr;
        opcode = "divmod";
        visit(e->left, "left");
        visit(e->right, "right");
        if (divmod_instr) {
            if (!operands.equiv(divmod_instr->operands))
                error("%s: only one div/mod operation possible in a stateful alu");
        } else {
            divmod_instr = createInstruction(); }
        operands.clear();
        predicate = saved_predicate;
        etype = OUTPUT;
        operands.push_back(new IR::MAU::SaluReg(e->type, op, false));
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo); }
    return false;
}

const IR::MAU::Instruction *CreateSaluInstruction::setup_output() {
    if (outputs.size() <= size_t(output_index)) outputs.resize(output_index+1);
    auto &output = outputs[output_index];
    if (Device::statefulAluSpec().OutputWords > 1)
        operands.insert(operands.begin(), new IR::MAU::SaluReg(operands.at(0)->type,
                                "word" + std::to_string(output_index), false));
    if (predicate)
        operands.insert(operands.begin(), predicate);
    if (is_address_output(operands.back()) && address_subword) {
        if (predicate && output_address_subword_predicate.count(output_index)) {
            auto &subword_predicate = output_address_subword_predicate[output_index];
            if (subword_predicate)
                subword_predicate = new IR::LOr(subword_predicate, predicate);
        } else {
            output_address_subword_predicate[output_index] = predicate; } }
    if (output) {
        if (!equiv(operands.back(), output->operands.back())) {
            error("Incompatible outputs in RegisterAction: %s and %s\n",
                  output->operands.back(), operands.back());
            return nullptr; }
        if (output->operands.size() == operands.size()) {
            if (predicate)
                operands[0] = new IR::LOr(output->operands[0], operands[0]);
            else
                return output;
        } else if (predicate) {
            return output; } }
    return output = new IR::MAU::Instruction("output", &operands);
}

const IR::MAU::Instruction *CreateSaluInstruction::createInstruction() {
    const IR::MAU::Instruction *rv = nullptr;
    switch (etype) {
    case IF:
        action->action.push_back(rv = new IR::MAU::Instruction(opcode, &operands));
        LOG3("  add " << *action->action.back());
        break;
    case VALUE:
    case MATCH:
        if (regtype->width_bits() == 1) {
            BUG_CHECK(!predicate, "can't have predicate on 1-bit instruction");
            auto k = operands.at(1)->to<IR::Constant>();
            BUG_CHECK(k, "non-const writeback in 1-bit instruction?");
            opcode = k->value ? "set_bit" : "clr_bit";
            if (onebit_cmpl) opcode += 'c';
            /* For non-resilient hashes, all the bits must be updated whenever a port comes
             * up or down and hence must use the adjust_total instructions */
            if (salu->selector && salu->selector->mode == "fair") opcode += "_at";
            rv = onebit = new IR::MAU::Instruction(opcode);
            break; }
        if (predicate)
            operands.insert(operands.begin(), predicate);
        action->action.push_back(rv = new IR::MAU::Instruction(opcode, &operands));
        LOG3("  add " << *action->action.back());
        break;
    case OUTPUT:
        if (regtype->width_bits() == 1) {
            BUG_CHECK(!predicate, "can't have predicate on 1-bit instruction");
            opcode = onebit ? onebit->name : "read_bit";
            if (onebit_cmpl) opcode += "c";
            rv = onebit = new IR::MAU::Instruction(opcode);
            operands.clear();
            operands.push_back(new IR::MAU::SaluReg(IR::Type::Bits::get(1), "alu_lo", false));
        } else if (auto k = operands.at(0)->to<IR::Constant>()) {
            if (k->value == 0) {
                // 0 will be output if we don't drive it at all
                break;
            } else if ((k->value & (k->value-1)) == 0 && predicate) {
                // use the predicate output
                int shift = floor_log2(k->value);
                if (salu->pred_comb_shift >= 0 && salu->pred_comb_shift != shift)
                    error("conflicting predicate output use in %s", salu);
                else
                    salu->pred_comb_shift = shift;
                if (salu->pred_shift >= 0 && salu->pred_shift != 28) {
                    if (shift > 0) {
                        error("conflicting predicate output use in %s", salu);
                    } else {
                        warning("conflicting predicate output use in %s, upper bits of "
                                "flag output will be non-zero", salu); }
                } else {
                    salu->pred_shift = 28; }
                operands.at(0) = new IR::MAU::SaluReg(k->type, "predicate", false);
            } else if (!salu->dual) {
                // FIXME -- can't output general constant!  Perhaps have an optimization pass
                // that deals with this better, but for now, see if we can use alu_hi to
                // to output the constant and use that instead
                locals.emplace("--output--", LocalVar("--output--", false, LocalVar::ALUHI));
                if (predicate)
                    action->action.push_back(new IR::MAU::Instruction(
                            "alu_a", predicate, new IR::MAU::SaluReg(k->type, "hi", true), k));
                else
                    action->action.push_back(new IR::MAU::Instruction(
                            "alu_a", new IR::MAU::SaluReg(k->type, "hi", true), k));
                LOG3("  add " << *action->action.back());
                operands.at(0) = new IR::MAU::SaluReg(k->type, "alu_hi", true);
            } else {
                error("%s: can't output a constant from a RegisterAction",
                      operands.at(0)->srcInfo); } }
        rv = setup_output();
        break;
    default:
        BUG("Invalid etype");
        break; }
    return rv;
}

bool CreateSaluInstruction::preorder(const IR::Declaration_Variable *v) {
    auto vt = v->type->to<IR::Type::Bits>();
    if (vt && vt->size == salu->width) {
        locals.emplace(v->name, LocalVar(v->name, false));
    } else if (v->type == regtype) {
        locals.emplace(v->name, LocalVar(v->name, true));
    } else {
        error("RegisterAction can't support local var %s", v); }
    return false;
}

std::map<std::pair<cstring, cstring>, std::vector<CreateSaluInstruction::param_t>>
CreateSaluInstruction::function_param_types = {
    {{"DirectRegisterAction", "apply"}, { param_t::VALUE, param_t::OUTPUT, param_t::OUTPUT,
                                          param_t::OUTPUT, param_t::OUTPUT }},
    {{ "RegisterAction", "apply" },     { param_t::VALUE, param_t::OUTPUT, param_t::OUTPUT,
                                          param_t::OUTPUT, param_t::OUTPUT }},
    {{ "RegisterAction", "overflow" },  { param_t::VALUE, param_t::OUTPUT, param_t::OUTPUT,
                                          param_t::OUTPUT, param_t::OUTPUT }},
    {{ "RegisterAction", "underflow" }, { param_t::VALUE, param_t::OUTPUT, param_t::OUTPUT,
                                          param_t::OUTPUT, param_t::OUTPUT }},
#ifdef HAVE_JBAY
    {{ "LearnAction", "apply" },        { param_t::VALUE, param_t::HASH, param_t::LEARN,
                                          param_t::OUTPUT, param_t::OUTPUT,
                                          param_t::OUTPUT, param_t::OUTPUT }},
    {{ "MinMaxAction", "apply" },       { param_t::VALUE, param_t::OUTPUT, param_t::OUTPUT,
                                          param_t::OUTPUT, param_t::OUTPUT }},
#endif
    {{ "selector_action", "apply" },    { param_t::VALUE, param_t::OUTPUT, param_t::OUTPUT,
                                          param_t::OUTPUT, param_t::OUTPUT }}
};

bool CreateSaluInstruction::preorder(const IR::Declaration_Instance *di) {
    BUG_CHECK(!reg_action, "%s: Nested extern", di->srcInfo);
    BUG_CHECK(di->properties.empty(), "direct from P4_14 salu blackbox no longer supported");
    reg_action = di;
    auto type = di->type;
    if (auto st = type->to<IR::Type_Specialized>())
        type = st->baseType;
    action_type_name = type->toString();
    // don't visit constructor arguments...
    visit(di->initializer, "initializer");
    return false;
}

bool CheckStatefulAlu::preorder(IR::MAU::StatefulAlu *salu) {
    const IR::Type *regtype = nullptr;
    if (salu->selector) {
        // selector action
        BUG_CHECK(salu->width == 1 && salu->dual == false, "wrong size for selector action");
        regtype = IR::Type::Bits::get(1);
    } else {
        BUG_CHECK(salu->reg && salu->reg->type->to<IR::Type_Specialized>(), "invalid SALU");
        regtype = getType(salu->reg->type->to<IR::Type_Specialized>()->arguments->at(0)); }
    auto bits = regtype->to<IR::Type::Bits>();
    if (auto str = regtype->to<IR::Type_Struct>()) {
        auto nfields = str->fields.size();
        if (nfields < 1 || !(bits = getType(str->fields.at(0)->type)->to<IR::Type::Bits>()) ||
            nfields > 2 || (nfields > 1 && bits != getType(str->fields.at(1)->type))) {
            bits = nullptr; }
        if (bits) {
            salu->dual = nfields > 1;
            if (bits->size == 1)
                bits = nullptr; } }
    if (bits) {
        if (bits->size == 1 && !salu->dual) {
            // ok
        } else if (bits->size < 8) {
            // too small
            bits = nullptr;
        } else if (bits->size > Device::statefulAluSpec().MaxSize) {
            if (bits->size == Device::statefulAluSpec().MaxDualSize && !salu->dual) {
                // we can support 1x1x  double the max width by using dual mode.
                salu->dual = true;
            } else {
                // too big
                bits = nullptr; }
        } else if (bits->size & (bits->size - 1)) {
            // not a power of two
            bits = nullptr; } }
    if (!bits) {
        std::stringstream detail;
        detail << "    Supported Register element types:\n       ";
        for (int sz = 8; sz < Device::statefulAluSpec().MaxDualSize; sz += sz)
            detail << " bit<" << sz << "> int<" << sz << ">";
        detail << "\n        structs containing one or two fields of one of the above types";
        detail << "\n        bit<1> bit<" << Device::statefulAluSpec().MaxDualSize << ">\n";
        error("Unsupported Register element type %s for %s\n%s", regtype, salu->reg,
              detail.str());
        return false; }

    // For a 1bit SALU, the driver expects a set and clr instr. Check if these
    // instr are already present, if not add them. Test - p4factory stful.p4 -
    // TestOneBit
    if (bits->size == 1) {
        ordered_set<cstring> set_clr { "set_bit", "clr_bit" };
        if (salu->selector) {
            set_clr = ordered_set<cstring> { "set_bit_at", "clr_bit_at" };
            if (salu->selector->mode == "resilient") {
                set_clr.insert("set_bit");
                set_clr.insert("clr_bit"); } }
        for (auto &salu_action : salu->instruction) {
            auto &salu_action_instr = salu_action.second;
            if (salu_action_instr) {
                for (auto &salu_instr : salu_action_instr->action) {
                    LOG4("SALU " << salu->name << " already has " << salu_instr->name <<
                         " instruction");
                    std::string name = std::string(salu_instr->name);
                    /* make sure that if the "bitc" variant instruction exists then
                     * we do not add the non-c variant. */
                    auto pos = name.find("bitc");
                    if (pos != std::string::npos) name.erase(pos+3, 1);
                    set_clr.erase(name); } } }
        for (auto sc : set_clr) {
            if (sc == "") continue;
            LOG4("SALU " << salu->name << " adding " << sc << " instruction");
            auto instr_action = new IR::MAU::SaluAction(IR::ID(sc + "_alu$0"));
            salu->instruction.addUnique(sc + "_alu$0", instr_action);
            auto set_clr_instr = new IR::MAU::Instruction(sc);
            instr_action->action.push_back(set_clr_instr);
        }
    }

    const IR::MAU::SaluAction *first = nullptr;;
    for (auto salu_action : Values(salu->instruction)) {
        auto chain = salu_action->annotations->getSingle("chain_address");
        if (first) {
            if (salu->chain_vpn != (chain != nullptr))
                error("Inconsistent chaining for %s and %s", first, salu_action);
        } else {
            salu->chain_vpn = chain != nullptr;
            first = salu_action;
        }
    }
    lmatch_usage.clear();
    lmatch_usage.salu = salu;
    salu->apply(lmatch_usage);
    return true;
}

void CheckStatefulAlu::AddressLmatchUsage::clear() {
    lmatch_operand = nullptr;
    inuse_mask = lmatch_inuse_mask = 0;
}

unsigned CheckStatefulAlu::AddressLmatchUsage::regmasks[] = { 0xaaaa, 0xcccc, 0xf0f0, 0xff00 };
unsigned CheckStatefulAlu::AddressLmatchUsage::eval_cmp(const IR::Expression *e) {
    if (auto *cmp = e->to<IR::MAU::SaluCmpReg>()) {
        return regmasks[cmp->index];
    } else if (auto *And = e->to<IR::LAnd>()) {
        return eval_cmp(And->left) & eval_cmp(And->right);
    } else if (auto *Or = e->to<IR::LOr>()) {
        return eval_cmp(Or->left) | eval_cmp(Or->right);
    } else if (auto *Not = e->to<IR::LNot>()) {
        return ~eval_cmp(Not->expr);
    } else {
        BUG("Invalid predicate");
    }
}

bool CheckStatefulAlu::AddressLmatchUsage::preorder(const IR::MAU::SaluAction *) {
    inuse_mask = 0;
    return true;
}
bool CheckStatefulAlu::AddressLmatchUsage::preorder(const IR::MAU::SaluCmpReg *cmp) {
    inuse_mask |= regmasks[cmp->index];
    return true;
}

/* Check to see if its safe to replace the lmatch expression 'b' with 'a', given the set
 * of registers in use for the action 'b' -- that is will 'a' evaluate to the same value
 * as 'b' if every register NOT in reguse is false. */
bool CheckStatefulAlu::AddressLmatchUsage::safe_merge(
    const IR::Expression *a, const IR::Expression *b, unsigned inuse
) {
    return (eval_cmp(a) & inuse) == (eval_cmp(b) & inuse);
}


bool CheckStatefulAlu::AddressLmatchUsage::preorder(const IR::MAU::SaluFunction *fn) {
    if (fn->name != "lmatch") return false;
    if (lmatch_operand) {
        if (safe_merge(lmatch_operand, fn->expr, inuse_mask)) {
            return false;
        } else if (safe_merge(fn->expr, lmatch_operand, lmatch_inuse_mask)) {
            lmatch_operand = fn->expr;
            lmatch_inuse_mask = inuse_mask;
        } else {
            error("Conflicting address calls in RegisterActions on %s", salu->reg);
        }
    } else {
        lmatch_operand = fn->expr;
        lmatch_inuse_mask = inuse_mask; }
    return false;
}
bool CheckStatefulAlu::preorder(IR::MAU::SaluFunction *fn) {
    if (fn->name != "lmatch") return false;
    fn->expr = lmatch_usage.lmatch_operand;
    return false;
}

