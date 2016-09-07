#include "instruction_selection.h"

const IR::ActionFunction *InstructionSelection::preorder(IR::ActionFunction *af) {
    return af;
}

const IR::ActionFunction *InstructionSelection::postorder(IR::ActionFunction *af) {
    return af;
}

static bool checkPHV(const IR::Expression *) {
    return true; }
static bool checkSrc1(const IR::Expression *) {
    return true; }
static bool checkConst(const IR::Expression *ex, long &value) {
    if (auto *k = ex->to<IR::Constant>()) {
        value = k->asLong();
        return true;
    } else {
        return false;
    }
}

static bool isDepositMask(long) {
    return false;
}
static const IR::Primitive *makeDepositField(IR::Primitive *prim, long) {
    return prim;
}

const IR::Primitive *InstructionSelection::postorder(IR::Primitive *prim) {
    const IR::Expression *dest = prim->operands.size() > 0 ? prim->operands[0] : nullptr;
    if (prim->name == "modify_field") {
        long mask;
        if ((prim->operands.size() | 1) != 3)
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        else if (!phv.field(dest))
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        else if (!checkSrc1(prim->operands[1]))
            error("%s: source of %s invalid", prim->srcInfo, prim->name);
        else if (prim->operands.size() == 2)
            return new IR::MAU::Instruction(prim->srcInfo, "set", &prim->operands);
        else if (!checkConst(prim->operands[2], mask))
            error("%s: mask of %s must be a constant", prim->srcInfo, prim->name);
        else if (1L << dest->type->width_bits() == mask + 1)
            return new IR::MAU::Instruction(prim->srcInfo, "set", dest, prim->operands[1]);
        else if (isDepositMask(mask))
            return makeDepositField(prim, mask);
        else
            return new IR::MAU::Instruction(prim->srcInfo, "bitmask-set", &prim->operands);
    } else if (prim->name == "add" || prim->name == "sub") {
        if (prim->operands.size() != 3)
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        else if (!phv.field(dest))
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        else if (!checkSrc1(prim->operands[1]))
            error("%s: source 1 of %s invalid", prim->srcInfo, prim->name);
        else if (!checkPHV(prim->operands[2]))
            error("%s: source 2 of %s invalid", prim->srcInfo, prim->name);
        else
            return new IR::MAU::Instruction(*prim);
    } else if (prim->name == "add_to_field") {
        if (prim->operands.size() != 2)
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        else if (!phv.field(dest))
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        else if (!checkSrc1(prim->operands[1]))
            error("%s: source 1 of %s invalid", prim->srcInfo, prim->name);
        else
            return new IR::MAU::Instruction(prim->srcInfo, "add", dest, prim->operands[1], dest);
    } else if (prim->name == "subtract_from_field") {
        if (prim->operands.size() != 2)
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        else if (!phv.field(dest))
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        else if (!checkSrc1(prim->operands[1]))
            error("%s: source 1 of %s invalid", prim->srcInfo, prim->name);
        else if (auto *k = prim->operands[1]->to<IR::Constant>())
            return new IR::MAU::Instruction(prim->srcInfo, "add", dest, dest, (-*k).clone());
        else
            return new IR::MAU::Instruction(prim->srcInfo, "sub", dest, dest, prim->operands[1]);
    }
    return prim;
}


