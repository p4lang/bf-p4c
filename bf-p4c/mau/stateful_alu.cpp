#include "stateful_alu.h"
#include "ir/pattern.h"

const Device::StatefulAluSpec &TofinoDevice::getStatefulAluSpec() const {
    static const Device::StatefulAluSpec spec = {
        /* .CmpMask = */ false,
        /* .CmpUnits = */ { "lo", "hi" },
        /* .MaxSize = */ 32,
        /* .OutputWords = */ 1,
    };
    return spec;
}

#if HAVE_JBAY
const Device::StatefulAluSpec &JBayDevice::getStatefulAluSpec() const {
    static const Device::StatefulAluSpec spec = {
        /* .CmpMask = */ true,
        /* .CmpUnits = */ { "cmp0", "cmp1", "cmp2", "cmp3" },
        /* .MaxSize = */ 64,
        /* .OutputWords = */ 4,
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
    static const char *names[] = { "NONE", "IF", "VALUE", "OUTPUT" };
    if (e < sizeof(names)/sizeof(names[0]))
        return out << names[e];
    else
        return out << "<invalid " << e << ">"; }

/// Check a name to see if it is a reference to an argument of register_action::apply,
/// or a reference to the local var we put in alu_hi.
/// or a reference to a copy of an in argument
/// If so, process it as an operand and return true
bool CreateSaluInstruction::applyArg(const IR::PathExpression *pe, cstring field) {
    LOG4("applyArg(" << pe << ", " << field << ") etype = " << etype);
    assert(dest == nullptr || etype != NONE);
    IR::Expression *e = nullptr;
    int idx = 0, field_idx = 0;
    output_index = 0;
    if (locals.count(pe->path->name.name)) {
        auto &local = locals.at(pe->path->name.name);
        if (etype == NONE)
            dest = &local;
        switch (local.use) {
        case LocalVar::NONE:
            // if this becomes a real instruction (not an elided copy), this
            // local will become alu_hi, so fall through
        case LocalVar::ALUHI:
            field_idx = 1;
            break;
        case LocalVar::MEMHI:
            field_idx = 1;
        case LocalVar::MEMLO:
            if (etype == NONE)
                error("%s: %s too complex", pe->srcInfo, action_type_name);
        case LocalVar::MEMALL:
            break;
        default:
            BUG("invalide use in CreateSaluInstruction::LocalVar %s %d", local.name, local.use); }
    } else {
        if (!params) return false;
        for (auto p : params->parameters) {
            if (p->name == pe->path->name) {
                break; }
            if (param_types->at(idx) == param_t::OUTPUT)
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
        if (etype == NONE) {
            if (!dest || dest->use == LocalVar::ALUHI)
                alu_write[field_idx] = true;
            etype = VALUE; }
        if (!opcode) opcode = "alu_a";
        if (etype == OUTPUT)
            name = (alu_write[field_idx] ? "alu_" : "mem_") + name;
        e = new IR::MAU::SaluReg(pe->type, name, field_idx > 0);
        break;
    case param_t::OUTPUT:       /* out rv; */
        if (etype == NONE)
            etype = OUTPUT;
        else
            error("Reading out param %s in %s not supported", pe, action_type_name);
        if (output_index > Device::statefulAluSpec().OutputWords)
            error("Only %d stateful output%s supported", Device::statefulAluSpec().OutputWords,
                  Device::statefulAluSpec().OutputWords > 1 ? "s" : "");
        if (!opcode) opcode = "output";
        break;
    case param_t::HASH:         /* in digest */
        if (etype == NONE) {
            error("Writing in param %s in %s not supported", pe, action_type_name);
            return false; }
        e = new IR::MAU::SaluReg(pe->type, "phv_" + name, field_idx > 0);
        break;
    case param_t::LEARN:        /* in learn */
        if (etype == NONE) {
            error("Writing in param %s in %s not supported", pe, action_type_name);
            return false; }
        e = new IR::MAU::SaluReg(pe->type, "learn", false);
        break;
    case param_t::MATCH:        /* out match */
        if (etype != NONE) {
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
                error("%s: Conflicting overflow function for register", func->srcInfo);
            else
                salu->overflow = name; }
        if (func->name == "underflow") {
            if (salu->underflow)
                error("%s: Conflicting underflow function for register", func->srcInfo);
            else
                salu->underflow = name; } }
    param_types = &function_param_types.at(std::make_pair(action_type_name, func->name));
    LOG3("Creating action " << name << " for stateful table " << salu->name);
    LOG5(func);
    action = new IR::MAU::SaluAction(func->srcInfo, name);
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
    int alu_hi_use = salu->dual ? 1 : 0;
    for (auto &local : Values(locals))
        if (local.use == LocalVar::ALUHI)
            alu_hi_use++;
    if (alu_hi_use > 1)
        error("%s: too many locals in register action", func->srcInfo);
    params = nullptr;
    action = nullptr;
}

bool CreateSaluInstruction::preorder(const IR::AssignmentStatement *as) {
    BUG_CHECK(operands.empty(), "recursion failure");
    etype = NONE;
    dest = nullptr;
    opcode = cstring();
    visit(as->left, "left");
    BUG_CHECK(operands.size() == (etype < OUTPUT) || ::errorCount() > 0, "recursion failure");
    if (etype == NONE)
        error("Can't assign to %s in register action", as->left);
    else
        visit(as->right);
    if (::errorCount() == 0) {
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
                error("%s: %s too complex", as->srcInfo, action_type_name);
            dest->use = use;
            LOG3("local " << dest->name << " use " << dest->use); }
        if (!dest || dest->use == LocalVar::ALUHI)
            createInstruction(); }
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
bool CreateSaluInstruction::preorder(const IR::Slice *sl) {
    visit(sl->e0, "e0");
    if (operands.back() == sl->e0)
        operands.back() = sl;
    else
        operands.back() = new IR::Slice(sl->srcInfo, operands.back(), sl->e1, sl->e2);
    return false;
}

bool CreateSaluInstruction::preorder(const IR::Primitive *prim) {
    if (prim->name == "math_unit.execute") {
        BUG_CHECK(prim->operands.size() == 2, "typechecking failure");
        operands.push_back(new IR::MAU::SaluMathFunction(prim->srcInfo, prim->operands.at(1)));
        LOG4("Math Unit operand: " << operands.back());
        auto gref = prim->operands.at(0)->to<IR::GlobalRef>();
        auto mu = gref ? gref->obj->to<IR::Declaration_Instance>() : nullptr;
        BUG_CHECK(mu, "typechecking failure?");
        BUG_CHECK(mu->arguments->size() == 4, "typechecking failure");
        math.valid = true;
        if (auto k = mu->arguments->at(0)->expression->to<IR::BoolLiteral>())
            math.exp_invert = k->value;
        if (auto k = mu->arguments->at(1)->expression->to<IR::Constant>())
            math.exp_shift = k->asInt();
        if (auto k = mu->arguments->at(2)->expression->to<IR::Constant>())
            math.scale = k->asInt();
        if (auto data = mu->arguments->at(3)->expression->to<IR::ListExpression>()) {
            unsigned i = 0;
            for (auto e : data->components) {
                if (i >= sizeof(math.table)/sizeof(math.table[0])) {
                    error("%s: too many elements for math table initializer", data->srcInfo);
                    break; }
                if (auto k = e->to<IR::Constant>())
                    math.table[i++] = k->asInt(); }
        } else {
            error("initializer %s is not a list expression", mu->arguments->at(3)->expression); }
    } else if (prim->name.endsWith(".address")) {
        operands.push_back(new IR::MAU::SaluReg(prim->type, "address", false));
    } else if (prim->name.endsWith(".predicate")) {
        operands.push_back(new IR::MAU::SaluReg(prim->type, "predicate", false));
    } else {
        error("%s: expression too complex for register action", prim->srcInfo); }
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
    auto bit1 = IR::Type::Bits::get(1);
    auto name = Device::statefulAluSpec().cmpUnit(idx);
    if (!name.startsWith("cmp")) name = "cmp" + name;
    if (opcode == cmp->name)
        return new IR::MAU::SaluReg(bit1, name, idx & 1);
    if (negate_op.at(opcode) == cmp->name)
        return new IR::LNot(new IR::MAU::SaluReg(bit1, name, idx & 0));
    return nullptr;
}

bool CreateSaluInstruction::preorder(const IR::Operation::Relation *rel, cstring op, bool eq) {
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
        auto bit1 = IR::Type::Bits::get(1);
        cstring name = Device::statefulAluSpec().cmpUnit(idx);
        operands.insert(operands.begin(), new IR::MAU::SaluReg(bit1, name, idx & 1));
        cmp_instr.push_back(createInstruction());
        if (!name.startsWith("cmp")) name = "cmp" + name;
        pred_operands.push_back(new IR::MAU::SaluReg(bit1, name, idx & 1));
        LOG4("Relation pred_operand: " << pred_operands.back());
        operands.clear();
    } else {
        error("%s: expression in stateful alu too complex", rel->srcInfo); }
    return false;
}

void CreateSaluInstruction::postorder(const IR::LNot *e) {
    if (etype == IF) {
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
    if (etype == OUTPUT && e->type->width_bits() == 1) {
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

static void setup_output(std::vector<const IR::MAU::Instruction *> &output, int index,
                         const IR::Expression *predicate,
                         std::vector<const IR::Expression *> operands) {
    if (output.size() <= size_t(index)) output.resize(index+1);
    if (Device::statefulAluSpec().OutputWords > 1)
        operands.insert(operands.begin(), new IR::MAU::SaluReg(operands.at(0)->type,
                                "word" + std::to_string(index), false));
    if (predicate)
        operands.insert(operands.begin(), predicate);
    if (output[index]) {
        if (!equiv(operands.back(), output[index]->operands.back())) {
            error("Incompatible outputs in RegisterAction: %s and %s\n",
                  output[index]->operands.back(), operands.back());
            return; }
        if (output[index]->operands.size() == operands.size()) {
            if (predicate)
                operands[0] = new IR::LOr(output[index]->operands[0], operands[0]);
            else
                return;
        } else if (predicate) {
            return; } }
    output[index] = new IR::MAU::Instruction("output", operands);
}

const IR::MAU::Instruction *CreateSaluInstruction::createInstruction() {
    const IR::MAU::Instruction *rv = nullptr;
    switch (etype) {
    case IF:
        action->action.push_back(rv = new IR::MAU::Instruction(opcode, operands));
        LOG3("  add " << *action->action.back());
        break;
    case VALUE:
    case MATCH:
        if (operands.at(0)->type->width_bits() == 1) {
            BUG_CHECK(!predicate, "can't have predicate on 1-bit instruction");
            auto k = operands.at(1)->to<IR::Constant>();
            BUG_CHECK(k, "non-const writeback in 1-bit instruction?");
            opcode = k->value ? "set_bit" : "clr_bit";
            if (onebit_cmpl) opcode += 'c';
            rv = onebit = new IR::MAU::Instruction(opcode);
            break; }
        if (predicate)
            operands.insert(operands.begin(), predicate);
        action->action.push_back(rv = new IR::MAU::Instruction(opcode, operands));
        LOG3("  add " << *action->action.back());
        break;
    case OUTPUT:
        if (operands.at(0)->type->width_bits() == 1) {
            BUG_CHECK(!predicate, "can't have predicate on 1-bit instruction");
            opcode = onebit_cmpl ? "read_bitc" : "read_bit";
            rv = onebit = new IR::MAU::Instruction(opcode);
            setup_output(outputs, 0, nullptr, {
                new IR::MAU::SaluReg(IR::Type::Bits::get(1), "alu_lo", false) });
            break;
        } else if (auto k = operands.at(0)->to<IR::Constant>()) {
            if (k->value == 0) {
                // 0 will be output if we don't drive it at all
                break;
            } else if (k->value == 1 && predicate) {
                // use the predicate output
                // FIXME -- need to set the salu_output_pred_shift/salu_output_pred_comb_shift
                // registers properly, but we currently have no way of specifying them in the
                // assembler.  The default (0) value works out for a 1 bit output, but by
                // using them we could generate other values (any power of 2?)
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
                error("%s: can't output a constant from a register action",
                      operands.at(0)->srcInfo); } }
        setup_output(outputs, output_index, predicate, operands);
        rv = outputs[output_index];
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
        error("register action can't support local var %s", v); }
    return false;
}

std::map<std::pair<cstring, cstring>, std::vector<CreateSaluInstruction::param_t>>
CreateSaluInstruction::function_param_types = {
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
    if (salu->reg->type->is<IR::Type_Extern>()) {
        // selector action
        BUG_CHECK(salu->width == 1 && salu->dual == false, "wrong size for selector action");
        return false; }
    auto regtype = salu->reg->type->to<IR::Type_Specialized>()->arguments->at(0);
    if (auto td = regtype->to<IR::Type_Typedef>())
        // FIXME -- Type_Typedef should have been resolved and removed by Typechecking in the midend
        regtype = td->type;
    auto bits = regtype->to<IR::Type::Bits>();
    if (auto str = regtype->to<IR::Type_Struct>()) {
        auto nfields = str->fields.size();
        if (nfields < 1 || !(bits = str->fields.at(0)->type->to<IR::Type::Bits>()) ||
            nfields > 2 || (nfields > 1 && bits != str->fields.at(1)->type))
            bits = nullptr;
        if (bits) {
            salu->dual = nfields > 1;;
            if (bits->size == 1)
                bits = nullptr; } }
    if (bits) {
        if (bits->size == 1 && !salu->dual) {
            // ok
        } else if (bits->size == 64 && !salu->dual) {
            // Some (broken?) test programs use width 1x64 when they really mean 2x32
            salu->dual = true;
        } else if (bits->size < 8) {
            // too small
            bits = nullptr;
        } else if (bits->size > Device::statefulAluSpec().MaxSize) {
            // too big
            bits = nullptr;
        } else if (bits->size & (bits->size - 1)) {
            // not a power of two
            bits = nullptr; } }
    if (!bits) {
        error("Unsupported register element type %s for stateful alu %s", regtype, salu);
        return false; }

    // For a 1bit SALU, the driver expects a set and clr instr. Check if these
    // instr are already present, if not add them. Test - p4factory stful.p4 -
    // TestOneBit
    if (bits->size == 1) {
        std::set<cstring> set_clr { "set_bit", "clr_bit" };
        for (auto &salu_action : salu->instruction) {
            auto &salu_action_instr = salu_action.second;
            if (salu_action_instr) {
                for (auto &salu_instr : salu_action_instr->action) {
                    set_clr.erase(salu_instr->name);
                }
            }
        }
        for (auto sc : set_clr) {
            if (sc == "") continue;
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

    return false;
}

