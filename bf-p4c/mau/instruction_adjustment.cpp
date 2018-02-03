#include "bf-p4c/mau/instruction_adjustment.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/phv/phv_fields.h"

/** SplitInstructions */

/** Run an action analysis to find any instructions that are marked as a split.  Mark the
 *  fields that are the writes of these instructions in order to remove these instructions
 *
 *  For example, let's say the following field, bigfield (64 bits) requires two 32 bit containers
 *  The instruction will originally look like:
 *      - set hdr.bigfield, param
 *  It will get converted to:
 *       - set hdr.bigfield.0-31, param.0-31
 *       - set hdr.bigfield.32-63, param.32-63
 *
 *  This is the purpose of SplitInstructions, to split both the PHV fields and the action
 *  data names, as the action data may not be contiguous
 */
const IR::MAU::Action *SplitInstructions::preorder(IR::MAU::Action *act) {
    container_actions_map.clear();
    split_fields.clear();
    aa.set_container_actions_map(&container_actions_map);
    aa.set_verbose();
    act->apply(aa);
    if (aa.misaligned_actiondata())
        throw ActionFormat::failure(act->name);


    for (auto &container_action_info : container_actions_map) {
        for (auto &field_action : container_action_info.second.field_actions) {
            if (!field_action.requires_split) continue;
            auto *field = phv.field(field_action.write.unsliced_expr());
            split_fields.insert(field);
        }
    }
    return act;
}

const IR::MAU::Instruction *SplitInstructions::preorder(IR::MAU::Instruction *instr) {
    write_found = false;
    hash_dist = false;
    meter_color = false;
    split_location = split_fields.end();
    return instr;
}

const IR::ActionArg *SplitInstructions::preorder(IR::ActionArg *arg) {
    return arg;
}

const IR::Constant *SplitInstructions::preorder(IR::Constant *constant) {
    return constant;
}

const IR::Primitive *SplitInstructions::preorder(IR::Primitive *prim) {
    prune();
    return prim;
}

const IR::Expression *SplitInstructions::preorder(IR::Expression *expr) {
    if (auto *field = phv.field(expr)) {
        if (isWrite()) {
            if (split_location != split_fields.end()) {
                BUG("Multiple writes in a single instruction?");
            }
            split_location = split_fields.find(field);
            write_found = true;
        }
    } else if (!aa.isActionParam(expr)) {
        BUG("Unhandled type of Expression within Split Instructions");
    }
    prune();
    return expr;
}

const IR::MAU::AttachedOutput *SplitInstructions::preorder(IR::MAU::AttachedOutput *ao) {
    prune();
    auto mtr = ao->attached->to<IR::MAU::Meter>();
    if (mtr && mtr->color_output())
        meter_color = true;
    return ao;
}

const IR::MAU::StatefulAlu *SplitInstructions::preorder(IR::MAU::StatefulAlu *salu) {
    prune(); return salu;
}

const IR::MAU::HashDist *SplitInstructions::preorder(IR::MAU::HashDist *hd) {
    hash_dist = true;
    prune(); return hd;
}

/**  If the instruction is to be split, the original instruction has to be removed
 */
const IR::MAU::Instruction *SplitInstructions::postorder(IR::MAU::Instruction *instr) {
    if (!write_found) {
        BUG("No write within a split instruction");
        return instr;
    }

    if (split_location == split_fields.end()) {
        return instr;
    } else {
        if (hash_dist)
            warning("%s: Due to lacking assembler support, cannot currently split "
                    "hash distribution units %s", instr->srcInfo, *instr);
        if (meter_color)
            ::error("%s: The compiler currently cannot support the splitting of instructions "
                    "that contain meter color: %s", instr->srcInfo, *instr);
        auto *field = *(split_location);
        removed_instrs[field] = instr;
        return nullptr;
    }
}

/** Adds the removed instructions as separate split instructions
 */
const IR::MAU::Action *SplitInstructions::postorder(IR::MAU::Action *act) {
    for (auto &container_action : container_actions_map) {
        auto &cont_action = container_action.second;
        for (auto &field_action : cont_action.field_actions) {
            if (!field_action.requires_split) continue;
            auto *field = phv.field(field_action.write.expr);

            IR::MAU::Instruction *split_instr
                = new IR::MAU::Instruction(removed_instrs.at(field)->srcInfo, cont_action.name);
            auto &write = field_action.write;
            split_instr->operands.push_back(write.expr);

            for (auto read : field_action.reads) {
                 split_instr->operands.push_back(read.expr);
            }
            act->action.push_back(split_instr);
        }
    }
    return act;
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
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_container_actions_map(&container_actions_map);
    act->apply(aa);

    bool proceed = false;
    for (auto &container_action_entry : container_actions_map) {
        auto container = container_action_entry.first;
        auto &cont_action = container_action_entry.second;
        if (cont_action.convert_constant_to_actiondata()) {
            proceed = true;
            constant_containers.insert(container.toString());
        }
    }
    if (!proceed) {
        prune();
        return act;
    }

    action_name = act->name;
    auto &constant_renames = tbl->resources->action_format.constant_locations.at(action_name);
    // Backtrack if the constants are not fully setup by the action format
    if (constant_renames.empty())
        throw ActionFormat::failure(act->name);

    return act;
}

const IR::MAU::Instruction *ConstantsToActionData::preorder(IR::MAU::Instruction *instr) {
    write_found = false;
    has_constant = false;
    constant_renames_key.first = cstring::empty;
    constant_renames_key.second = 0;
    return instr;
}

const IR::ActionArg *ConstantsToActionData::preorder(IR::ActionArg *arg) {
    return arg;
}

const IR::Primitive *ConstantsToActionData::preorder(IR::Primitive *prim) {
    prune();
    return prim;
}

const IR::Constant *ConstantsToActionData::preorder(IR::Constant *constant) {
    has_constant = true;
    return constant;
}

void ConstantsToActionData::analyze_phv_field(IR::Expression *expr) {
    bitrange bits;
    auto *field = phv.field(expr, &bits);

    if (field == nullptr)
        return;

    if (isWrite()) {
        if (write_found)
            BUG("Multiple writes found within a single field instruction");

        int write_count = 0;
        int container_bit = 0;
        cstring container_name;
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
            write_count++;
            container_bit = alloc.container_bit;
            container_name = alloc.container.toString();
        });

        if (write_count != 1)
            BUG("Splitting of writes did not work in ConstantsToActionData");

        constant_renames_key.first = container_name;
        constant_renames_key.second = container_bit;
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

    if (constant_containers.find(constant_renames_key.first) == constant_containers.end())
        return instr;

    auto &constant_renames = tbl->resources->action_format.constant_locations.at(action_name);
    bool constant_found = constant_renames.find(constant_renames_key) != constant_renames.end();

    if (constant_found != has_constant)
        BUG("Constant lookup does not match the ActionFormat");

    if (!constant_found)
        return instr;

    cstring constant_name = constant_renames.at(constant_renames_key);

    for (size_t i = 0; i < instr->operands.size(); i++) {
        const IR::Constant *c = instr->operands[i]->to<IR::Constant>();
        if (c == nullptr)
            continue;
        int size = c->type->width_bits();
        auto *adc = new IR::MAU::ActionDataConstant(IR::Type::Bits::get(size),
                                                    constant_name, c);
        instr->operands[i] = adc;
    }
    return instr;
}

const IR::MAU::Action *ConstantsToActionData::postorder(IR::MAU::Action *act) {
    return act;
}


/** Merge Instructions */

/** Run an analysis on the instructions to determine which instructions should be merged.  The
 *  merged instructions must be initially removed, and then added back as a single instruction
 *  over a container
 */
const IR::MAU::Action *MergeInstructions::preorder(IR::MAU::Action *act) {
    container_actions_map.clear();
    merged_fields.clear();
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_container_actions_map(&container_actions_map);
    act->apply(aa);
    if (aa.misaligned_actiondata())
        throw ActionFormat::failure(act->name);
    unsigned error_mask = ~ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE;

    for (auto &container_action : container_actions_map) {
        auto container = container_action.first;
        auto &cont_action = container_action.second;
        if ((cont_action.error_code & error_mask) != 0) continue;
        if (cont_action.field_actions.size() == 1)
            if (!cont_action.to_deposit_field
                && (cont_action.error_code & ~error_mask) == 0)
                continue;
        // Currently skip unresolved ActionAnalysis issues
        merged_fields.insert(container);
    }

    if (merged_fields.empty())
        prune();

    return act;
}

const IR::MAU::Instruction *MergeInstructions::preorder(IR::MAU::Instruction *instr) {
    merged_location = merged_fields.end();
    write_found = false;
    return instr;
}

void MergeInstructions::analyze_phv_field(IR::Expression *expr) {
    bitrange bits;
    auto *field = phv.field(expr, &bits);
    if (field != nullptr && isWrite()) {
        if (merged_location != merged_fields.end())
            BUG("More than one write within an instruction");

        int split_count = 0;
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &) {
            split_count++;
        });
        if (split_count != 1)
            BUG("Instruction on field %s not a single container instruction", field->name);
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
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
    if (phv.field(expr))
        analyze_phv_field(expr);
    prune();
    return expr;
}

const IR::ActionArg *MergeInstructions::preorder(IR::ActionArg *aa) {
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
                bitrange bits;
                auto *field = phv.field(read.expr, &bits);
                int split_count = 0;
                field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
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
    if (cont_action.field_actions.size() == 1 && cont_action.name != "set") {
        unsigned error_mask = ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE;
        BUG_CHECK((cont_action.error_code & error_mask) != 0,
            "Invalid call to build a merged instruction");
        return dest_slice_to_container(container, cont_action);
    }

    const IR::Expression *dst = nullptr;
    const IR::Expression *src1 = nullptr;
    const IR::Expression *src2 = nullptr;
    bitvec src1_writebits;
    IR::Vector<IR::Expression> components;
    BUG_CHECK(cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA]
              + cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] <= 1,
              "When merging an instruction, at most either one action data or constant "
              "value is allowed");
    if (cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] == 1) {
        auto &adi = cont_action.adi;
        auto mo = new IR::MAU::MultiOperand(components, adi.action_data_name, false);
        fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::ACTIONDATA,
                                    adi.action_data_name, mo);
        src1 = mo;
        src1_writebits = adi.ad_alignment.write_bits;
        bitvec src1_read_bits = adi.ad_alignment.read_bits;
        if (src1_read_bits.popcount() != static_cast<int>(container.size())) {
            src1 = MakeSlice(src1, src1_read_bits.min().index(), src1_read_bits.max().index());
        }
    } else if (cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] == 1) {
        src1 = find_field_action_constant(cont_action);
        src1_writebits = cont_action.constant_alignment.write_bits;
    }

    for (auto &phv_ta : cont_action.phv_alignment) {
        auto read_container = phv_ta.first;
        auto read_alignment = phv_ta.second;
        if (read_alignment.is_src1) {
            auto mo = new IR::MAU::MultiOperand(components, read_container.toString(), true);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::PHV,
                                        read_container.toString(), mo);
            src1 = mo;
            src1_writebits = read_alignment.write_bits;
            bitvec src1_read_bits = read_alignment.read_bits;
            if (src1_read_bits.popcount() != static_cast<int>(read_container.size())) {
                src1 = MakeSlice(src1, src1_read_bits.min().index(), src1_read_bits.max().index());
            }
        } else {
            auto mo = new IR::MAU::MultiOperand(components, read_container.toString(), true);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::PHV,
                                        read_container.toString(), mo);
            src2 = mo;
        }
    }

    BUG_CHECK(src1 != nullptr, "No src1 in a merged instruction");
    auto *dst_mo = new IR::MAU::MultiOperand(components, container.toString(), true);
    fill_out_write_multi_operand(cont_action, dst_mo);
    dst = dst_mo;
    if (!cont_action.partial_overwrite() && src1_writebits.popcount()
                                          != static_cast<int>(container.size())) {
        dst = MakeSlice(dst, src1_writebits.min().index(), src1_writebits.max().index());
    }

    cstring instr_name = cont_action.name;
    if (cont_action.to_bitmasked_set)
        instr_name = "bitmasked-set";
    else if (cont_action.to_deposit_field)
        instr_name = "deposit-field";

    IR::MAU::Instruction *merged_instr = new IR::MAU::Instruction(instr_name);
    merged_instr->operands.push_back(dst);
    merged_instr->operands.push_back(src1);
    if (src2)
        merged_instr->operands.push_back(src2);
    // Currently bitmasked-set requires at least 2 source operands, or it crashes
    if (cont_action.to_bitmasked_set && !src2)
        merged_instr->operands.push_back(dst);
    return merged_instr;
}

/** Total Instruction Adjustment */

const IR::MAU::Table *TotalInstructionAdjustment::preorder(IR::MAU::Table *tbl) {
    for (auto &action : Values(tbl->actions)) {
        action = action->apply(SplitInstructions(phv, tbl))->to<IR::MAU::Action>();
        action = action->apply(ConstantsToActionData(phv, tbl))->to<IR::MAU::Action>();
        action = action->apply(MergeInstructions(phv, tbl))->to<IR::MAU::Action>();
    }
    return tbl;
}

