#include <boost/optional.hpp>
#include "bf-p4c/mau/instruction_adjustment.h"
#include "bf-p4c/mau/ixbar_expr.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/asm_output.h"

/** SplitInstructions */

const IR::Node *SplitInstructions::preorder(IR::MAU::Instruction *inst) {
    le_bitrange bits;
    auto* field = phv.field(inst->operands.at(0), &bits);
    if (!field) return inst;  // error?

    std::vector<le_bitrange> slices;
    PHV::FieldUse use(PHV::FieldUse::WRITE);
    field->foreach_alloc(bits, findContext<IR::MAU::Table>(), &use,
                         [&](const PHV::Field::alloc_slice& alloc) {
        slices.push_back(alloc.field_bits());
    });
    BUG_CHECK(slices.size() >= 1, "No PHV slices allocated for %s", &use);
    if (slices.size() <= 1) return inst;  // nothing to split

    auto split = new IR::Vector<IR::Primitive>();
    cstring opcode = inst->name;
    bool check_pairing = false;
    for (auto slice : slices) {
        auto *n = inst->clone();
        n->name = opcode;
        for (auto &operand : n->operands)
            operand = MakeSlice(operand, slice.lo - bits.lo, slice.hi - bits.lo);
        split->push_back(n);
        // FIXME -- addc/subc only work if there are exactly 2 slices and they're in
        // an even-odd pair of PHVs.  Check for failure to meet that constraint and
        // give an error?
        if (opcode == "add" || opcode == "sub") {
            opcode += "c";
            check_pairing = true; } }
    if (check_pairing) {
        BUG_CHECK(slices.size() == 2, "PHV pairing failure for wide %s", inst->name);
        auto &s1 = field->for_bit(slices[0].lo);
        auto &s2 = field->for_bit(slices[1].lo);
        BUG_CHECK(s1.container.index() + 1 == s2.container.index() &&
                  (s1.container.index() & 1) == 0,
                  "PHV alloc failed to put wide %s into even/odd PHV pair", inst->name); }
    return split;
}

/** ConvertConstantsToActionData */

/** The purpose of this pass is to either convert all constants that are necessarily supposed
 *  to be action data, to action data, or if the action formats were decided before PHV
 *  allocation was known, throw a Backtrack exception back to TableLayout in order to determine
 *  the best allocation.
 *
 *  If a container is determined to need conversion, then all of the constants are converted into
 *  action data for that container.  The reasons constants are converted are detailed in the
 *  action_analysis pass, but summarized are restricted from a load_const, and a src2 limitation
 *  on all instructions.
 */
const IR::MAU::Action *ConstantsToActionData::preorder(IR::MAU::Action *act) {
    container_actions_map.clear();
    constant_containers.clear();
    auto tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_container_actions_map(&container_actions_map);
    act->apply(aa);

    bool proceed = false;
    for (auto &container_action_entry : container_actions_map) {
        auto container = container_action_entry.first;
        auto &cont_action = container_action_entry.second;
        if (cont_action.convert_constant_to_actiondata()) {
            proceed = true;
            constant_containers.insert(container);
        }
    }
    if (!proceed) {
        prune();
        return act;
    }

    action_name = act->name;
    return act;
}


const IR::Node *ConstantsToActionData::preorder(IR::Node *node) {
    visitOnce();
    return node;
}

const IR::MAU::Instruction *ConstantsToActionData::preorder(IR::MAU::Instruction *instr) {
    write_found = false;
    has_constant = false;
    constant_rename_key.action_name = findContext<IR::MAU::Action>()->name;
    return instr;
}

const IR::MAU::ActionArg *ConstantsToActionData::preorder(IR::MAU::ActionArg *arg) {
    return arg;
}

const IR::Primitive *ConstantsToActionData::preorder(IR::Primitive *prim) {
    prune();
    return prim;
}

const IR::Constant *ConstantsToActionData::preorder(IR::Constant *constant) {
    has_constant = true;
    unsigned constant_value;
    if (constant->value.fits_uint_p())
        constant_value = constant->value.get_ui();
    else
        constant_value = static_cast<unsigned>(constant->asInt());
    ActionData::Parameter *param = new ActionData::Constant(constant_value,
                                                            constant->type->width_bits());
    constant_rename_key.param = param;
    return constant;
}

void ConstantsToActionData::analyze_phv_field(IR::Expression *expr) {
        le_bitrange bits;
    auto *field = phv.field(expr, &bits);

    if (field == nullptr)
        return;

    if (isWrite()) {
        if (write_found)
            BUG("Multiple writes found within a single field instruction");

        int write_count = 0;
        le_bitrange container_bits;
        PHV::Container container;
        PHV::FieldUse use(PHV::FieldUse::WRITE);
        field->foreach_alloc(bits, findContext<IR::MAU::Table>(), &use,
                             [&](const PHV::Field::alloc_slice &alloc) {
            write_count++;
            container_bits = alloc.container_bits();
            container = alloc.container;
        });

        if (write_count != 1)
            BUG("Splitting of writes did not work in ConstantsToActionData");

        constant_rename_key.container = container;
        constant_rename_key.phv_bits = container_bits;
        write_found = true;
    }
}

const IR::Slice *ConstantsToActionData::preorder(IR::Slice *sl) {
    if (phv.field(sl))
        analyze_phv_field(sl);

    prune();
    return sl;
}

const IR::Expression *ConstantsToActionData::preorder(IR::Expression *expr) {
    if (!findContext<IR::MAU::Instruction>()) {
        prune();
        return expr;
    }

    if (phv.field(expr)) {
        prune();
        analyze_phv_field(expr);
    }
    return expr;
}

const IR::MAU::AttachedOutput *ConstantsToActionData::preorder(IR::MAU::AttachedOutput *ao) {
    prune();
    return ao;
}

const IR::MAU::StatefulAlu *ConstantsToActionData::preorder(IR::MAU::StatefulAlu *salu) {
    prune();
    return salu;
}

const IR::MAU::HashDist *ConstantsToActionData::preorder(IR::MAU::HashDist *hd) {
    prune();
    return hd;
}

/** Replace any constant in these particular instructions with the an IR::MAU::ActionDataConstant
 */
const IR::MAU::Instruction *ConstantsToActionData::postorder(IR::MAU::Instruction *instr) {
    if (!write_found)
        BUG("No write found in an instruction in ConstantsToActionData?");

    if (constant_containers.find(constant_rename_key.container) == constant_containers.end())
        return instr;
    if (!has_constant)
        return instr;

    auto tbl = findContext<IR::MAU::Table>();
    auto &action_format = tbl->resources->action_format;

    auto *alu_parameter = action_format.find_param_alloc(constant_rename_key, nullptr);
    bool constant_found = alu_parameter != nullptr;

    if (constant_found != has_constant)
        BUG("Constant lookup does not match the ActionFormat");

    if (!constant_found)
        return instr;

    auto alias = alu_parameter->param->to<ActionData::Constant>()->alias();

    for (size_t i = 0; i < instr->operands.size(); i++) {
        const IR::Constant *c = instr->operands[i]->to<IR::Constant>();
        if (c == nullptr)
            continue;
        int size = c->type->width_bits();
        auto *adc = new IR::MAU::ActionDataConstant(IR::Type::Bits::get(size), alias, c);
        instr->operands[i] = adc;
    }
    return instr;
}

const IR::MAU::Action *ConstantsToActionData::postorder(IR::MAU::Action *act) {
    return act;
}


/**
 * Certain Expressions (currently only IR::Constants) because of their associated uses in
 * ALU Operations with HashDists as well, must be converted to HashDists.  (At some point,
 * the immediate_adr_default could be used to generate constants rather than Hash, as this
 * is excessive resources.
 *
 * Currently the instruction adjustment cannot work with these default constants
 */
const IR::MAU::Action *ExpressionsToHash::preorder(IR::MAU::Action *act) {
    container_actions_map.clear();
    expr_to_hash_containers.clear();
    auto tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_container_actions_map(&container_actions_map);
    act->apply(aa);

    for (auto &container_action_entry : container_actions_map) {
        auto container = container_action_entry.first;
        auto &cont_action = container_action_entry.second;
        if (cont_action.convert_constant_to_hash()) {
            expr_to_hash_containers.insert(container);
        }
    }

    if (expr_to_hash_containers.empty())
        prune();
    return act;
}

const IR::MAU::Instruction *ExpressionsToHash::preorder(IR::MAU::Instruction *instr) {
    prune();
    le_bitrange bits;
    auto write_expr = phv.field(instr->operands[0], &bits);
    PHV::Container container;
    ActionData::UniqueLocationKey expr_lookup;

    expr_lookup.action_name = findContext<IR::MAU::Action>()->name;
    auto tbl = findContext<IR::MAU::Table>();
    PHV::FieldUse use(PHV::FieldUse::WRITE);

    int write_count = 0;
    write_expr->foreach_alloc(bits, tbl, &use, [&](const PHV::Field::alloc_slice &alloc) {
        write_count++;
        expr_lookup.phv_bits = alloc.container_bits();
        expr_lookup.container = alloc.container;
    });

    BUG_CHECK(write_count == 1, "An expression writes to more than one container position");

    if (expr_to_hash_containers.count(expr_lookup.container) == 0)
        return instr;

    IR::MAU::Instruction *rv = new IR::MAU::Instruction(instr->srcInfo, instr->name);
    rv->operands.push_back(instr->operands[0]);

    auto &action_format = tbl->resources->action_format;

    for (size_t i = 1; i < instr->operands.size(); i++) {
        expr_lookup.param = nullptr;

        auto operand = instr->operands[i];
        const IR::Expression *rv_operand = nullptr;
        // Build a hash from a single constant
        if (auto con = operand->to<IR::Constant>()) {
            P4HashFunction func;
            func.inputs.push_back(con);
            func.algorithm = IR::MAU::HashFunction::identity();
            func.hash_bits = { 0, con->type->width_bits() - 1 };
            ActionData::Hash *param = new ActionData::Hash(func);
            expr_lookup.param = param;
            auto alu_parameter = action_format.find_param_alloc(expr_lookup, nullptr);
            BUG_CHECK(alu_parameter != nullptr, "%1% Constant in instruction has not correctly "
                   "been converted to hash");
            auto *hge = new IR::MAU::HashGenExpression(con->srcInfo, con->type, con,
                                                       IR::MAU::HashFunction::identity());
            auto *hd = new IR::MAU::HashDist(hge->srcInfo, hge->type, hge);
            rv_operand = hd;
        } else {
            rv_operand = operand;
        }
        rv->operands.push_back(rv_operand);
    }
    return rv;
}


/** Merge Instructions */

/** Run an analysis on the instructions to determine which instructions should be merged.  The
 *  merged instructions must be initially removed, and then added back as a single instruction
 *  over a container
 */
const IR::MAU::Action *MergeInstructions::preorder(IR::MAU::Action *act) {
    container_actions_map.clear();
    merged_fields.clear();
    auto tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_container_actions_map(&container_actions_map);
    aa.set_verbose();
    act->apply(aa);

    unsigned allowed_errors = ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE
                            | ActionAnalysis::ContainerAction::REFORMAT_CONSTANT
                            | ActionAnalysis::ContainerAction::UNRESOLVED_REPEATED_ACTION_DATA;
    unsigned error_mask = ~allowed_errors;

    for (auto &container_action : container_actions_map) {
        auto container = container_action.first;
        auto &cont_action = container_action.second;
        if ((cont_action.error_code & error_mask) != 0) continue;
        if (cont_action.operands() == cont_action.alignment_counts()) {
            if (!cont_action.convert_instr_to_deposit_field
                && !cont_action.convert_instr_to_bitmasked_set
                && !cont_action.convert_instr_to_byte_rotate_merge
                && !cont_action.adi.specialities.getbit(ActionAnalysis::ActionParam::HASH_DIST)
                && !cont_action.adi.specialities.getbit(ActionAnalysis::ActionParam::RANDOM)
                && (cont_action.error_code & ~error_mask) == 0)
                continue;
        // Currently skip unresolved ActionAnalysis issues
        }
        merged_fields.insert(container);
    }

    if (merged_fields.empty())
        prune();

    return act;
}

const IR::Node *MergeInstructions::preorder(IR::Node *node) {
    visitOnce();
    return node;
}

const IR::MAU::Instruction *MergeInstructions::preorder(IR::MAU::Instruction *instr) {
    merged_location = merged_fields.end();
    write_found = false;
    return instr;
}

void MergeInstructions::analyze_phv_field(IR::Expression *expr) {
    le_bitrange bits;
    auto *field = phv.field(expr, &bits);
    if (field != nullptr && isWrite()) {
        if (merged_location != merged_fields.end())
            BUG("More than one write within an instruction");

        int split_count = 0;
        PHV::FieldUse use(PHV::FieldUse::WRITE);
        field->foreach_alloc(bits, findContext<IR::MAU::Table>(), &use,
                             [&](const PHV::Field::alloc_slice &) {
            split_count++;
        });
        if (split_count != 1)
            BUG("Instruction on field %s not a single container instruction", field->name);
        field->foreach_alloc(bits, findContext<IR::MAU::Table>(), &use,
                             [&](const PHV::Field::alloc_slice &alloc) {
            auto container = alloc.container;
            merged_location = merged_fields.find(container);
            write_found = true;
        });
    }
}

const IR::Slice *MergeInstructions::preorder(IR::Slice *sl) {
    if (phv.field(sl))
        analyze_phv_field(sl);
    prune();
    return sl;
}

/** Mark instructions that have a write corresponding to the expression being removed
 */
const IR::Expression *MergeInstructions::preorder(IR::Expression *expr) {
    if (!findContext<IR::MAU::Instruction>()) {
        prune();
        return expr;
    }

    if (phv.field(expr))
        analyze_phv_field(expr);
    prune();
    return expr;
}

const IR::MAU::ActionArg *MergeInstructions::preorder(IR::MAU::ActionArg *aa) {
    prune();
    return aa;
}

const IR::MAU::ActionDataConstant *MergeInstructions::preorder(IR::MAU::ActionDataConstant *adc) {
    prune();
    return adc;
}

const IR::Constant *MergeInstructions::preorder(IR::Constant *cst) {
    prune();
    return cst;
}

const IR::Primitive *MergeInstructions::preorder(IR::Primitive *prim) {
    prune();
    return prim;
}

const IR::MAU::AttachedOutput *MergeInstructions::preorder(IR::MAU::AttachedOutput *ao) {
    prune();
    return ao;
}

const IR::MAU::StatefulAlu *MergeInstructions::preorder(IR::MAU::StatefulAlu *salu) {
    prune();
    return salu;
}

const IR::MAU::HashDist *MergeInstructions::preorder(IR::MAU::HashDist *hd) {
    prune();
    return hd;
}

/** If marked for a merge, remove the original instruction to be added back later
 */
const IR::MAU::Instruction *MergeInstructions::postorder(IR::MAU::Instruction *instr) {
    if (!write_found)
        BUG("No write found within the instruction");

    if (merged_location == merged_fields.end()) {
        return instr;
    } else {
        return nullptr;
    }
}

/** Merge the Expressions as a MultiOperand, and then set the operands of these instructions
 *  as a multi-operand
 */
const IR::MAU::Action *MergeInstructions::postorder(IR::MAU::Action *act) {
    if (merged_fields.empty())
        return act;

    for (auto &container_action_info : container_actions_map) {
        auto container = container_action_info.first;
        auto &cont_action = container_action_info.second;
        if (merged_fields.find(container) == merged_fields.end()) continue;
        act->action.push_back(build_merge_instruction(container, cont_action));
    }
    return act;
}

/** Given that a constant will only appear once, this will find the IR::Constant node within
 *  the field actions.  Thus the size of the IR node is still maintained.
 */
const IR::Constant *MergeInstructions::find_field_action_constant(
         ActionAnalysis::ContainerAction &cont_action) {
    for (auto &fa : cont_action.field_actions) {
        for (auto read : fa.reads) {
            if (read.type == ActionAnalysis::ActionParam::CONSTANT) {
                BUG_CHECK(read.expr->is<IR::Constant>(), "Value incorrectly saved as a constant");
                return read.expr->to<IR::Constant>();
            }
        }
    }
    BUG("Should never reach this point in find_field_action_constant");
    return nullptr;
}

/**
 * Convert one or many HashDist operands to a single Hash Dist object or Slice of a HashDist
 * object with its units set.
 *
 * The units have to both be coordinated through the action format (in order to know which
 * immed_lo/immed_hi to use, as well as the input_xbar alloc, in order to understand which
 * unit coordinates to hash_dist lo/hash_dist hi
 */
const IR::Expression * MergeInstructions::fill_out_hash_operand(PHV::Container container,
        ActionAnalysis::ContainerAction &cont_action) {
    auto tbl = findContext<IR::MAU::Table>();
    auto &adi = cont_action.adi;
    BUG_CHECK(adi.specialities.getbit(ActionAnalysis::ActionParam::HASH_DIST) &&
              adi.specialities.popcount() == 1,
              "Can only create hash dist from hash dist associated objects");

    bitvec op_bits_used_bv = adi.alignment.read_bits();
    bitvec immed_bits_used_bv = op_bits_used_bv << (adi.start * 8);

    // Find out which sections of immediate sections and then coordinate to these to the
    // hash dist sections
    bitvec hash_dist_units_used;
    for (int i = 0; i < 2; i++) {
        if (!immed_bits_used_bv.getslice(i * IXBar::HASH_DIST_BITS, IXBar::HASH_DIST_BITS).empty())
            hash_dist_units_used.setbit(i);
    }

    BUG_CHECK(!hash_dist_units_used.empty(), "Hash Dist in %s has no allocation", cont_action);

    IR::Vector<IR::Expression> hash_dist_parts;
    for (auto &fa : cont_action.field_actions) {
        for (auto read : fa.reads) {
            if (read.speciality != ActionAnalysis::ActionParam::HASH_DIST)
                continue;
            hash_dist_parts.push_back(read.expr);
        }
    }

    IR::ListExpression *le = new IR::ListExpression(hash_dist_parts);
    auto type = IR::Type::Bits::get(hash_dist_units_used.popcount() * IXBar::HASH_DIST_BITS);
    auto *hd = new IR::MAU::HashDist(tbl->srcInfo, type, le);

    auto tbl_hash_dists = tbl->resources->hash_dist_immed_units();
    for (auto bit : hash_dist_units_used) {
        hd->units.push_back(tbl_hash_dists.at(bit));
    }

    int wrapped_lo = 0;  int wrapped_hi = 0;
    // Wrapping the slice in the function outside
    if (adi.alignment.is_wrapped_shift(container, &wrapped_lo, &wrapped_hi)) {
        return hd;
    }

    BUG_CHECK(immed_bits_used_bv.is_contiguous(), "Hash Dist object must be contiguous, if it "
          "not a Wrapped Sliced");
    // If a single hash dist object is used, only the 16 bit slices are necessary, so start
    // at the first position
    le_bitrange immed_bits_used = { immed_bits_used_bv.min().index(),
                                    immed_bits_used_bv.max().index() };
    int hash_dist_bits_shift = (immed_bits_used.lo / IXBar::HASH_DIST_BITS);
    hash_dist_bits_shift *= IXBar::HASH_DIST_BITS;
    le_bitrange hash_dist_bits_used = immed_bits_used.shiftedByBits(-1 * hash_dist_bits_shift);
    return MakeSlice(hd, hash_dist_bits_used.lo, hash_dist_bits_used.hi);
}


/**
 * The RNG_unit is assigned in this particular function (coordinated through ActionAnalysis)
 * and the rng allocation in the action data bus
 */
const IR::Expression *MergeInstructions::fill_out_rand_operand(PHV::Container container,
        ActionAnalysis::ContainerAction &cont_action) {
    auto tbl = findContext<IR::MAU::Table>();
    auto &adi = cont_action.adi;
    BUG_CHECK(adi.specialities.getbit(ActionAnalysis::ActionParam::RANDOM) &&
              adi.specialities.popcount() == 1,
              "Can only create random number from random number associated objects");

    int unit = tbl->resources->rng_unit();
    auto *rn = new IR::MAU::RandomNumber(tbl->srcInfo,
                                          IR::Type::Bits::get(ActionData::Format::IMMEDIATE_BITS),
                                          "hw_rng");
    rn->rng_unit = unit;

    int wrapped_lo = 0;  int wrapped_hi = 0;
    // Wrapping the slice in the function outside
    if (adi.alignment.is_wrapped_shift(container, &wrapped_lo, &wrapped_hi)) {
        return rn;
    }

    bitvec op_bits_used_bv = adi.alignment.read_bits();
    BUG_CHECK(op_bits_used_bv.is_contiguous(), "Random Number must be contiguous if it is not a "
        "wrapped slice");
    le_bitrange op_bits_used = { op_bits_used_bv.min().index(), op_bits_used_bv.max().index() };
    le_bitrange immed_bits_used = op_bits_used.shiftedByBits(adi.start * 8);
    return MakeSlice(rn, immed_bits_used.lo, immed_bits_used.hi);
}

/** In order to keep the IR holding the fields that are contained within the container, this
 *  holds every single IR field within these individual container.  It walks over the reads of
 *  field actions within the container action, and adds them to the list.  Currently we don't
 *  use these fields in any way after this.  However, we may at some point.
 */
void MergeInstructions::fill_out_read_multi_operand(ActionAnalysis::ContainerAction &cont_action,
        ActionAnalysis::ActionParam::type_t type, cstring match_name,
        IR::MAU::MultiOperand *mo) {
    for (auto &fa : cont_action.field_actions) {
         for (auto read : fa.reads) {
             if (read.type != type) continue;
             if (type == ActionAnalysis::ActionParam::ACTIONDATA) {
                 mo->push_back(read.expr);
             } else if (type == ActionAnalysis::ActionParam::PHV) {
                le_bitrange bits;
                auto *field = phv.field(read.expr, &bits);
                int split_count = 0;
                PHV::FieldUse use(PHV::FieldUse::READ);
                field->foreach_alloc(bits, cont_action.table_context, &use,
                                     [&](const PHV::Field::alloc_slice &alloc) {
                    split_count++;
                    if (alloc.container.toString() != match_name)
                       return;
                    const IR::Expression* read_mo_expr = read.expr;
                    if (alloc.width != read.size()) {
                        int start = alloc.field_bit - bits.lo;
                        read_mo_expr = MakeSlice(read.expr, start, start + alloc.width - 1);
                    }
                    mo->push_back(read_mo_expr);
                });
             }
         }
    }
}

/** Fills out the IR::MAU::MultiOperand will all of the underlying fields that are part of a
 *  write.
 */
void MergeInstructions::fill_out_write_multi_operand(ActionAnalysis::ContainerAction &cont_action,
        IR::MAU::MultiOperand *mo) {
    for (auto &fa : cont_action.field_actions) {
        mo->push_back(fa.write.expr);
    }
}


/** The purpose of this is to convert any full container instruction destination to the container
 *  in order for the container to be the correct size.  The assembler will only parse full
 *  container instruction if the destination is the correct size.  This is based on the
 *  verify_overwritten check in ActionAnalysis in order to determine that a partial overwrite of
 *  the container is actually valid, due to the rest of the container being unoccupied.
 */
IR::MAU::Instruction *MergeInstructions::dest_slice_to_container(PHV::Container container,
        ActionAnalysis::ContainerAction &cont_action) {
    BUG_CHECK(cont_action.field_actions.size() == 1, "Can only call this function on an operation "
                                                     "that has one field action");
    IR::MAU::Instruction *rv = new IR::MAU::Instruction(cont_action.name);
    IR::Vector<IR::Expression> components;
    auto *dst_mo = new IR::MAU::MultiOperand(components, container.toString(), true);
    fill_out_write_multi_operand(cont_action, dst_mo);
    rv->operands.push_back(dst_mo);
    for (auto &read : cont_action.field_actions[0].reads) {
        rv->operands.push_back(read.expr);
    }
    return rv;
}

void MergeInstructions::build_actiondata_source(ActionAnalysis::ContainerAction &cont_action,
        const IR::Expression **src1_p, bitvec &src1_writebits, ByteRotateMergeInfo &brm_info,
        PHV::Container container) {
    IR::Vector<IR::Expression> components;
    auto &adi = cont_action.adi;
    if (adi.specialities.getbit(ActionAnalysis::ActionParam::HASH_DIST)) {
        *src1_p = fill_out_hash_operand(container, cont_action);
        src1_writebits = adi.alignment.write_bits();
    } else if (adi.specialities.getbit(ActionAnalysis::ActionParam::RANDOM)) {
        *src1_p = fill_out_rand_operand(container, cont_action);
        src1_writebits = adi.alignment.write_bits();
    } else if (cont_action.ad_renamed()) {
        auto mo = new IR::MAU::MultiOperand(components, adi.action_data_name, false);
        fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::ACTIONDATA,
                                    adi.action_data_name, mo);
        *src1_p = mo;
        src1_writebits = adi.alignment.write_bits();
    } else {
        bool single_action_data = true;
        for (auto &field_action : cont_action.field_actions) {
            for (auto &read : field_action.reads) {
                if (read.type != ActionAnalysis::ActionParam::ACTIONDATA)
                    continue;
                if (read.is_conditional)
                    continue;
                BUG_CHECK(single_action_data, "Action data that shouldn't require an alias "
                          "does require an alias");
                *src1_p = read.expr;
                src1_writebits = adi.alignment.write_bits();
                single_action_data = false;
            }
        }
    }

    int wrapped_lo = 0;  int wrapped_hi = 0;
    if (cont_action.convert_instr_to_byte_rotate_merge) {
        brm_info.src1_shift = adi.alignment.right_shift / 8;
        brm_info.src1_byte_mask = adi.alignment.byte_rotate_merge_byte_mask(container);
    } else if (!cont_action.convert_instr_to_bitmasked_set
        && adi.alignment.is_wrapped_shift(container, &wrapped_lo, &wrapped_hi)) {
        // The alias begins at the first bit used in the action bus slot
        wrapped_lo -= adi.alignment.direct_read_bits.min().index();
        wrapped_hi -= adi.alignment.direct_read_bits.min().index();
        *src1_p = MakeWrappedSlice(*src1_p, wrapped_lo, wrapped_hi, container.size());
    }
}

void MergeInstructions::build_phv_source(ActionAnalysis::ContainerAction &cont_action,
        const IR::Expression **src1_p, const IR::Expression **src2_p, bitvec &src1_writebits,
        bitvec &src2_writebits, ByteRotateMergeInfo &brm_info, PHV::Container container) {
    IR::Vector<IR::Expression> components;
    for (auto &phv_ta : cont_action.phv_alignment) {
        auto read_container = phv_ta.first;
        auto read_alignment = phv_ta.second;
        if (read_alignment.is_src1) {
            auto mo = new IR::MAU::MultiOperand(components, read_container.toString(), true);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::PHV,
                                        read_container.toString(), mo);
            *src1_p = mo;
            src1_writebits = read_alignment.write_bits();
            bitvec src1_read_bits = read_alignment.read_bits();
            int wrapped_lo = 0;  int wrapped_hi = 0;
            if (cont_action.convert_instr_to_byte_rotate_merge) {
                brm_info.src1_shift = read_alignment.right_shift / 8;
                brm_info.src1_byte_mask = read_alignment.byte_rotate_merge_byte_mask(container);
            } else if (read_alignment.is_wrapped_shift(container, &wrapped_lo, &wrapped_hi)) {
                *src1_p = MakeWrappedSlice(*src1_p, wrapped_lo, wrapped_hi, container.size());
            } else if (src1_read_bits.popcount() != static_cast<int>(read_container.size())) {
                if (src1_read_bits.is_contiguous()) {
                    *src1_p = MakeSlice(*src1_p, src1_read_bits.min().index(),
                                        src1_read_bits.max().index());
                }
            }
        } else {
            auto mo = new IR::MAU::MultiOperand(components, read_container.toString(), true);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::PHV,
                                        read_container.toString(), mo);
            *src2_p = mo;
            src2_writebits = read_alignment.write_bits();
            if (cont_action.convert_instr_to_byte_rotate_merge)
                brm_info.src2_shift = read_alignment.right_shift / 8;
        }
    }
}

/** The purpose of this function is to morph together instructions over an individual container.
 *  If multiple field actions are contained within an individual container action, then they
 *  have to be merged into an individual ALU instruction.
 *
 *  This will have to happen to instructions like the following:
 *    - set hdr.f1, param1
 *    - set hdr.f2, param2
 *
 *  where hdr.f1 and hdr.f2 are contained within the same container.  This would be translated
 *  to something along the lines of:
 *    - set $(container), $(action_data_name)
 *
 *  where $(container) is the container in which f1 and f2 are in, and $(action_data_name)
 *  is the assembly name of this combined action data parameter.  This also works between
 *  instructions with PHVs, and can even slice PHVs
 *
 *  This will also directly convert into bitmasked-sets and deposit-field.  Bitmasked-set is
 *  necessary, when the fields in the container are not contingous.  Deposit-field is necessary
 *  when there are two sources.  In any other set case, the actual instruction encoding can be
 *  directly translated from a set instruction.
 *
 *  The instruction formats are setup as a destination and two sources.  ActionAnalysis can
 *  now determine which parameters go to which source.
 */
IR::MAU::Instruction *MergeInstructions::build_merge_instruction(PHV::Container container,
         ActionAnalysis::ContainerAction &cont_action) {
    if (cont_action.is_shift()) {
        unsigned error_mask = ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE;
        BUG_CHECK((cont_action.error_code & error_mask) != 0,
            "Invalid call to build a merged instruction");
        return dest_slice_to_container(container, cont_action);
    }


    const IR::Expression *dst = nullptr;
    const IR::Expression *src1 = nullptr;
    const IR::Expression *src2 = nullptr;
    bitvec src1_writebits;
    bitvec src2_writebits;
    IR::Vector<IR::Expression> components;
    ByteRotateMergeInfo brm_info;

    BUG_CHECK(cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] <= 1, "At most "
              "one section of action data is allowed in a merge instruction");

    BUG_CHECK(!(cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] == 1 &&
                cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] >= 1), "Before "
              "merge instructions, some constant was not converted to action data");

    if (cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] == 1) {
        build_actiondata_source(cont_action, &src1, src1_writebits, brm_info, container);
    } else if (cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] > 0) {
        // Constant merged into a single constant over the entire container
        unsigned constant_value = cont_action.ci.valid_instruction_constant(container.size());
        int width_bits;
        if ((cont_action.error_code & ActionAnalysis::ContainerAction::REFORMAT_CONSTANT) == 0)
            width_bits = cont_action.ci.alignment.bitrange_size();
        else
            width_bits = container.size();
        src1 = new IR::Constant(IR::Type::Bits::get(width_bits), constant_value);
        src1_writebits = cont_action.ci.alignment.write_bits();
    }


    // Go through all PHV sources and create src1/src2 if a source is contained within these
    // PHV fields
    build_phv_source(cont_action, &src1, &src2, src1_writebits, src2_writebits, brm_info,
                     container);

    // Src1 is not sources from parameters, but instead is equal to the destination: BRIG-914
    if (cont_action.implicit_src1) {
        BUG_CHECK(src1 == nullptr, "Src1 found in an implicit_src1 calculation");
        src1 = new IR::MAU::MultiOperand(components, container.toString(), true);
        bitvec reverse = bitvec(0, container.size()) - src2_writebits;
        src1 = MakeSlice(src1, reverse.min().index(), reverse.max().index());
        src1_writebits = reverse;
    }

    // Src2 is not sources from parameters, but instead is equal to the destination: BRIG-883
    if (cont_action.implicit_src2) {
        BUG_CHECK(src2 == nullptr, "Src2 found in an implicit_src2 calculation");
        src2 = new IR::MAU::MultiOperand(components, container.toString(), true);
    }

    auto *dst_mo = new IR::MAU::MultiOperand(components, container.toString(), true);
    fill_out_write_multi_operand(cont_action, dst_mo);
    dst = dst_mo;
    if (!cont_action.partial_overwrite() && src1_writebits.popcount()
                                          != static_cast<int>(container.size())) {
        dst = MakeSlice(dst, src1_writebits.min().index(), src1_writebits.max().index());
    }

    cstring instr_name = cont_action.name;
    if (cont_action.convert_instr_to_bitmasked_set)
        instr_name = "bitmasked-set";
    else if (cont_action.convert_instr_to_deposit_field)
        instr_name = "deposit-field";
    else if (cont_action.convert_instr_to_byte_rotate_merge)
        instr_name = "byte-rotate-merge";

    IR::MAU::Instruction *merged_instr = new IR::MAU::Instruction(instr_name);
    merged_instr->operands.push_back(dst);
    if (!cont_action.no_sources()) {
        BUG_CHECK(src1 != nullptr, "No src1 in a merged instruction");
        merged_instr->operands.push_back(src1);
    }
    if (src2)
        merged_instr->operands.push_back(src2);
    // Currently bitmasked-set requires at least 2 source operands, or it crashes
    if (cont_action.convert_instr_to_bitmasked_set && !src2)
        merged_instr->operands.push_back(dst);

    // For a byte-rotate-merge, the last 3 opcodes are the src1 shift, the src2 shift,
    // and the src1 byte mask
    if (cont_action.convert_instr_to_byte_rotate_merge) {
        merged_instr->operands.push_back(
            new IR::Constant(IR::Type::Bits::get(container.size() / 16), brm_info.src1_shift));
        merged_instr->operands.push_back(
            new IR::Constant(IR::Type::Bits::get(container.size() / 16), brm_info.src2_shift));
        merged_instr->operands.push_back(
            new IR::Constant(IR::Type::Bits::get(container.size() / 8),
                             brm_info.src1_byte_mask.getrange(0, container.size() / 8)));
    }
    return merged_instr;
}

/** The purpose of this pass it to convert any field within an SaluAction to either a slice of
 *  phv_lo or phv_hi.  This is because a field could potentially be split in the PHV, and
 *  be a single SALU instruction.
 *
 *  This also verifies that the allocation on the input xbar is correct, by checking the location
 *  of these individual bytes and coordinating their location to guarantee correctness.
 *
 *  This assumes that the stateful alu is accessing its data through the search bus rather
 *  than the hash bus, as the input xbar algorithm can only put it on the search bus.  When
 *  we add hash matrix support for stateful ALUs, we will add that as well.
 */
const IR::Annotations *AdjustStatefulInstructions::preorder(IR::Annotations *annot) {
    prune();
    return annot;
}

const IR::MAU::IXBarExpression *AdjustStatefulInstructions::preorder(IR::MAU::IXBarExpression *e) {
    prune();
    return e;
}

/** Guarantees that all bits of a particular field are aligned correctly given a size of a
 *  field and beginning position on the input xbar
 */
bool AdjustStatefulInstructions::check_bit_positions(std::map<int, le_bitrange> &salu_inputs,
        le_bitrange field_bits, int starting_bit) {
    bitvec all_bits;
    for (auto entry : salu_inputs) {
        int ixbar_bit_start = entry.first - starting_bit;
        if (ixbar_bit_start + field_bits.lo != entry.second.lo)
            return false;
        all_bits.setrange(entry.second.lo, entry.second.size());
    }

    if (all_bits.popcount() != field_bits.size() || !all_bits.is_contiguous())
        return false;
    return true;
}

bool AdjustStatefulInstructions::verify_on_search_bus(const IR::MAU::StatefulAlu *salu,
        const IXBar::Use &salu_ixbar, const PHV::Field *field, le_bitrange bits, bool &is_hi) {
    std::map<int, le_bitrange> salu_inputs;
    bitvec salu_bytes;
    int group = 0;
    bool group_set = false;
    // Gather up all of the locations of the associated bytes within the input xbar
    for (auto &byte : salu_ixbar.use) {
        bool byte_used = true;
        for (auto fi : byte.field_bytes) {
            if (fi.field != field->name || fi.lo < bits.lo || fi.hi > bits.hi) {
                byte_used = false;
            }
        }
        if (!byte_used)
            continue;

        if (!group_set) {
            group = byte.loc.group;
        } else if (group == byte.loc.group) {
            ::error("Input %s for a stateful alu %s allocated across multiple groups, and "
                     "cannot be resolved", field->name, salu->name);
             return false;
        }
        salu_bytes.setbit(byte.loc.byte);
        for (auto fi : byte.field_bytes) {
            le_bitrange field_bits = { fi.lo, fi.hi };
            salu_inputs[byte.loc.byte * 8 + fi.cont_lo] = field_bits;
        }
    }

    int phv_width = salu->source_width();
    if (salu_bytes.popcount() > (phv_width / 8)) {
        ::error("The input %s to stateful alu %s is allocated to more input xbar bytes than the "
                "width than the ALU and cannot be resolved.", field->name, salu->name);
        return false;
    }

    if (!salu_bytes.is_contiguous()) {
        // FIXME -- we've lost the source info on 'field' so can't generate a decent error
        // message here -- should pass in `expr` from the caller to this function.
        ::error("The input %s to stateful alu %s is not allocated contiguously by byte on the "
                "input xbar and cannot be resolved.", field->name, salu->name);
       return false;
    }


    std::set<int> valid_start_positions;

    int initial_offset = 0;
    if (Device::currentDevice() == Device::TOFINO)
        initial_offset = IXBar::TOFINO_METER_ALU_BYTE_OFFSET;


    valid_start_positions.insert(initial_offset);
    valid_start_positions.insert(initial_offset + (phv_width / 8));

    if (valid_start_positions.count(salu_bytes.min().index()) == 0) {
        ::error("The input %s to stateful alu %s is not allocated in a valid region on the input "
                "xbar to be a source of an ALU operation", field->name, salu->name);
        return false;
    }

    if (!check_bit_positions(salu_inputs, bits, salu_bytes.min().index() * 8)) {
        ::error("The input %s to stateful alu %s is not allocated contiguously by bit on the "
                "input xbar and cannot be resolved.", field->name, salu->name);
        return false;
    }

    is_hi = salu_bytes.min().index() != initial_offset;
    return true;
}

bool AdjustStatefulInstructions::verify_on_hash_bus(const IR::MAU::StatefulAlu *salu,
        const IXBar::Use::MeterAluHash &mah, const IR::Expression *expr,
        bool &is_hi) {
    for (auto &exp : mah.computed_expressions) {
        if (exp.second->equiv(*expr)) {
            is_hi = exp.first != 0;
            return true; } }

    BUG("The input %s to the stateful alu %s cannot be found on the hash input",
        expr, salu->name);
    return false;
}

/** The entire point of this pass is to convert any field name in a Stateful ALU instruction
 *  to either phv_lo or phv_hi, depending on the input xbar allocation.  If the field
 *  comes through the hash bus, then the stateful ALU cannot resolve the name without
 *  phv_lo or phv_hi anyway.
 */
const IR::Expression *AdjustStatefulInstructions::preorder(IR::Expression *expr) {
    visitAgain();
    if (!findContext<IR::MAU::SaluAction>()) {
        return expr;
    }

    le_bitrange bits;
    auto field = phv.field(expr, &bits);
    if (field == nullptr) {
        return expr;
    }

    auto tbl = findContext<IR::MAU::Table>();
    auto salu = findContext<IR::MAU::StatefulAlu>();
    auto &salu_ixbar = tbl->resources->salu_ixbar;
    bool is_hi = false;
    if (!salu_ixbar.meter_alu_hash.allocated) {
        if (!verify_on_search_bus(salu, salu_ixbar, field, bits, is_hi)) {
            prune();
            return expr;
        }
    } else {
        if (!verify_on_hash_bus(salu, salu_ixbar.meter_alu_hash, expr, is_hi)) {
            prune();
            return expr;
        }
    }

    cstring name = "phv";
    if (is_hi)
        name += "_hi";
    else
        name += "_lo";

    IR::MAU::SaluReg *salu_reg
        = new IR::MAU::SaluReg(expr->srcInfo, IR::Type::Bits::get(salu->source_width()), name,
                               is_hi);
    int phv_width = ((bits.size() + 7) / 8) * 8;
    salu_reg->phv_src = expr;
    const IR::Expression *rv = salu_reg;
    // Sets the byte_mask for the input for the stateful alu
    if (phv_width < salu->source_width()) {
        rv = MakeSlice(rv, 0, phv_width - 1);
    }
    prune();
    return rv;
}

/** Instruction Adjustment */
InstructionAdjustment::InstructionAdjustment(const PhvInfo &phv) {
    addPasses({
        new SplitInstructions(phv),
        new ConstantsToActionData(phv),
        new ExpressionsToHash(phv),
        new MergeInstructions(phv),
        new AdjustStatefulInstructions(phv)
    });
}