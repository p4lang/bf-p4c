#include "bf-p4c/mau/instruction_selection.h"
#include "lib/bitops.h"
#include "lib/safe_vector.h"
#include "action_analysis.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/validate_allocation.h"

const IR::MAU::Action *Synth2PortSetup::preorder(IR::MAU::Action *act) {
    clear_action();
    return act;
}

/** Converts any method calls relating to Synth2Port tables to the associated AttachedOutput
 *  if necessary, and once converted, saves this value to the primitive
 */
const IR::Node *Synth2PortSetup::postorder(IR::Primitive *prim) {
    if (findContext<IR::MAU::SaluAction>())
        return prim;

    if (findContext<IR::MAU::Action>() == nullptr)
        return prim;

    auto dot = prim->name.find('.');
    auto objType = dot ? prim->name.before(dot) : cstring();
    IR::Node *rv = prim;

    cstring method = dot ? cstring(dot+1) : prim->name;
    if (objType == "RegisterAction" || objType == "LearnAction" ||
        objType == "selector_action") {
        bool direct_access = (prim->operands.size() == 1 && method == "execute") ||
                             method == "execute_direct";
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto salu = glob->obj->to<IR::MAU::StatefulAlu>();
        // needed to setup the index and/or type properly
        stateful.push_back(prim);

        if (objType == "RegisterAction" && salu->direct != direct_access)
            error("%s: %sdirect access to %sdirect register", prim->srcInfo,
                  direct_access ? "" : "in", salu->direct ? "" : "in");
        int bit = 32;
        unsigned idx = method == "execute_direct" ? 1 : 2;

        for (; idx < prim->operands.size(); ++idx, bit += 32) {
            auto ao = new IR::MAU::AttachedOutput(IR::Type::Bits::get(bit+32), salu);
            auto instr = new IR::MAU::Instruction(prim->srcInfo, "set", prim->operands[idx],
                                                  MakeSlice(ao, bit, bit+31));
            // Have to put these instructions at the highest level of the instruction
            created_instrs.push_back(instr);
        }
        rv = new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(prim->type),
                                      new IR::MAU::AttachedOutput(prim->type, salu));
    } else if (prim->name == "Counter.count") {
        stateful.push_back(prim);  // needed to setup the index
        rv = nullptr;
    } else if (prim->name == "Lpf.execute" || prim->name == "Wred.execute" ||
               prim->name == "Meter.execute" || prim->name == "DirectLpf.execute" ||
               prim->name == "DirectWred.execute") {
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto mtr = glob->obj->to<IR::MAU::Meter>();
        BUG_CHECK(mtr != nullptr, "%s: Cannot find associated meter for the method call %s",
                  prim->srcInfo, *prim);
        stateful.push_back(prim);
        rv = new IR::MAU::AttachedOutput(prim->type, mtr);
    } else if (prim->name == "DirectCounter.count") {
        stateful.push_back(prim);
        rv = nullptr;
    } else if (prim->name == "DirectMeter.execute") {
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto mtr = glob->obj->to<IR::MAU::Meter>();
        stateful.push_back(prim);
        rv = new IR::MAU::AttachedOutput(IR::Type::Bits::get(8), mtr);
    }

    if (findContext<IR::Primitive>() != nullptr)
        return rv;
    // If instructions are at the top level of the instruction, then push these instructions
    // in after
    if (!created_instrs.empty()) {
        auto *rv_vec = new IR::Vector<IR::Node>();
        if (rv != nullptr)
            rv_vec->push_back(rv);
        for (auto instr : created_instrs)
            rv_vec->push_back(instr);
        created_instrs.clear();
        return rv_vec;
    }
    return rv;
}

const IR::MAU::Action *Synth2PortSetup::postorder(IR::MAU::Action *act) {
    act->stateful.append(stateful);
    act->meter_pfe = meter_pfe;
    act->stats_pfe = stats_pfe;
    return act;
}

template<class T> static
T *clone(const T *ir) { return ir ? ir->clone() : nullptr; }

DoInstructionSelection::DoInstructionSelection(const PhvInfo &phv) : phv(phv) {}

Visitor::profile_t DoInstructionSelection::init_apply(const IR::Node *root) {
    auto rv = MauTransform::init_apply(root);
    return rv;
}

IR::Member *DoInstructionSelection::genIntrinsicMetadata(gress_t gress,
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

const IR::GlobalRef *DoInstructionSelection::preorder(IR::GlobalRef *gr) {
    /* don't recurse through GlobalRefs as they refer to things elsewhere, not stuff
     * we want to turn into VLIW instructions */
    prune();
    return gr;
}

class DoInstructionSelection::SplitInstructions : public Transform {
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

const IR::MAU::Action *DoInstructionSelection::postorder(IR::MAU::Action *af) {
    IR::Vector<IR::Primitive> split;
    // FIXME: This should be pulled out as a different pass
    for (auto *p : af->action)
        split.push_back(p->apply(SplitInstructions(split)));
    if (split.size() > af->action.size())
        af->action = std::move(split);
    LOG5("Postorder " << af);
    this->af = nullptr;
    return af;
}

const IR::MAU::Action *DoInstructionSelection::preorder(IR::MAU::Action *af) {
    BUG_CHECK(findContext<IR::MAU::Action>() == nullptr, "Nested action functions");
    LOG2("DoInstructionSelection processing action " << af->name);
    LOG5(af);
    this->af = af;
    return af;
}

bool DoInstructionSelection::checkPHV(const IR::Expression *e) {
    if (auto *c = e->to<IR::Cast>())
        return checkPHV(c->expr);
    return phv.field(e);
}

bool DoInstructionSelection::checkSrc1(const IR::Expression *e) {
    if (auto *c = e->to<IR::Cast>())
        return checkSrc1(c->expr);
    if (auto slice = e->to<IR::Slice>())
        return checkSrc1(slice->e0);
    if (e->is<IR::Constant>()) return true;
    if (e->is<IR::BoolLiteral>()) return true;
    if (e->is<IR::ActionArg>()) return true;
    if (e->is<IR::MAU::HashDist>()) return true;
    if (e->is<IR::MAU::RandomNumber>()) return true;
    if (e->is<IR::MAU::AttachedOutput>()) return true;
    return phv.field(e);
}

bool DoInstructionSelection::checkConst(const IR::Expression *ex, long &value) {
    if (auto *k = ex->to<IR::Constant>()) {
        value = k->asLong();
        return true;
    } else {
        return false;
    }
}

bool DoInstructionSelection::equiv(const IR::Expression *a, const IR::Expression *b) {
    if (*a == *b) return true;
    if (typeid(*a) != typeid(*b)) return false;
    if (auto ca = a->to<IR::Cast>()) {
        auto cb = b->to<IR::Cast>();
        return ca->type == cb->type && equiv(ca->expr, cb->expr);
    }
    return false;
}

const IR::Expression *DoInstructionSelection::postorder(IR::BoolLiteral *bl) {
    if (!findContext<IR::MAU::Action>())
        return bl;
    return new IR::Constant(new IR::Type::Bits(1, false), static_cast<int>(bl->value));
}

const IR::Expression *DoInstructionSelection::postorder(IR::BAnd *e) {
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

const IR::Expression *DoInstructionSelection::postorder(IR::BOr *e) {
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

const IR::Expression *DoInstructionSelection::postorder(IR::BXor *e) {
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

const IR::Expression *DoInstructionSelection::postorder(IR::Cmpl *e) {
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

const IR::Expression *DoInstructionSelection::postorder(IR::Add *e) {
    if (!af) return e;
    return new IR::MAU::Instruction(e->srcInfo, "add", new IR::TempVar(e->type), e->left, e->right);
}

const IR::Expression *DoInstructionSelection::postorder(IR::Sub *e) {
    if (!af) return e;
    if (auto *k = e->right->to<IR::Constant>())
        return new IR::MAU::Instruction(e->srcInfo, "add", new IR::TempVar(e->type),
                                        (-*k).clone(), e->left);
    return new IR::MAU::Instruction(e->srcInfo, "sub", new IR::TempVar(e->type), e->left, e->right);
}

const IR::Expression *DoInstructionSelection::postorder(IR::Shl *e) {
    if (!af) return e;
    if (!e->right->is<IR::Constant>())
        error("%s: shift count must be a constant in %s", e->srcInfo, e);
    return new IR::MAU::Instruction(e->srcInfo, "shl", new IR::TempVar(e->type), e->left, e->right);
}

const IR::Expression *DoInstructionSelection::postorder(IR::Shr *e) {
    if (!af) return e;
    if (!e->right->is<IR::Constant>())
        error("%s: shift count must be a constant in %s", e->srcInfo, e);
    const char *shr = "shru";
    if (e->type->is<IR::Type_Bits>() && e->type->to<IR::Type_Bits>()->isSigned)
        shr = "shrs";
    return new IR::MAU::Instruction(e->srcInfo, shr, new IR::TempVar(e->type), e->left, e->right);
}

const IR::Expression *DoInstructionSelection::postorder(IR::Mux *e) {
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

const IR::Slice *DoInstructionSelection::postorder(IR::Slice *sl) {
    if (auto expr = sl->e0->to<IR::Slice>()) {
        sl->e0 = expr->e0;
        sl->e1 = new IR::Constant(sl->getH() + expr->getL());
        sl->e2 = new IR::Constant(sl->getL() + expr->getL());
        BUG_CHECK(int(sl->getH()) < sl->e0->type->width_bits(), "invalid slice on slice"); }
    return sl;
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

const IR::Node *DoInstructionSelection::postorder(IR::Primitive *prim) {
    if (!af) return prim;
    const IR::Expression *dest = prim->operands.size() > 0 ? prim->operands[0] : nullptr;
    auto dot = prim->name.find('.');
    auto objType = dot ? prim->name.before(dot) : cstring();
    cstring method = dot ? cstring(dot+1) : prim->name;
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
                          MakeSlice(egress_spec, 0, 6), MakeSlice(prim->operands.at(0), 0, 6));
            auto s2 = new IR::MAU::Instruction(prim->srcInfo, "set",
                          MakeSlice(egress_spec, 7, 8), MakeSlice(ingress_port, 7, 8));
            return new IR::Vector<IR::Expression>({s1, s2});
        }
    } else if (prim->name == "Hash.get") {
        auto glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto decl = glob->obj->to<IR::Declaration_Instance>();
        auto type = decl->type->to<IR::Type_Specialized>()->arguments->at(0);
        unsigned size = type->to<IR::Type_Bits>()->size;

        int op_size = prim->operands.size();
        if (op_size > 3) {
            if (auto *constant = prim->operands[2]->to<IR::Constant>()) {
                if (constant->asInt() != 0)
                    error("%s: The initial offset for a hash "
                          "calculation function has to be zero %s",
                          prim->srcInfo, *prim); }
            if (auto *constant = prim->operands[3]->to<IR::Constant>()) {
                if (constant->asLong() != 0) {
                    size = bitcount(constant->asLong() - 1);
                    if ((1LL << size) != constant->asLong())
                        error("%s: The hash offset must be a power of 2 in a hash calculation %s",
                              prim->srcInfo, *prim); } } }

        IR::MAU::hash_function algorithm;
        if (!algorithm.setup(decl->arguments->at(0)->expression))
            BUG("invalid hash algorithm %s", decl->arguments->at(0));
        auto *hd = new IR::MAU::HashDist(prim->srcInfo, IR::Type::Bits::get(size),
                                         prim->operands[1], algorithm, prim);
        hd->bit_width = size;
        return new IR::Cast(IR::Type::Bits::get(size), hd);
    } else if (prim->name == "random.get") {
        auto max_value = prim->operands[1]->to<IR::Constant>()->value;
        max_value += mpz_class(1);
        int one_pos = mpz_scan1(max_value.get_mpz_t(), 0);
        if ((mpz_class(1) << one_pos) != max_value)
            error("%s: The random declaration %s max size must be a power of two",
                  prim->srcInfo, prim);
        auto rn = new IR::MAU::RandomNumber(prim->srcInfo, IR::Type::Bits::get(one_pos));
        return new IR::Cast(IR::Type::Bits::get(one_pos), rn);
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
    if (prim->name.startsWith("RegisterAction.") || prim->name.startsWith("LearnAction.") ||
        prim->name.startsWith("selector_action."))
        return IR::Type_Register::get();
    BUG("Not a stateful primitive %s", prim);
}

ssize_t index_operand(const IR::Primitive *prim) {
    if (prim->name.startsWith("Counter") || prim->name.startsWith("Meter") ||
        prim->name.startsWith("RegisterAction"))
        return 1;
    else if (prim->name.startsWith("Lpf") || prim->name.startsWith("Wred"))
        return 2;
    else if (prim->name.startsWith("DirectLpf") || prim->name.startsWith("DirectWred") ||
             prim->name.startsWith("DirectCounter") || prim->name.startsWith("DirectMeter"))
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


bool StatefulAttachmentSetup::Scan::preorder(const IR::MAU::Action *act) {
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

bool StatefulAttachmentSetup::Scan::preorder(const IR::MAU::Instruction *) {
    self.saved_tempvar = nullptr;
    self.saved_hashdist = nullptr;
    return true;
}

bool StatefulAttachmentSetup::Scan::preorder(const IR::TempVar *tv) {
    if (self.remove_tempvars.count(tv->name))
        self.saved_tempvar = tv;
    return true;
}

bool StatefulAttachmentSetup::Scan::preorder(const IR::MAU::HashDist *hd) {
    self.saved_hashdist = hd;
    return true;
}

void StatefulAttachmentSetup::Scan::postorder(const IR::MAU::Instruction *instr) {
    if (self.saved_tempvar && self.saved_hashdist) {
        self.stateful_alu_from_hash_dists[self.saved_tempvar->name] = self.saved_hashdist;
        self.remove_instr.insert(instr); }
}

void StatefulAttachmentSetup::Scan::postorder(const IR::Primitive *prim) {
    const IR::Attached *obj = nullptr;
    use_t use = IR::MAU::BackendAttached::NO_USE;
    auto dot = prim->name.find('.');
    auto objType = dot ? prim->name.before(dot) : cstring();
    cstring method = dot ? cstring(dot+1) : prim->name;
    if (objType == "RegisterAction" || objType == "LearnAction" || objType == "selector_action") {
        obj = prim->operands.at(0)->to<IR::GlobalRef>()->obj->to<IR::MAU::StatefulAlu>();
        BUG_CHECK(obj, "invalid object");
        if (method == "execute") {
            use = prim->operands.size() == 1 ? IR::MAU::BackendAttached::DIRECT
                                             : IR::MAU::BackendAttached::INDIRECT;
        } else if (method == "execute_log") {
            use = IR::MAU::BackendAttached::LOG;
        } else if (method == "enqueue") {
            use = IR::MAU::BackendAttached::FIFO_PUSH;
        } else if (method == "dequeue") {
            use = IR::MAU::BackendAttached::FIFO_POP;
        } else if (method == "push") {
            use = IR::MAU::BackendAttached::STACK_PUSH;
        } else if (method == "pop") {
            use = IR::MAU::BackendAttached::STACK_POP;
        } else {
            BUG("Unknown %s method %s in: %s", objType, method, prim); }
    } else if (method == "execute") {
        obj = prim->operands.at(0)->to<IR::GlobalRef>()->obj->to<IR::MAU::Meter>();
        BUG_CHECK(obj, "invalid object");
        use = objType.startsWith("Direct") ? IR::MAU::BackendAttached::DIRECT
                                           : IR::MAU::BackendAttached::INDIRECT;
    } else if (method == "count") {
        obj = prim->operands.at(0)->to<IR::GlobalRef>()->obj->to<IR::MAU::Counter>();
        BUG_CHECK(obj, "invalid object");
        use = objType.startsWith("Direct") ? IR::MAU::BackendAttached::DIRECT
                                           : IR::MAU::BackendAttached::INDIRECT;
    }
    if (obj) {
        auto *act = findContext<IR::MAU::Action>();
        use_t &prev_use = self.action_use[act][obj];
        if (prev_use && prev_use != use)
            error("Inconsistent use of %s in action %s", obj, act);
        prev_use = use;
    }
}

IR::MAU::HashDist *StatefulAttachmentSetup::create_hash_dist(const IR::Expression *expr,
                                                           const IR::Primitive *prim) {
    auto hash_field = expr;
    if (auto c = expr->to<IR::Cast>())
        hash_field = c->expr;

    int size = hash_field->type->width_bits();
    auto *hd = new IR::MAU::HashDist(prim->srcInfo, IR::Type::Bits::get(size), hash_field,
                                     IR::MAU::hash_function::identity(), prim);
    hd->bit_width = size;
    return hd;
}

/** Either find or generate a Hash Distribution unit, given what IR::Node is in the primitive
 *  FIXME: Currently v1model always casts these particular parameters to a size.  Perhaps
 *  these casts will be gone by the time we reach extract_maupipe.
 */
const IR::MAU::HashDist *StatefulAttachmentSetup::find_hash_dist(const IR::Expression *expr,
                                                               const IR::Primitive *prim) {
    while (auto *c = expr->to<IR::Cast>())
        expr = c->expr;
    const IR::MAU::HashDist *hd = expr->to<IR::MAU::HashDist>();
    if (!hd) {
        auto tv = expr->to<IR::TempVar>();
        if (tv != nullptr && stateful_alu_from_hash_dists.count(tv->name)) {
            hd = stateful_alu_from_hash_dists.at(tv->name);
        } else if (phv.field(expr)) {
            hd = create_hash_dist(expr, prim); } }
    return hd;
}

/** This pass was specifically created to deal with adding the HashDist object to different
 *  stateful objects.  On one particular case, execute_stateful_alu_from_hash was creating
 *  two separate instructions, a TempVar = hash function call, and an execute stateful call
 *  addressed by this TempVar.  This pass combines these instructions into one instruction,
 *  and correctly saves the HashDist IR into these attached tables
 */
void StatefulAttachmentSetup::Scan::postorder(const IR::MAU::Table *tbl) {
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

const IR::MAU::Table *StatefulAttachmentSetup::Update::postorder(IR::MAU::Table *tbl) {
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

const IR::MAU::BackendAttached *
        StatefulAttachmentSetup::Update::preorder(IR::MAU::BackendAttached *ba) {
    auto *tbl = findOrigCtxt<IR::MAU::Table>();
    HashDistKey hdk = std::make_pair(ba->attached, tbl);
    if (auto hd = ::get(self.update_hd, hdk)) {
        ba->hash_dist = hd; }
    use_t use = IR::MAU::BackendAttached::NO_USE;
    for (auto act : Values(tbl->actions)) {
        if (auto use2 = self.action_use[act][ba->attached]) {
            if (use && use != use2) {
                error("inconsistent use of %s in table %s", ba->attached, tbl);
                break; }
            use = use2; } }
    ba->use = use;
    prune();
    return ba;
}

const IR::MAU::Instruction *StatefulAttachmentSetup::Update::preorder(IR::MAU::Instruction *inst) {
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

void DLeftSetup::postorder(IR::MAU::Table *tbl) {
    if (tbl->for_dleft()) {
        ERROR_CHECK(Device::currentDevice() != "Tofino", "Tofino does not support dleft hash "
                    "tables");
    }
}

void DLeftSetup::postorder(IR::MAU::BackendAttached *ba) {
    auto tbl = findContext<IR::MAU::Table>();
    if (!tbl->for_dleft())
        return;
    if (!ba->attached->is<IR::MAU::StatefulAlu>())
        return;
    if (tbl->match_key.empty())
        return;

    IR::Vector<IR::Expression> components;
    IR::ListExpression *field_list = new IR::ListExpression(components);

    for (auto *read : tbl->match_key) {
        if (read->for_match() || read->for_dleft()) {
            field_list->push_back(read->expr);
        }
    }
    ba->hash_dist = new IR::MAU::HashDist(IR::Type::Bits::get(0), field_list,
                                          IR::MAU::hash_function::random(), nullptr);
}

void DLeftSetup::postorder(IR::MAU::InputXBarRead *read) {
    auto tbl = findContext<IR::MAU::Table>();
    if (!tbl->for_dleft())
        return;
    if (read->for_match())
        read->match_type = IR::ID("dleft_hash");
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
        BUG_CHECK(c->expr->type->width_bits() >=  int(sl->getH() - sl->getL() + 1),
                  "Slice of a cast that is larger than the cast");
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

/** The purpose of BackendCopyPropagation is to propagate reads written in previous sets.
 *  This will only work for set operations, i.e. the following action:
 *
 *      set b, a
 *      set c, b
 *      set d, c
 *
 *  should afterwards be:
 *
 *     set b, a
 *     set c, a
 *     set d, a
 *
 *  The point of this is to parallelize the action as much as possible in order to guarantee
 *  that the action can be performed within a single stage.
 *
 *  Currently the algorithm does not copy propagate forward any non-set operation.  The following
 *  would be considered to be too difficult to copy_propagate
 *
 *      xor c, b, a 
 *      add e, c, d 
 *
 *  as it is not a guarantee that any action can possibly be handled within a single stage.
 *  At some point, this could be loosened
 *
 *      xor c, b, a
 *      set d, c
 *
 *  could be:
 *
 *      xor c, b, a,
 *      xor d, b, a
 *
 *  Another example not currently wall reads are not previously written, and that the writes
 *  are simple, i.e.
 *
 *     set f1[7:0], f2
 *     set f3, f1[3:0]
 *
 *  would be considered too difficult to copy propagate correctly in the short term, as this
 *  itself would require the instructions to first be split into the minimal field slice in
 *  order to correctly copy propagate.  Perhaps this can be done at a later time 
 *
 *  However, instruction with mutually exclusive bitranges would be completely acceptable.
 *  Note that no instructions are eliminated, as this should be the job of ElimUnused
 */
const IR::MAU::Action *BackendCopyPropagation::preorder(IR::MAU::Action *a) {
    visitOnce();
    copy_propagation_replacements.clear();
    return a;
}

const IR::MAU::Instruction *BackendCopyPropagation::preorder(IR::MAU::Instruction *instr) {
    instr->copy_propagated.clear();
    instr->copy_propagated.resize(instr->operands.size(), false);
    // In order to maintain the sequential property, the reads have to be visited before the writes
    for (ssize_t i = instr->operands.size() - 1; i >= 0; i--) {
        bool is_write = i == 0;
        bool elem_copy_propagated = false;
        if (is_write)
            update(instr);
        else
            instr->operands[i] = propagate(instr, instr->operands[i], elem_copy_propagated);
        instr->copy_propagated[i] = elem_copy_propagated;
    }
    prune();
    return instr;
}
/** Mark instr->operands[1] as the most recent replacement for instr->operands[0] when @inst 
  * is a set instruction.  Otherwise, remove instr->operands[0] from the set of copy propagation 
  * candidates. 
  */
void BackendCopyPropagation::update(const IR::MAU::Instruction *instr) {
    const IR::Expression *e = instr->operands[0];
    auto act = findContext<IR::MAU::Action>();
    if (act == nullptr) {
        return;
    }

    le_bitrange bits = { 0, 0 };
    auto field = phv.field(e, &bits);
    if (field == nullptr) {
        return;
    }

    bool replaced = false;
    // If a value is previously written, and previously had a copy propagation,
    // replace this value with a new value, if in a set, or clear the value
    auto it = copy_propagation_replacements[field].begin();
    while (it != copy_propagation_replacements[field].end()) {
        if (it->dest_bits == bits) {
            if (instr->name == "set") {
                it->read = instr->operands[1];
                it++;
            } else {
                it = copy_propagation_replacements[field].erase(it);
            }
            replaced = true;
        // overlapping ranges for copy propagation are too difficult to handle for the
        // first pass
        } else if (!it->dest_bits.intersectWith(bits).empty()) {
            ::error("%s: Currently the field %s[%d:%d] in action %s is assigned in a "
                    "way too complex for the compiler to currently handle.  Please consider "
                    "simplifying this action around this parameter", instr->srcInfo,
                    field->name, bits.hi, bits.lo, act->name);
            replaced = true;
            it++;
        } else {
            it++;
        }
    }

    if (!replaced && instr->name == "set") {
        copy_propagation_replacements[field].emplace_back(bits, instr->operands[1]);
    }
}

/** @returns the copy propagation candidate for @e if @e can be replaced (setting 
  * @elem_copy_propagated to true), or @e if @e cannot be replaced (setting @elem_copy_propagated 
  * to false). 
  */
const IR::Expression *BackendCopyPropagation::propagate(const IR::MAU::Instruction *instr,
    const IR::Expression *e, bool &elem_copy_propagated) {
    auto act = findContext<IR::MAU::Action>();
    if (act == nullptr) {
        elem_copy_propagated = false;
        return e;
    }

    le_bitrange bits = { 0, 0 };
    auto field = phv.field(e, &bits);
    if (field == nullptr) {
        elem_copy_propagated = false;
        return e;
    }

    // If a read is possibly replaced with a copy propagated value, replace this value
    for (auto replacement : copy_propagation_replacements[field]) {
        if (replacement.dest_bits.contains(bits)) {
            elem_copy_propagated = true;
            return MakeSlice(replacement.read, bits.lo, bits.hi);
        } else if (!replacement.dest_bits.intersectWith(bits).empty()) {
           ::error("%s: Currently the field %s[%d:%d] in action %s is read in a way "
                   "too complex for the compiler to currently handle.  Please consider "
                   "simplifying this action around this parameter", instr->srcInfo,
                   field->name, bits.hi, bits.lo, act->name);
        }
    }

    elem_copy_propagated = false;
    return e;
}


/** The purpose of this pass is to verify that an action is able to be performed in parallel
 *  Because the semantics of P4 are that instructions are sequential, and the actions in
 *  Tofino are parallel, this guarantees that an action is possible as a single action.
 *
 *  The following example would be marked as non-parallel
 *
 *     set f2, f1
 *     set f3, f2
 *
 *  as f2 is previously written and then read, which would require a two stage parameter.
 *
 *  Fields will be skipped if they have been copy propagated.  This is necessary if the P4
 *  programmer intended on swapping fields, i.e.
 *
 *      set $tmp, f2
 *      set f2, f1
 *      set f1, $tmp
 *
 *  BackendCopyPropagation will have the following output:
 *
 *      set $tmp, f2,
 *      set f2, f1,
 *      set f1, f2
 *
 *  The f2 read in the final instruction will be marked as having been copy propagated.  By
 *  using this marking, the algorithm skips over any things that have been copy propagated
 *  as the pre-change value is the value desired.
 *
 *  Note the following instruction will also be caught:
 *
 *      set f1[7:0], f2
 *      set f1[11:4], f3
 *
 *  as these instructions not parallelizable.
 *
 *  In the future, an action could possibly be split across multiple stages, given that
 *  the following is implemented:
 * 
 *      1. Splitting a complex actions into multiple actions that are single stage.
 *      2. Chaining the next table with these action splitting
 *      3. Somehow update the context JSON, in the case that this requires either stateful
 *         outputs or action parameters.  This 3rd step is significantly more complicated
 *
 *   Let say a table t1 has actions a1-a3.  a2 and a3 are single-stage actions, while a1
 *   is the following:
 *        xor $tmp1, f1, f2
 *        add f4, f3, $tmp1
 *
 *   a1 would be split into:
 *
 *   action a1_0 { xor $tmp1, f1, f2 }
 *   action a1_1 { add f4, f3, $tmp1 }
 *
 *   the table apply then must be converted into
 *   if (t1.apply().action_run) {
 *       a1_0 { a1_1(); }
 *   }
 *
 *   The splitting of an action is relatively easy.  The chaining could have many corner
 *   cases, but would be only compiler.  However, if instead of f3, the compiler had
 *   an action data parameter, an API would be required for the splitting of this table
 *   to write to two logical tables, which definitely does not yet have driver support. 
 *
 */
bool VerifyParallelWritesAndReads::is_parallel(const IR::Expression *e, bool is_write) {
    le_bitrange bits = { 0, 0 };
    auto field = phv.field(e, &bits);
    if (field == nullptr)
        return true;

    if (is_write) {
        bool append = true;
        // Ensures that the writes of ranges of field bits are either completely identical
        // or over mutually exclusive regions of that field, as those are too difficult
        // to deal with
        for (auto write_bits : writes[field]) {
            // Because EliminateAllButLastWrite has to come after this, due to the write
            // appearing in potentially reads
            if (bits == write_bits) {
                append = false;
            } else if (!bits.intersectWith(write_bits).empty()) {
                return false;
            }
        }
        if (append)
            writes[field].push_back(bits);
    } else {
        for (auto write_bits : writes[field]) {
            if (!bits.intersectWith(write_bits).empty()) {
                return false;
            }
        }
    }
    return true;
}

/** Determines if any values of this particular instruction have previously been written
 *  within this action, and if so, throw an error
 */
bool VerifyParallelWritesAndReads::preorder(const IR::MAU::Instruction *instr) {
    auto act = findContext<IR::MAU::Action>();
    for (ssize_t i = instr->operands.size() -1; i >= 0; i--) {
        // Skip copy propagated values
        if (instr->copy_propagated[i])
            continue;
        bool is_write = i == 0;
        if (!is_parallel(instr->operands[i], is_write)) {
            le_bitrange bits = {0, 0};
            auto field = phv.field(instr->operands[i], &bits);
            ::error("%s: The action %s manipulates field %s[%d:%d] in such a way that "
                    "requires multiple stages from an action.  Currently p4c only single "
                    "stage actions are support.  Consider rewriting the action to be a "
                    "single stage action", instr->srcInfo, act->name, field->name, bits.hi,
                    bits.lo);
        }
    }
    return false;
}

bool VerifyParallelWritesAndReads::preorder(const IR::MAU::Action *) {
    writes.clear();
    return true;
}

/** The purpose of this pass is to parallelize the passes by removing all writes to the last
 *  from a field, i.e.
 *
 *      set f1, f2
 *      xor f1, f3, f4
 *      set f1, f5
 *
 *  will be translated into:
 *
 *      set f1, f5
 *
 *  because in a parallel sense, this is the only result that matters.
 *
 *  This pass has to follow VerifyParallelWritesAndReads, due to the following example:
 *
 *      add f1, f2, f3
 *      add f1, f1, f4 
 *
 *  This could not be considered parallel, as long as the check happens before the elimination
 */
bool EliminateAllButLastWrite::Scan::preorder(const IR::MAU::Action *) {
    last_instr_map.clear();
    return true;
}

bool EliminateAllButLastWrite::Scan::preorder(const IR::MAU::Instruction *instr) {
    if (instr->operands.size() == 0)
        return false;

    auto write = instr->operands[0];
    le_bitrange bits = { 0, 0 };
    auto field = self.phv.field(write, &bits);
    if (field == nullptr) {
        auto *act = findContext<IR::MAU::Action>();
        ::error("%s: A write of an instruction in action %s is not a PHV field", instr->srcInfo,
                act->name);
        return false;
    }
    PHV::Field::Slice fs(field, bits);
    // Ensures that the last instruction relating to this instruction is marked
    last_instr_map[fs] = instr;
    return false;
}

void EliminateAllButLastWrite::Scan::postorder(const IR::MAU::Action *a) {
    self.last_instr_per_action_map[a] = last_instr_map;
}

const IR::MAU::Action *EliminateAllButLastWrite::Update::preorder(IR::MAU::Action *act) {
    current_af = getOriginal()->to<IR::MAU::Action>();
    return act;
}

const IR::MAU::Instruction *
        EliminateAllButLastWrite::Update::preorder(IR::MAU::Instruction *instr) {
    auto orig_instr = getOriginal()->to<IR::MAU::Instruction>();
    auto last_instr_map = self.last_instr_per_action_map[current_af];
    prune();

    if (instr->operands.size() == 0)
        return instr;

    auto write = instr->operands[0];
    le_bitrange bits = { 0, 0 };
    auto field = self.phv.field(write, &bits);
    if (field == nullptr) {
        ::error("%s: A write of an instruction in action %s is not a PHV field", instr->srcInfo,
                current_af->name);
        return instr;
    }
    PHV::Field::Slice fs(field, bits);
    BUG_CHECK(last_instr_map.count(fs) != 0, "A write was not found in the inspect pass, but "
              "was found in the update pass");
    // Remove if not the last instruction
    if (last_instr_map.at(fs) != orig_instr) {
        return nullptr;
    }
    return instr;
}

/** EliminateAllButLastWrite has to follow VerifyParallelWritesAndReads.  Look at the example
 *  above EliminateAllButLastWrite
 */
InstructionSelection::InstructionSelection(PhvInfo &phv) : PassManager {
    new ValidateInvalidatePrimitive(phv),
    new Synth2PortSetup(phv),
    new DoInstructionSelection(phv),
    new ConvertCastToSlice,
    new StatefulAttachmentSetup(phv),
    new LPFSetup(phv),
    new DLeftSetup,
    new CollectPhvInfo(phv),
    new BackendCopyPropagation(phv),
    new VerifyParallelWritesAndReads(phv),
    new EliminateAllButLastWrite(phv),
    new CollectPhvInfo(phv),
    new PHV::ValidateActions(phv, false, false, false)
} {}
