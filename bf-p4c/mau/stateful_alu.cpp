#include "stateful_alu.h"

bool CreateSaluInstruction::preorder(const IR::Property *prop) {
    etype = NONE;
    negate = false;
    opcode = cstring();
    operands.clear();
    if (prop->name == "reg") {
        // handled in extract_maupipe when creating the IR::MAU::StatefulAlu
        return false;
    } else if (prop->name == "selector_binding") {
        // FIXME -- skip for now
        return false;
    } else if (prop->name == "initial_register_lo_value") {
        // not sure if Tofino can even set this?  Or just goes to context json.
        return false;
    } else if (prop->name == "initial_register_hi_value") {
        // not sure if Tofino can even set this?  Or just goes to context json.
        return false;
    } else if (prop->name == "condition_hi" || prop->name == "condition_lo") {
        etype = COND;
    } else if (prop->name == "update_lo_1_predicate" || prop->name == "update_lo_2_predicate" ||
               prop->name == "update_hi_1_predicate" || prop->name == "update_hi_2_predicate" ||
               prop->name == "output_predicate") {
        etype = PRED;
    } else if (prop->name == "update_lo_1_value" || prop->name == "update_lo_2_value" ||
               prop->name == "update_hi_1_value" || prop->name == "update_hi_2_value") {
        if (salu->width == 1) {
            etype = BIT_INSTR;
        } else {
            opcode = "alu_a";
            etype = VALUE; }
    } else if (prop->name == "output_value") {
        opcode = "output";
        etype = OUTPUT;
    } else if (prop->name == "output_dst") {
        if (auto ev = prop->value->to<IR::ExpressionValue>())
            action->output_dst = ev->expression;
        return false;
    } else if (prop->name == "math_unit_input") {
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            math_input = ev->expression;
            if (math_function)
                math_function->expr = math_input;
        } else {
            error("%s: %s must be a constant", prop->value->srcInfo, prop->name); }
        return false;
    } else if (prop->name == "math_unit_output_scale") {
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            if (auto k = ev->expression->to<IR::Constant>()) {
                math.valid = true;
                math.scale = k->asInt();
                return false; } }
        error("%s: %s must be a constant", prop->value->srcInfo, prop->name);
        return false;
    } else if (prop->name == "math_unit_exponent_shift") {
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            if (auto k = ev->expression->to<IR::Constant>()) {
                math.valid = true;
                math.exp_shift = k->asInt();
                return false; } }
        error("%s: %s must be a constant", prop->value->srcInfo, prop->name);
        return false;
    } else if (prop->name == "math_unit_exponent_invert") {
        if (auto ev = prop->value->to<IR::ExpressionValue>()) {
            if (auto k = ev->expression->to<IR::BoolLiteral>()) {
                math.valid = true;
                math.exp_invert = k->value;
                return false; } }
        error("%s: %s must be a boolean constant", prop->value->srcInfo, prop->name);
        return false;
    } else if (prop->name == "math_unit_lookup_table") {
        if (auto elist = prop->value->to<IR::ExpressionListValue>()) {
            int idx = -1;
            math.valid = true;
            for (auto ev : elist->expressions) {
                if (++idx >= 16)
                    error("%s: too many valus for %s", ev->srcInfo, prop->name);
                else if (auto k = ev->to<IR::Constant>())
                    math.table[idx] = k->asInt();
                else
                    error("%s: %s values must be a constants", ev->srcInfo, prop->name); }
        } else {
            error("%s: %s must be a list", prop->value->srcInfo, prop->name); }
        return false;
    } else if (prop->name == "reduction_or_group") {
        // FIXME -- skip for now
        return false;
    } else if (prop->name == "stateful_logging_mode") {
        // FIXME -- skip for now
        return false;
    } else {
        BUG("Unhandled property %s in stateful_alu extern", prop->name);
    }
    return true;
}

bool CreateSaluInstruction::preorder(const IR::Constant *c) {
    if (etype == COND && c->value == 0)
        return false;
    if (negate)
        c = (-*c).clone();
    operands.push_back(c);
    return false;
}
bool CreateSaluInstruction::preorder(const IR::AttribLocal *attr) {
    IR::Expression *e = nullptr;
    switch (etype) {
    case OUTPUT:
        if (attr->name == "predicate" || attr->name == "combined_predicate")
            e = new IR::MAU::SaluReg("pred");
        else if (attr->name == "register_lo")
            e = new IR::MAU::SaluReg("mem_lo");
        else if (attr->name == "register_hi")
            e = new IR::MAU::SaluReg("mem_hi");
        else if (attr->name == "alu_lo")
            e = new IR::MAU::SaluReg("alu_lo");
        else if (attr->name == "alu_hi")
            e = new IR::MAU::SaluReg("alu_hi");
        break;
    case VALUE:
        if (attr->name == "math_unit") {
            if (!math_function)
                math_function = new IR::MAU::SaluMathFunction(attr->srcInfo, math_input);
            e = math_function; }
        // fall through
    case COND:
        if (attr->name == "register_lo")
            e = new IR::MAU::SaluReg("lo");
        else if (attr->name == "register_hi")
            e = new IR::MAU::SaluReg("hi");
        else if (attr->name == "alu_lo")
            e = new IR::MAU::SaluReg("alu_lo");
        else if (attr->name == "alu_hi")
            e = new IR::MAU::SaluReg("alu_hi");
        break;
    case PRED:
        if (attr->name == "condition_lo")
            e = new IR::MAU::SaluReg("cmplo");
        else if (attr->name == "condition_hi")
            e = new IR::MAU::SaluReg("cmphi");
        break;
    case BIT_INSTR:
        if (attr->name == "set_bit" || attr->name == "set_bitc" || attr->name == "clr_bit" ||
            attr->name == "clr_bitc" || attr->name == "read_bit" || attr->name == "read_bitc" ||
            attr->name == "set_bit_at" || attr->name == "set_bitc_at" ||
            attr->name == "clr_bit_at" || attr->name == "clr_bitc_at") {
            opcode = attr->name;
            return false; }
        break;
    default:
        break; }
    if (e) {
        if (negate)
            e = new IR::Neg(e);
        operands.push_back(e);
    } else {
        error("%s: unexpected keyword %s", attr->srcInfo, attr->name); }
    return false;
}
bool CreateSaluInstruction::preorder(const IR::Member *e) {
    if (negate)
        operands.push_back(new IR::Neg(e));
    else
        operands.push_back(e);
    return false;
}

bool CreateSaluInstruction::preorder(const IR::Operation::Relation *rel, cstring op, bool eq) {
    if (etype == COND) {
        visit(rel->left, "left");
        negate = !negate;
        visit(rel->right, "right");
        negate = !negate;
        if (!eq) {
            auto t = rel->left->type->to<IR::Type::Bits>();
            op += (t && t->isSigned) ? ".s" : ".u"; }
        opcode = op;
    } else {
        error("%s: expression in stateful alu too complex", rel->srcInfo); }
    return false;
}

void CreateSaluInstruction::postorder(const IR::LNot *e) {
    if (operands.size() < 1) return;  // can only happen if there has been an error
    if (etype == PRED)
        operands.back() = new IR::LNot(e->srcInfo, operands.back());
    else
        error("%s: expression too complex for stateful alu", e->srcInfo);
}
void CreateSaluInstruction::postorder(const IR::LAnd *e) {
    if (operands.size() < 2) return;  // can only happen if there has been an error
    if (etype == PRED) {
        auto r = operands.back();
        operands.pop_back();
        operands.back() = new IR::LAnd(e->srcInfo, operands.back(), r);
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo); }
}
void CreateSaluInstruction::postorder(const IR::LOr *e) {
    if (operands.size() < 2) return;  // can only happen if there has been an error
    if (etype == PRED) {
        auto r = operands.back();
        operands.pop_back();
        operands.back() = new IR::LOr(e->srcInfo, operands.back(), r);
    } else {
        error("%s: expression too complex for stateful alu", e->srcInfo); }
}

bool CreateSaluInstruction::preorder(const IR::Add *e) {
    switch (etype) {
    case COND:
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
    case COND:
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
    if (complement.count(opcode))
        opcode = complement.at(opcode);
    else if (etype != VALUE)
        error("%s: expression too complex for stateful alu", e->srcInfo);
}

void CreateSaluInstruction::postorder(const IR::Property *prop) {
    int pred_idx = -1;
    cstring dest;
    if (prop->name == "condition_hi") {
        operands.insert(operands.begin(), new IR::MAU::SaluReg("hi"));
    } else if (prop->name == "condition_lo") {
        operands.insert(operands.begin(), new IR::MAU::SaluReg("lo"));
    } else if (prop->name == "update_lo_1_predicate" || prop->name == "update_lo_1_value") {
        pred_idx = 0;
        dest = "lo";
    } else if (prop->name == "update_lo_2_predicate" || prop->name == "update_lo_2_value") {
        pred_idx = 1;
        dest = "lo";
    } else if (prop->name == "update_hi_1_predicate" || prop->name == "update_hi_1_value") {
        pred_idx = 2;
        dest = "hi";
    } else if (prop->name == "update_hi_2_predicate" || prop->name == "update_hi_2_value") {
        pred_idx = 3;
        dest = "hi";
    } else if (prop->name == "output_predicate" || prop->name == "output_value") {
        pred_idx = 4;
    } else if (prop->name == "output_dst") {
    } else if (prop->name == "math_unit_input") {
    } else if (prop->name == "math_unit_output_scale") {
    } else if (prop->name == "math_unit_exponent_shift") {
    } else if (prop->name == "math_unit_exponent_invert") {
    } else if (prop->name == "math_unit_lookup_table") {
    } else if (prop->name == "reduction_or_group") {
    } else if (prop->name == "stateful_logging_mode") {
    }
    switch (etype) {
    case COND:
        action->action.push_back(new IR::MAU::Instruction(opcode, operands));
        LOG3("  add " << *action->action.back());
        break;
    case PRED:
        predicates[pred_idx] = operands.at(0);
        break;
    case VALUE:
        operands.insert(operands.begin(), new IR::MAU::SaluReg(dest));
        /* DANGER -- we're relying on the properties being processed in alphabetical
         * order (as they're in a NameMap<std::map>) to process predicates before values */
        if (predicates[pred_idx])
            operands.insert(operands.begin(), predicates[pred_idx]);
        action->action.push_back(new IR::MAU::Instruction(opcode, operands));
        LOG3("  add " << *action->action.back());
        break;
    case BIT_INSTR:
        if (opcode) {
            action->action.push_back(new IR::MAU::Instruction(opcode));
            LOG3("  add " << *action->action.back());
        } else {
            /* error message already output */ }
        break;
    case OUTPUT:
        if (predicates[pred_idx])
            operands.insert(operands.begin(), predicates[pred_idx]);
        output = new IR::MAU::Instruction(opcode, operands);
        break;
    default:
        break; }
}

bool CreateSaluInstruction::preorder(const IR::Declaration_Instance *di) {
    BUG_CHECK(!action, "%s: Nested extern", di->srcInfo);
    BUG_CHECK(di->type->to<IR::Type_Extern>()->name == "stateful_alu_14",
              "%s: Not a stateful_alu", di->srcInfo);
    LOG3("Creating action " << di->name << " for stateful table " << salu->name);
    action = new IR::MAU::SaluAction(di->srcInfo, di->name);
    salu->instruction.addUnique(di->name, action);
    predicates[0] = predicates[1] = predicates[2] = predicates[3] = predicates[4] = nullptr;
    output = nullptr;
    math = IR::MAU::StatefulAlu::MathUnit();
    math_function = nullptr;
    math_input = nullptr;
    di->properties.visit_children(*this);  // only visit the properties
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
    action = nullptr;
    predicates[0] = predicates[1] = predicates[2] = predicates[3] = predicates[4] = nullptr;
    output = nullptr;
    math = IR::MAU::StatefulAlu::MathUnit();
    math_function = nullptr;
    math_input = nullptr;
    return false;
}

bool CheckStatefulAlu::preorder(IR::MAU::StatefulAlu *salu) {
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
    return false;
}
