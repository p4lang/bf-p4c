#include "instruction_adjustment.h"
#include "tofino/common/slice.h"

bool InstructionAdjustment::BuildContainerActions::preorder(const IR::MAU::Instruction *instr) {
    instr_process.clear();
    instr_process.name = instr->name;
    return true;
}

bool InstructionAdjustment::BuildContainerActions::preorder(const IR::ActionArg *arg) {
    if (!findContext<IR::MAU::Instruction>())
        return false;

    instr_process.reads.emplace_back(ActionParam::ACTIONDATA, arg, arg->type->width_bits());
    return false;
}

bool InstructionAdjustment::BuildContainerActions::preorder(const IR::Constant *constant) {
    instr_process.reads.emplace_back(ActionParam::CONSTANT, constant, 0);
    return false;
}

bool InstructionAdjustment::BuildContainerActions::preorder(const IR::Primitive *) {
    return false;
}


bool InstructionAdjustment::BuildContainerActions::preorder(const IR::Expression *expr) {
    if (auto *field = phv.field(expr)) {
        if (isWrite()) {
            if (instr_process.write_found) {
                BUG("Multiple write in a single instruction?");
            }
            ActionParam write(ActionParam::PHV, expr, field->size);
            instr_process.setWrite(write);
        } else {
            instr_process.reads.emplace_back(ActionParam::PHV, expr, field->size);
        }
    } else {
        ERROR("IR structure not yet handled by the BuildContainerActions pass");
    }
    return false;
}

/** Currently assuming that there is no slicing of these instructions yet.  Will
 *  be put in at a later time
 */ 
void InstructionAdjustment::BuildContainerActions::postorder(const IR::MAU::Instruction *instr) {
    if (instr_process.write_found) {
        auto *field = phv.field(instr_process.write.expr);
        bool split = true;
        if (field->alloc.size() == 1)
            split = false;
        if (field->alloc.size() == 0)
            ERROR("PHV not allocated for this field");
        for (auto &alloc : field->alloc) {
            auto container = alloc.container;
            if (container_actions.find(container) == container_actions.end()) {
                ContainerProcess cont_proc;
                container_actions.emplace(container, cont_proc);
            }
            if (!split) {
                instr_process.write.cont_bit = alloc.container_bit;
                container_actions[container].instr_procs.push_back(instr_process);
            } else {
                InstructionProcess instr_process_split = instr_process;
                instr_process_split.write.set_split(alloc.field_bit, alloc.field_hi());
                instr_process_split.write.cont_bit = alloc.container_bit;
                container_actions[container].instr_procs.push_back(instr_process_split);
            }
        }
    } else {
        ERROR("Nothing written in the instruction " << instr);
    }
}

const IR::MAU::Action *InstructionAdjustment::preorder(IR::MAU::Action *act) {
    container_actions.clear();
    BuildContainerActions bca(phv, container_actions);
    act->apply(bca);
    analyze_container_actions(act->name);
    return act;
}

/** This function checks whether or not the action data in a function can correctly line up with
 *  the PHV read.  If the container size does not match, or the alignment of the data does not
 *  line up, then the function will return false.
 *
 *  The action data also tracks to make sure that if multiple action data fields are in the read,
 *  that they belong to same action data section, and tracks that through the ActionDataInfo
 *  object
 *
 *  If the alignment doesn't match up, then the function will return false.
 */
bool InstructionAdjustment::verify_action_data(const ActionParam &write, ActionParam &read,
        cstring action_name, ActionDataInfo &adi, int &count, const PHV::Container &container) {
    auto &action_format = tbl->resources->action_format;
    auto &placements = action_format.arg_placement.at(action_name);
    const vector<ActionFormat::ActionDataPlacement> *action_data_format = nullptr;
    const vector<ActionFormat::ActionDataPlacement> *immediate_format = nullptr;
    action_data_format = &(action_format.action_data_format.at(action_name));

    if (tbl->layout.action_data_bytes_in_overhead > 0)
        immediate_format = &(action_format.immediate_format.at(action_name));

    auto arg_name = read.expr->to<IR::ActionArg>()->name;
    auto &arg_placement = placements.at(arg_name);
    bool found = false;
    bool is_immediate;
    for (auto vector_loc : arg_placement) {
        ActionFormat::ActionDataPlacement adp;
        if (vector_loc.second != (tbl->layout.action_data_bytes_in_overhead > 0))
            continue;
        if (tbl->layout.action_data_bytes_in_overhead > 0) {
            adp = (*immediate_format)[vector_loc.first];
            is_immediate = true;
        } else {
            adp = (*action_data_format)[vector_loc.first];
            is_immediate = false;
        }
        for (auto arg_loc : adp.arg_locs) {
            if (arg_loc.name != arg_name) continue;
            if (static_cast<size_t>(adp.size) != container.size()) continue;
            int lo = arg_loc.field_bit;
            int hi = lo + arg_loc.data_loc.popcount() - 1;

            if (!(lo <= write.lo && hi >= write.hi)) continue;

            found = true;
            if (!arg_loc.single_loc)
                // FIXME: At some point need to have even further splits of action data
                read.set_split(write.lo, write.hi);
            bitvec write_bits(write.cont_bit, write.hi - write.lo + 1);
            if (count == 0) {
                adi.action_data_name = adp.asm_name;
                adi.immediate = is_immediate;
                adi.start = adp.start;
                adi.total_field_affects = adp.arg_locs.size();
                adi.field_affects = 1;
                adi.read_action_data.emplace_back(write_bits, arg_loc.data_loc);
                adi.total_write_bits |= write_bits;
                adi.total_read_bits |= arg_loc.data_loc;
                count++;
            } else if (adi.start != adp.start || adi.immediate != is_immediate) {
                count++;
            } else {
                adi.field_affects++;
                adi.read_action_data.emplace_back(write_bits, arg_loc.data_loc);
                adi.total_write_bits |= write_bits;
                adi.total_read_bits |= arg_loc.data_loc;;
            }
            break;
        }
        if (found) break;
    }
    return found;
}

/** This function checks the alignment of PHV reads to PHV writes.  Essentially if the action
 *  is impossible due to the individual layouts of the read container vs. the write container,
 *  this funciton will reutrn false.  It also tracks the alignment information through the
 *  total_reads_phvs map in the ContainerProcess
 */
bool InstructionAdjustment::verify_phv_field(const ActionParam &write, ActionParam &read,
        ContainerProcess &cont_proc, int &count) {
    auto *read_field = phv.field(read.expr);
    bool found;

    auto &total_reads_phvs = cont_proc.total_reads_phvs;
    for (auto &alloc : read_field->alloc) {
        if (!(alloc.field_bit <= write.lo && alloc.field_hi() >= write.hi)) continue;

        bitvec write_bits(write.cont_bit, write.hi - write.lo + 1);
        // FIXME: This has to be adjusted if the read slice is larger than the write slice
        bitvec read_bits(alloc.container_bit, alloc.container_hi() - alloc.container_bit + 1);
        if (total_reads_phvs.find(alloc.container) == total_reads_phvs.end()) {
            TotalReadPhvInfo trpi;
            trpi.read_phvs.emplace_back(write_bits, read_bits);
            trpi.total_write_bits |= write_bits;
            trpi.total_read_bits |= read_bits;
            total_reads_phvs[alloc.container] = trpi;
            count++;
        } else {
            total_reads_phvs[alloc.container].read_phvs.emplace_back(write_bits, read_bits);
            total_reads_phvs[alloc.container].total_write_bits |= write_bits;
            total_reads_phvs[alloc.container].total_read_bits |= read_bits;
        }

        found = true;
        // FIXME: Just a temporary fix
        if (write.is_split) {
            read.set_split(write.lo, write.hi);
        }
        break;
    }
    return found;
}

bool InstructionAdjustment::verify_constant(const ActionParam &write, ActionParam &read,
                                            int &count) {
    if (write.is_split) {
        read.set_split(write.lo, write.hi);
    }
    count++;
    return true;
}

/** Verification of the alignment information of the PHV field data to the read, whether it is
 *  completely able to be aligned.
 *
 *  Still missing the verification of these constraints:
 *      - Must check on a individual read to write basis of the shifts
 *      - Also does not check for the possibility of a rotational shift
 *      - Need to check for holes
 *      - No check if a single PHV container contains both the aligned and shifted data, right now 
 *        must be in separate container
 *      - For particular actions, must check if rest of container will not be affected, or 
 *        essentially if the holes constitute unused data
 */
bool InstructionAdjustment::verify_alignment(bitvec &total_wb, bitvec &total_rb,
        PHV::Container container, bool &is_aligned, ContainerProcess &cont_proc) {
    if (total_rb.popcount() != total_wb.popcount()) {
        ERROR("In action " << action_name << " of table " << tbl->name << ", the action "
              << "over container " << container.toString()<< " has a difference "
              << "in the number of bits used by the separate issues");
        cont_proc.unhandled_action = true;
        return false;
    }
    int first_rb = total_rb.ffs();
    int first_wb = total_wb.ffs();

    if ((total_rb >> first_rb) != (total_wb >> first_wb)) {
        ERROR("In action " << action_name << " of table " << tbl->name << ", the action "
              << "over container " << container.toString() << " has alignment "
              << "issues for PHVs");
        cont_proc.unhandled_action = true;
        return false;
    }

    if (first_rb == first_wb) {
        is_aligned = true;
    }
    return false;
}

/** This function checks the entire action in total on whether or not the action is breaking
 *  any constraints of the ALU, or if the requirements on the ALU have not yet been implemented
 *  yet within instruction adjustments
 *
 *  General requirements of the ALU are the following
 *      - Two reads in total are allowed per container
 *      - The first read has to be a PHV field, the second read can be a PHV or ActionData
 *      - Constants are fine by themselves if they are between -8..7, if a constant is
 *        not in that range, or read with a PHV or ActionData, it has to be converted to
 *        action data
 *      - If there are two reads, then the first PHV has to be aligned bit by bit width the
 *        written PHV
 *      - The bits that are interacting with each other have to have the same general alignment
 *        in the PHV within a rotation shift.
 *      - PHV to PHV modification cannot have any holes in the PHV container, action data can
 *        have holes through a bitmasked-set
 */
void InstructionAdjustment::verify_all_constraints(ContainerProcess &cont_proc,
                                                   cstring action_name, PHV::Container container) {
    auto &counts = cont_proc.counts;

    if (counts[ActionParam::PHV] > 2) {
        ERROR("In action " << action_name << " of table " << tbl->name << ", there is an "
              << "impossible action over container " << container.toString() << " as more than"
              << "two PHVs are required by the container.");
        cont_proc.unhandled_action = true;
        return;
    }

    if (counts[ActionParam::PHV] == 2) {
        if (counts[ActionParam::ACTIONDATA] > 0 || counts[ActionParam::CONSTANT] > 0) {
            ERROR("In action " << action_name << " of table " << tbl->name << ", there is an "
                  << "impossible action over container " << container.toString() << " as "
                  << "2 PHVs and action data are required.");
            cont_proc.unhandled_action = true;
            return;
        }
        bool one_aligned = false;
        for (auto &container_read_phv : cont_proc.total_reads_phvs) {
            auto &total_read_phv = container_read_phv.second;
            bitvec &total_wb = total_read_phv.total_write_bits;
            bitvec &total_rb = total_read_phv.total_read_bits;
            bool is_aligned = false;
            bool failure = verify_alignment(total_wb, total_rb, container, is_aligned, cont_proc);
            if (failure)
                return;
            if (is_aligned)
                one_aligned = true;
        }

        if (one_aligned == false) {
            ERROR("In action " << action_name << " of table " << tbl->name << ", the action "
                  << "over container " << container.toString() << " has 2 PHV field reads "
                  << "and neither are aligned initially with the container.");
            cont_proc.unhandled_action = true;
            return;
        }

        if (cont_proc.operands() == 1) {
            ERROR("In action " << action_name << " of table " << tbl->name << ", the action over "
                  << "container " << container.toString() << " has 2 PHV field reads "
                  " and requires a deposit field, which is currently unhandled.");
            cont_proc.unhandled_action = true;
            return;
        }
    }

    if (counts[ActionParam::ACTIONDATA] > 1) {
        throw ActionFormat::failure(action_name);
    }

    if (counts[ActionParam::CONSTANT] > 1) {
        ERROR("In action " << action_name << "of table " << tbl->name << ", the action over "
              << "container " << container.toString() << " requires multiple constants, and "
              << " cannot be handled yet.");
        cont_proc.unhandled_action = true;
        return;
    }

    if (counts[ActionParam::ACTIONDATA] > 0 && counts[ActionParam::CONSTANT] > 0) {
        ERROR("In action " << action_name << " of table " << tbl->name << ", the action over "
              << "container " << container.toString() << " needs to backtrack as a "
              << "constant has to be set up as action data");
        cont_proc.unhandled_action = true;
        return;
    }

    if (counts[ActionParam::PHV] == 1) {
        if (counts[ActionParam::CONSTANT] > 0) {
            ERROR("In action " << action_name << " of table " << tbl->name << ", the action over "
                  << "container " << container.toString() << " needs to backtrack as a constant "
                  << "has to be set up as action data for a PHV and as a deposit field.");
            cont_proc.unhandled_action = true;
            return;
        }
        if (counts[ActionParam::ACTIONDATA] > 0) {
            ERROR("In action " << action_name << " of table " << tbl->name << ", the action over "
                  << "container " << container.toString() << " needs to be set up as a deposit "
                  "field, which is currently unhandled.");
            cont_proc.unhandled_action = true;
            return;
        }
    }

    if (cont_proc.adi.total_field_affects != cont_proc.adi.field_affects) {
        ERROR("Action format does not match the placement");
    }
}

/** After the container_actions structure is built, this analyzes each of the individual actions
 *  within a container, as well as the entire action to the container as an individual object.
 *
 *  The individual checks just verify that the reads can be correctly aligned to the write PHV.
 *     - For PHVs, this means that the total read PHV is completely capture in the write
 *     - For ActionData, whether the action data format is correctly aligned with the PHV
 *     - For Constants, currently that the field is only in one container.  This will be changed
 *       at a later point
 *
 *  The total container action also goes through a large verification step, which checks
 *  general constraints on total number of PHVs, ActionData and Constants used.  It'll then
 *  mark an instruction currently impossible or not yet implemented if it is either. 
 */
void InstructionAdjustment::analyze_container_actions(cstring action_name) {
    for (auto &container_action : container_actions) {
        auto &container = container_action.first;
        auto &cont_process = container_action.second;
        bool must_be_removed = false;
        int index = 0;
        cstring instr_name;
        for (auto &instr_process : cont_process.instr_procs) {
            if (index == 0)
                instr_name = instr_process.name;
            else if (instr_name != instr_process.name)
                BUG("Multiple types of actions happening on the same container");
        }
        cont_process.name = instr_name;

        for (auto &instr_process : cont_process.instr_procs) {
            auto &write = instr_process.write;
            for (auto &read : instr_process.reads) {
                if (read.type == ActionParam::PHV
                    && !verify_phv_field(write, read, cont_process,
                                         cont_process.counts[ActionParam::PHV])) {
                    ERROR("In action " << action_name << " of table " << tbl->name << ", a PHV "
                          << "alignment over container " << container.toString()
                          << " is deemed completely impossible for alignment issue.");
                    cont_process.unhandled_action = true;
                } else if (read.type == ActionParam::ACTIONDATA
                           && !verify_action_data(write, read, action_name, cont_process.adi,
                                                  cont_process.counts[ActionParam::ACTIONDATA],
                                                  container)) {
                    throw ActionFormat::failure(action_name);
                    ///> At some point, we may want to collect all of this information and then
                    ///> run a backtrack on all of these pieces, such as the knowledge to convert
                    ///> certain constants to ActionData
                } else if (read.type == ActionParam::CONSTANT
                           && !verify_constant(write, read,
                                               cont_process.counts[ActionParam::CONSTANT])) {
                    ERROR("In action " << action_name << " of table " << tbl->name << ", a "
                          << "constant is required to be split at " << container.toString()
                          << " which is currently not supported");
                    cont_process.unhandled_action = true;
                }
                /*
                if (read.is_split())
                    must_be_removed = true;
                */
            }

            if (write.is_split) {
                must_be_removed = true;
            }
        }
        verify_all_constraints(cont_process, action_name, container);

        if (cont_process.instr_procs.size() > 1) {
            must_be_removed = true;
        }

        if (must_be_removed)
            cont_process.requires_adjustment = true;
    }
}

const IR::MAU::Instruction *InstructionAdjustment::preorder(IR::MAU::Instruction *instr) {
    written_field = nullptr;
    return instr;
}

const IR::ActionArg *InstructionAdjustment::preorder(IR::ActionArg *arg) {
    prune();
    return arg;
}

const IR::Constant *InstructionAdjustment::preorder(IR::Constant *constant) {
    prune();
    return constant;
}

const IR::Primitive *InstructionAdjustment::preorder(IR::Primitive *prim) {
    prune();
    return prim;
}

const IR::Expression *InstructionAdjustment::preorder(IR::Expression *expr) {
    if (auto *field = phv.field(expr)) {
        if (isWrite()) {
           if (written_field != nullptr)
               ERROR("Multiple writes in a single instruction?");
           else
               written_field = field;
        }
    } else {
        ERROR("Unhandled type of Expression");
    }
    prune();
    return expr;
}

/** Essentially if the instruction has been marked for removal by analyze_container_actions,
 *  this postorder will remove these instructions, and save them for either recombination or
 *  splitting
 */
const IR::MAU::Instruction *InstructionAdjustment::postorder(IR::MAU::Instruction *instr) {
    if (written_field == nullptr) {
        ERROR("No write contained in the instruction");
        return instr;
    }

    int index = 0;
    bool remove = false;
    for (auto alloc : written_field->alloc) {
        if (index == 0)
            remove = container_actions.at(alloc.container).requires_adjustment;
        else if (remove != container_actions.at(alloc.container).requires_adjustment)
            BUG("Somehow only part of the instruction is to be removed");
    }

    if (remove) {
        for (auto alloc : written_field->alloc) {
            removed_instrs[alloc.container].push_back(instr);
        }
        return nullptr;
    } else {
        return instr;
    }
}

/** Builds the MultiOperand structure from all of the particular reads or writes.  Right now,
 *  has no support for any deposit field, which will obviously have to change in later
 *  iterations
 */
void InstructionAdjustment::combine_cont_instr(ContainerProcess &cont_proc,
    MultiOperandInfo &mo, PHV::Container container) {
    IR::Vector<IR::Expression> components;
    mo.write = new IR::MAU::MultiOperand(components, container.toString(), true);

    if (cont_proc.operands() == 2) {
        BUG("Cannot yet handle 2 operand combinations within an action");
    } else {
        if (cont_proc.total_types() >= 2) {
            BUG("Not yet handling deposit fields of multiple things");
        } else if (cont_proc.counts[ActionParam::ACTIONDATA] == 1) {
            mo.reads.push_back(new IR::MAU::MultiOperand(components,
                               cont_proc.adi.action_data_name, false));
        } else if (cont_proc.counts[ActionParam::PHV] == 1) {
            for (auto &read_phv_info : cont_proc.total_reads_phvs) {
                mo.reads.push_back(new IR::MAU::MultiOperand(components,
                                   read_phv_info.first.toString(), true));
            }
        }
    }

    for (auto &instr_proc : cont_proc.instr_procs) {
        mo.write->push_back(instr_proc.write.expr);
        for (auto &read : instr_proc.reads) {
            int index = 0;
            if (cont_proc.total_types() == 1)
                index = 0;
            else if (cont_proc.counts[ActionParam::PHV] == 2)
                // FIXME: This will have to be solved eventually for deposit field
                index = 1;
            else if (read.type == ActionParam::ACTIONDATA)
                index = 1;
            mo.reads[index]->push_back(read.expr);
        }
    }
}

/** The function will either split instructions affecting multiple containers, or combine
 *  instructions that affect the same container into one container.  Will probably be have
 *  to be modified in order to handle all types of instructions, such as deposit fields.
 */
void InstructionAdjustment::perform_simple_split(ContainerProcess &cont_proc,
        IR::MAU::Action *act, PHV::Container container) {
    ///> If the instruction requires a combination of original field instructions
    if (cont_proc.instr_procs.size() > 1) {
        MultiOperandInfo mo;
        combine_cont_instr(cont_proc, mo, container);
        IR::MAU::Instruction *combined_instr = new IR::MAU::Instruction(cont_proc.name);
        bitvec total_write = cont_proc.total_write();
        if (static_cast<size_t>(total_write.popcount()) == container.size()) {
            combined_instr->operands.push_back(mo.write);
        } else {
            int lo = total_write.min().index();
            int hi = total_write.max().index();
            combined_instr->operands.push_back(MakeSlice(mo.write, lo, hi));
        }
        for (auto &read : mo.reads) {
            ///> Potentially trying to split the MultiOperand
            if (read->is_phv) {
                for (auto &total_read : cont_proc.total_reads_phvs) {
                    auto read_container = total_read.first;
                    if (read_container.toString() != read->name) continue;
                    bitvec read_bits = total_read.second.total_read_bits;
                    if (static_cast<size_t>(read_bits.popcount()) == container.size()) {
                        combined_instr->operands.push_back(read);
                    } else {
                        int lo = read_bits.min().index();
                        int hi = read_bits.max().index();
                        combined_instr->operands.push_back(MakeSlice(read, lo, hi));
                    }
                }
            } else {
                bitvec read_bits = cont_proc.adi.total_read_bits;
                if (static_cast<size_t>(read_bits.popcount()) == container.size()) {
                    combined_instr->operands.push_back(read);
                } else {
                    int lo = read_bits.min().index();
                    int hi = read_bits.max().index();
                    combined_instr->operands.push_back(MakeSlice(read, lo, hi));
                }
            }
        }
        act->action.push_back(combined_instr);
    ///> If the instruction is only one split of an instruction, as a too large of a field
    } else {
        auto old_instr = removed_instrs[container].at(0);
        IR::MAU::Instruction *container_instr
            = new IR::MAU::Instruction(old_instr->srcInfo, cont_proc.name);

        for (auto &instr_proc : cont_proc.instr_procs) {
            auto &write = instr_proc.write;
            if (write.is_split) {
                container_instr->operands.push_back(MakeSlice(write.expr, write.lo, write.hi));
            } else {
                BUG("Masking issues.  Cannot yet be handled by this.");
            }
            for (auto read : instr_proc.reads) {
                if (read.is_split) {
                    container_instr->operands.push_back(MakeSlice(read.expr, read.lo, read.hi));
                } else {
                    container_instr->operands.push_back(read.expr);
                }
            }
        }
        act->action.push_back(container_instr);
    }
}

/** This section analyzes the instructions that have been previously removed, and then, if the
 *  adjustment phase is implemented, they are adjusted within a container by container basis.
 *  If the adjustment is currently too not implemented, then the original instructions are
 *  added back in.  These non-implemented instructions will not assemble, but they won't
 *  introduce a ton of new FAILs into the test suite.
 *
 *  Currently not implemented:
 *      - Anything that requires a deposit_field instruction
 *      - Anything that requires a bitmasked-set instruction
 *      - Constant that need to be adjusted into action data
 */
const IR::MAU::Action *InstructionAdjustment::postorder(IR::MAU::Action *act) {
    for (auto &container_action : container_actions) {
        auto container = container_action.first;
        auto &cont_proc = container_action.second;
        if (!cont_proc.requires_adjustment) continue;

        if (cont_proc.unhandled_action) {
            for (auto *instr : removed_instrs[container])
                act->action.push_back(instr);
            continue;
        }
        // FIXME: Everything that can be done is only a simple split
        perform_simple_split(cont_proc, act, container);
    }
    return act;
}

const IR::MAU::Table *TotalInstructionAdjustment::preorder(IR::MAU::Table *tbl) {
    for (auto &action : Values(tbl->actions)) {
        action = action->apply(InstructionAdjustment(phv, tbl))->to<IR::MAU::Action>();
    }
    return tbl;
}

