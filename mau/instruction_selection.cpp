#include "instruction_selection.h"

template<class T> static
T *clone(const T *ir) { return ir ? ir->clone() : nullptr; }

InstructionSelection::InstructionSelection(PhvInfo &phv) : phv(phv) {}

Visitor::profile_t InstructionSelection::init_apply(const IR::Node *root) {
    auto rv = MauTransform::init_apply(root);
    stateful.clear();
    return rv;
}

IR::Member *InstructionSelection::gen_stdmeta(cstring field) {
    // FIXME -- this seems like an ugly hack -- need to make it match up to the
    // names created by CreateThreadLocalInstances.  Should have a better way of getting
    // a handle on the standard metadata.
    auto *std_meta = findContext<IR::Tofino::Pipe>()->standard_metadata->clone();
    std_meta->name = IR::ID(cstring::to_cstring(VisitingThread(this)) + "::" + std_meta->name);
    if (auto f = std_meta->type->getField(field))
        return new IR::Member(f->type, new IR::ConcreteHeaderRef(std_meta), field);
    else
        BUG("No field %s in standard_metadata", field);
    return nullptr;
}

const IR::ActionFunction *InstructionSelection::preorder(IR::ActionFunction *af) {
    BUG_CHECK(this->af == nullptr, "Nested action functions");
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
    BUG_CHECK(this->af == af, "Nested action functions");
    this->af = nullptr;
    IR::Vector<IR::Primitive> split;
    for (auto *p : af->action)
        split.push_back(p->apply(SplitInstructions(split)));
    if (split.size() > af->action.size())
        af->action = std::move(split);
    LOG1("Af name " << af->name);
    if (stateful.count(af) || modify_with_hash.count(af)) {
        BUG_CHECK(!af->is<IR::MAU::ActionFunctionEx>(), "already processed action function?");
        auto *rv = new IR::MAU::ActionFunctionEx(*af);
        LOG1("Size in instr sel " << modify_with_hash[af].size());
        rv->stateful.insert(rv->stateful.end(), stateful[af].begin(), stateful[af].end());
        rv->modify_with_hash.insert(rv->modify_with_hash.end(), modify_with_hash[af].begin(),
                                    modify_with_hash[af].end());
        stateful[rv] = stateful[af];
        modify_with_hash[rv] = modify_with_hash[af];
        LOG1("Size test 2 " << rv->modify_with_hash.size());
        af = rv; }
    return af;
}

bool InstructionSelection::checkPHV(const IR::Expression *e) {
    return phv.field(e);
}

bool InstructionSelection::checkSrc1(const IR::Expression *e) {
    if (e->is<IR::Constant>()) return true;
    if (e->is<IR::ActionArg>()) return true;
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

const IR::Expression *InstructionSelection::postorder(IR::Cast *e) {
    // FIXME -- just ignoring casts may be wrong if they actually do something
    return e->expr;
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

const IR::Expression *InstructionSelection::postorder(IR::Mux *e) {
    if (auto r = e->e0->to<IR::Operation_Relation>()) {
        bool isMin = false;
        if (r->is<IR::Lss>() || r->is<IR::Leq>())
            isMin = true;
        else if (!r->is<IR::Grt>() && !r->is<IR::Geq>())
            return e;
        if (*r->left == *e->e2 && *r->right == *e->e1)
            isMin = !isMin;
        else if (*r->left != *e->e1 || *r->right != *e->e2)
            return e;
        cstring op = isMin ? "minu" : "maxu";
        if (auto t = r->left->type->to<IR::Type::Bits>())
            if (t->isSigned)
                op = isMin ? "mins" : "maxs";
        return new IR::MAU::Instruction(e->srcInfo, op, new IR::TempVar(e->type), e->e1, e->e2); }
    return e;
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
    LOG1("Primitive name " << prim->name);
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
            return new IR::MAU::Instruction(prim->srcInfo, "bitmasked-set", &prim->operands);
    } else if (prim->name == "add" || prim->name == "sub" || prim->name == "subtract") {
        if (prim->operands.size() != 3) {
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        } else if (!phv.field(dest)) {
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        } else if (!checkSrc1(prim->operands[1])) {
            error("%s: source 1 of %s invalid", prim->srcInfo, prim->name);
        } else if (!checkPHV(prim->operands[2])) {
            if (checkPHV(prim->operands[1])) {
                if (prim->name == "add") {
                    if (checkSrc1(prim->operands[2]))
                        return new IR::MAU::Instruction(prim->srcInfo, "add", dest,
                                                        prim->operands[2], prim->operands[1]);
                } else if (auto *k = prim->operands[2]->to<IR::Constant>()) {
                    return new IR::MAU::Instruction(prim->srcInfo, "add", dest, (-*k).clone(),
                                                    prim->operands[1]); } }
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
            return rv; }
    } else if (prim->name == "drop" || prim->name == "mark_to_drop") {
        return new IR::MAU::Instruction(prim->srcInfo, "invalidate",
            gen_stdmeta(VisitingThread(this) ? "egress_port" : "egress_spec"));
    } else if (prim->name == "count" || prim->name == "execute_meter" ||
               prim->name == "execute_stateful_alu") {
        stateful[af].emplace_back(prim);
        return nullptr;
    } else if (prim->name == "hash") {
        for (size_t i = 0; i < prim->operands.size(); i++) {
            LOG1("Operand " << i << " is " << prim->operands[i]);
        }
        modify_with_hash[af].emplace_back(prim);
        IR::MAU::Instruction *instr = new IR::MAU::Instruction(prim->srcInfo, "set",
                                                               prim->operands[0]);
        instr->through_arg = false;
        return instr;
    }
    WARNING("unhandled in InstSel: " << *prim);
    return prim;
}

const IR::Type *stateful_type_for_primitive(const IR::Primitive *prim) {
    if (prim->name == "count")
        return IR::Type_Counter::get();
    if (prim->name == "execute_meter")
        return IR::Type_Meter::get();
    if (prim->name == "execute_stateful_alu")
        return IR::Type_Register::get();
    BUG("Not a stateful primitive %s", prim);
}

class SetupIndirectIndex : public MauModifier {
    const IR::Expression *indirect;

    bool preorder(IR::MAU::MAUCounter *counter) {
        counter->indirect_index = indirect;
        return true;
    }

    bool preorder(IR::MAU::MAUMeter *meter) {
        meter->indirect_index = indirect;
        return true;
    }
 public:
    explicit SetupIndirectIndex(const IR::Expression *i) : indirect(i) {}
};

const IR::MAU::Table *InstructionSelection::postorder(IR::MAU::Table *tbl) {
    for (auto act : Values(tbl->actions)) {
        if (!stateful.count(act)) continue;
        for (auto prim : stateful[act]) {
            if (prim->name == "execute_stateful_alu")
                continue;  // skip for now
            // typechecking should have verified
            BUG_CHECK(prim->operands.size() >= 2, "Invalid primitive %s", prim);
            auto gref = prim->operands[0]->to<IR::GlobalRef>();
            // typechecking should catch this too
            BUG_CHECK(gref, "No object named %s", prim->operands[0]);
            auto stateful = gref->obj->to<IR::Stateful>();
            auto type = stateful_type_for_primitive(prim);
            if (!stateful || stateful->getType() != type) {
                // typechecking is unable to check this without a good bit more work
                error("%s: %s is not a %s", prim->operands[0]->srcInfo, gref->obj, type);
            } else if (!contains(tbl->attached, stateful)) {
                const IR::Expression *indirect = prim->operands[1];
                if (auto *c = stateful->to<IR::Counter>())
                    tbl->attached.push_back(new IR::MAU::MAUCounter(*c, indirect));
                else if (auto *m = stateful->to<IR::Meter>())
                    tbl->attached.push_back(new IR::MAU::MAUMeter(*m, indirect));
                else
                    tbl->attached.push_back(stateful);
            } else {
                const IR::Stateful *stateful_update = nullptr;
                for (size_t i = 0; i < tbl->attached.size(); i++) {
                    if (stateful == tbl->attached[i]) {
                        stateful_update = stateful;
                        tbl->attached.erase(tbl->attached.begin() + i);
                        break;
                    }
                }
                for (auto at : tbl->attached) {
                    if (at == stateful) {
                        stateful_update = stateful;
                    }
                }
                const IR::Expression *indirect = prim->operands[1];
                stateful_update =
                    stateful_update->apply(SetupIndirectIndex(indirect))->to<IR::Stateful>();
                tbl->attached.push_back(stateful_update);
            }
        }
    }
    return tbl;
}
