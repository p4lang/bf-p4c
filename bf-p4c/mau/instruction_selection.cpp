#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/mau/static_entries_const_prop.h"
#include "ir/pattern.h"
#include "lib/bitops.h"
#include "lib/safe_vector.h"
#include "action_analysis.h"
#include "ixbar_expr.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/ir_utils.h"
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

bool HashGenSetup::CreateHashGenExprs::preorder(const IR::BFN::SignExtend *se) {
    if (!findContext<IR::MAU::Action>())
        return false;
    if (CanBeIXBarExpr(se)) {
        auto hge = new IR::MAU::HashGenExpression(se->srcInfo, se->type, se,
                                                  IR::MAU::HashFunction::identity());
        self.hash_gen_injections[se] = hge;
        return false;
    }
    return true;
}

bool HashGenSetup::CreateHashGenExprs::preorder(const IR::Concat *c) {
    if (!findContext<IR::MAU::Action>())
        return false;
    if (auto k = c->left->to<IR::Constant>()) {
        if (k->value == 0) {
            // HACK -- avoid dealing with 0-prefix concats (zero extension) as the midend
            // now changes zero-extend casts into them, and trying to do them in the hash
            // breaks more things than it fixes
            return true; } }
    if (CanBeIXBarExpr(c)) {
        auto hge = new IR::MAU::HashGenExpression(c->srcInfo, c->type, c,
                                                  IR::MAU::HashFunction::identity());
        self.hash_gen_injections[c] = hge;
    }
    return c;
}


void HashGenSetup::CreateHashGenExprs::check_for_symmetric(const IR::Declaration_Instance *decl,
        const IR::ListExpression *le, IR::MAU::HashFunction hf, LTBitMatrix *sym_keys) {
    auto gress = findContext<IR::MAU::Table>()->gress;
    safe_vector<const IR::Expression *> field_list;
    for (auto expr : le->components) {
        field_list.push_back(expr);
    }
    VerifySymmetricHashPairs(self.phv, field_list, decl->annotations, gress, hf, sym_keys);
}

/**
 * The Hash.get function has different IR for P4-14 and P4-16.  This function converts all
 * of these to HashGenExpression, which currently is language dependent, as there is currently
 * no unified way of handling all of the expressivity of Hash in the p4-16 language yet through
 * our externs
 *
 * Any function that uses the Hash.get call is by definition a dynamic hash.  The rules are:
 *
 * 1.  All Hash.get come from an original Hash extern, which has a name.  (In p4-14, instead of
 *     using this compiler generated name, we use the field_list_calculation name)
 * 2.  Any Hash.get from the same Hash extern must have the same input field list, and
 *     currently only one field list, as this is the list that can be associated
 * 3.  P4-14 can allow only certain algorithms, the one that come through names, p4-16 can allow
 *     any hash algorithm necessary.  Everything is rotateable and permutable.
 */
bool HashGenSetup::CreateHashGenExprs::preorder(const IR::Primitive *prim) {
    if (prim->name != "Hash.get")
        return true;

    cstring hash_name;
    IR::MAU::HashGenExpression *hge = nullptr;
    IR::MAU::FieldListExpression *fle = nullptr;
    IR::MAU::HashFunction algorithm;

    auto it = prim->operands.begin();
    // operand 0 is always the extern itself.
    BUG_CHECK(it != prim->operands.end(), "primitive %s does not have a reference to P4 extern",
              prim->name);
    auto glob = (*it)->to<IR::GlobalRef>();
    auto decl = glob->obj->to<IR::Declaration_Instance>();
    auto *orig_type = decl->type->to<IR::Type_Specialized>()->arguments->at(0);
    int hash_output_width = orig_type->width_bits();
    int bit_size = hash_output_width;

    if (self.options.langVersion == CompilerOptions::FrontendVersion::P4_14) {
    } else {
        hash_name = decl->controlPlaneName();
    }

    bool custom_hash = false;
    std::advance(it, 1);
    auto crc_poly = (*it)->to<IR::GlobalRef>();
    if (crc_poly) {
        custom_hash = true;
        if (!algorithm.convertPolynomialExtern(crc_poly))
            BUG("invalid hash algorithm %s", decl->arguments->at(1));
        std::advance(it, 1);
    }

    // otherwise, if not a custom hash from user, it is one of the hashes built into compiler.
    if (!custom_hash && !algorithm.setup(decl->arguments->at(0)->expression))
        BUG("invalid hash algorithm %s", decl->arguments->at(0));

    int remaining_op_size = std::distance(it, prim->operands.end());

    auto orig_hash_list = *it;
    if (remaining_op_size > 1) {
        auto base = std::next(it, 1);
        if (auto *constant = (*base)->to<IR::Constant>()) {
            if (constant->asInt() != 0)
                error("%1%: The initial offset for a hash calculation function has to be zero "
                      "instead of %2%", prim, constant);
        }
        auto max = std::next(it, 2);
        if (auto *constant = (*max)->to<IR::Constant>()) {
            auto value = constant->asUint64();
            if (value != 0) {
                bit_size = bitcount(value - 1);
                if ((1ULL << bit_size) != value)
                    error("%1%: The hash offset must be a power of 2 in a hash calculation "
                          "instead of %2%", prim, value);
            }
        }
    }

    const IR::NameList *alg_names = nullptr;
    if (self.options.langVersion == CompilerOptions::FrontendVersion::P4_14) {
        auto hle = orig_hash_list->to<IR::HashListExpression>();
        BUG_CHECK(hle != nullptr, "Hash not converted correctly in the midend");
        IR::ID fl_id(hle->fieldListNames->names[0]);
        fle = new IR::MAU::FieldListExpression(hle->srcInfo, hle->components, fl_id);
        hash_name = hle->fieldListCalcName;
        hash_output_width = hle->outputWidth;
        alg_names = hle->algorithms;
    } else {
        const IR::ListExpression *le = orig_hash_list->to<IR::ListExpression>();
        if (le == nullptr) {
            if (orig_hash_list->is<IR::Expression>()) {
                IR::Vector<IR::Expression> le_vec;
                le_vec.push_back(orig_hash_list);
                le = new IR::ListExpression(orig_hash_list->srcInfo, le_vec);
            }
        }
        BUG_CHECK(le != nullptr, "Hash.get calls must have a valid input or list of inputs");
        IR::ID fl_id("$field_list_1");
        fle = new IR::MAU::FieldListExpression(le->srcInfo, le->components, fl_id);
        fle->rotateable = true;
        fle->permutable = true;
        // Arbitrary name, added previously, not to break APIs.  Happy to change
        hash_name += ".$CONFIGURE";
    }

    check_for_symmetric(decl, fle, algorithm, &fle->symmetric_keys);
    auto *type = IR::Type::Bits::get(bit_size);
    hge = new IR::MAU::HashGenExpression(prim->srcInfo, type, fle, IR::ID(hash_name), algorithm);
    // Symmetric is not supported with bf-utils dynamic hash library
    hge->dynamic = fle->symmetric_keys.empty();
    hge->any_alg_allowed = self.options.langVersion == CompilerOptions::FrontendVersion::P4_16;
    hge->hash_output_width = hash_output_width;
    hge->alg_names = alg_names;
    self.hash_gen_injections[prim] = hge;
    return false;
}

bool HashGenSetup::ScanHashDists::preorder(const IR::Expression *expr) {
    if (self.hash_gen_injections.count(expr) == 0)
        return true;
    auto context = getContext();
    const IR::Node *curr_node = expr;
    while (context->node->is<IR::Slice>() || context->node->is<IR::Cast>()) {
        curr_node = context->node;
        context = context->parent;
    }

    auto highest_expr = curr_node->to<IR::Expression>();
    self.hash_dist_injections.insert(highest_expr);
    return false;
}

/**
 * Must introduce the instruction, in case someone writes the following:
 *
 *     action a {
 *         hash.get(blah);
 *     }
 *
 * as converting this to a HashGenExpression by itself will fail the Action check that
 * all base statements in the action are Primitives or their subclass.
 */
const IR::Expression *HashGenSetup::UpdateHashDists::postorder(IR::Expression *e) {
    auto rv = e;
    auto origExpr = getOriginal()->to<IR::Expression>();
    auto hgi = self.hash_gen_injections.find(origExpr);
    if (hgi != self.hash_gen_injections.end()) {
        rv = hgi->second;
    }

    auto hdi = self.hash_dist_injections.find(origExpr);
    if (hdi != self.hash_dist_injections.end()) {
        auto tv = new IR::TempVar(e->type);
        auto hd2 = new IR::MAU::HashDist(rv->srcInfo, rv->type, rv);
        auto inst = new IR::MAU::Instruction(e->srcInfo, "set", tv, hd2);
        rv = inst;
    }
    return rv;
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
    const char *tail = objType.c_str() + objType.size();
    while (tail > objType && std::isdigit(tail[-1])) --tail;
    objType = objType.before(tail);
    IR::Node *rv = prim;

    const IR::GlobalRef *glob = nullptr;

    IR::MAU::MeterType meter_type = IR::MAU::MeterType::UNUSED;

    cstring method = dot ? cstring(dot+1) : prim->name;
    if (objType.endsWith("Action") || objType == "SelectorAction") {
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
        auto *salu_inst = salu->calledAction(tbl, act);
        auto salu_index = salu_inst->inst_code;
        if (salu_index < 0) {
            // FIXME -- should be allocating/setting this
            auto pos = salu->instruction.find(salu_inst->name);
            salu_index = std::distance(salu->instruction.begin(), pos); }
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
                    "memory in %s", prim->srcInfo, salu_inst, salu->name);
        }

        // needed to setup the index and/or type properly
        stateful.push_back(prim);

        if (objType == "RegisterAction" && salu->direct != direct_access)
            error("%s: %sdirect access to %sdirect register", prim->srcInfo,
                  direct_access ? "" : "in", salu->direct ? "" : "in");

        int output_offsets[] = { 0, 64, 32, 96 };
        auto makeInstr = [&](const IR::Expression *dest, int output) -> IR::MAU::Instruction * {
            BUG_CHECK(size_t(output) < sizeof(output_offsets)/sizeof(output_offsets[0]),
                      "too many outputs");
            int bit = output_offsets[output];
            int output_size = prim->type->width_bits();
            if ((salu_inst->return_predicate_words >> output) & 1) {
                // an output enum encoded in the 16-bit predicate
                BUG_CHECK(salu->pred_shift >= 0, "Not outputting predicate even though "
                          "its being used");
                bit += 4 + salu->pred_shift;
                output_size = 1 << Device::statefulAluSpec().CmpUnits.size(); }
            auto ao = new IR::MAU::AttachedOutput(IR::Type::Bits::get(bit+output_size), salu);
            output_size = std::min(dest->type->width_bits(), output_size);
            return new IR::MAU::Instruction(prim->srcInfo, "set", dest,
                                            MakeSlice(ao, bit, bit+output_size - 1));
        };

        unsigned idx = (method == "execute" && !direct_access) ? 2 : 1;
        for (int output = 1; idx < prim->operands.size(); ++idx, ++output) {
            // Have to put these instructions at the highest level of the instruction
            created_instrs.push_back(makeInstr(prim->operands[idx], output)); }
        rv = nullptr;
        if (!prim->type->is<IR::Type::Void>())
            rv = makeInstr(new IR::TempVar(prim->type), 0);
    } else if (prim->name == "Register.clear" || prim->name == "DirectRegister.clear") {
        glob = prim->operands.at(0)->to<IR::GlobalRef>();
        meter_type = IR::MAU::MeterType::STFUL_CLEAR;
        stateful.push_back(prim);  // needed to setup clear/busy values
        rv = nullptr;
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
    if (auto *c = e->to<IR::BFN::ReinterpretCast>())
        return checkPHV(c->expr);
    return phv.field(e);
}

bool DoInstructionSelection::checkActionBus(const IR::Expression *e) {
    if (auto *c = e->to<IR::BFN::ReinterpretCast>())
        return checkActionBus(c->expr);
    if (auto *c = e->to<IR::BFN::SignExtend>())
        return checkActionBus(c->expr);
    if (auto slice = e->to<IR::Slice>())
        return checkActionBus(slice->e0);
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
    return false;
}

bool DoInstructionSelection::checkSrc1(const IR::Expression *e) {
    LOG3("Checking src1 : " << e);
    if (auto *c = e->to<IR::BFN::ReinterpretCast>())
        return checkSrc1(c->expr);
    if (auto *c = e->to<IR::BFN::SignExtend>())
        return checkSrc1(c->expr);
    if (auto slice = e->to<IR::Slice>())
        return checkSrc1(slice->e0);
    if (checkActionBus(e))
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
    if (auto ca = a->to<IR::BFN::ReinterpretCast>()) {
        auto cb = b->to<IR::BFN::ReinterpretCast>();
        return ca->type == cb->type && equiv(ca->expr, cb->expr);
    }
    return false;
}

void DoInstructionSelection::limitWidth(const IR::Expression *e) {
    // P4C-2694
    // Verify that the operation width is less than the maximum container width.
    // Required for instructions that can't be split without rewriting the
    // instruction.
    auto bits = e->type->to<IR::Type_Bits>();
    unsigned short max_size = static_cast<unsigned short>(
            *Device::phvSpec().containerSizes().rbegin());
    if (bits && bits->width_bits() > max_size) {
        ::error(ErrorType::ERR_OVERLIMIT,
                "%1%: Saturating arithmetic operators may not exceed "
                "maximum PHV container width (%2%b)",
                e->srcInfo, max_size);
    }
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
    if (auto *fold = ::clone(e->expr->to<IR::MAU::Instruction>())) {
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
    /// HACK(hanw): I had to put in this hack to get p4-14 switch.p4 to compile after removing the
    /// cast, we need a follow-up PR to add the support for '++' operator in the backen.
    auto operand = e->right;
    if (auto concat = e->right->to<IR::Concat>()) {
        if (concat->left->is<IR::Constant>()) {
            operand = concat->right; } }
    return new IR::MAU::Instruction(e->srcInfo, "add", new IR::TempVar(e->type), e->left, operand);
}

const IR::Expression *DoInstructionSelection::postorder(IR::AddSat *e) {
    if (!af) return e;
    auto opName = "saddu";
    if (e->type->is<IR::Type_Bits>() && e->type->to<IR::Type_Bits>()->isSigned)
        opName = "sadds";
    limitWidth(e);
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
    limitWidth(e);

    // P4C-1819
    // Compiler generates an invalid instruction here for saturated unsigned
    // subtract with a constant value as src2 which is unsupported in
    // Tofino/JBAY.
    // P4:   hdr.ipv4.ttl = hdr.ipv4.ttl |-| 1;
    // BFA:  - ssubu hdr.ipv4.ttl, hdr.ipv4.ttl, 1
    //
    // Soln : Rewrite P4 by initializing the "1" through a field which makes it
    // a PHV which is supported as src2
    //
    // Unsupported alternate solutions:
    // 1. Use the ADD instruction: src1 (immediate -1) + src2 (unsigned PHV field)
    //    and then detect underflow from 0 to 255 in a subsequent stage and map back to 0.
    // 2. Instead of using an additional stage, use a table in this stage to detect TTL
    //    value of 0 to conditionally execute the subtract or not
    // Both these solutions require program transformations
    if (bits && !bits->isSigned && eRight->to<IR::Constant>()) {
        error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%1%"
            "A saturated unsigned subtract (ssubu) cannot have the second operand "
            "(value to be subtracted) as a constant value.  "
            "Try rewriting the relevant P4 by initializing the constant value "
            "to be subtracted within a field.", e->srcInfo);
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

const IR::Expression *DoInstructionSelection::preorder(IR::BFN::SignExtend *c) {
    if (CanBeIXBarExpr(c))
        BUG("%s: Hash Dist object on concat %s not correctly converted", c->srcInfo, c->toString());
    return c;
}

const IR::Expression *DoInstructionSelection::preorder(IR::Concat *c) {
    if (auto k = c->left->to<IR::Constant>()) {
        if (k->value == 0) {
            // HACK -- avoid dealing with 0-prefix concats (zero extension) as the midend
            // now changes zero-extend casts into them, and trying to do them in the hash
            // breaks more things than it fixes
            return c; } }
    if (CanBeIXBarExpr(c))
        BUG("%s: Hash Dist object on concat %s not correctly converted", c->srcInfo, c->toString());
    return c;
}

static const IR::MAU::Instruction *fillInstDest(const IR::Expression *in,
                                                const IR::Expression *dest, int lo = -1,
                                                int hi = -1, bool cast = false) {
    if (auto *c = in->to<IR::BFN::ReinterpretCast>())
        // perhaps everything underneath should be cast to the same size
        return fillInstDest(c->expr, dest, c->destType->width_bits(), -1, true);
    if (auto *sl = in->to<IR::Slice>())
        return fillInstDest(sl->e0, dest, sl->getL(), sl->getH());
    if (auto *c = in->to<IR::BFN::SignExtend>())
        return fillInstDest(c->expr, dest, c->destType->width_bits(), -1);
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
                continue;
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
            error(ErrorType::ERR_INVALID, "wrong number of operands to %1%", prim);
        } else if (!phv.field(dest)) {
            error(ErrorType::ERR_INVALID, "destination of %1% must be a field", prim);
        } else if (auto *rv = fillInstDest(prim->operands[1], dest)) {
            return rv;
        } else if (!checkSrc1(prim->operands[1])) {
            /**
             * Converting ternary operands into conditionally-set format:
             *
             *     conditionally-set destination, (optional background), source, conditional arg
             *
             * In examples:
             *     f1 = cond ? arg1 : f1 -> conditionally-set f1, arg1, cond1 (implicit background)
             *
             *     f1 = cond ? arg1 : f2 -> conditionally-set f1, f2, arg1, cond1
             */
            if (auto mux = prim->operands[1]->to<IR::Mux>()) {
                auto type = prim->operands[0]->type->to<IR::Type::Bits>();
                auto arg = mux->e0->to<IR::MAU::ActionArg>();
                if (!arg) {
                    error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%1%\nConditions in an action must "
                          "be simple comparisons of an action data parameter\nTry moving the test "
                          "out of the action and into a control apply block, or making it part "
                          "of the table key", prim->srcInfo);
                    return prim; }
                cstring cond_arg_name = "$cond_arg" + std::to_string(synth_arg_num++);
                auto cond_arg = new IR::MAU::ConditionalArg(mux->e0->srcInfo, type, af->name,
                                                            cond_arg_name, arg);
                cstring instr_name = "conditionally-set";
                IR::MAU::Instruction *rv = nullptr;
                if (equiv(prim->operands[0], mux->e2) && checkActionBus(mux->e1)) {
                    rv = new IR::MAU::Instruction(prim->srcInfo, instr_name,
                             { prim->operands[0], mux->e1, cond_arg });
                } else if (equiv(prim->operands[0], mux->e1) && checkActionBus(mux->e2)) {
                    cond_arg->one_on_true = false;
                    rv = new IR::MAU::Instruction(prim->srcInfo, instr_name,
                            { prim->operands[0], mux->e2, cond_arg });
                    error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%1%\nConditional assignment must "
                          "be reversed, as the non PHV parameter must be on the true branch for "
                          "support in the driver", prim->srcInfo);
                } else if (checkActionBus(mux->e1) && checkPHV(mux->e2)) {
                    rv = new IR::MAU::Instruction(prim->srcInfo, instr_name,
                            { prim->operands[0], mux->e2, mux->e1, cond_arg });
                } else if (checkActionBus(mux->e2) && checkPHV(mux->e1)) {
                    cond_arg->one_on_true = false;
                    rv = new IR::MAU::Instruction(prim->srcInfo, instr_name,
                            { prim->operands[0], mux->e1, mux->e2, cond_arg });
                    error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%1%\nConditional assignment must "
                          "be reversed, as the non PHV parameter must be on the true branch for "
                          "support in the driver", prim->srcInfo);
                } else {
                    error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%1%\nConditional assignment is "
                          "too complicated to support in a single operation\nTry moving the test "
                          "out of the action and into a control apply block, or making it part "
                          "of the table key", prim->srcInfo); }
                return rv;
            } else {
                error("%s: source of %s invalid", prim->srcInfo, prim->name);
            }
        } else if (prim->operands.size() == 2) {
            return new IR::MAU::Instruction(prim->srcInfo, "set", &prim->operands);
        } else if (!checkConst(prim->operands[2], mask)) {
            error(ErrorType::ERR_INVALID, "mask of %1% must be a constant", prim);
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

    if (prim->name == "Hash.get") {
        BUG("%s: Should have already converted %s in previous pass", prim->srcInfo,
            prim->toString());
    } else if (prim->name == "Random.get") {
        auto glob = prim->operands[0]->to<IR::GlobalRef>();
        auto decl = glob->obj->to<IR::Declaration_Instance>();
        auto rn = new IR::MAU::RandomNumber(prim->srcInfo, prim->type, decl->name);
        auto next_type = prim->type;
        return new IR::MAU::Instruction(prim->srcInfo, "set", new IR::TempVar(next_type), rn);
    } else if (prim->name == "invalidate") {
        return new IR::MAU::Instruction(prim->srcInfo, "invalidate", prim->operands[0]);
    } else if (prim->name == "min" || prim->name == "max") {
        if (prim->operands.size() != 2) {
            error(ErrorType::ERR_INVALID, "wrong number of operands to %1%", prim);
        } else if (!prim->type->is<IR::Type::Bits>()) {
            error(ErrorType::ERR_INVALID, "non-numeric operrands to %1%", prim);
        } else {
            cstring op = prim->name;
            op += prim->type->to<IR::Type::Bits>()->isSigned ? 's' : 'u';
            return new IR::MAU::Instruction(prim->srcInfo, op, new IR::TempVar(prim->type),
                                            prim->operands.at(0), prim->operands.at(1)); }
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
    if (auto a = strstr(prim->name, "Action")) {
        if (a[6] == '.' || (std::isdigit(a[6]) && a[7] == '.'))
            return IR::Type_Register::get(); }
    if (prim->name == "Register.clear" || prim->name == "DirectRegister.clear")
        return IR::Type_Register::get();
    BUG("Not a stateful primitive %s", prim);
}

static ssize_t index_operand(const IR::Primitive *prim) {
    if (prim->name.startsWith("Direct") || prim->name.endsWith(".clear"))
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
            if (auto *c = prim->operands[1]->to<IR::BFN::ReinterpretCast>()) {
                if (auto tv = c->expr->to<IR::TempVar>())
                    self.remove_tempvars.insert(tv->name);
            }
            if (auto *cc = prim->operands[1]->to<IR::Concat>()) {
                std::vector<const IR::Expression *> possible_vars;
                simpl_concat(possible_vars, cc);
                for (auto expr : possible_vars) {
                    auto tv = expr->to<IR::TempVar>();
                    if (tv)
                        self.remove_tempvars.insert(tv->name);
                }
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
    cstring method = dot ? cstring(dot+1) : prim->name;
    while (dot && dot > prim->name && std::isdigit(dot[-1])) --dot;
    auto objType = dot ? prim->name.before(dot) : cstring();
    if (objType.endsWith("Action")) {
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
    } else if (method == "clear") {
        obj = prim->operands.at(0)->to<IR::GlobalRef>()->obj->to<IR::MAU::StatefulAlu>();
        BUG_CHECK(obj, "invalid object");
        use = IR::MAU::StatefulUse::FAST_CLEAR;
        bitvec clear_value;
        uint32_t busy_value = 0;
        if (prim->operands.size() > 1) {
            auto *v = prim->operands.at(1)->to<IR::Constant>();
            if (!v) {
                error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "clear value %1% must be a constant",
                      prim->operands.at(1));
            } else {
                clear_value.putrange(0, 64, static_cast<uint64_t>(v->value));
                clear_value.putrange(64, 64,
                    static_cast<uint64_t>(static_cast<big_int>(v->value >> 64))); } }
        if (prim->operands.size() > 2) {
            auto *v = prim->operands.at(2)->to<IR::Constant>();
            if (!v) {
                error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "busy value %1% must be a constant",
                      prim->operands.at(2));
            } else {
                busy_value = v->asUnsigned(); } }
        auto &info = self.table_clears[findContext<IR::MAU::Table>()];
        if (info) {
            if (obj != info->attached)
                error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "Clearing %1% and %2% in one table",
                      info->attached, obj);
            if (info->clear_value != clear_value || info->busy_value != busy_value)
                error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "Inconsistent clear arguments in %1%",
                      prim);
        } else {
            info = &self.salu_clears[obj];
            if (info->attached) {
                if (info->clear_value != clear_value || info->busy_value != busy_value)
                    error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "Inconsistent clear arguments "
                          "for %1%", info->attached); }
            info->attached = obj; }
        info->clear_value = clear_value;
        info->busy_value = busy_value;
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
    if (auto c = expr->to<IR::BFN::ReinterpretCast>())
        hash_field = c->expr;

    int size = hash_field->type->width_bits();
    auto *hge = new IR::MAU::HashGenExpression(prim->srcInfo, IR::Type::Bits::get(size),
                        hash_field, IR::MAU::HashFunction::identity());

    auto *hd = new IR::MAU::HashDist(hge->srcInfo, hge->type, hge);
    return hd;
}

/**
 * Find or generate a Hash Distribution unit, given what IR::Node is in the primitive
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
 * Simplify concatenation expression for index operand.
 * Current limitation:
 * - only one sub-expression in concatenation expression can be a field.
 * - other sub-expression must be constant.
 */
void StatefulAttachmentSetup::Scan::simpl_concat(std::vector<const IR::Expression*>& slices,
        const IR::Concat* expr) {
    if (expr->left->is<IR::Constant>()) {
        // ignore
    } else if (auto lhs = expr->left->to<IR::Concat>()) {
        simpl_concat(slices, lhs);
    } else {
        slices.push_back(expr->left); }
    if (expr->right->is<IR::Constant>()) {
        // ignore
    } else if (auto rhs = expr->right->to<IR::Concat>()) {
        simpl_concat(slices, rhs);
    } else {
        slices.push_back(expr->right); }
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
    const IR::Expression* simpl_expr = nullptr;
    std::vector<const IR::Expression*> expressions;
    if (index_expr->is<IR::Concat>()) {
        simpl_concat(expressions, index_expr->to<IR::Concat>());

        if (expressions.size() == 1) {
            simpl_expr = expressions.at(0);
        } else {
            ::error("Complex expression is not yet supported: %1%", index_expr);
        }
    } else {
        simpl_expr = index_expr;
        if (auto sl = index_expr->to<IR::Slice>()) {
            // corner case -- action arg used both for index and elsewhere in P4_14 which
            // is inferred as larger than the index size (due to the other use).  We end up
            // with a slice on the index which we want to ignore.
            if (sl->e0->is<IR::MAU::ActionArg>() && sl->getL() == 0 &&
                (2 << sl->getH()) >= synth2port->size) {
                simpl_expr = sl->e0; } }
    }

    bool both_hash_and_index = false;
    auto index_check = std::make_pair(synth2port, tbl);

    if (auto hd = self.find_hash_dist(simpl_expr, call->prim)) {
        HashDistKey hdk = std::make_pair(synth2port, tbl);
        if (self.update_hd.count(hdk)) {
            auto hd_comp = self.update_hd.at(hdk);
            BuildP4HashFunction builder(self.phv);
            hd->apply(builder);
            P4HashFunction *a_func = builder.func();
            hd_comp->apply(builder);
            P4HashFunction *b_func = builder.func();
            if (!a_func->equiv(b_func)) {
                error("%s: Incompatible attached indexing between actions in table %s",
                      call->prim->srcInfo, tbl->name);
            }
        }
        self.update_hd[hdk] = hd;
        simpl_expr = hd;
        if (self.addressed_by_index.count(index_check))
            both_hash_and_index = true;
        self.addressed_by_hash.insert(index_check);
    } else if (!simpl_expr->is<IR::Constant>() && !simpl_expr->is<IR::MAU::ActionArg>()) {
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
    self.update_calls[sck] = simpl_expr;
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
    return ba;
}

const IR::MAU::StatefulAlu *StatefulAttachmentSetup::Update::preorder(IR::MAU::StatefulAlu *salu) {
    auto *orig = getOriginal<IR::MAU::StatefulAlu>();
    if (self.salu_clears.count(orig)) {
        auto &info = self.salu_clears.at(orig);
        salu->clear_value = info.clear_value;
        // truncate the value to width bits, then replicate back to 128 bits
        salu->clear_value.clrrange(salu->width, ~0);
        for (size_t w = salu->width; w < 128; w = w*2)
            salu->clear_value |= salu->clear_value << w;
        salu->busy_value = info.busy_value; }
    prune();
    return salu;
}

const IR::MAU::Instruction *StatefulAttachmentSetup::Update::preorder(IR::MAU::Instruction *inst) {
    if (self.remove_instr.count(getOriginal())) return nullptr;
    return inst;
}

bool MeterSetup::Scan::preorder(const IR::MAU::Instruction *) {
    return false;
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
    if (!field)
        error("%1%: Not a phv field in the lpf execute: %2%", prim->srcInfo, input);

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
    // pre_color = convert_cast_to_slice(pre_color);
    auto *field = self.phv.field(pre_color);
    if (!field) {
        // The pre-color must come from phv.
        error(ErrorType::ERR_UNEXPECTED, "The pre-color must come from phv. Please have a separate"
              " table that writes the precolor to meter metadata in an earlier stage. It makes "
              "sure that the precolor comes from PHV.");
        return;
    }

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
        auto hge = new IR::MAU::HashGenExpression(pre_color->srcInfo, IR::Type::Bits::get(2),
                           pre_color, IR::MAU::HashFunction::identity());
        auto hd = new IR::MAU::HashDist(hge->srcInfo, hge->type, hge);
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

struct CheckInvalidate : public Inspector {
    explicit CheckInvalidate(const PhvInfo& phv) : phv(phv) { }

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
            if (!f->is_invalidate_from_arch()) {
                error("%s: invalid operand %s for primitive %s", prim->srcInfo, f->name, prim);
            }
        }
    }

    const PhvInfo& phv;
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
    // In order to maintain the sequential property, the reads have to be visited before the writes
    for (ssize_t i = instr->operands.size() - 1; i >= 0; i--) {
        elem_copy_propagated = false;
        visit(instr->operands[i], "operands", i);
        instr->copy_propagated[i] = elem_copy_propagated; }
    prune();
    return instr;
}
/** Mark instr->operands[1] as the most recent replacement for instr->operands[0] when @inst
  * is a set instruction.  Otherwise, remove instr->operands[0] from the set of copy propagation
  * candidates.
  */
void BackendCopyPropagation::update(const IR::MAU::Instruction *instr, const IR::Expression *e) {
    if (findContext<IR::MAU::SaluAction>()) {
        // don't propagate within or out of SALU actions
        return; }
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
        LOG5("BackendCopyProp: saving " << instr->operands[0] << " = " << instr->operands[1]);
        copy_propagation_replacements[field].emplace_back(bits, instr->operands[1]);
    }
}

/** @returns the copy propagation candidate for @e if @e can be replaced (setting
  * @elem_copy_propagated to true), or @e if @e cannot be replaced (setting @elem_copy_propagated
  * to false).
  */
const IR::Expression *BackendCopyPropagation::propagate(const IR::MAU::Instruction *instr,
    const IR::Expression *e) {
    auto act = findContext<IR::MAU::Action>();
    if (act == nullptr) {
        prune();
        return e;
    }

    le_bitrange bits = { 0, 0 };
    auto field = phv.field(e, &bits);
    if (field == nullptr) {
        return e;
    }
    bool isSalu = findContext<IR::MAU::SaluAction>() != nullptr;

    prune();
    // If a read is possibly replaced with a copy propagated value, replace this value
    for (auto replacement : copy_propagation_replacements[field]) {
        if (isSalu && replacement.read->is<IR::MAU::ActionArg>()) {
            // can't access action args in the SALU
            continue; }
        if (replacement.dest_bits.contains(bits)) {
            elem_copy_propagated = true;
            auto rv = MakeSlice(replacement.read, bits.lo, bits.hi);
            if (isSalu && replacement.read->is<IR::MAU::HashDist>()) {
                // FIXME -- SALU uses hash directly, not via hash dist; need refactoring
                // of IXBarExpression/HashGenExpression to make this more sane
                auto *hd = replacement.read->to<IR::MAU::HashDist>();
                rv = MakeSlice(hd->expr, bits.lo, bits.hi);
                rv = new IR::MAU::IXBarExpression(rv); }
            LOG4("BackendCopyProp: " << e << " -> " << rv);
            return rv;
        } else if (!replacement.dest_bits.intersectWith(bits).empty()) {
           ::error("%s: Currently the field %s[%d:%d] in action %s is read in a way "
                   "too complex for the compiler to currently handle.  Please consider "
                   "simplifying this action around this parameter", instr->srcInfo,
                   field->name, bits.hi, bits.lo, act->name);
        }
    }

    return e;
}

const IR::Expression *BackendCopyPropagation::preorder(IR::Expression *expr) {
    auto instr = findContext<IR::MAU::Instruction>();
    if (!instr) {
        prune();
    } else if (isWrite()) {
        prune();
        update(instr, expr);
    } else {
        return propagate(instr, expr);
    }
    return expr;
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
void VerifyParallelWritesAndReads::postorder(const IR::MAU::Instruction *instr) {
    auto act = findContext<IR::MAU::Action>();
    for (ssize_t i = instr->operands.size() -1; i >= 0; i--) {
        // Skip copy propagated values
        if (instr->copy_propagated[i])
            continue;
        if (!is_parallel(instr->operands[i], instr->isOutput(i))) {
            le_bitrange bits = {0, 0};
            auto field = phv.field(instr->operands[i], &bits);
            ::error(ErrorType::ERR_UNSUPPORTED,
                    "%1%: action spanning multiple stages. "
                    "Operations on operand %3% (%4%[%5%..%6%]) in action %2% require multiple "
                    "stages for a single action. We currently support only single stage actions. "
                    "Please consider rewriting the action to be a single stage action.",
                    instr, act, (i+1), field->name, bits.lo, bits.hi);
        }
    }
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

/**
 * modify_field_with_hash_based_offset is not yet converted correctly in the converters,
 * as the slicing operation portion, i.e. the max size of the instruction is not correct.
 *
 * This leads to mismatched sizes in HashDist Instructions, which used to be done by
 * ConvertCastToSlice, though that pass no longer exists.  In order for ActionAnalysis
 * to function on hash dist parameters, all operands in hash based instructions must
 * be the same size.  This pass guarantees this.
 */
bool GuaranteeHashDistSize::Scan::preorder(const IR::MAU::Instruction *) {
    contains_hash_dist = false;
    return true;
}

bool GuaranteeHashDistSize::Scan::preorder(const IR::MAU::HashDist *) {
    contains_hash_dist = true;
    return false;
}

void GuaranteeHashDistSize::Scan::postorder(const IR::MAU::Instruction *instr) {
    if (!contains_hash_dist)
        return;

    bool size_set = false;
    bool all_same_size = true;
    int size = 0;
    for (auto op : instr->operands) {
        if (!size_set) {
            size = op->type->width_bits();
            size_set = true;
        } else {
            int check_size = op->type->width_bits();
            if (check_size != size)
                all_same_size = false;
        }
    }

    if (all_same_size)
        return;

    if (instr->name != "set")
        ::error("%1%: Currently cannot handle a non-assignment hash function in an action "
                "where the hash size is not the same size as the write operand", instr);
    else
        self.hash_dist_instrs.insert(instr);
}

const IR::Node *GuaranteeHashDistSize::Update::postorder(IR::MAU::Instruction *instr) {
    auto orig_instr = getOriginal()->to<IR::MAU::Instruction>();
    if (self.hash_dist_instrs.count(orig_instr) == 0)
        return instr;

    BUG_CHECK(instr->name == "set", "Incorrectly adjusting a non-set hash instruction");

    auto *rv_vec = new IR::Vector<IR::Node>();
    auto write = instr->operands[0];
    auto read = instr->operands[1];

    int write_size = write->type->width_bits();
    int read_size = read->type->width_bits();

    if (write_size > read_size) {
        rv_vec->push_back(new IR::MAU::Instruction(instr->srcInfo, instr->name,
                              MakeSlice(write, 0, read_size - 1), read));
        auto zero = new IR::Constant(IR::Type::Bits::get(write_size - read_size), 0);
        rv_vec->push_back(new IR::MAU::Instruction(instr->srcInfo, instr->name,
                              MakeSlice(write, read_size, write_size -1), zero));
    } else if (write->type->width_bits() < read->type->width_bits()) {
        rv_vec->push_back(new IR::MAU::Instruction(instr->srcInfo, instr->name, write,
                                                   MakeSlice(read, 0, write_size)));
    } else {
        BUG("Incorrectly adjusting a non-set hash instruction");
    }
    return rv_vec;
}

/**
 * Remove a slice of an ActionArg in an instruction, if the argument was the same size
 * as the slice.  The naming in the assembly output assumes that a slice will only happen
 * when the portion of the argument is not the full width of the argument.
 *
 * This was to deal with issue583.p4
 */
const IR::Node *RemoveUnnecessaryActionArgSlice::preorder(IR::Slice *sl) {
    if (!findContext<IR::MAU::Instruction>())
       return sl;
    auto aa = sl->e0->to<IR::MAU::ActionArg>();
    if (aa == nullptr)
        return sl;
    if (sl->type->width_bits() == aa->type->width_bits() && sl->getL() == 0)
        return aa;
    return sl;
}

// Simplify "actionArg != 0 ? f0 : f1" to "actionArg ? f0 : f1"
const IR::Node* SimplifyConditionalActionArg::postorder(IR::Mux* mux) {
    Pattern::Match<IR::MAU::ActionArg> aa;
    if ((0 != aa).match(mux->e0))
        mux->e0 = aa;
    return mux;
}

/** EliminateAllButLastWrite has to follow VerifyParallelWritesAndReads.  Look at the example
 *  above EliminateAllButLastWrite
 */
InstructionSelection::InstructionSelection(const BFN_Options& options, PhvInfo &phv) : PassManager {
    new CheckInvalidate(phv),
    new UnimplementedRegisterMethodCalls,
    new HashGenSetup(phv, options),
    new Synth2PortSetup(phv),
    new SimplifyConditionalActionArg(),
    new DoInstructionSelection(phv),
    new StatefulAttachmentSetup(phv),
    new MeterSetup(phv),
    // new DLeftSetup,
    new SetupAttachedAddressing,
    new NullifyAllStatefulCallPrim,
    new GuaranteeHashDistSize,
    new CollectPhvInfo(phv),
    new StaticEntriesConstProp(phv),
    new BackendCopyPropagation(phv),
    new VerifyParallelWritesAndReads(phv),
    new EliminateAllButLastWrite(phv),
    new RemoveUnnecessaryActionArgSlice,
    new CollectPhvInfo(phv),
    new PHV::ValidateActions(phv, false, false, false)
} {}
