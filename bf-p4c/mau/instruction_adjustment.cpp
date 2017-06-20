#include "instruction_adjustment.h"
#include "tofino/common/slice.h"

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

const IR::MAU::Instruction *SplitInstructions::preorder(IR::MAU::Instruction *instr) {
    write_found = false;
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
    } else {
        ERROR("Unhandled type of Expression");
    }
    prune();
    return expr;
}

const IR::MAU::AttachedOutput *SplitInstructions::preorder(IR::MAU::AttachedOutput *ao) {
    prune(); return ao;
}

const IR::MAU::StatefulAlu *SplitInstructions::preorder(IR::MAU::StatefulAlu *salu) {
    prune(); return salu;
}

const IR::MAU::HashDist *SplitInstructions::preorder(IR::MAU::HashDist *hd) {
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

/** Merge Instructions */

/** Run an analysis on the instructions to determine which instructions should be merged.  The
 *  merged instructions must be initially removed, and then added back as a single instruction
 *  over a container
 */
const IR::MAU::Action *MergeInstructions::preorder(IR::MAU::Action *act) {
    container_actions_map.clear();
    removed_instrs.clear();
    merged_fields.clear();
    ActionAnalysis aa(phv, true, true, tbl);
    aa.set_container_actions_map(&container_actions_map);
    act->apply(aa);
    if (aa.misaligned_actiondata())
        throw ActionFormat::failure(act->name);

    for (auto &container_action : container_actions_map) {
        auto container = container_action.first;
        auto &cont_action = container_action.second;
        if (cont_action.field_actions.size() == 1) continue;
        // FIXME: Give decent error messages as well
        if (cont_action.error_code != ActionAnalysis::ContainerAction::NO_PROBLEM) continue;
        // FIXME: To do these shortly
        if (cont_action.to_deposit_field) continue;
        if (cont_action.to_bitmasked_set) continue;

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
    PhvInfo::Field::bitrange bits;
    auto *field = phv.field(expr, &bits);
    if (field != nullptr && isWrite()) {
        if (merged_location != merged_fields.end())
            BUG("More than one write within an instruction");

        int split_count = 0;
        field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &) {
            split_count++;
        });
        if (split_count != 1)
            BUG("Instruction on field %s not a single container instruction", field->name);
        field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &alloc) {
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
        auto container = *(merged_location);
        if (removed_instrs.find(container) == removed_instrs.end()) {
            vector<IR::MAU::Instruction *> vec;
            removed_instrs[container] = vec;
        }
        removed_instrs[container].push_back(instr);
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
        // FIXME: Obviously to do these shortly
        if (cont_action.to_deposit_field) continue;
        if (cont_action.to_bitmasked_set) continue;
        act->action.push_back(make_multi_operand_set(container, cont_action));
    }
    return act;
}

/** Builds the different IR::MAU::MultiOperand structures for both the reads and the writes.
 *  Assumes at most that there are two reads, based on the ActionAnalysis pass.
 *  Has to go through all of the reads, and map directly to a PHV field.  The order of
 *  operands does not necessarily determine which PHV container an action is in.
 *  Thus, which MultiOperand the read goes to is compared by name, which requires an
 *  extra loop due to the name.  However, with the max size at 2, the looping is negligible.
 */
void MergeInstructions::build_multi_operand_info(PHV::Container container,
        ActionAnalysis::ContainerAction &cont_action, MultiOperandInfo &mo) {
    IR::Vector<IR::Expression> components;
    mo.write = new IR::MAU::MultiOperand(components, container.toString(), true);

    // FIXME: this should be handled as a separate case, as constants can be combined
    if (cont_action.counts[ActionAnalysis::ActionParam::CONSTANT] > 0)
        BUG("Unhandled case of sharing constants");

    for (auto &tot_align_info : cont_action.phv_alignment) {
        auto read_cont = tot_align_info.first;
        mo.reads.emplace_back(read_cont.toString(),
                              new IR::MAU::MultiOperand(components, read_cont.toString(), true));
    }

    auto &adi = cont_action.adi;
    if (adi.initialized)
        mo.reads.emplace_back(adi.action_data_name,
                              new IR::MAU::MultiOperand(components, adi.action_data_name, false));

    for (auto &field_action : cont_action.field_actions) {
        auto &write = field_action.write;

        mo.write->push_back(write.expr);

        for (auto &read : field_action.reads) {
            ///> lookup_name corresponds to PHV::Container name/Action Data Name
            cstring lookup_name;
            if (read.type == ActionAnalysis::ActionParam::PHV) {
                PhvInfo::Field::bitrange bits;
                auto *field = phv.field(read.expr, &bits);
                int split_count = 0;
                field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &) {
                    split_count++;
                });
                if (split_count != 1)
                    BUG("Read variable cannot be used within a single action");

                field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &alloc) {
                    lookup_name = alloc.container.toString();
                });
            } else {
                lookup_name = cont_action.adi.action_data_name;
            }

            size_t index = -1;
            // Finds the lookup name in the reads array and adds this individual expression to
            // the MultiOperand
            for (auto read_check : mo.reads) {
                index++;
                if (read_check.first == lookup_name)
                    break;
            }
            if (index == mo.reads.size())
                BUG("Naming mismatch within the make_multi_operand_set");


            mo.reads[index].second->push_back(read.expr);
        }
    }
}

/** A simple merge of instructions.  Essentially turns multiple instructions into one, i.e.
 *  let's say two fields are within the same container, f1 and f2, and both are set by an
 *  action parameter:
 *     - set hdr.f1, param1
 *     - set hdr.f2, param2
 * to:
 *     - set $(container), $(action_data_name)
 *
 *  where $(container) is the container in which f1 and f2 are in, and $(action_data_name)
 *  is the assembly name of this combined action data parameter.  This also works between
 *  instructions with PHVs, and can even slice PHVs
 *
 *  Deposit-field and bitmasked-set are more complicated, so they'll need separate
 *  function calls.
 */
IR::MAU::Instruction *MergeInstructions::make_multi_operand_set(PHV::Container container,
        ActionAnalysis::ContainerAction &cont_action) {
    MultiOperandInfo mo;
    build_multi_operand_info(container, cont_action, mo);

    IR::MAU::Instruction *merged_instr = new IR::MAU::Instruction(cont_action.name);

    bitvec tot_write = cont_action.total_write();
    const IR::Expression *write_operand;
    if (tot_write.popcount() != static_cast<int>(container.size()))
        write_operand = MakeSlice(mo.write, tot_write.min().index(), tot_write.max().index());
    else
        write_operand = mo.write;
    merged_instr->operands.push_back(write_operand);

    for (auto &read_mo : mo.reads) {
        bitvec tot_read;
        bool found = false;
        auto lookup_name = read_mo.first;
        for (auto tot_align_info : cont_action.phv_alignment) {
            if (tot_align_info.first.toString() == lookup_name) {
                found = true;
                tot_read = tot_align_info.second.read_bits;
                break;
            }
        }
        if (!found) {
            tot_read = cont_action.adi.ad_alignment.read_bits;
        }

        const IR::Expression *read_operand;
        if (tot_read.popcount() != static_cast<int>(container.size()))
            read_operand = MakeSlice(read_mo.second, tot_read.min().index(),
                                     tot_read.max().index());
        else
            read_operand = read_mo.second;
        merged_instr->operands.push_back(read_operand);
    }

    return merged_instr;
}

/** Total Instruction Adjustment */

const IR::MAU::Table *TotalInstructionAdjustment::preorder(IR::MAU::Table *tbl) {
    for (auto &action : Values(tbl->actions)) {
        action = action->apply(SplitInstructions(phv, tbl))->to<IR::MAU::Action>();
        action = action->apply(MergeInstructions(phv, tbl))->to<IR::MAU::Action>();
    }
    return tbl;
}

