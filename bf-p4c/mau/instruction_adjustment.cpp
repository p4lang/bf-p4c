#include <boost/optional.hpp>
#include "bf-p4c/mau/instruction_adjustment.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/common/asm_output.h"

#define cstr(name) cstring::to_cstring(canon_name(name))

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
    auto tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_container_actions_map(&container_actions_map);
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

/** All of these passes are Transforms with visitDagOnce = false, as certain Expressions within
 *  different Instructions use the same IR::Node (though this itself could be changed).
 *
 *  Actions appear in tables, that can themselves appear multiple times, and we only want
 *  to transform these actions once while keeping the table in position.  Thus by calling
 *  visitOnce on Nodes that don't have a preorder, the pass won't duplicate any Tables or
 *  TableSequences
 */
const IR::Node *SplitInstructions::preorder(IR::Node *node) {
    visitOnce();
    return node;
}

const IR::MAU::Instruction *SplitInstructions::preorder(IR::MAU::Instruction *instr) {
    write_found = false;
    meter_color = false;
    split_location = split_fields.end();
    return instr;
}

const IR::MAU::ActionArg *SplitInstructions::preorder(IR::MAU::ActionArg *arg) {
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
    if (!findContext<IR::MAU::Instruction>()) {
        prune();
        return expr;
    }

    if (auto *field = phv.field(expr)) {
        if (isWrite()) {
            if (split_location != split_fields.end()) {
                BUG("Multiple writes in a single instruction?");
            }
            split_location = split_fields.find(field);
            write_found = true;
        }
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
    prune(); return hd; }

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
    auto &constant_renames = tbl->resources->action_format.constant_locations.at(action_name);
    // Backtrack if the constants are not fully setup by the action format
    if (constant_renames.empty())
        throw ActionFormat::failure(act->name);

    return act;
}


const IR::Node *ConstantsToActionData::preorder(IR::Node *node) {
    visitOnce();
    return node;
}

const IR::MAU::Instruction *ConstantsToActionData::preorder(IR::MAU::Instruction *instr) {
    write_found = false;
    has_constant = false;
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
        int container_bit = 0;
        PHV::Container container;
        cstring container_name;
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
            write_count++;
            container_bit = alloc.container_bit;
            container = alloc.container;
        });

        if (write_count != 1)
            BUG("Splitting of writes did not work in ConstantsToActionData");

        constant_renames_key.init_constant(container, container_bit);
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

    if (constant_containers.find(constant_renames_key.container) == constant_containers.end())
        return instr;

    auto tbl = findContext<IR::MAU::Table>();
    auto &constant_renames = tbl->resources->action_format.constant_locations.at(action_name);
    auto &action_format = tbl->resources->action_format.action_data_format.at(action_name);
    bool constant_found = constant_renames.find(constant_renames_key) != constant_renames.end();

    if (constant_found != has_constant)
        BUG("Constant lookup does not match the ActionFormat");

    if (!constant_found)
        return instr;

    auto value = constant_renames.at(constant_renames_key);
    auto &placement = action_format[value.placement_index];
    auto &arg_loc = placement.arg_locs[value.arg_index];

    for (size_t i = 0; i < instr->operands.size(); i++) {
        const IR::Constant *c = instr->operands[i]->to<IR::Constant>();
        if (c == nullptr)
            continue;
        int size = c->type->width_bits();
        auto *adc = new IR::MAU::ActionDataConstant(IR::Type::Bits::get(size),
                                                    arg_loc.name, c);
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
    auto tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_container_actions_map(&container_actions_map);
    act->apply(aa);
    if (aa.misaligned_actiondata())
        throw ActionFormat::failure(act->name);

    unsigned allowed_errors = ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE
                            | ActionAnalysis::ContainerAction::REFORMAT_CONSTANT
                            | ActionAnalysis::ContainerAction::UNRESOLVED_REPEATED_ACTION_DATA;
    unsigned error_mask = ~allowed_errors;

    for (auto &container_action : container_actions_map) {
        auto container = container_action.first;
        auto &cont_action = container_action.second;
        if ((cont_action.error_code & error_mask) != 0) continue;
        if (cont_action.field_actions.size() == 1)
            if (!cont_action.convert_instr_to_deposit_field
                && (cont_action.error_code & ~error_mask) == 0)
                continue;
        // Currently skip unresolved ActionAnalysis issues
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
    LOG1("Build merge instruction " << cont_action << " " << cont_action.error_code);
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

    BUG_CHECK(cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] <= 1, "At most "
              "one section of action data is allowed in a merge instruction");

    BUG_CHECK(!(cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] == 1 &&
                cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] >= 1), "Before "
              "merge instructions, some constant was not converted to action data");

    if (cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] == 1) {
        if (cont_action.ad_renamed()) {
            auto &adi = cont_action.adi;
            auto mo = new IR::MAU::MultiOperand(components, adi.action_data_name, false);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::ACTIONDATA,
                                        adi.action_data_name, mo);
            src1 = mo;
            src1_writebits = adi.alignment.write_bits();
            bitvec src1_read_bits = adi.alignment.read_bits();
            if (src1_read_bits.popcount() != static_cast<int>(container.size())) {
                src1 = MakeSlice(src1, src1_read_bits.min().index(), src1_read_bits.max().index());
            }
        } else {
            bool single_action_data = true;
            auto &adi = cont_action.adi;
            for (auto &field_action : cont_action.field_actions) {
                for (auto &read : field_action.reads) {
                    if (read.type != ActionAnalysis::ActionParam::ACTIONDATA)
                        continue;
                    BUG_CHECK(single_action_data, "Action data that shouldn't require an alias "
                              "does require an alias");
                    src1 = read.expr;
                    src1_writebits = adi.alignment.write_bits();
                    single_action_data = false;
                }
            }
        }
    } else if (cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] > 0) {
        // Constant merged into a single constant over the entire container
        int constant_value = cont_action.ci.valid_instruction_constant(container.size());
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
    for (auto &phv_ta : cont_action.phv_alignment) {
        auto read_container = phv_ta.first;
        auto read_alignment = phv_ta.second;
        if (read_alignment.is_src1) {
            auto mo = new IR::MAU::MultiOperand(components, read_container.toString(), true);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::PHV,
                                        read_container.toString(), mo);
            src1 = mo;
            src1_writebits = read_alignment.write_bits();
            bitvec src1_read_bits = read_alignment.read_bits();
            int wrapped_lo = 0;  int wrapped_hi = 0;
            if (read_alignment.is_wrapped_shift(container, &wrapped_lo, &wrapped_hi)) {
                src1 = MakeWrappedSlice(src1, wrapped_lo, wrapped_hi, container.size());
            } else if (src1_read_bits.popcount() != static_cast<int>(read_container.size())) {
                if (src1_read_bits.is_contiguous()) {
                    src1 = MakeSlice(src1, src1_read_bits.min().index(),
                                     src1_read_bits.max().index());
                }
            }
        } else {
            auto mo = new IR::MAU::MultiOperand(components, read_container.toString(), true);
            fill_out_read_multi_operand(cont_action, ActionAnalysis::ActionParam::PHV,
                                        read_container.toString(), mo);
            src2 = mo;
            src2_writebits = read_alignment.write_bits();
        }
    }

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

/** Guarantees that all bits of a particular field are aligned correctly given a size of a
 *  field and beginning position on the input xbar
 */
bool AdjustStatefulInstructions::check_bit_positions(std::map<int, le_bitrange> &salu_inputs,
        int field_size, int starting_bit) {
    bitvec all_bits;
    for (auto entry : salu_inputs) {
        int ixbar_bit_start = entry.first - starting_bit;
        if (ixbar_bit_start != entry.second.lo)
            return false;
        all_bits.setrange(entry.second.lo, entry.second.size());
    }

    if (all_bits.popcount() != field_size || !all_bits.is_contiguous())
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
        ::error("The input %s to stateful alu %s is not allocated contiguously by byte on the "
                "input xbar and cannot be resolved.", field->name, salu->name);
       return false;
    }


    std::set<int> valid_start_positions;

    int initial_offset = 0;
    if (Device::currentDevice() == Device::TOFINO)
        initial_offset = IXBar::TOFINO_METER_ALU_BYTE_OFFSET;


    valid_start_positions.insert(initial_offset);
    if (salu->dual)
        valid_start_positions.insert(initial_offset + (phv_width / 8));

    if (valid_start_positions.count(salu_bytes.min().index()) == 0) {
        ::error("The input %s to stateful alu %s is not allocated in a valid region on the input "
                "xbar to be a source of an ALU operation", field->name, salu->name);
        return false;
    }

    if (!check_bit_positions(salu_inputs, bits.size(), salu_bytes.min().index() * 8)) {
        ::error("The input %s to stateful alu %s is not allocated contiguously by bit on the "
                "input xbar and cannot be resolved.", field->name, salu->name);
        return false;
    }

    is_hi = salu_bytes.min().index() != initial_offset;
    return true;
}

bool AdjustStatefulInstructions::verify_on_hash_bus(const IR::MAU::StatefulAlu *salu,
        const IXBar::Use::MeterAluHash &mah, const PHV::Field *field, le_bitrange bits,
        bool &is_hi) {
    if (mah.identity_positions.count(field) == 0) {
        ::error("The input %s to the stateful alu %s cannot be found on the hash input",
                 field->name, salu->name);
        return false;
    }

    auto &pos_vec = mah.identity_positions.at(field);
    bool range_found = false;
    for (auto &pos : pos_vec) {
        if (pos.field_range != bits)
            continue;
        range_found = true;
        is_hi = pos.hash_start != 0;
    }

    if (!range_found) {
        ::error("The range for the input %s to the stateful alu %s is not found on the hash "
                "input", field->name, salu->name);
        return false;
    }
    return true;
}

/** The entire point of this pass is to convert any field name in a Stateful ALU instruction
 *  to either phv_lo or phv_hi, depending on the input xbar allocation.  If the field
 *  comes through the hash bus, then the stateful ALU cannot resolve the name without
 *  phv_lo or phv_hi anyway.
 */
const IR::Expression *AdjustStatefulInstructions::preorder(IR::Expression *expr) {
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
        if (!verify_on_hash_bus(salu, salu_ixbar.meter_alu_hash, field, bits, is_hi)) {
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

void GeneratePrimitiveInfo::add_op_json(Util::JsonObject *prim,
        const std::string op, const std::string type, cstring name) {
    auto op_json = new Util::JsonObject();
    op_json->emplace("type", type);
    op_json->emplace("name", name);
    prim->emplace(op, op_json);
}

void GeneratePrimitiveInfo::add_stful_op_json(Util::JsonObject *prim,
        const std::string op, const std::string op_pfx, const std::string type, cstring name) {
    auto op_json = new Util::JsonObject();
    op_json->emplace(op_pfx + "_type", type);
    op_json->emplace(op_pfx + "_value", name);
    prim->emplace(op, op_json);
}

void GeneratePrimitiveInfo::gen_action_json(const IR::MAU::Action *act,
        Util::JsonObject *_action) {
    LOG1("GeneratePrimitiveInfo Act: " << canon_name(act->name));
    auto _primitives = new Util::JsonArray();
    for (auto call : act->stateful_calls) {
        // FIXME: Add info for hash_inputs, related to context.json schema 1.5.8
        auto prim = call->prim;
        auto _primitive = new Util::JsonObject();
        auto *at = prim->operands.at(0)->to<IR::GlobalRef>()
                       ->obj->to<IR::MAU::AttachedMemory>();
        auto *salu = at->to<IR::MAU::StatefulAlu>();
        if (salu) {
            _primitive->emplace("name", "ExecuteStatefulAluPrimitive");
            add_op_json(_primitive, "dst", "stateful", cstr(at->name));
            for (size_t i = 1; i < prim->operands.size(); ++i) {
                if (auto *k = prim->operands.at(i)->to<IR::Constant>()) {
                    add_op_json(_primitive, "idx", "immediate", k->toString());
                } else if (auto *a = prim->operands.at(i)->to<IR::MAU::ActionArg>()) {
                    add_op_json(_primitive, "idx", "action_param", a->name.toString());
                } else if (auto *c = prim->operands.at(i)->to<IR::Cast>()) {
                    if (auto *a = c->expr->to<IR::MAU::ActionArg>()) {
                        add_op_json(_primitive, "idx", "action_param", a->name.toString());
                    }
                }
            }
            auto *salu_details = new Util::JsonObject();
            auto single_bit_mode = salu->source_width() == 1 ? true : false;
            salu_details->emplace("single_bit_mode", single_bit_mode);
            if (salu->instruction.size() > 0) {
                auto *sact = salu->instruction.begin()->second;
                salu_details->emplace("name", canon_name(sact->name));
                for (auto &sact_inst : sact->action) {
                    std::string inst_name = sact_inst->name.c_str();
                    auto *sact_update = new Util::JsonObject();
                    if (inst_name == "alu_a" || inst_name == "alu_b"
                            || inst_name == "add" || inst_name == "sub") {
                        if (sact_inst->operands.size() == 2) {
                            auto src = sact_inst->operands[1];
                            auto src_string = src->toString();
                            if (auto *k = src->to<IR::Constant>()) {
                                sact_update->emplace("operand_1_type", "immediate");
                                sact_update->emplace("operand_1_value", k->toString());
                            } else if (auto phv_field = phv.field(src_string)) {
                                sact_update->emplace("operand_1_type", "phv");
                                sact_update->emplace("operand_1_value", src_string);
                            }
                        } else if (sact_inst->operands.size() == 3) {
                            auto src1 = sact_inst->operands[1];
                            auto src2 = sact_inst->operands[2];
                            std::string op = "";
                            if (inst_name == "add") op = "+";
                            if (inst_name == "sub") op = "-";
                            sact_update->emplace("operation", op);
                            if (auto *s = src1->to<IR::MAU::SaluReg>()) {
                                sact_update->emplace("operand_1_type", "memory");
                                sact_update->emplace("operand_1_value", "register_" + s->name);
                            }
                            if (auto *k = src2->to<IR::Constant>()) {
                                sact_update->emplace("operand_2_type", "immediate");
                                sact_update->emplace("operand_2_value", k->toString());
                            } else if (auto phv_field = phv.field(src2)) {
                                sact_update->emplace("operand_2_type", "phv");
                                sact_update->emplace("operand_2_value",
                                        cstr(phv_field->externalName()));
                            }
                        }
                        if (sact_inst->operands.size() > 1) {
                            if (auto *dst = sact_inst->operands[0]->to<IR::MAU::SaluReg>()) {
                                if (dst->name == "lo") {
                                    salu_details->emplace("update_lo_1_value", sact_update);
                                } else if (dst->name == "hi") {
                                    salu_details->emplace("update_hi_1_value", sact_update);
                                }
                            }
                        }
                    } else if (inst_name == "output") {
                        if (sact_inst->operands.size() == 1) {
                            if (auto dst = sact_inst->operands[0]->to<IR::MAU::SaluReg>()) {
                                sact_update->emplace("operand_1_type", "memory");
                                sact_update->emplace("operand_1_value", dst->name);
                                salu_details->emplace("output_value", sact_update);
                            }
                        }
                    }
                }
            }
            _primitive->emplace("stateful_alu_details", salu_details);
            _primitives->append(_primitive);
        }
        auto *meter = at->to<IR::MAU::Meter>();
        if (meter) {
            _primitive->emplace("name", "ExecuteMeterPrimitive");
            add_op_json(_primitive, "dst", "meter", cstr(meter->name));
            if (auto pc = meter->pre_color) {
                if (auto hd = pc->to<IR::MAU::HashDist>()) {
                    if (auto fl = hd->field_list) {
                        if (auto sl = fl->to<IR::Slice>()) {
                            if (auto e0 = sl->e0) {
                                add_op_json(_primitive, "idx", "action_param",
                                        cstr(e0->toString()));
                            }
                        }
                    }
                }
            }
            _primitives->append(_primitive);
        }
    }


    std::vector<std::string> modifyPrimVec = { "set" };
    std::vector<std::string> invalidatePrimVec = { "invalidate" };
    std::vector<std::string> shiftPrimVec = { "shru", "shl", "shrs" };
    std::vector<std::string> directAluPrimVec = {
        "add", "addc", "saddu", "sadds",
        "and", "andca", "andcb", "nand",
        "nor", "not", "or", "orca", "orcb",
        "xnor", "xor", "maxu", "minu",
        "sub", "subc", "ssubu", "ssubs" };
    std::map<std::string, std::vector<std::string>* > prims = {
        { "ModifyFieldPrimitive", &modifyPrimVec },
        { "InvalidatePrimitive", &invalidatePrimVec },
        { "ShiftPrimitive", &shiftPrimVec },
        { "DirectAluPrimitive", &directAluPrimVec }
    };
    for (auto inst : act->action) {
        auto _primitive = new Util::JsonObject();
        std::string inst_name = inst->name.c_str();
        bool skip_prim_check = false;
        if ((inst_name == "set")
                && (inst->operands.size() == 2)) {
            cstring dst = inst->operands[0]->toString();
            auto src = inst->operands[1];
            if (dst.endsWith("$valid")) {
                if (auto val = src->to<IR::Constant>()) {
                    if (val->value == 1) {
                        _primitive->emplace("name", "AddHeaderPrimitive");
                        skip_prim_check = true;
                    } else if (val->value == 0) {
                        _primitive->emplace("name", "RemoveHeaderPrimitive");
                        skip_prim_check = true;
                    }
                    add_op_json(_primitive, "dst", "header", cstr(dst));
                }
            } else if (dst.endsWith("drop_ctl")) {
                if (auto val = src->to<IR::Constant>()) {
                    if (val->value == 1) {
                        _primitive->emplace("name", "DropPrimitive");
                        skip_prim_check = true;
                        add_op_json(_primitive, "dst", "phv", cstr(dst));
                        add_op_json(_primitive, "src1", "immediate", "1");
                    }
                }
            }
        }
        bool is_stful_dest = false;
        if (!skip_prim_check) {
            for (auto &p : prims) {
                auto pv = *p.second;
                if (std::any_of(pv.begin(), pv.end(),
                        [&inst_name](std::string const& elem) {
                        return inst_name == elem; })) {
                    _primitive->emplace("name", p.first);
                    _primitive->emplace("operation", inst_name);
                    if (inst->operands.size() == 2) {
                        auto src = inst->operands[1];
                        if (auto *ao = src->to<IR::MAU::AttachedOutput>()) {
                            if (ao->attached->to<IR::MAU::StatefulAlu>()) {
                                cstring dst = inst->operands[0]->toString();
                                // Add output_dst to previously added stateful
                                // primitive
                                for (auto _prim : *_primitives) {
                                    auto _prim_o = _prim->to<Util::JsonObject>();
                                    auto _prim_o_name = _prim_o->get("name");
                                    auto _prim_o_name_val = _prim_o_name->to<Util::JsonValue>();
                                    auto _prim_o_name_val_str = _prim_o_name_val->getString();
                                    bool stful_prim =
                                        (_prim_o_name_val_str == "ExecuteStatefulAluPrimitive");
                                    if (!stful_prim) continue;
                                    auto _salu_d = _prim_o->get("stateful_alu_details");
                                    if (_salu_d) {
                                        auto _salu_d_o = _salu_d->to<Util::JsonObject>();
                                        _salu_d_o->emplace("output_dst", cstr(dst));
                                        is_stful_dest = true;
                                    }
                                }
                                break;
                            }
                        }
                    } else if (inst->operands.size() == 1) {
                        if (inst_name == "invalidate") {
                            auto dst = inst->operands[0]->to<IR::Expression>();
                            if (auto phv_field = phv.field(dst)) {
                                add_op_json(_primitive,
                                        "dst", "phv", cstr(phv_field->externalName()));
                            }
                        }
                    }
                }
            }
            // Don't output operand json if instruction is a stateful destination,
            // this info goes within the stateful primitive evaluated above.
            if ((inst->operands.size() >= 2) && (!is_stful_dest)) {
                // Add dst operands
                auto dst = inst->operands[0]->to<IR::Expression>();
                le_bitrange bits = {0, 0};
                if (auto phv_field = phv.field(dst, &bits)) {
                    add_op_json(_primitive, "dst", "phv", cstr(phv_field->externalName()));
                    add_op_json(_primitive, "dst_mask", "immediate",
                            std::to_string((1U << bits.size()) - 1));
                }
                // Add src operands
                auto idx = 0;
                for (auto src : inst->operands) {
                    if (idx++ == 0) continue;  // skip 1st op which is dst
                    auto src_name = "src" + std::to_string(idx - 1);
                    validate_add_op_json(_primitive, src_name, src);
                }
            }
        }
        // FIXME: This name should be set above.
        // 'name' is a required attribute for primitives.
        if (_primitive->find("name") == _primitive->end()) {
            _primitive->emplace("name", "PrimitiveNameNeeded");
        }
        if (!is_stful_dest) _primitives->append(_primitive);
    }
    _action->emplace("primitives", _primitives);
}

void GeneratePrimitiveInfo::validate_add_op_json(Util::JsonObject *_primitive,
        const std::string op_name, const IR::Expression *exp) {
    if (auto phv_field = phv.field(exp)) {
         add_op_json(_primitive, op_name, "phv", cstr(phv_field->externalName()));
    } else  if (auto cnst = exp->to<IR::Constant>()) {
         add_op_json(_primitive, op_name, "immediate", cnst->toString());
     } else if (auto aarg = exp->to<IR::MAU::ActionArg>()) {
         add_op_json(_primitive, op_name, "action_param", cstr(aarg->name));
     } else if (auto *sl = exp->to<IR::Slice>()) {
         if (auto e0 = sl->e0) {
            if (auto *ao = e0->to<IR::MAU::AttachedOutput>()) {
                if (auto stful = ao->attached->to<IR::MAU::StatefulAlu>()) {
                    if (op_name == "dst")
                        add_op_json(_primitive, op_name, "stateful", cstr(stful->name));
                    else
                        add_op_json(_primitive, op_name, "phv", cstr(stful->name));
                } else if (auto meter = ao->attached->to<IR::MAU::Meter>()) {
                   if (op_name == "src1")
                       add_op_json(_primitive, op_name, "action_param", cstr(meter->name));
                   else
                       add_op_json(_primitive, op_name, "phv", cstr(meter->name));
                }
            }
        }
    }
}

bool GeneratePrimitiveInfo::preorder(const IR::MAU::Table *tbl) {
    auto tname = tbl->match_table ? tbl->match_table->externalName() : tbl->name;
    LOG1("Table: " << canon_name(tname));
    bool alpm_preclassifier = tbl->name.endsWith("preclassifier");

    if (tbl->actions.empty()) return true;

    auto _table = new Util::JsonObject();
    auto _actions = new Util::JsonArray();
    for (auto act : Values(tbl->actions)) {
        if (act->miss_action_only) continue;
        auto _action = new Util::JsonObject();
        _action->emplace("name", cstr(act->name));
        gen_action_json(act, _action);
        _actions->append(_action);
    }

    _table->emplace("name", cstr(tname));
    if (alpm_preclassifier) {
        auto _match_attr = new Util::JsonObject();
        auto _pre_classifier = new Util::JsonObject();
        _pre_classifier->emplace("actions", _actions);
        _match_attr->emplace("pre_classifier", _pre_classifier);
        _table->emplace("match_attributes", _match_attr);
    } else {
        _table->emplace("actions", _actions);
    }

    _tables->append(_table);
    return true;
}

void GeneratePrimitiveInfo::end_apply() {
    // Write to primitive json file
    auto _pNode = new Util::JsonObject();
    _pNode->emplace("tables", _tables);
    _primNode = *_pNode;
}

/** Instruction Adjustment */
InstructionAdjustment::InstructionAdjustment(const PhvInfo &phv, Util::JsonObject &primNode) {
    addPasses({
        new GeneratePrimitiveInfo(phv, primNode),
        new SplitInstructions(phv),
        new ConstantsToActionData(phv),
        new MergeInstructions(phv),
        new AdjustStatefulInstructions(phv)
    });
}
