#include "bf-p4c/mau/instruction_selection.h"
#include "lib/bitops.h"
#include "lib/safe_vector.h"
#include "action_analysis.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/validate_allocation.h"

template<class T> static
T *clone(const T *ir) { return ir ? ir->clone() : nullptr; }

InstructionSelection::InstructionSelection(PhvInfo &phv) : phv(phv) {}

Visitor::profile_t InstructionSelection::init_apply(const IR::Node *root) {
    auto rv = MauTransform::init_apply(root);
    return rv;
}

IR::Member *InstructionSelection::genIntrinsicMetadata(gress_t gress,
                                                       cstring header, cstring field) {
    auto metadataName = cstring::to_cstring(gress) + "::" + header;
    auto* meta = findContext<IR::BFN::Pipe>()->metadata[metadataName];
    if (!meta) {
        BUG("Unable to find metadata %s", metadataName);
        return nullptr;
    }
    if (auto* f = meta->type->getField(field))
        return new IR::Member(f->type, new IR::ConcreteHeaderRef(meta), field);
    BUG("No field %s in %s", field, metadataName);
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
    const IR::MAU::AttachedOutput *preorder(IR::MAU::AttachedOutput *ao) override {
        // don't recurse into attached tables read by instructions.
        prune();
        return ao; }
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
    if (auto *c = e->to<IR::Cast>())
        return checkPHV(c->expr);
    return phv.field(e);
}

bool InstructionSelection::checkSrc1(const IR::Expression *e) {
    if (auto *c = e->to<IR::Cast>())
        return checkSrc1(c->expr);
    if (auto slice = e->to<IR::Slice>())
        return checkSrc1(slice->e0);
    if (e->is<IR::Constant>()) return true;
    if (e->is<IR::BoolLiteral>()) return true;
    if (e->is<IR::ActionArg>()) return true;
    if (e->is<IR::MAU::HashDist>()) return true;
    if (e->is<IR::MAU::AttachedOutput>()) return true;
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

bool InstructionSelection::equiv(const IR::Expression *a, const IR::Expression *b) {
    if (*a == *b) return true;
    if (typeid(*a) != typeid(*b)) return false;
    if (auto ca = a->to<IR::Cast>()) {
        auto cb = b->to<IR::Cast>();
        return ca->type == cb->type && equiv(ca->expr, cb->expr);
    }
    return false;
}

const IR::Expression *InstructionSelection::postorder(IR::BoolLiteral *bl) {
    if (!findContext<IR::MAU::Action>())
        return bl;
    return new IR::Constant(new IR::Type::Bits(1, false), static_cast<int>(bl->value));
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
        if (equiv(r->left, e->e2) && equiv(r->right, e->e1))
            isMin = !isMin;
        else if (!equiv(r->left, e->e1) || !equiv(r->right, e->e2))
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
    if (auto *c = in->to<IR::Cast>())
        return fillInstDest(c->expr, dest);
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

const IR::Node *InstructionSelection::postorder(IR::Primitive *prim) {
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
    } else if (prim->name == "recirculate_raw") {
        if (prim->operands.size() != 1) {
            error("%s: wrong number of operands to %s", prim->srcInfo, prim->name);
        } else {
            if (VisitingThread(this) != gress_t::INGRESS)
                error("%s%: %s is only allowed in ingress", prim->srcInfo, prim->name);

            auto egress_spec = genIntrinsicMetadata(gress_t::INGRESS,
                                                    "ingress_intrinsic_metadata_for_tm",
                                                    "ucast_egress_port");
            auto ingress_port = genIntrinsicMetadata(gress_t::INGRESS,
                                                     "ingress_intrinsic_metadata",
                                                     "ingress_port");

            auto s1 = new IR::MAU::Instruction(prim->srcInfo, "set",
                          MakeSlice(egress_spec, 0, 6),
                          MakeSlice(prim->operands.at(0), 0, 6));
            auto s2 = new IR::MAU::Instruction(prim->srcInfo, "set",
                          MakeSlice(egress_spec, 7, 8),
                          MakeSlice(ingress_port, 7, 8));
            return new IR::Vector<IR::Expression>({s1, s2}); }
    } else if (prim->name == "register_action.execute" ||
               prim->name == "register_action.execute_log" ||
               prim->name == "selector_action.execute" ||
               prim->name == "selector_action.execute_log") {
        bool direct_access = false;
        if (prim->operands.size() == 1 && prim->name == "register_action.execute")
            direct_access = true;
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto salu = glob->obj->to<IR::MAU::StatefulAlu>();
        if (prim->operands.size() > 1 || salu->instruction.size() > 1)
            stateful.push_back(prim);  // needed to setup the index and/or type properly
        if (salu->direct != direct_access)
            error("%s: %sdirect access to %sdirect register", prim->srcInfo,
                  direct_access ? "" : "in", salu->direct ? "" : "in");
        return new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(prim->type),
                                        new IR::MAU::AttachedOutput(prim->type, salu));
    } else if (prim->name == "Counter.count") {
        stateful.push_back(prim);  // needed to setup the index
        return nullptr;
    } else if (prim->name == "Lpf.execute" || prim->name == "Wred.execute" ||
               prim->name == "Meter.execute" || prim->name == "DirectLpf.execute" ||
               prim->name == "DirectWred.execute") {
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto mtr = glob->obj->to<IR::MAU::Meter>();
        BUG_CHECK(mtr != nullptr, "%s: Cannot find associated meter for the method call %s",
                  prim->srcInfo, *prim);
        stateful.push_back(prim);
        return new IR::MAU::AttachedOutput(prim->type, mtr);
    } else if (prim->name == "DirectCounter.count") {
        return nullptr;
    } else if (prim->name == "DirectMeter.execute") {
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto mtr = glob->obj->to<IR::MAU::Meter>();
        return new IR::MAU::AttachedOutput(IR::Type::Bits::get(8), mtr);
    // Convert hash extern in tofino.p4
    } else if (prim->name == "hash.get_hash") {
        unsigned size = 1;
        int op_size = prim->operands.size();
        if (op_size > 3) {
            if (prim->operands[3]->to<IR::Constant>()) {
                size = bitcount(prim->operands[3]->to<IR::Constant>()->asLong() - 1);
                if ((1LL << size) != prim->operands[3]->to<IR::Constant>()->asLong())
                    error("%s: The hash offset must be a power of 2 in a hash calculation %s",
                          prim->srcInfo, *prim);
            }
        }

        cstring algorithm;
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto decl = glob->obj->to<IR::Declaration_Instance>();
        if (auto *mem = decl->arguments->at(0)->to<IR::Member>()) {
            algorithm = mem->member;
        }
        auto *hd = new IR::MAU::HashDist(prim->srcInfo, IR::Type::Bits::get(size),
                                         prim->operands[1], algorithm, prim);
        hd->bit_width = size;
        if (op_size > 1) {
            if (auto *constant = prim->operands[1]->to<IR::Constant>()) {
                if (constant->asInt() != 0)
                    error("%s: The initial offset for a hash "
                          "calculation function has to be zero %s",
                          prim->srcInfo, *prim);
            }
        }
        return hd;
    } else if (prim->name == "invalidate") {
        return new IR::MAU::Instruction(prim->srcInfo, "invalidate", prim->operands[0]);
    } else {
        WARNING("unhandled in InstSel: " << *prim); }
    return prim;
}

const IR::Type *stateful_type_for_primitive(const IR::Primitive *prim) {
    if (prim->name == "Counter.count" || prim->name == "DirectCounter.count")
        return IR::Type_Counter::get();
    if (prim->name == "Meter.execute" || prim->name == "DirectMeter.execute" ||
        prim->name == "Lpf.execute" || prim->name == "DirectLpf.execute" ||
        prim->name == "Wred.execute" || prim->name == "DirectWred.execute")
        return IR::Type_Meter::get();
    if (prim->name.startsWith("register_action.") || prim->name.startsWith("selector_action."))
        return IR::Type_Register::get();
    BUG("Not a stateful primitive %s", prim);
}

ssize_t index_operand(const IR::Primitive *prim) {
    if (prim->name.startsWith("Counter") || prim->name.startsWith("Meter")
        || prim->name.startsWith("register_action"))
        return 1;
    else if (prim->name.startsWith("Lpf") || prim->name.startsWith("Wred"))
        return 2;
    else if (prim->name.startsWith("DirectLpf") || prim->name.startsWith("DirectWred"))
        return -1;
    return 1;
}

size_t input_operand(const IR::Primitive *prim) {
    if (prim->name.startsWith("Lpf") || prim->name.startsWith("Wred") ||
            prim->name.startsWith("DirectLpf") || prim->name.startsWith("DirectWred"))
        return 1;
    else
        return -1;
}

bool StatefulHashDistSetup::Scan::preorder(const IR::MAU::Action *act) {
    self.remove_tempvars.clear();
    if (act->stateful.empty())
        return false;

    for (auto prim : act->stateful) {
        BUG_CHECK(prim->operands.size() >= 1, "Invalid primitive %s", prim);
        auto gref = prim->operands[0]->to<IR::GlobalRef>();
        BUG_CHECK(gref, "No object named %s", prim->operands[0]);
        if (prim->operands.size() >= 2) {
            if (auto *tv = prim->operands[1]->to<IR::TempVar>()) {
                self.remove_tempvars.insert(tv->name);
            }
            if (auto *c = prim->operands[1]->to<IR::Cast>()) {
                if (auto tv = c->expr->to<IR::TempVar>())
                    self.remove_tempvars.insert(tv->name);
            }
        }
    }
    return true;
}

bool StatefulHashDistSetup::Scan::preorder(const IR::MAU::Instruction *) {
    self.saved_tempvar = nullptr;
    self.saved_hashdist = nullptr;
    return true;
}

bool StatefulHashDistSetup::Scan::preorder(const IR::TempVar *tv) {
    if (self.remove_tempvars.count(tv->name))
        self.saved_tempvar = tv;
    return true;
}

bool StatefulHashDistSetup::Scan::preorder(const IR::MAU::HashDist *hd) {
    self.saved_hashdist = hd;
    return true;
}

void StatefulHashDistSetup::Scan::postorder(const IR::MAU::Instruction *instr) {
    if (self.saved_tempvar && self.saved_hashdist) {
        self.stateful_alu_from_hash_dists[self.saved_tempvar->name] = self.saved_hashdist;
        self.remove_instr.insert(instr); }
}

IR::MAU::HashDist *StatefulHashDistSetup::create_hash_dist(const IR::Expression *expr,
                                                           const IR::Primitive *prim) {
    cstring algorithm = "identity";
    auto hash_field = expr;
    if (auto c = expr->to<IR::Cast>())
        hash_field = c->expr;

    int size = hash_field->type->width_bits();
    auto *hd = new IR::MAU::HashDist(prim->srcInfo, IR::Type::Bits::get(size), hash_field,
                                     algorithm, prim);
    hd->algorithm = algorithm;
    hd->bit_width = size;
    return hd;
}

/** Either find or generate a Hash Distribution unit, given what IR::Node is in the primitive
 *  FIXME: Currently v1model always casts these particular parameters to a size.  Perhaps
 *  these casts will be gone by the time we reach extract_maupipe.
 */
const IR::MAU::HashDist *StatefulHashDistSetup::find_hash_dist(const IR::Expression *expr,
                                                               const IR::Primitive *prim) {
    if (auto *c = expr->to<IR::Cast>())
        return find_hash_dist(c->expr, prim);
    const IR::MAU::HashDist *hd = nullptr;
    if (auto *tv = expr->to<IR::TempVar>())
        hd = stateful_alu_from_hash_dists.at(tv->name);
    else if (phv.field(expr))
        hd = create_hash_dist(expr, prim);
    return hd;
}

/** This pass was specifically created to deal with adding the HashDist object to different
 *  stateful objects.  On one particular case, execute_stateful_alu_from_hash was creating
 *  two separate instructions, a TempVar = hash function call, and an execute stateful call
 *  addressed by this TempVar.  This pass combines these instructions into one instruction,
 *  and correctly saves the HashDist IR into these attached tables
 */
void StatefulHashDistSetup::Scan::postorder(const IR::MAU::Table *tbl) {
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

            auto index_op = index_operand(prim);
            if (index_op < 0)
                continue;

            if (prim->operands.size() >= size_t(index_op) + 1) {
                if (auto hd = self.find_hash_dist(prim->operands[index_operand(prim)], prim)) {
                    HashDistKey hdk = std::make_pair(synth2port, tbl);
                    self.update_hd[hdk] = hd;
                }
            }
        }
    }
}

const IR::MAU::Table *StatefulHashDistSetup::Update::postorder(IR::MAU::Table *tbl) {
    for (auto act : Values(tbl->actions)) {
        for (auto prim : act->stateful) {
            auto gref = prim->operands[0]->to<IR::GlobalRef>();
            auto synth2port = gref->obj->to<IR::MAU::Synth2Port>();
            bool already_attached = false;
            for (auto back_at : tbl->attached) {
                if (synth2port == back_at->attached) {
                    already_attached = true;
                    break;
                }
            }

            if (!already_attached) {
                BUG("%s not attached to %s", synth2port->name, tbl->name);
                // tbl->attached.push_back(synth2port);
            }
        }
    }
    return tbl;
}

const IR::MAU::Table *StatefulHashDistSetup::Update::preorder(IR::MAU::Table *tbl) {
    orig_tbl = getOriginal()->to<IR::MAU::Table>();
    return tbl;
}

const IR::MAU::BackendAttached *
        StatefulHashDistSetup::Update::preorder(IR::MAU::BackendAttached *ba) {
    HashDistKey hdk = std::make_pair(ba->attached, orig_tbl);
    if (auto hd = ::get(self.update_hd, hdk)) {
        ba->hash_dist = hd;
    }
    prune();
    return ba;
}

const IR::MAU::Instruction *StatefulHashDistSetup::Update::preorder(IR::MAU::Instruction *inst) {
    if (self.remove_instr.count(getOriginal())) return nullptr;
    return inst;
}

bool LPFSetup::Scan::preorder(const IR::MAU::Instruction *) {
    return false;
}

/** Linking the input for an LPF found in the action call with the IR node.  The Scan pass finds
 *  the PHV field, and the Update pass updates the AttachedMemory object
 */
bool LPFSetup::Scan::preorder(const IR::Primitive *prim) {
    int input_index = input_operand(prim);
    if (input_index == -1)
        return false;

    auto gref = prim->operands[0]->to<IR::GlobalRef>();
    // typechecking should catch this too
    BUG_CHECK(gref, "No object named %s", prim->operands[0]);
    auto mtr = gref->obj->to<IR::MAU::Meter>();
    BUG_CHECK(mtr, "%s: Operand in LPF execute is not a meter", prim->srcInfo);
    auto input = prim->operands[input_index];
    auto *field = self.phv.field(input);
    BUG_CHECK(field, "%s: Not a phv field in the lpf execute: %s", prim->srcInfo, field->name);

    if (self.update_lpfs.count(mtr) == 0) {
        self.update_lpfs[mtr] = input;
        return false;
    }

    auto *act = findContext<IR::MAU::Action>();
    auto *tbl = findContext<IR::MAU::Table>();
    auto *other_field = self.phv.field(self.update_lpfs.at(mtr));

    ERROR_CHECK(field == other_field, "%s: The call of this lpf.execute in action %s has "
                "a different input %s than another lpf.execute on %s in the same table %s. "
                "The other input is %s.", prim->srcInfo, act->name, field->name, mtr->name,
                tbl->name, other_field->name);
    return false;
}

bool LPFSetup::Update::preorder(IR::MAU::Meter *mtr) {
    auto orig_meter = getOriginal()->to<IR::MAU::Meter>();
    bool should_have_input = mtr->implementation.name == "lpf" ||
                             mtr->implementation.name == "wred";
    bool has_input = self.update_lpfs.count(orig_meter) > 0;
    if (has_input != should_have_input) {
        ERROR_CHECK(should_have_input && !has_input, "%s: %s meter %s never provided an input "
                    "through an action", mtr->srcInfo, mtr->implementation.name, mtr->name);
        ERROR_CHECK(has_input && !should_have_input, "%s: meter %s does not require an input, "
                    "but is provided one through an action", mtr->srcInfo, mtr->name);
    }
    if (!(has_input && should_have_input))
        return false;
    mtr->input = self.update_lpfs.at(orig_meter);
    return false;
}

const IR::MAU::Instruction *ConvertCastToSlice::preorder(IR::MAU::Instruction *instr) {
    BUG_CHECK(findContext<IR::MAU::Instruction>() == nullptr, "nested instructions");
    contains_cast = false;
    return instr;
}

/** Currently because of AttachedOutputs, StatefulAlus appear in the code.  Only changes
 *  to the IR and TableDependency will elimintate the need for this preorder
 */
const IR::MAU::SaluAction *ConvertCastToSlice::preorder(IR::MAU::SaluAction *sact) {
    prune();
    return sact;
}

/**
 *  FIXME: a small hack on converting casts in slices to just slices, which should have really
 *  been taken care of in the midend
 */
const IR::Expression *ConvertCastToSlice::preorder(IR::Slice *sl) {
    if (auto *c = sl->e0->to<IR::Cast>()) {
        BUG_CHECK(c->expr->type->width_bits() >=  (sl->getH() - sl->getL() + 1), "Slice of a cast "
                  "that is larger than the cast");
        return MakeSlice(c->expr, sl->getL(), sl->getH());
    }
    return sl;
}

/**
 *  FIXME: Quick fix in order for mirror_test to be correct.  This should be handled in the
 *  midend way before this
 */
const IR::Node *ConvertCastToSlice::preorder(IR::Cast *c) {
    contains_cast = true;
    auto *upper_cast = findContext<IR::Cast>();
    if (upper_cast == nullptr) {
        return c;
    } else {
        return c->expr;
    }
}

/** The goal of this particular function is to remove all final casts from any particular backend
 *  instruction, and if the particular instruction is an assignment of mismatched fields, then
 *  properly convert this into the correct field by field instructions.  Currently the compiler
 *  will print out a warning if the action contains fields and parameters that do not have the
 *  same size, but will continue.  Unfortunately, I have to do this as switch-l2 will fail at
 *  this point if this is not the case.
 */
const IR::Node *ConvertCastToSlice::postorder(IR::MAU::Instruction *instr) {
    if (!contains_cast)
        return instr;
    auto converted_instrs = new IR::Vector<IR::Primitive>();

    if (instr->name != "set") {
        bool size_set = false;
        bool all_equal = true;
        auto s1 = new IR::MAU::Instruction(instr->srcInfo, instr->name);
        int operand_size;
        for (auto operand : instr->operands) {
            auto expr = operand;
            if (auto c = operand->to<IR::Cast>()) {
                expr = c->expr;
            }
            if (!size_set) {
                size_set = true;
                operand_size = expr->type->width_bits();
            } else if (operand_size != expr->type->width_bits()) {
                all_equal = false;
            }
            s1->operands.push_back(expr);
        }

        WARN_CHECK(all_equal, "%s: Currently the Barefoot HW compiler cannot handle any non "
                   "direct assignment instruction that has missized rvalues.  Please rewrite "
                   "so that all parameters are of the same size -- %s", instr->srcInfo, instr);
        return s1;
    }
    BUG_CHECK(instr->operands.size() == 2, "Set instruction does not two operands?");
    auto write = instr->operands[0];
    auto read_cast = instr->operands[1]->to<IR::Cast>();
    BUG_CHECK(read_cast != nullptr, "%s: ConvertCastToSlice pass does not have read IR::Cast -- "
                                    "%s", instr->srcInfo, instr);
    auto read = read_cast->expr;
    if (write->type->width_bits() == read->type->width_bits()) {
        auto s1 = new IR::MAU::Instruction(instr->srcInfo, instr->name, write, read);
        converted_instrs->push_back(s1);
    } else if (write->type->width_bits() < read->type->width_bits()) {
        auto s1 = new IR::MAU::Instruction(instr->srcInfo, instr->name, write,
                                           MakeSliceSource(read, 0, write->type->width_bits() - 1,
                                               write));
        converted_instrs->push_back(s1);
    } else {
        auto difference = write->type->width_bits() - read->type->width_bits();
        auto s1 = new IR::MAU::Instruction(instr->srcInfo, instr->name,
                                           MakeSliceDestination(write, 0, read->type->width_bits() -
                                           1), read);
        auto s2 = new IR::MAU::Instruction(instr->srcInfo, instr->name,
                                           MakeSliceDestination(write, read->type->width_bits(),
                                                     write->type->width_bits() - 1),
                                           new IR::Constant(IR::Type::Bits::get(difference), 0));
        converted_instrs->push_back(s1);
        converted_instrs->push_back(s2);
    }
    return converted_instrs;
}

struct CollectInvalidatableFields : public Inspector {
    explicit CollectInvalidatableFields(const PhvInfo& phv) : phv(phv) { }

    bool preorder(const IR::BFN::DeparserParameter* parameter) override {
        if (parameter->canPack == false) {
            invalidatable_fields.insert(phv.field(parameter->source->field));
        }
        return true;
    }

    std::set<const PHV::Field*> invalidatable_fields;
    const PhvInfo& phv;
};

struct CheckInvalidate : public Inspector {
    CheckInvalidate(const PhvInfo& phv,
                    const std::set<const PHV::Field*>& fields)
        : phv(phv), invalidatable_fields(fields) { }


    void postorder(const IR::Primitive *prim) override {
        if (prim->name == "invalidate") {
            auto* f = phv.field(prim->operands[0]);
            if (!invalidatable_fields.count(f)) {
                error("%s: invalid operand, %s", prim->srcInfo, prim);
            }
        }
    }

    const PhvInfo& phv;
    const std::set<const PHV::Field*>& invalidatable_fields;
};

struct ValidateInvalidatePrimitive : public PassManager {
    explicit ValidateInvalidatePrimitive(const PhvInfo& phv) {
        auto* collectFields = new CollectInvalidatableFields(phv);
        addPasses({
                collectFields,
                    new CheckInvalidate(phv, collectFields->invalidatable_fields),
            });
    }
};

DoInstructionSelection::DoInstructionSelection(PhvInfo &phv) : PassManager {
    new ValidateInvalidatePrimitive(phv),
    new InstructionSelection(phv),
    new ConvertCastToSlice,
    new StatefulHashDistSetup(phv),
    new LPFSetup(phv),
    new CollectPhvInfo(phv),
    new PHV::ValidateActions(phv, false, false, false)
} {}
