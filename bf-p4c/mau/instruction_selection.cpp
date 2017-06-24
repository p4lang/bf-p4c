#include "instruction_selection.h"
#include "lib/bitops.h"

template<class T> static
T *clone(const T *ir) { return ir ? ir->clone() : nullptr; }

InstructionSelection::InstructionSelection(PhvInfo &phv) : phv(phv) {}

Visitor::profile_t InstructionSelection::init_apply(const IR::Node *root) {
    auto rv = MauTransform::init_apply(root);
    return rv;
}

IR::Member *InstructionSelection::gen_stdmeta(cstring field) {
    // FIXME -- this seems like an ugly hack -- need to make it match up to the
    // names created by CreateThreadLocalInstances.  Should have a better way of getting
    // a handle on the standard metadata.
    auto gress = VisitingThread(this);
    auto *std_meta = findContext<IR::Tofino::Pipe>()->thread[gress].in_metadata->clone();
    std_meta->name = IR::ID(cstring::to_cstring(gress) + "::" + std_meta->name);
    if (auto f = std_meta->type->getField(field))
        return new IR::Member(f->type, new IR::ConcreteHeaderRef(std_meta), field);
    else
        BUG("No field %s in standard_metadata", field);
    return nullptr;
}

const IR::GlobalRef *InstructionSelection::preorder(IR::GlobalRef *gr) {
    /* don't recurse through GlobalRefs as they refer to things elsewhere, not stuff
     * we want to turn into VLIW instructions */
    prune();
    return gr;
}

const IR::MAU::Action *InstructionSelection::preorder(IR::MAU::Action *af) {
    BUG_CHECK(this->af == nullptr, "Nested action functions");
    BUG_CHECK(stateful.empty() && modify_with_hash.empty(), "invalid state in visitor");
    LOG2("InstructionSelection processing action " << af->name);
    this->af = af;
    return af;
}

class InstructionSelection::SplitInstructions : public Transform {
    InstructionSelection &self;
    IR::Vector<IR::Primitive> &split;
    const IR::Expression *postorder(IR::MAU::Instruction *inst) override {
        if (inst->operands.empty()) return inst;
        if (auto *tv = inst->operands[0]->to<IR::TempVar>()) {
            self.phv.addTempVar(tv);
            if (getContext() != nullptr) {
                LOG3("splitting instruction " << inst);
                split.push_back(inst);
                return tv; } }
        return inst; }
 public:
    SplitInstructions(InstructionSelection &self, IR::Vector<IR::Primitive> &s)
    : self(self), split(s) {}
};

const IR::MAU::Action *InstructionSelection::postorder(IR::MAU::Action *af) {
    BUG_CHECK(this->af == af, "Nested action functions");
    this->af = nullptr;
    IR::Vector<IR::Primitive> split;
    for (auto *p : af->action)
        split.push_back(p->apply(SplitInstructions(*this, split)));
    if (split.size() > af->action.size())
        af->action = std::move(split);
    af->stateful.append(stateful);
    stateful.clear();
    af->modify_with_hash.append(modify_with_hash);
    modify_with_hash.clear();
    return af;
}

bool InstructionSelection::checkPHV(const IR::Expression *e) {
    return phv.field(e);
}

bool InstructionSelection::checkSrc1(const IR::Expression *e) {
    if (e->is<IR::Constant>()) return true;
    if (e->is<IR::BoolLiteral>()) return true;
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
    if (!af) return prim;
    const IR::Expression *dest = prim->operands.size() > 0 ? prim->operands[0] : nullptr;
    if (prim->name == "modify_field") {
        long mask;
        if ((prim->operands.size() | 1) != 3) {
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        } else if (!phv.field(dest)) {
            error("%s: destination of %s must be a field", prim->srcInfo, prim->name);
        } else if (auto *rv = fillInstDest(prim->operands[1], dest)) {
            return rv;
        } else if (!checkSrc1(prim->operands[1])) {
            if (prim->operands[1]->is<IR::Mux>())
                error("%s: conditional assignment not supported", prim->srcInfo);
            else
                error("%s: source of %s invalid", prim->srcInfo, prim->name);
        } else if (prim->operands.size() == 2) {
            return new IR::MAU::Instruction(prim->srcInfo, "set", &prim->operands);
        } else if (!checkConst(prim->operands[2], mask)) {
            error("%s: mask of %s must be a constant", prim->srcInfo, prim->name);
        } else if (1L << dest->type->width_bits() == mask + 1) {
            return new IR::MAU::Instruction(prim->srcInfo, "set", dest, prim->operands[1]);
        } else if (isDepositMask(mask)) {
            return makeDepositField(prim, mask);
        } else {
            return new IR::MAU::Instruction(prim->srcInfo, "bitmasked-set", &prim->operands); }
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
    } else if (prim->name == "isValid") {
        auto hdr_ref = prim->operands[0]->to<const IR::HeaderRef>();
        // tyepchecking should have caught these errors
        BUG_CHECK(hdr_ref, "Invalid header operand in isValid");
        BUG_CHECK(!hdr_ref->baseRef()->is<IR::Metadata>(), "Can't check validity of metadata");
        auto bit1 = IR::Type::Bits::get(1);
        return new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(bit1),
                                        new IR::Member(prim->srcInfo, bit1, hdr_ref, "$valid"));
    } else if (prim->name == "drop" || prim->name == "mark_to_drop") {
        return new IR::MAU::Instruction(prim->srcInfo, "invalidate",
            gen_stdmeta(VisitingThread(this) ? "egress_port" : "egress_spec"));
    } else if (prim->name == "stateful_alu_14.execute_stateful_alu" ||
               prim->name == "stateful_alu_14.execute_stateful_alu_from_hash" ||
               prim->name == "stateful_alu_14.execute_stateful_log" ||
               prim->name == "register_action.execute") {
        bool direct_access = false;
        if (prim->operands.size() > 1)
            stateful.push_back(prim);  // needed to setup the index properly
        else if (prim->name == "stateful_alu_14.execute_stateful_alu" ||
                 prim->name == "register_action.execute")
            direct_access = true;
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto salu = glob->obj->to<IR::MAU::StatefulAlu>();
        if (salu->direct != direct_access)
            error("%s: %sdirect access to %sdirect register", prim->srcInfo,
                  direct_access ? "" : "in", salu->direct ? "" : "in");
        cstring action = findContext<IR::ActionFunction>()->name;
        auto out = salu->instruction.at(salu->action_map.at(action))->output_dst;
        if (prim->name == "register_action.execute")
            out = new IR::TempVar(prim->type);
        if (out)
            return new IR::MAU::Instruction(prim->srcInfo, "set", out,
                                            new IR::MAU::AttachedOutput(salu));
        return nullptr;
    } else if (prim->name == "counter.count" || prim->name == "meter.execute_meter") {
        stateful.push_back(prim);  // needed to setup the index
        return nullptr;
    } else if (prim->name == "direct_counter.count" || prim->name == "direct_meter.read") {
        return nullptr;
    } else if (prim->name == "hash") {
        modify_with_hash.push_back(prim);
        int size = bitcount(prim->operands[4]->to<IR::Constant>()->asLong() - 1);
        /* FIXME -- is the above correct?  Or do we want ceil_log2? */
        IR::MAU::Instruction *instr = new IR::MAU::Instruction(prim->srcInfo, "set",
            new IR::Slice(prim->operands[0], size-1, 0), new IR::MAU::HashDist);
        return instr;
    } else {
        WARNING("unhandled in InstSel: " << *prim); }
    return prim;
}

const IR::Type *stateful_type_for_primitive(const IR::Primitive *prim) {
    if (prim->name == "counter.count" || prim->name == "direct_counter.count")
        return IR::Type_Counter::get();
    if (prim->name == "meter.execute_meter" || prim->name == "direct_meter.read")
        return IR::Type_Meter::get();
    if (prim->name.startsWith("stateful_alu_14."))
        return IR::Type_Register::get();
    BUG("Not a stateful primitive %s", prim);
}

const IR::MAU::Table *InstructionSelection::postorder(IR::MAU::Table *tbl) {
    for (auto act : Values(tbl->actions)) {
        for (auto prim : act->stateful) {
            // typechecking should have verified
            BUG_CHECK(prim->operands.size() >= 1, "Invalid primitive %s", prim);
            auto gref = prim->operands[0]->to<IR::GlobalRef>();
            // typechecking should catch this too
            BUG_CHECK(gref, "No object named %s", prim->operands[0]);
            auto stateful = gref->obj->to<IR::Stateful>();
            auto type = stateful_type_for_primitive(prim);
            if (!stateful || stateful->getType() != type) {
                // typechecking is unable to check this without a good bit more work
                error("%s: %s is not a %s", prim->operands[0]->srcInfo, gref->obj, type);
            } else if (!contains(tbl->attached, stateful)) {
                // FIXME -- Needed because extract_maupipe does not correctly attach tables to
                // multiple match tables.
                // BUG("%s not attached to %s", stateful->name, tbl->name);
                tbl->attached.push_back(stateful);
            }
        }
    }
    return tbl;
}
