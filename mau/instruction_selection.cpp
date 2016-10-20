#include "instruction_selection.h"

template<class T> static
T *clone(const T *ir) { return ir ? ir->clone() : nullptr; }

const IR::ActionFunction *InstructionSelection::preorder(IR::ActionFunction *af) {
    LOG2("InstructionSelection processing action " << af->name);
    this->af = af;
    return af;
}

class InstructionSelection::SplitInstructions : public Transform {
    IR::Vector<IR::Primitive> &split;
    const IR::Expression *postorder(IR::MAU::Instruction *inst) override {
        if (inst->operands[0]->is<IR::TempVar>() && getContext() != nullptr) {
            LOG3("splitting instruction " << inst);
            split.push_back(inst);
            return inst->operands[0]; }
        return inst; }
 public:
    explicit SplitInstructions(IR::Vector<IR::Primitive> &s) : split(s) {}
};

const IR::ActionFunction *InstructionSelection::postorder(IR::ActionFunction *af) {
    this->af = nullptr;
    IR::Vector<IR::Primitive> split;
    for (auto *p : af->action)
        split.push_back(p->apply(SplitInstructions(split)));
    if (split.size() > af->action.size())
        af->action = std::move(split);
    return af;
}

bool InstructionSelection::checkPHV(const IR::Expression *e) {
    return phv.field(e);
}

bool InstructionSelection::checkSrc1(const IR::Expression *e) {
    if (e->is<IR::Constant>()) return true;
    if (e->is<IR::ActionArg>()) return true;
    if (auto cast = e->to<IR::Cast>())
        if (cast->expr->is<IR::ActionArg>()) return true;
    if (auto slice = e->to<IR::Slice>())
        if (slice->e0->is<IR::ActionArg>()) return true;
    return phv.field(e);
}

bool InstructionSelection::checkConst(const IR::Expression *ex, long &value) {
    if (auto *k = ex->to<IR::Constant>()) {
        value = k->asLong();
        return true;
    } else {
        return false;
    }
}

const IR::Expression *InstructionSelection::postorder(IR::BAnd *e) {
    if (!af) return e;
    auto *left = e->left, *right = e->right;
    const char *op = "and";
    auto *l = left->to<IR::MAU::Instruction>();
    auto *r = right->to<IR::MAU::Instruction>();
    if (l && l->name == "not" && r && r->name == "not") {
        left = l->operands[1];
        right = r->operands[1];
        op = "nor";
    } else if (l && l->name == "not") {
        left = l->operands[1];
        op = "andca";
    } else if (r && r->name == "not") {
        right = r->operands[1];
        op = "andcb"; }
    return new IR::MAU::Instruction(e->srcInfo, op, new IR::TempVar(e->type), left, right);
}

const IR::Expression *InstructionSelection::postorder(IR::BOr *e) {
    if (!af) return e;
    auto *left = e->left, *right = e->right;
    const char *op = "or";
    auto *l = left->to<IR::MAU::Instruction>();
    auto *r = right->to<IR::MAU::Instruction>();
    if (l && l->name == "not" && r && r->name == "not") {
        left = l->operands[1];
        right = r->operands[1];
        op = "nand";
    } else if (l && l->name == "not") {
        left = l->operands[1];
        op = "orca";
    } else if (r && r->name == "not") {
        right = r->operands[1];
        op = "orcb"; }
    return new IR::MAU::Instruction(e->srcInfo, op, new IR::TempVar(e->type), left, right);
}

const IR::Expression *InstructionSelection::postorder(IR::BXor *e) {
    if (!af) return e;
    auto *left = e->left, *right = e->right;
    const char *op = "xor";
    auto *l = left->to<IR::MAU::Instruction>();
    auto *r = right->to<IR::MAU::Instruction>();
    if (l && l->name == "not" && r && r->name == "not") {
        left = l->operands[1];
        right = r->operands[1];
    } else if (l && l->name == "not") {
        left = l->operands[1];
        op = "xnor";
    } else if (r && r->name == "not") {
        right = r->operands[1];
        op = "xnor"; }
    return new IR::MAU::Instruction(e->srcInfo, op, new IR::TempVar(e->type), left, right);
}

const IR::Expression *InstructionSelection::postorder(IR::Cmpl *e) {
    if (!af) return e;
    if (auto *fold = clone(e->expr->to<IR::MAU::Instruction>())) {
        if (fold->name == "and") fold->name = "nand";
        else if (fold->name == "andca") fold->name = "orcb";
        else if (fold->name == "andcb") fold->name = "orca";
        else if (fold->name == "nand") fold->name = "and";
        else if (fold->name == "nor") fold->name = "or";
        else if (fold->name == "or") fold->name = "nor";
        else if (fold->name == "orca") fold->name = "andcb";
        else if (fold->name == "orcb") fold->name = "andca";
        else if (fold->name == "xnor") fold->name = "xor";
        else if (fold->name == "xor") fold->name = "xnor";
        else
            fold = nullptr;
        if (fold) return fold; }
    return new IR::MAU::Instruction(e->srcInfo, "not", new IR::TempVar(e->type), e->expr);
}

const IR::Expression *InstructionSelection::postorder(IR::Add *e) {
    if (!af) return e;
    return new IR::MAU::Instruction(e->srcInfo, "add", new IR::TempVar(e->type), e->left, e->right);
}

const IR::Expression *InstructionSelection::postorder(IR::Sub *e) {
    if (!af) return e;
    if (auto *k = e->right->to<IR::Constant>())
        return new IR::MAU::Instruction(e->srcInfo, "add", new IR::TempVar(e->type),
                                        (-*k).clone(), e->left);
    return new IR::MAU::Instruction(e->srcInfo, "sub", new IR::TempVar(e->type), e->left, e->right);
}

const IR::Expression *InstructionSelection::postorder(IR::Shl *e) {
    if (!af) return e;
    if (!e->right->is<IR::Constant>())
        error("%s: shift count must be a constant in %s", e->srcInfo, e);
    return new IR::MAU::Instruction(e->srcInfo, "shl", new IR::TempVar(e->type), e->left, e->right);
}

const IR::Expression *InstructionSelection::postorder(IR::Shr *e) {
    if (!af) return e;
    if (!e->right->is<IR::Constant>())
        error("%s: shift count must be a constant in %s", e->srcInfo, e);
    const char *shr = "shru";
    if (e->type->is<IR::Type_Bits>() && e->type->to<IR::Type_Bits>()->isSigned)
        shr = "shrs";
    return new IR::MAU::Instruction(e->srcInfo, shr, new IR::TempVar(e->type), e->left, e->right);
}

static const IR::MAU::Instruction *fillInstDest(const IR::Expression *in,
                                                const IR::Expression *dest) {
    auto *inst = in ? in->to<IR::MAU::Instruction>() : nullptr;
    auto *tv = inst ? inst->operands[0]->to<IR::TempVar>() : nullptr;
    if (tv) {
        int id;
        if (sscanf(tv->name, "$tmp%d", &id) > 0 && id == tv->uid) --tv->uid;
        auto *rv = inst->clone();
        rv->operands[0] = dest;
        return rv; }
    return nullptr;
}

static bool isDepositMask(long) {
    /* TODO(cdodd) */
    return false;
}
static const IR::Primitive *makeDepositField(IR::Primitive *prim, long) {
    /* TODO(cdodd) */
    return prim;
}

const IR::Primitive *InstructionSelection::postorder(IR::Primitive *prim) {
    if (!af) return prim;
    const IR::Expression *dest = prim->operands.size() > 0 ? prim->operands[0] : nullptr;
    if (prim->name == "modify_field") {
        long mask;
        if ((prim->operands.size() | 1) != 3)
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        else if (!phv.field(dest))
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        else if (auto *rv = fillInstDest(prim->operands[1], dest))
            return rv;
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
    } else if (prim->name == "add" || prim->name == "sub" || prim->name == "subtract") {
        if (prim->operands.size() != 3) {
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        } else if (!phv.field(dest)) {
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        } else if (!checkSrc1(prim->operands[1])) {
            error("%s: source 1 of %s invalid", prim->srcInfo, prim->name);
        } else if (!checkPHV(prim->operands[2])) {
            long value;
            if (prim->name == "add" && checkSrc1(prim->operands[2]) && checkPHV(prim->operands[1]))
                return new IR::MAU::Instruction(prim->srcInfo, "add", dest,
                                                prim->operands[2], prim->operands[1]);
            else if (checkSrc1(prim->operands[2]) && checkConst(prim->operands[1], value))
                return new IR::MAU::Instruction(prim->srcInfo, "add", dest,
                                                prim->operands[2], new IR::Constant(-value));
            error("%s: source 2 of %s invalid", prim->srcInfo, prim->name);
        } else {
            return new IR::MAU::Instruction(*prim); }
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
    } else if (prim->name == "bit_and" || prim->name == "bit_andca" || prim->name == "bit_andcb" ||
               prim->name == "bit_nand" || prim->name == "bit_or" || prim->name == "bit_orca" ||
               prim->name == "bit_orcb" || prim->name == "bit_xor" || prim->name == "bit_xnor") {
        if (prim->operands.size() != 3) {
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        } else if (!phv.field(dest)) {
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        } else if (!checkSrc1(prim->operands[1])) {
            error("%s: source 1 of %s invalid", prim->srcInfo, prim->name);
        } else if (!checkSrc1(prim->operands[2])) {
            error("%s: source 2 of %s invalid", prim->srcInfo, prim->name);
        } else if (!checkPHV(prim->operands[1]) && !checkPHV(prim->operands[2])) {
            error("%s: one source of %s must be a simple field", prim->srcInfo, prim->name);
        } else {
            auto rv = new IR::MAU::Instruction(*prim);
            rv->name = rv->name + 4;  // strip off bit_ prefix
            return rv; } }
    WARNING("unhandled in InstSel: " << *prim);
    return prim;
}


