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
    cstring metadataName = cstring::to_cstring(VisitingThread(this)) +
                           "::standard_metadata";
    auto* meta = findContext<IR::BFN::Pipe>()->metadata[metadataName];
    if (auto* f = meta->type->getField(field))
        return new IR::Member(f->type, new IR::ConcreteHeaderRef(meta), field);
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
    BUG_CHECK(stateful.empty(), "invalid state in visitor");
    LOG2("InstructionSelection processing action " << af->name);
    this->af = af;
    return af;
}

class InstructionSelection::SplitInstructions : public Transform {
    IR::Vector<IR::Primitive> &split;
    const IR::Expression *postorder(IR::MAU::Instruction *inst) override {
        if (inst->operands.empty()) return inst;
        if (auto *tv = inst->operands[0]->to<IR::TempVar>()) {
            if (getContext() != nullptr) {
                LOG3("splitting instruction " << inst);
                split.push_back(inst);
                return tv; } }
        return inst; }
 public:
    explicit SplitInstructions(IR::Vector<IR::Primitive> &s) : split(s) {}
};

const IR::MAU::Action *InstructionSelection::postorder(IR::MAU::Action *af) {
    BUG_CHECK(this->af == af, "Nested action functions");
    this->af = nullptr;
    IR::Vector<IR::Primitive> split;
    for (auto *p : af->action)
        split.push_back(p->apply(SplitInstructions(split)));
    if (split.size() > af->action.size())
        af->action = std::move(split);
    af->stateful.append(stateful);
    stateful.clear();
    return af;
}

bool InstructionSelection::checkPHV(const IR::Expression *e) {
    return phv.field(e);
}

bool InstructionSelection::checkSrc1(const IR::Expression *e) {
    if (e->is<IR::Constant>()) return true;
    if (e->is<IR::BoolLiteral>()) return true;
    if (e->is<IR::ActionArg>()) return true;
    if (e->is<IR::Primitive>()) return true;
    if (e->is<IR::MAU::HashDist>()) return true;
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

const IR::Expression *InstructionSelection::postorder(IR::BoolLiteral *bl) {
    if (!findContext<IR::MAU::Action>())
        return bl;
    return new IR::Constant(new IR::Type::Bits(1, false), static_cast<int>(bl->value));
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

const IR::Expression *InstructionSelection::postorder(IR::Primitive *prim) {
    LOG1("prim " << prim);
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
    } else if (prim->name == "drop" || prim->name == "mark_to_drop") {
        return new IR::MAU::Instruction(prim->srcInfo, "invalidate",
            gen_stdmeta(VisitingThread(this) ? "egress_port" : "egress_spec"));
    } else if (prim->name == "register_action.execute") {
        bool direct_access = false;
        if (prim->operands.size() > 1)
            stateful.push_back(prim);  // needed to setup the index properly
        else if (prim->name == "register_action.execute")
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
    } else if (prim->name == "counter.count" || prim->name == "meter.execute_meter" ||
               prim->name == "meter.execute") {
        // XXX(hanw)
        stateful.push_back(prim);  // needed to setup the index
        return nullptr;
    } else if (prim->name == "direct_counter.count" || prim->name == "direct_meter.read") {
        return nullptr;
    // Convert this hash to a set a PHV field to an IR::MAU::HashDist
    } else if (prim->name == "hash") {
        unsigned size = 1;
        if (prim->operands[4]->to<IR::Constant>()) {
            size = bitcount(prim->operands[4]->to<IR::Constant>()->asLong() - 1);
            if ((1LL << size) != prim->operands[4]->to<IR::Constant>()->asLong())
                error("%s: The hash offset must be a power of 2 in a hash calculation %s",
                      prim->srcInfo, *prim);
        } else {
            error("NULL operand 4 for %s", *prim);
        }
        cstring algorithm;
        if (auto *mem = prim->operands[1]->to<IR::Member>())
            algorithm = mem->member;
        vector<int> init_units;
        auto *hd = new IR::MAU::HashDist(prim->srcInfo, prim->operands[3], algorithm,
                                         init_units, prim);
        hd->bit_width = size;
        if (auto *constant = prim->operands[2]->to<IR::Constant>()) {
            if (constant->asInt() != 0)
                error("%s: The initial offset for a hash calculation function has to be zero %s",
                       prim->srcInfo, *prim);
        }

        IR::MAU::Instruction *instr =
            new IR::MAU::Instruction( prim->srcInfo, "set",
                new IR::Slice(prim->operands[0], size-1, 0), hd);
        return instr;
    // Convert hash extern in tofino.p4
    } else if (prim->name == "hash.get_hash") {
        unsigned size = 1;
        if (prim->operands[3]->to<IR::Constant>()) {
            size = bitcount(prim->operands[3]->to<IR::Constant>()->asLong() - 1);
            if ((1LL << size) != prim->operands[3]->to<IR::Constant>()->asLong())
                error("%s: The hash offset must be a power of 2 in a hash calculation %s",
                      prim->srcInfo, *prim);
        } else {
            error("NULL operand 3 for %s", *prim);
        }

        cstring algorithm;
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto decl = glob->obj->to<IR::Declaration_Instance>();
        if (auto *mem = decl->arguments->at(0)->to<IR::Member>()) {
            algorithm = mem->member;
        }
        vector<int> init_units;
        auto *hd = new IR::MAU::HashDist(prim->srcInfo, prim->operands[1], algorithm,
                                         init_units, prim);
        hd->bit_width = size;
        if (auto *constant = prim->operands[2]->to<IR::Constant>()) {
            if (constant->asInt() != 0)
                error("%s: The initial offset for a hash calculation function has to be zero %s",
                      prim->srcInfo, *prim);
        }
        return hd;
    } else {
        WARNING("unhandled in InstSel: " << *prim); }
    return prim;
}


const IR::Type *stateful_type_for_primitive(const IR::Primitive *prim) {
    if (prim->name == "counter.count" || prim->name == "direct_counter.count")
        return IR::Type_Counter::get();
    if (prim->name == "meter.execute_meter" || prim->name == "direct_meter.read" ||
        prim->name == "meter.execute")
        return IR::Type_Meter::get();
    if (prim->name.startsWith("register_action."))
        return IR::Type_Register::get();
    BUG("Not a stateful primitive %s", prim);
}

const IR::MAU::Action *StatefulHashDistSetup::preorder(IR::MAU::Action *act) {
    remove_tempvars.clear();
    if (act->stateful.empty())
        prune();

    for (auto prim : act->stateful) {
        BUG_CHECK(prim->operands.size() >= 1, "Invalid primitive %s", prim);
        auto gref = prim->operands[0]->to<IR::GlobalRef>();
        BUG_CHECK(gref, "No object named %s", prim->operands[0]);
        if (prim->operands.size() >= 2) {
            if (auto *tv = prim->operands[1]->to<IR::TempVar>()) {
                remove_tempvars.insert(tv->name);
            }
        }
    }
    return act;
}

const IR::MAU::Instruction *StatefulHashDistSetup::preorder(IR::MAU::Instruction *instr) {
    saved_tempvar = nullptr;
    saved_hashdist = nullptr;
    return instr;
}

const IR::TempVar *StatefulHashDistSetup::preorder(IR::TempVar *tv) {
    if (remove_tempvars.find(tv->name) != remove_tempvars.end())
        saved_tempvar = tv;
    return tv;
}

const IR::MAU::Instruction *StatefulHashDistSetup::postorder(IR::MAU::Instruction *instr) {
    if (saved_tempvar && saved_hashdist) {
        stateful_alu_from_hash_dists[saved_tempvar->name] = saved_hashdist;
        return nullptr;
    }
    return instr;
}

const IR::MAU::HashDist *StatefulHashDistSetup::preorder(IR::MAU::HashDist *hd) {
    saved_hashdist = hd;
    return hd;
}

IR::MAU::HashDist *StatefulHashDistSetup::create_hash_dist(const IR::Expression *expr,
                                                           const IR::Primitive *prim) {
    vector<int> init_units;
    cstring algorithm = "identity";
    auto *hd = new IR::MAU::HashDist(prim->srcInfo, expr, algorithm, init_units, prim);
    hd->algorithm = algorithm;
    hd->bit_width = expr->type->width_bits();
    return hd;
}


class InitializeHashDist : public MauTransform {
    const IR::MAU::HashDist *hd;
    const IR::MAU::Synth2Port *preorder(IR::MAU::Synth2Port *sp) {
        sp->hash_dist = hd;
        prune();
        return sp;
    }

 public:
    explicit InitializeHashDist(const IR::MAU::HashDist *h) : hd(h) {}
};

/** This pass was specifically created to deal with adding the HashDist object to different
 *  stateful objects.  On one particular case, execute_stateful_alu_from_hash was creating
 *  two separate instructions, a TempVar = hash function call, and an execute stateful call
 *  addressed by this TempVar.  This pass combines these instructions into one instruction,
 *  and correctly saves the HashDist IR into these attached tables
 */
const IR::MAU::Table *StatefulHashDistSetup::postorder(IR::MAU::Table *tbl) {
    for (auto act : Values(tbl->actions)) {
        for (auto prim : act->stateful) {
            // typechecking should have verified
            BUG_CHECK(prim->operands.size() >= 1, "Invalid primitive %s", prim);
            auto gref = prim->operands[0]->to<IR::GlobalRef>();
            // typechecking should catch this too
            BUG_CHECK(gref, "No object named %s", prim->operands[0]);
            auto synth2port = gref->obj->to<IR::MAU::Synth2Port>();
            auto type = stateful_type_for_primitive(prim);
            if (!synth2port || synth2port->getType() != type) {
                // typechecking is unable to check this without a good bit more work
                error("%s: %s is not a %s", prim->operands[0]->srcInfo, gref->obj, type);
            }

            if (!contains(tbl->attached, synth2port)) {
                // FIXME -- Needed because extract_maupipe does not correctly attach tables to
                // multiple match tables.
                // BUG("%s not attached to %s", stateful->name, tbl->name);
                tbl->attached.push_back(synth2port);
            }

            if (prim->operands.size() >= 2) {
                IR::MAU::HashDist *hd = nullptr;
                if (phv.field(prim->operands[1])) {
                    hd = create_hash_dist(prim->operands[1], prim);
                } else if (auto *tv = prim->operands[1]->to<IR::TempVar>()) {
                    hd = stateful_alu_from_hash_dists.at(tv->name);
                }
                if (hd == nullptr) continue;
                // Painful code as it is unclear what is visited first, the actions or the
                // attached tables.  Probably should separate into multiple passes
                auto synth2port_adjust = synth2port->apply(InitializeHashDist(hd))
                                               ->to<IR::MAU::Synth2Port>();
                for (size_t i = 0; i < tbl->attached.size(); i++) {
                    if (tbl->attached[i] == synth2port) {
                        tbl->attached[i] = synth2port_adjust;
                        break;
                    }
                }
            }
        }
    }
    return tbl;
}

DoInstructionSelection::DoInstructionSelection(PhvInfo &phv) : PassManager {
    new InstructionSelection(phv),
    new StatefulHashDistSetup(phv)
} {}
