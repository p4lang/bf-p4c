#include "bf-p4c/mau/instruction_selection.h"
#include "lib/bitops.h"
#include "lib/safe_vector.h"
#include "action_analysis.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/validate_allocation.h"


bool UnimplementedRegisterMethodCalls::preorder(const IR::Primitive *prim) {
    auto dot = prim->name.find('.');
    auto objType = dot ? prim->name.before(dot) : cstring();
    cstring method = dot ? cstring(dot+1) : prim->name;

    if (objType == "Register" && (method == "read" || method == "write")) {
        P4C_UNIMPLEMENTED("%s: The method call of read and write on a Register is currently not "
                          "supported in p4c.  Please use RegisterAction to describe any register "
                          "programming.", prim->srcInfo);
    }
    return true;
}

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

    auto act = findContext<IR::MAU::Action>();
    if (act == nullptr)
        return prim;

    auto tbl = findContext<IR::MAU::Table>();
    if (tbl == nullptr)
        return prim;

    auto dot = prim->name.find('.');
    auto objType = dot ? prim->name.before(dot) : cstring();
    IR::Node *rv = prim;

    const IR::GlobalRef *glob = nullptr;

    IR::MAU::MeterType meter_type = IR::MAU::MeterType::UNUSED;

    cstring method = dot ? cstring(dot+1) : prim->name;
    if (objType.endsWith("Action") || objType == "selector_action") {
        bool direct_access = (prim->operands.size() == 1 && method == "execute") ||
                             objType == "DirectRegisterAction" ||
                             method == "execute_direct";
        glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto salu = glob->obj->to<IR::MAU::StatefulAlu>();
        if (method == "address") {
            if (getParent<IR::MAU::Action>()) {
                // dead use of the address, so discard it.
                return nullptr; }
            auto t = IR::Type::Bits::get(32);
            return new IR::MAU::StatefulCounter(prim->srcInfo, t, salu); }
        auto ta_pair = tbl->name + "-" + act->name.originalName;
        BUG_CHECK(salu->action_map.count(ta_pair), "%s: Stateful Alu %s does not "
                  "have an action in it's action map", prim->srcInfo, salu->name);
        auto salu_action_name = salu->action_map.at(ta_pair);
        auto pos = salu->instruction.find(salu_action_name);
        int salu_index = std::distance(salu->instruction.begin(), pos);
        switch (salu_index) {
            case 0:
                meter_type = IR::MAU::MeterType::STFUL_INST0; break;
            case 1:
                meter_type = IR::MAU::MeterType::STFUL_INST1; break;
            case 2:
                meter_type = IR::MAU::MeterType::STFUL_INST2; break;
            case 3:
                meter_type = IR::MAU::MeterType::STFUL_INST3; break;
            default:
                BUG("%s: An stateful instruction %s is outside the bounds of the stateful "
                    "memory in %s", prim->srcInfo, pos->second, salu->name);
        }

        // needed to setup the index and/or type properly
        stateful.push_back(prim);

        if (objType == "RegisterAction" && salu->direct != direct_access)
            error("%s: %sdirect access to %sdirect register", prim->srcInfo,
                  direct_access ? "" : "in", salu->direct ? "" : "in");
        unsigned idx = (method == "execute" && !direct_access) ? 2 : 1;
        int output = 1;
        int output_offsets[] = { 0, 64, 32, 96 };

        for (; idx < prim->operands.size(); ++idx, ++output) {
            BUG_CHECK(size_t(output) < sizeof(output_offsets)/sizeof(output_offsets[0]),
                      "too many outputs");
            int bit = output_offsets[output];
            int output_size = prim->type->width_bits();
            auto ao = new IR::MAU::AttachedOutput(IR::Type::Bits::get(bit+output_size), salu);
            auto dest = prim->operands[idx];
            auto instr = new IR::MAU::Instruction(prim->srcInfo, "set", dest,
                                                  MakeSlice(ao, bit, bit+output_size - 1));
            // Have to put these instructions at the highest level of the instruction
            created_instrs.push_back(instr);
        }
        rv = new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(prim->type),
                                      new IR::MAU::AttachedOutput(prim->type, salu));
    } else if (prim->name == "Counter.count") {
        glob = prim->operands.at(0)->to<IR::GlobalRef>();
        stateful.push_back(prim);  // needed to setup the index
        rv = nullptr;
    } else if (prim->name == "Lpf.execute" || prim->name == "Wred.execute" ||
               prim->name == "Meter.execute" || prim->name == "DirectLpf.execute" ||
               prim->name == "DirectWred.execute") {
        glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto mtr = glob->obj->to<IR::MAU::Meter>();
        BUG_CHECK(mtr != nullptr, "%s: Cannot find associated meter for the method call %s",
                  prim->srcInfo, *prim);
        stateful.push_back(prim);
        rv = new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(prim->type),
                                      new IR::MAU::AttachedOutput(prim->type, mtr));
    } else if (prim->name == "DirectCounter.count") {
        glob = prim->operands.at(0)->to<IR::GlobalRef>();
        stateful.push_back(prim);
        rv = nullptr;
    } else if (prim->name == "DirectMeter.execute") {
        glob = prim->operands.at(0)->to<IR::GlobalRef>();
        auto mtr = glob->obj->to<IR::MAU::Meter>();
        stateful.push_back(prim);
        rv = new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(prim->type),
                                      new IR::MAU::AttachedOutput(IR::Type::Bits::get(8), mtr));
    }

    if (glob != nullptr) {
        auto at_mem = glob->obj->to<IR::MAU::AttachedMemory>();
        auto u_id = at_mem->unique_id();
        if (per_flow_enables.count(u_id) > 0) {
            ::error("%s: An attached table can only be executed once per action", prim->srcInfo);
        }
        per_flow_enables.insert(u_id);
        if (meter_type != IR::MAU::MeterType::UNUSED)
            meter_types[u_id] = meter_type;
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
    for (auto stateful_prim : stateful) {
        auto at_mem = stateful_prim->operands.at(0)->to<IR::GlobalRef>()
                                   ->obj->to<IR::MAU::AttachedMemory>();
        BUG_CHECK(at_mem, "%s: Stateful Call %s doesn't have a stateful object",
                          stateful_prim->srcInfo, stateful_prim);
        act->stateful_calls.emplace_back(stateful_prim->srcInfo, stateful_prim, at_mem);
    }

    // act->stateful.append(stateful);
    act->per_flow_enables.insert(per_flow_enables.begin(), per_flow_enables.end());
    act->meter_types.insert(meter_types.begin(), meter_types.end());
    return act;
}

template<class T> static
T *clone(const T *ir) { return ir ? ir->clone() : nullptr; }

DoInstructionSelection::DoInstructionSelection(const BFN_Options& options, const PhvInfo &phv)
        : options(options), phv(phv) {}

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
    LOG3("Checking src1 : " << e);
    if (auto *c = e->to<IR::Cast>())
        return checkSrc1(c->expr);
    if (auto slice = e->to<IR::Slice>())
        return checkSrc1(slice->e0);
    if (e->is<IR::Constant>()) return true;
    if (e->is<IR::BoolLiteral>()) return true;
    if (e->is<IR::MAU::ActionArg>()) return true;
    if (e->is<IR::MAU::HashDist>()) return true;
    if (e->is<IR::MAU::RandomNumber>()) return true;
    if (e->is<IR::MAU::AttachedOutput>()) return true;
    if (e->is<IR::MAU::StatefulCounter>()) return true;
    if (auto m = e->to<IR::Member>())
        if (m->expr->is<IR::MAU::AttachedOutput>())
            return true;
    return phv.field(e);
}

bool DoInstructionSelection::checkConst(const IR::Expression *ex, long &value) {
    if (auto *k = ex->to<IR::Constant>()) {
        value = k->asLong();  // \TODO: long or 64-bit value?
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

const IR::Expression *DoInstructionSelection::postorder(IR::AddSat *e) {
    if (!af) return e;
    auto opName = "saddu";
    if (e->type->is<IR::Type_Bits>() && e->type->to<IR::Type_Bits>()->isSigned)
        opName = "sadds";
    return new IR::MAU::Instruction(e->srcInfo, opName,
                                        new IR::TempVar(e->type), e->left, e->right);
}

const IR::Expression *DoInstructionSelection::postorder(IR::SubSat *e) {
    if (!af) return e;
    auto opName = "ssubu";
    auto eLeft = e->left;
    auto eRight = e->right;
    auto bits = e->type->to<IR::Type_Bits>();
    if (bits && bits->isSigned) {
        opName = "ssubs";
        if (auto *k = eRight->to<IR::Constant>()) {
            // Dont convert to an add when constant is equal to maximum negative
            // value as the value will overflow upon negation.
            // e.g. For an 8 bit subtraction
            // ssubs b, a, -128 => sadds b, a, 128 (but 128 in 8 bits overflows and becomes -128).
            if (k->asLong() != -(1LL << (bits->width_bits() - 1))) {
                opName = "sadds";
                eLeft = (-*k).clone();
                eRight = e->left;
            }
        }
    }
    return new IR::MAU::Instruction(e->srcInfo, opName, new IR::TempVar(e->type), eLeft, eRight);
}

const IR::Expression *DoInstructionSelection::postorder(IR::Sub *e) {
    if (!af) return e;
    if (auto *k = e->right->to<IR::Constant>())
        return new IR::MAU::Instruction(e->srcInfo, "add", new IR::TempVar(e->type),
                                        (-*k).clone(), e->left);
    return new IR::MAU::Instruction(e->srcInfo, "sub", new IR::TempVar(e->type), e->left, e->right);
}
const IR::Expression *DoInstructionSelection::postorder(IR::Neg *e) {
    if (!af) return e;
    return new IR::MAU::Instruction(e->srcInfo, "sub", new IR::TempVar(e->type),
                                    new IR::Constant(0), e->expr);
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
                                                const IR::Expression *dest, int lo = -1,
                                                int hi = -1, bool cast = false) {
    if (auto *c = in->to<IR::Cast>())
        // perhaps everything underneath should be cast to the same size
        return fillInstDest(c->expr, dest, c->destType->width_bits(), -1, true);
    if (auto *sl = in->to<IR::Slice>()) {
        return fillInstDest(sl->e0, dest, sl->getL(), sl->getH());
    }
    auto *inst = in ? in->to<IR::MAU::Instruction>() : nullptr;
    auto *tv = inst ? inst->operands[0]->to<IR::TempVar>() : nullptr;
    if (tv) {
        int id;
        if (sscanf(tv->name, "$tmp%d", &id) > 0 && id == tv->uid) --tv->uid;
        auto *rv = inst->clone();
        rv->operands[0] = dest;
        for (size_t i = 1; i < rv->operands.size(); i++) {
            if (lo == -1)
                break;
            if (cast)
                rv->operands[i] = new IR::Cast(IR::Type::Bits::get(lo), rv->operands[i]);
            else
                rv->operands[i] = MakeSlice(rv->operands[i], lo, hi);
        }
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
    LOG4("DoInstructionSelection::postorder on primitive " << prim->name);
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
        return prim; }

    // get rid of introduced tempvars
    for (auto &op : prim->operands) {
        if (auto *inst = op->to<IR::MAU::Instruction>()) {
            if (inst->name == "set" && inst->operands.at(0)->is<IR::TempVar>()) {
               BUG_CHECK(inst->operands.size() == 2, "invalid set");
               op = inst->operands.at(1); } } }

    if (prim->name == "recirculate_raw") {
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
        bool custom_hash = false;
        auto it = prim->operands.begin();
        // operand 0 is always the extern itself.
        BUG_CHECK(it != prim->operands.end(), "primitive %s does not have a "
                                              "reference to P4 extern", prim->name);
        auto glob = (*it)->to<IR::GlobalRef>();
        auto decl = glob->obj->to<IR::Declaration_Instance>();
        auto type = decl->type->to<IR::Type_Specialized>()->arguments->at(0);
        unsigned size = type->width_bits();
        std::advance(it, 1);

        // operand 1 can be either crc_poly or the first argument in get().
        IR::MAU::HashFunction algorithm;
        // if operand 1 is crc_poly extern
        auto crc_poly = (*it)->to<IR::GlobalRef>();
        if (crc_poly) {
            custom_hash = true;
            if (!algorithm.convertPolynomialExtern(crc_poly))
                BUG("invalid hash algorithm %s", decl->arguments->at(1));
            std::advance(it, 1); }

        // otherwise, if not a custom hash from user, it is one of the hashes built into compiler.
        if (!custom_hash && !algorithm.setup(decl->arguments->at(0)->expression))
                BUG("invalid hash algorithm %s", decl->arguments->at(0));

        // remaining operands must be the arguments for get().
        int remaining_op_size = std::distance(it, prim->operands.end());
        auto data = *it;
        if (remaining_op_size > 1) {
            auto base = std::next(it, 1);
            if (auto *constant = (*base)->to<IR::Constant>()) {
                if (constant->asInt() != 0)
                    error("%s: The initial offset for a hash "
                          "calculation function has to be zero %s",
                          prim->srcInfo, *prim); }
            auto max = std::next(it, 2);
            if (auto *constant = (*max)->to<IR::Constant>()) {
                auto value = constant->asUint64();
                if (value != 0) {
                    size = bitcount(value - 1);
                    if ((1ULL << size) != value)
                        error("%s: The hash offset must be a power of 2 in a hash calculation %s",
                              prim->srcInfo, *prim); } } }

        // ADD PD GEN Info for Dynamic Hashing in P4_16
        if (options.langVersion == CompilerOptions::FrontendVersion::P4_16) {
            auto dynHashName = decl->controlPlaneName() + ".$CONFIGURE";
            if (auto le = data->to<IR::ListExpression>()) {
                auto hle = new IR::HashListExpression(data->srcInfo, le->components, dynHashName);
                auto nl = new IR::NameList();
                nl->names.push_back("$field_list_1");
                hle->fieldListNames = nl;
                auto al = new IR::NameList();
                al->names.emplace_back(data->srcInfo, algorithm.name());
                hle->algorithms = al;
                data = hle;
            }
        }
        auto *hd = new IR::MAU::HashDist(prim->srcInfo, IR::Type::Bits::get(size), data, algorithm);
        hd->bit_width = size;
        auto next_type = IR::Type::Bits::get(size);
        return new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(next_type),
                                        new IR::Cast(next_type, hd));
    } else if (prim->name == "Random.get") {
        auto rn = new IR::MAU::RandomNumber(prim->srcInfo, prim->type);
        auto next_type = prim->type;
        return new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(next_type),
                                        new IR::Cast(next_type, rn));
    } else if (prim->name == "invalidate") {
        return new IR::MAU::Instruction(prim->srcInfo, "invalidate", prim->operands[0]);
    } else {
        WARNING("unhandled in InstSel: " << *prim); }
    return prim;
}

static const IR::Type *stateful_type_for_primitive(const IR::Primitive *prim) {
    if (prim->name == "Counter.count" || prim->name == "DirectCounter.count")
        return IR::Type_Counter::get();
    if (prim->name == "Meter.execute" || prim->name == "DirectMeter.execute" ||
        prim->name == "Lpf.execute" || prim->name == "DirectLpf.execute" ||
        prim->name == "Wred.execute" || prim->name == "DirectWred.execute")
        return IR::Type_Meter::get();
    if (strstr(prim->name, "Action.") || prim->name.startsWith("selector_action."))
        return IR::Type_Register::get();
    BUG("Not a stateful primitive %s", prim);
}

static ssize_t index_operand(const IR::Primitive *prim) {
    if (prim->name.startsWith("Direct"))
        return -1;
    else if (prim->name.startsWith("Counter") || prim->name.startsWith("Meter") ||
        prim->name.endsWith("Action.execute"))
        return 1;
    else if (strstr(prim->name, "Action."))
        return -1;
    else if (prim->name.startsWith("Lpf") || prim->name.startsWith("Wred"))
        return 2;
    return 1;
}

static size_t input_operand(const IR::Primitive *prim) {
    if (prim->name.startsWith("Lpf") || prim->name.startsWith("Wred") ||
            prim->name.startsWith("DirectLpf") || prim->name.startsWith("DirectWred"))
        return 1;
    else
        return -1;
}

static size_t precolor_operand(const IR::Primitive *prim) {
    if (prim->name.startsWith("DirectMeter"))
        return 1;
    else if (prim->name.startsWith("Meter"))
        return 2;
    return -1;
}


bool StatefulAttachmentSetup::Scan::preorder(const IR::MAU::Action *act) {
    self.remove_tempvars.clear();
    if (act->stateful_calls.empty())
        return false;

    for (auto call : act->stateful_calls) {
        auto prim = call->prim;
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
    const IR::MAU::AttachedMemory *obj = nullptr;
    use_t use = IR::MAU::StatefulUse::NO_USE;
    auto dot = prim->name.find('.');
    auto objType = dot ? prim->name.before(dot) : cstring();
    cstring method = dot ? cstring(dot+1) : prim->name;
    if (objType.endsWith("Action") || objType == "selector_action") {
        obj = prim->operands.at(0)->to<IR::GlobalRef>()->obj->to<IR::MAU::StatefulAlu>();
        BUG_CHECK(obj, "invalid object");
        if (method == "execute") {
            if (objType == "DirectRegisterAction")
                use = IR::MAU::StatefulUse::DIRECT;
            else
                use = IR::MAU::StatefulUse::INDIRECT;
        } else if (method == "execute_log") {
            use = IR::MAU::StatefulUse::LOG;
        } else if (method == "enqueue") {
            use = IR::MAU::StatefulUse::FIFO_PUSH;
        } else if (method == "dequeue") {
            use = IR::MAU::StatefulUse::FIFO_POP;
        } else if (method == "push") {
            use = IR::MAU::StatefulUse::STACK_PUSH;
        } else if (method == "pop") {
            use = IR::MAU::StatefulUse::STACK_POP;
        } else {
            BUG("Unknown %s method %s in: %s", objType, method, prim); }
    } else if (method == "execute") {
        obj = prim->operands.at(0)->to<IR::GlobalRef>()->obj->to<IR::MAU::Meter>();
        BUG_CHECK(obj, "invalid object");
        use = objType.startsWith("Direct") ? IR::MAU::StatefulUse::DIRECT
                                           : IR::MAU::StatefulUse::INDIRECT;
    } else if (method == "count") {
        obj = prim->operands.at(0)->to<IR::GlobalRef>()->obj->to<IR::MAU::Counter>();
        BUG_CHECK(obj, "invalid object");
        use = objType.startsWith("Direct") ? IR::MAU::StatefulUse::DIRECT
                                           : IR::MAU::StatefulUse::INDIRECT;
    }
    if (obj) {
        auto *act = findContext<IR::MAU::Action>();
        use_t &prev_use = self.action_use[act][obj];
        if (prev_use != IR::MAU::StatefulUse::NO_USE && prev_use != use)
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
                                     IR::MAU::HashFunction::identity());
    hd->bit_width = size;
    return hd;
}

/** Either find or generate a Hash Distribution unit, given what IR::Node is in the primitive
 *  FIXME: Currently v1model always casts these particular parameters to a size.  Perhaps
 *  these casts will be gone by the time we reach extract_maupipe.
 */
const IR::MAU::HashDist *StatefulAttachmentSetup::find_hash_dist(const IR::Expression *expr,
                                                               const IR::Primitive *prim) {
    const IR::MAU::HashDist *hd = expr->to<IR::MAU::HashDist>();
    if (!hd) {
        auto tv = expr->to<IR::TempVar>();
        if (tv != nullptr && stateful_alu_from_hash_dists.count(tv->name)) {
            hd = stateful_alu_from_hash_dists.at(tv->name);
        } else if (phv.field(expr)) {
            hd = create_hash_dist(expr, prim); } }
    return hd;
}

/**
 * Determine the index operand for a particular action.  This is to determine the address
 * for the stateful call, which is required for the context JSON.
 *
 * Also currently validates that the address is able to be understood, i.e. if it
 * can be part of a HashDist, Constant, etc.
 *
 * FIXME: a hash.get is not yet translated to a HashDist before this.  The only way to
 * do this is to initialize a temporary variable as this, and use this as an address
 */
void StatefulAttachmentSetup::Scan::setup_index_operand(const IR::Expression *index_expr,
        const IR::MAU::Synth2Port *synth2port, const IR::MAU::Table *tbl,
        const IR::MAU::StatefulCall *call) {
    while (auto *c = index_expr->to<IR::Cast>()) {
        index_expr = c->expr;
    }

    bool both_hash_and_index = false;
    auto index_check = std::make_pair(synth2port, tbl);

    if (auto hd = self.find_hash_dist(index_expr, call->prim)) {
        HashDistKey hdk = std::make_pair(synth2port, tbl);
        if (self.update_hd[hdk] && !self.update_hd[hdk]->equiv(*hd)) {
            error("%sIncompatible attached indexing between actions in table %s",
                  call->prim->srcInfo, tbl->name); }
        self.update_hd[hdk] = hd;
        index_expr = hd;
        if (self.addressed_by_index.count(index_check))
            both_hash_and_index = true;
        self.addressed_by_hash.insert(index_check);
    } else if (!index_expr->is<IR::Constant>() && !index_expr->is<IR::MAU::ActionArg>()) {
        ::error("%s: The index is too complex for the primitive to be handled.",
             call->prim->srcInfo);
    } else {
        if (self.addressed_by_hash.count(index_check))
            both_hash_and_index = true;
        self.addressed_by_index.insert(index_check);
    }

    if (both_hash_and_index) {
        ::error("%s: The attached %s is addressed by both hash and index in %s, "
                "which cannot be supported.", call->prim->srcInfo, synth2port, tbl); }

    StatefulCallKey sck = std::make_pair(call, tbl);
    self.update_calls[sck] = index_expr;
}

/** This pass was specifically created to deal with adding the HashDist object to different
 *  stateful objects.  On one particular case, execute_stateful_alu_from_hash was creating
 *  two separate instructions, a TempVar = hash function call, and an execute stateful call
 *  addressed by this TempVar.  This pass combines these instructions into one instruction,
 *  and correctly saves the HashDist IR into these attached tables
 */
void StatefulAttachmentSetup::Scan::postorder(const IR::MAU::Table *tbl) {
    for (auto act : Values(tbl->actions)) {
        for (auto call : act->stateful_calls) {
            auto prim = call->prim;
            // typechecking should have verified
            BUG_CHECK(prim->operands.size() >= 1, "Invalid primitive %s", prim);
            auto gref = prim->operands[0]->to<IR::GlobalRef>();
            // typechecking should catch this too
            BUG_CHECK(gref, "No object named %s", prim->operands[0]);
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
            }

            auto type = stateful_type_for_primitive(prim);
            if (!synth2port || synth2port->getType() != type) {
                // typechecking is unable to check this without a good bit more work
                error("%s: %s is not a %s", prim->operands[0]->srcInfo, gref->obj, type);
            }

            auto index_op = index_operand(prim);
            if (index_op < 0) {
                continue;
            }

            if (static_cast<int>(prim->operands.size()) > index_op)
                setup_index_operand(prim->operands[index_op], synth2port, tbl, call);
            else
                ::error("%s: Indirect attached object %s requires an index to address, as it "
                        "isn't directly addressed from the match entry", prim->srcInfo,
                         synth2port->name);
        }
    }
}

/**
 * Save the index operand into the StatefulCall IR Node
 */
const IR::MAU::StatefulCall *
    StatefulAttachmentSetup::Update::preorder(IR::MAU::StatefulCall *call) {
    auto *tbl = findOrigCtxt<IR::MAU::Table>();
    auto *orig_call = getOriginal()->to<IR::MAU::StatefulCall>();

    StatefulCallKey sck = std::make_pair(orig_call, tbl);
    if (auto expr = ::get(self.update_calls, sck))
        call->index = expr;

    auto prim = call->prim;
    BUG_CHECK(prim->operands.size() >= 1, "Invalid primitive %s", prim);
    auto gref = prim->operands[0]->to<IR::GlobalRef>();
    auto attached = gref->obj->to<IR::MAU::AttachedMemory>();
    auto act = findOrigCtxt<IR::MAU::Action>();
    use_t use = self.action_use[act][attached];
    if (!(use == IR::MAU::StatefulUse::NO_USE ||
          use == IR::MAU::StatefulUse::DIRECT ||
          use == IR::MAU::StatefulUse::INDIRECT)) {
        BUG_CHECK(call->index == nullptr, "%s: Primitive cannot both have index and use "
                  "counter index: %s", prim->srcInfo, prim);
        call->index = new IR::MAU::StatefulCounter(prim->srcInfo, prim->type, attached);
    }

    prune();
    return call;
}

/**
 * Save the Hash Distribution unit and the type of the stateful ALU counter
 */
const IR::MAU::BackendAttached *
        StatefulAttachmentSetup::Update::preorder(IR::MAU::BackendAttached *ba) {
    auto *tbl = findOrigCtxt<IR::MAU::Table>();
    HashDistKey hdk = std::make_pair(ba->attached, tbl);
    if (auto hd = ::get(self.update_hd, hdk)) {
        ba->hash_dist = hd; }
    use_t use = IR::MAU::StatefulUse::NO_USE;
    for (auto act : Values(tbl->actions)) {
        auto use2 = self.action_use[act][ba->attached];
        if (use2 != IR::MAU::StatefulUse::NO_USE) {
            if (use != IR::MAU::StatefulUse::NO_USE && use != use2) {
                error("inconsistent use of %s in table %s", ba->attached, tbl);
                break;
            }
            use = use2;
        }
    }
    ba->use = use;
    prune();
    return ba;
}

const IR::MAU::Instruction *StatefulAttachmentSetup::Update::preorder(IR::MAU::Instruction *inst) {
    if (self.remove_instr.count(getOriginal())) return nullptr;
    return inst;
}

bool MeterSetup::Scan::preorder(const IR::MAU::Instruction *) {
    return false;
}

const IR::Expression *MeterSetup::Scan::convert_cast_to_slice(const IR::Expression *expr) {
    if (auto c = expr->to<IR::Cast>()) {
        return convert_cast_to_slice(MakeSlice(c->expr, 0, c->type->width_bits() - 1));
    }
    return expr;
}

void MeterSetup::Scan::find_input(const IR::Primitive *prim) {
    int input_index = input_operand(prim);
    if (input_index == -1)
        return;

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
        return;
    }

    auto *act = findContext<IR::MAU::Action>();
    auto *tbl = findContext<IR::MAU::Table>();
    auto *other_field = self.phv.field(self.update_lpfs.at(mtr));

    ERROR_CHECK(field == other_field, "%s: The call of this lpf.execute in action %s has "
                "a different input %s than another lpf.execute on %s in the same table %s. "
                "The other input is %s.", prim->srcInfo, act->name, field->name, mtr->name,
                tbl->name, other_field->name);
}

/** This determines the field to be used for the pre-cplor.  It will also mark a meter as
 *  color-aware or color-blind.
 */
void MeterSetup::Scan::find_pre_color(const IR::Primitive *prim) {
    auto act = findContext<IR::MAU::Action>();
    if (act == nullptr)
        return;
    auto gref = prim->operands[0]->to<IR::GlobalRef>();
    // typechecking should catch this too
    BUG_CHECK(gref, "No object named %s", prim->operands[0]);
    auto mtr = gref->obj->to<IR::MAU::Meter>();
    int pre_color_index = precolor_operand(prim);
    BUG_CHECK(!(mtr == nullptr && pre_color_index != -1), "%s: Operation requiring pre-color is "
             "not a meter", prim->srcInfo);

    if (mtr == nullptr)
        return;

    // A pre-color only appears as an extra parameter on direct/indirect meters.  If the meter
    // either doesn't have a pre-color or is an lpf/wred, then the type is normal
    if (pre_color_index == -1 || static_cast<int>(prim->operands.size() - 1) < pre_color_index) {
        self.standard_types[act] = mtr->unique_id();
        return;
    }

    auto pre_color = prim->operands[pre_color_index];
    pre_color = convert_cast_to_slice(pre_color);
    auto *field = self.phv.field(pre_color);
    BUG_CHECK(field, "%s: Not a phv field in the lpf execute: %s", prim->srcInfo, field->name);

    if (self.update_pre_colors.count(mtr) == 0) {
        self.update_pre_colors[mtr] = pre_color;
    }

    auto *other_field = self.phv.field(self.update_pre_colors.at(mtr));
    ERROR_CHECK(field == other_field, "%s: The meter execute with a pre-color in action %s has "
                "a different pre-color %s than another meter execute on %s.  This other "
                "pre-color is %s.", prim->srcInfo, act->name, field->name, mtr->name,
                other_field->name);
    self.pre_color_types[act] = mtr->unique_id();
}

/** Linking the input for an LPF found in the action call with the IR node.  The Scan pass finds
 *  the PHV field, and the Update pass updates the AttachedMemory object
 */
bool MeterSetup::Scan::preorder(const IR::Primitive *prim) {
    find_input(prim);
    find_pre_color(prim);
    return false;
}

void MeterSetup::Update::update_input(IR::MAU::Meter *mtr) {
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
        return;
    mtr->input = self.update_lpfs.at(orig_meter);
}

void MeterSetup::Update::update_pre_color(IR::MAU::Meter *mtr) {
    auto orig_meter = getOriginal()->to<IR::MAU::Meter>();
    bool has_pre_color = self.update_pre_colors.count(orig_meter) > 0;

    if (has_pre_color) {
        auto pre_color = self.update_pre_colors.at(orig_meter);
        auto hd = new IR::MAU::HashDist(pre_color->srcInfo, IR::Type::Bits::get(2), pre_color,
                       IR::MAU::HashFunction::identity());
        hd->bit_width = 2;
        mtr->pre_color = hd;
    }
}


bool MeterSetup::Update::preorder(IR::MAU::Meter *mtr) {
    update_input(mtr);
    update_pre_color(mtr);
    return true;
}

bool MeterSetup::Update::preorder(IR::MAU::Action *act) {
    auto orig_act = getOriginal()->to<IR::MAU::Action>();
    if (self.standard_types.count(orig_act) > 0) {
        act->meter_types[self.standard_types.at(orig_act)] = IR::MAU::MeterType::COLOR_BLIND;
    } else if (self.pre_color_types.count(orig_act) > 0) {
        act->meter_types[self.pre_color_types.at(orig_act)] = IR::MAU::MeterType::COLOR_AWARE;
    }
    return true;
}

#if 0
void DLeftSetup::postorder(IR::MAU::Table *tbl) {
    if (tbl->for_dleft()) {
        ERROR_CHECK(Device::currentDevice() != Device::TOFINO,
                    "Tofino does not support dleft hash tables");
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
                                          IR::MAU::HashFunction::random(), nullptr);
}
#endif

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
        int operand_size = 0;
        for (auto operand : instr->operands) {
            auto expr = operand;
            if (auto c = operand->to<IR::Cast>()) {
                expr = c->expr;
                // If it's a downcast for source for add/sub, we can add slice for them.
                if (size_set && expr->type->width_bits() > operand_size
                    && (instr->name == "add" || instr->name == "sub")
                    && c->destType) {
                    if (auto* type_bits = c->destType->to<IR::Type_Bits>()) {
                        if (type_bits->width_bits() == operand_size) {
                            expr = MakeSlice(expr, 0, operand_size - 1);
                        }
                    }
                }
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

    bool preorder(const IR::Member* parameter) override {
        if (parameter->member.name.endsWith("digest_type")) {
            invalidatable_fields.insert(phv.field(parameter->toString()));
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
            if (!f) {
                std::string hdrInvalid = "";
                if (prim->operands[0]->is<IR::ConcreteHeaderRef>()) {
                    hdrInvalid += "\nTo invalidate a header, use .setInvalid()";
                }
                error("%s: invalid operand %s for primitive %s: not a field.%s", prim->srcInfo,
                      prim->operands[0], prim, hdrInvalid.c_str());
                return;
            }
            if (!invalidatable_fields.count(f)) {
                error("%s: invalid operand %s for primitive %s", prim->srcInfo, f->name, prim);
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

/** The execution of Counters, Meters, and Stateful ALUs can be per action.  In the following
 *  example, a table has two actions a1 and a2, and an associated counter cnt.  But only
 *  one of the actions has an associated execution.
 *
 *  a1(index) { cnt.execute(index); }
 *  a2() { }
 *
 *  The addresses for counters/meter/stateful alus (as well as all other addresses) have
 *  a per_flow_enable bit.  If this pfe == true, then the associated counter/meter/stateful
 *  alu will run, and if pfe == false, then the table will not run.  This per flow enable
 *  bit is described in section 6.4.3.5.2 Per Entry Enable
 *
 *  The per flow enable bit can be defaulted to true in all addresses.  This can happen
 *  only if all actions run the associated object.  However, if the object is not executed
 *  in all hit actions, then the per flow enable bit must come from match overhead.
 *
 *  A similar concept to per flow enable bit is meter type.  The meter address, which goes
 *  to meters, stateful alus, and selectors, has a 3 bit type associated with the address.
 *  This type is described in section 6.4.4.11. Address Distribution Non-Address Bit
 *  Encodings.
 *
 *  For selectors, there is only one type.  For Meters, a meter can either use a pre-color
 *  value or not.  For Stateful ALUs, one of up to 4 stateful ALUs instructions can be used.
 *  Similar to per flow enable, the meter type can be defaulted, if the object executed
 *  has an identical meter type for all actions.  If the meter type is different per action,
 *  however, the meter type has to come from overhead.
 *
 *  Examine the following example: a table with two actions a1 and a2, and an associated
 *  meter.
 *
 *  a1 (index) { meter.execute(index, pre_color); }
 *  a2 (index) { meter.execute(index);  // no pre_color }
 *
 *  Now both actions execute a meter, so the per_flow_enable can be defaulted on.  However,
 *  because actions have a different meter_type, one with color awareness and one without
 *  color awareness, the meter type has to come from overhead.
 *
 *  When a table is associated with a gateway, a pfe must come from overhead, though that is
 *  not known until table placement, and is not associated with this analysis.  Currently
 *  this needs some work during TableFormat and TablePlacement, and does not yet fully
 *  work.
 */
bool SetupAttachedAddressing::InitializeAttachedInfo::preorder(const IR::MAU::BackendAttached *ba) {
    auto at_mem = ba->attached;
    if (!(at_mem->is<IR::MAU::Counter>() || at_mem->is<IR::MAU::Meter>()
          || at_mem->is<IR::MAU::StatefulAlu>())) {
        return false;
    }

    AttachedActionCoord aac;
    auto tbl = findContext<IR::MAU::Table>();
    auto &attached_info = self.all_attached_info[tbl];
    attached_info[at_mem->unique_id()] = aac;
    return false;
}

bool SetupAttachedAddressing::ScanActions::preorder(const IR::MAU::Action *act) {
    auto tbl = findContext<IR::MAU::Table>();
    if (act->miss_only())
        return false;

    auto &attached_info = self.all_attached_info[tbl];
    for (auto &kv : attached_info) {
        auto &uid = kv.first;
        auto &aac = kv.second;

        if (act->per_flow_enables.count(uid) == 0) {
            aac.all_per_flow_enabled = false;
        }
        if (uid.has_meter_type()) {
            if (act->meter_types.count(uid) == 0)
                continue;
            if (!aac.meter_type_set) {
                aac.meter_type = act->meter_types.at(uid);
                aac.meter_type_set = true;
            } else if (aac.meter_type != act->meter_types.at(uid)) {
                aac.all_same_meter_type = false;
            }
        }
    }
    return false;
}

/** In the case of direct tables, or tables where there isn't any match overhead, but have
 *  an associated address through hash, then a per flow enable bit must always be defaulted
 *  on.  (The hash may not apply for JBay, but unsupported).
 *
 *  The reason for this is that unlike an indirect address, which can be different per
 *  entry, the address is pulled from the same place per direct entry, and the associated
 *  pfe must be identical for all entries.
 *
 *  The meter type must also be identical for these types of tables, as the meter type
 *  must be pulled from after the shift of the address, which is impossible in a direct
 *  entry as the address is at the MSB of the payload.  This pass verifies that this
 *  behavior is correct.
 */
bool SetupAttachedAddressing::VerifyAttached::preorder(const IR::MAU::BackendAttached *ba) {
    auto at_mem = ba->attached;
    if (!(at_mem->is<IR::MAU::Counter>() || at_mem->is<IR::MAU::Meter>()
        || at_mem->is<IR::MAU::StatefulAlu>())) {
        return false;
    }

    auto tbl = findContext<IR::MAU::Table>();
    bool direct = at_mem->direct;
    bool from_hash = ba->hash_dist != nullptr;

    bool keyless = true;
    for (auto key : tbl->match_key) {
        if (key->for_match()) {
            keyless = false;
            break;
        }
    }

    bool singular_functionality = (direct || (from_hash && keyless));

    auto &aac = self.all_attached_info.at(tbl).at(at_mem->unique_id());
    if (singular_functionality) {
        std::string problem = direct ? "direct attached objects"
                                     : "objects attached to a hash action";

        std::string solution = direct ? "" : "either have match data or ";
        std::string meter_type_problem = at_mem->is<IR::MAU::Meter>()
                                       ? "color aware per flow meters"
                                       : "multiple stateful ALU actions";
        ERROR_CHECK(aac.all_per_flow_enabled, "%s: Attached object %s in table %s is executed "
            "in some actions and not executed in others.  However, %s must be enabled in all "
            "hit actions.  If you require this functionality, consider converting this to "
            "%sindirect addressing", ba->srcInfo, at_mem->name, tbl->name, problem, solution);
        ERROR_CHECK(aac.all_same_meter_type, "%s: Attached object %s in table %s requires "
            "multiple different types of meter addressing due to %s.  However %s must "
            "have the same type in all hit actions.  If you require this functionality "
            "consider converting this to %sindirect addressing", ba->srcInfo, at_mem->name,
            tbl->name, meter_type_problem, problem, solution);
    }
    self.attached_coord[ba] = aac;
    return false;
}

void SetupAttachedAddressing::UpdateAttached::simple_attached(IR::MAU::BackendAttached *ba) {
    auto at_mem = ba->attached;
    if (at_mem->direct)
        ba->addr_location = IR::MAU::AddrLocation::DIRECT;
    else
        ba->addr_location = IR::MAU::AddrLocation::OVERHEAD;
    if (at_mem->is<IR::MAU::Selector>()) {
        ba->pfe_location = IR::MAU::PfeLocation::OVERHEAD;
        ba->type_location = IR::MAU::TypeLocation::DEFAULT;
    } else {
        ba->pfe_location = IR::MAU::PfeLocation::DEFAULT;
    }
}

bool SetupAttachedAddressing::UpdateAttached::preorder(IR::MAU::BackendAttached *ba) {
    auto at_mem = ba->attached;
    if (!(at_mem->is<IR::MAU::Counter>() || at_mem->is<IR::MAU::Meter>()
        || at_mem->is<IR::MAU::StatefulAlu>())) {
        simple_attached(ba);
        return false;
    }

    auto orig_ba = getOriginal()->to<IR::MAU::BackendAttached>();
    auto &aac = self.attached_coord.at(orig_ba);

    IR::MAU::PfeLocation pfe_loc = IR::MAU::PfeLocation::DEFAULT;
    IR::MAU::TypeLocation type_loc = IR::MAU::TypeLocation::DEFAULT;

    if (!aac.all_per_flow_enabled)
        pfe_loc = IR::MAU::PfeLocation::OVERHEAD;
    if (!aac.all_same_meter_type)
        type_loc = IR::MAU::TypeLocation::OVERHEAD;

    if (at_mem->direct) {
        ba->addr_location = IR::MAU::AddrLocation::DIRECT;
    } else if (ba->hash_dist != nullptr) {
        ba->addr_location = IR::MAU::AddrLocation::HASH;
    } else if (!(ba->use == IR::MAU::StatefulUse::NO_USE ||
                 ba->use == IR::MAU::StatefulUse::DIRECT ||
                 ba->use == IR::MAU::StatefulUse::INDIRECT)) {
        ba->addr_location = IR::MAU::AddrLocation::STFUL_COUNTER;
    } else {
        ba->addr_location = IR::MAU::AddrLocation::OVERHEAD;
    }

    ba->pfe_location = pfe_loc;
    if (at_mem->is<IR::MAU::StatefulAlu>() || at_mem->is<IR::MAU::Meter>())
        ba->type_location = type_loc;
    return false;
}

/**
 * By the time this pass is run, all relevant information about the different stateful
 * calls has been moved to other parts of the IR.
 *
 * The primitive, however, will potentially keep information around that could potentially
 * be erroneously used by PHV, i.e. temporary variables that were converted to hash
 * distribution IR nodes.  In order to not have PHV allocation make space for these Temporary
 * variables, these primitives must be discarded.
 *
 * If other information is potentially relevant, it must be saved in other IR nodes
 * before this pass
 */
bool NullifyAllStatefulCallPrim::preorder(IR::MAU::StatefulCall *sc) {
    sc->prim = nullptr;
    return false;
}


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
    PHV::FieldSlice fs(field, bits);
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
    PHV::FieldSlice fs(field, bits);
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
InstructionSelection::InstructionSelection(const BFN_Options& options, PhvInfo &phv) : PassManager {
    new ValidateInvalidatePrimitive(phv),
    new UnimplementedRegisterMethodCalls,
    new Synth2PortSetup(phv),
    new DoInstructionSelection(options, phv),
    new ConvertCastToSlice,
    new StatefulAttachmentSetup(phv),
    new MeterSetup(phv),
    // new DLeftSetup,
    new SetupAttachedAddressing,
    new NullifyAllStatefulCallPrim,
    new CollectPhvInfo(phv),
    new BackendCopyPropagation(phv),
    new VerifyParallelWritesAndReads(phv),
    new EliminateAllButLastWrite(phv),
    new CollectPhvInfo(phv),
    new PHV::ValidateActions(phv, false, false, false)
} {}
