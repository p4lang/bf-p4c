#include "stateful_alu.h"

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
                error("%s: RegisterAction too complex", pe->srcInfo);
        case LocalVar::MEMALL:
            break;
        default:
            BUG("invalide use in CreateSaluInstruction::LocalVar %s %d", local.name, local.use); }
    } else {
        if (!params) return false;
        for (auto p : params->parameters) {
            if (p->name == pe->path->name) {
                break; }
            ++idx; }
        if (size_t(idx) >= params->parameters.size()) return false; }
    if (field_idx == 0 && field && regtype->is<IR::Type_StructLike>()) {
        for (auto f : regtype->to<IR::Type_StructLike>()->fields) {
            if (f->name == field)
                break;
            ++field_idx; }
        BUG_CHECK(field_idx < 2, "bad field name in register layout"); }
    cstring name = field_idx ? "hi" : "lo";
    switch (idx) {
    case 0:  /* first parameter to apply:  inout value; */
        if (etype == NONE) {
            if (!dest || dest->use == LocalVar::ALUHI)
                alu_write[field_idx] = true;
            etype = VALUE; }
        if (!opcode) opcode = "alu_a";
        if (etype == OUTPUT)
            name = (alu_write[field_idx] ? "alu_" : "mem_") + name;
        e = new IR::MAU::SaluReg(pe->type, name, field_idx > 0);
        break;
    case 1:  /* second parameter to apply:  out rv; */
        if (etype == NONE)
            etype = OUTPUT;
        else
            error("Reading out param %s in RegisterAction not supported", pe);
        if (!opcode) opcode = "output";
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
    BUG_CHECK(params == nullptr, "Nested function?");
    LOG5(func);
    params = func->type->parameters;
    return true;
}
void CreateSaluInstruction::postorder(const IR::Function *func) {
    BUG_CHECK(params == func->type->parameters, "recursion failure");
    params = nullptr;
}
bool CreateSaluInstruction::preorder(const IR::AssignmentStatement *as) {
    BUG_CHECK(operands.empty(), "recursion failure");
    etype = NONE;
    dest = nullptr;
    opcode = cstring();
    visit(as->left, "left");
    BUG_CHECK(operands.size() == (etype != OUTPUT) || ::errorCount() > 0, "recursion failure");
    if (etype == NONE)
        error("Can't assign to %s in register action", as->left);
    else
        visit(as->right);
    if (::errorCount() == 0) {
        BUG_CHECK(operands.size() > (etype != OUTPUT), "recursion failure");
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
                error("%s: RegisterAction too complex", as->srcInfo);
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
    if (!pred_operands.empty()) {
        error("%s: nested conditionals not supported in register action", s->srcInfo);
        return false; }
    etype = IF;
    dest = nullptr;
    visit(s->condition, "condition");
    BUG_CHECK(pred_operands.size() == 1, "recursion failure");
    etype = NONE;
    predicate = pred_operands.at(0);
    visit(s->ifTrue, "ifTrue");
    predicate = negatePred(predicate);
    visit(s->ifFalse, "ifFalse");
    predicate = nullptr;
    pred_operands.clear();
    return false;
}

bool CreateSaluInstruction::preorder(const IR::PathExpression *pe) {
    applyArg(pe, cstring());
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
    if (opcode == cmp->name)
        return new IR::MAU::SaluReg(IR::Type::Bits::get(1), idx ? "cmphi" : "cmplo", idx > 0);
    if (negate_op.at(opcode) == cmp->name)
        return new IR::LNot(new IR::MAU::SaluReg(IR::Type::Bits::get(1),
                                                 idx ? "cmphi" : "cmplo", idx > 0));
    return nullptr;
}

bool CreateSaluInstruction::preorder(const IR::Operation::Relation *rel, cstring op, bool eq) {
    if (etype == IF) {
        visit(rel->left, "left");
        negate = !negate;
        visit(rel->right, "right");
        negate = !negate;
        if (!eq) {
            auto t = rel->left->type->to<IR::Type::Bits>();
            op += (t && t->isSigned) ? ".s" : ".u"; }
        opcode = op;
        if (etype == IF) {
            int idx = 0;
            for (auto cmp : cmp_instr) {
                if (auto inst = reuseCmp(cmp, idx++)) {
                    LOG4("Relation reuse pred_operand: " << inst);
                    pred_operands.push_back(inst);
                    operands.clear();
                    return false; } }
            cstring name = idx ? "hi" : "lo";
            operands.insert(operands.begin(),
                new IR::MAU::SaluReg(IR::Type::Bits::get(1), name, idx > 0));
            cmp_instr.push_back(createInstruction());
            pred_operands.push_back(
                new IR::MAU::SaluReg(IR::Type::Bits::get(1), "cmp" + name, idx > 0));
            LOG4("Relation pred_operand: " << pred_operands.back());
            operands.clear(); }
    } else {
        error("%s: expression in stateful alu too complex", rel->srcInfo); }
    return false;
}

void CreateSaluInstruction::postorder(const IR::LNot *e) {
    if (etype == IF) {
        if (pred_operands.size() < 1) return;  // can only happen if there has been an error
        pred_operands.back() = new IR::LNot(e->srcInfo, pred_operands.back());
        LOG4("LNot rewrite pred_opeands: " << pred_operands.back());
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo); }
}
void CreateSaluInstruction::postorder(const IR::LAnd *e) {
    if (etype == IF) {
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
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo);
        return false; }
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
        output_cmpl = true;
        return; }
    if (complement.count(opcode))
        opcode = complement.at(opcode);
    else if (etype != VALUE)
        error("%s: expression too complex for stateful alu", e->srcInfo);
}

const IR::MAU::Instruction *CreateSaluInstruction::createInstruction() {
    const IR::MAU::Instruction *rv = nullptr;
    switch (etype) {
    case IF:
        action->action.push_back(rv = new IR::MAU::Instruction(opcode, operands));
        LOG3("  add " << *action->action.back());
        break;
    case VALUE:
        if (operands.at(0)->type->width_bits() == 1) {
            BUG_CHECK(!predicate, "can't have predicate on 1-bit instruction");
            auto k = operands.at(1)->to<IR::Constant>();
            BUG_CHECK(k, "non-const writeback in 1-bit instruction?");
            opcode = k->value ? "set_bit" : "clr_bit";
            if (output_cmpl) opcode += 'c';
            onebit = new IR::MAU::Instruction(opcode);
            rv = output = new IR::MAU::Instruction("output",
                new IR::MAU::SaluReg(operands.at(0)->type, "alu_lo", false));
            break; }
        if (predicate)
            operands.insert(operands.begin(), predicate);
        action->action.push_back(rv = new IR::MAU::Instruction(opcode, operands));
        LOG3("  add " << *action->action.back());
        break;
    case OUTPUT:
        if (operands.at(0)->type->width_bits() == 1) {
            BUG_CHECK(!predicate, "can't have predicate on 1-bit instruction");
            opcode = output_cmpl ? "read_bitc" : "read_bit";
            onebit = new IR::MAU::Instruction(opcode);
            rv = output = new IR::MAU::Instruction("output",
                new IR::MAU::SaluReg(operands.at(0)->type, "alu_lo", false));
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
                action->action.push_back(new IR::MAU::Instruction(
                        "alu_a", new IR::MAU::SaluReg(k->type, "hi", true), k));
                LOG3("  add " << *action->action.back());
                operands.at(0) = new IR::MAU::SaluReg(k->type, "alu_hi", true);
            } else {
                error("%s: can't output a constant from a register action",
                      operands.at(0)->srcInfo); } }
        if (predicate)
            operands.insert(operands.begin(), predicate);
        rv = output = new IR::MAU::Instruction(opcode, operands);
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

bool CreateSaluInstruction::preorder(const IR::Declaration_Instance *di) {
    BUG_CHECK(!action, "%s: Nested extern", di->srcInfo);
    LOG3("Creating action " << di->name << " for stateful table " << salu->name);
    action = new IR::MAU::SaluAction(di->srcInfo, di->name);
    salu->instruction.addUnique(di->name, action);
    visit(di->properties, "properties");    // for P4_14 stateful_alu
    visit(di->initializer, "initializer");  // for P4_16 abstract function
    if (cmp_instr.size() > 2)
        error("%s: register action %s needs %d comparisons; only 2 possible",
              di->srcInfo, di->name, cmp_instr.size());
    if (onebit) {
        action->action.push_back(onebit);
        LOG3("  add " << *action->action.back()); }
    if (output) {
        action->action.push_back(output);
        LOG3("  add " << *action->action.back()); }
    if (math.valid) {
        if (salu->math.valid && !(math == salu->math))
            error("%s: math unit incompatible with %s", di->srcInfo, salu);
        else
            salu->math = math; }
    if (math_function && !math_function->expr)
        error("%s: math unit requires math_input", di->srcInfo);
    int alu_hi_use = salu->dual ? 1 : 0;
    for (auto &local : Values(locals))
        if (local.use == LocalVar::ALUHI)
            alu_hi_use++;
    if (alu_hi_use > 1)
        error("%s: too many locals in register action", di->srcInfo);
    return false;
}

bool CheckStatefulAlu::preorder(IR::MAU::StatefulAlu *salu) {
    if (salu->reg->type->is<IR::Type_Extern>()) {
        // selector action
        BUG_CHECK(salu->width == 1 && salu->dual == false, "wrong size for selector action");
        return false; }
    auto regtype = salu->reg->type->to<IR::Type_Specialized>()->arguments->at(0);
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
    if (bits && bits->size == 64 && !salu->dual) {
        // Some (broken?) test programs use width 1x64 when they really mean 2x32
        salu->dual = true;
    } else if (!bits ||
               (bits->size != 1 && bits->size != 8 && bits->size != 16 && bits->size != 32)) {
        error("Unsupported register element type %s for stateful alu %s", regtype, salu); }

    // For a 1bit SALU, the driver expects a set and clr instr. Check if these
    // instr are already present, if not add them. Test - p4factory stful.p4 -
    // TestOneBit
    if (bits && bits->size == 1) {
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
    return false;
}
