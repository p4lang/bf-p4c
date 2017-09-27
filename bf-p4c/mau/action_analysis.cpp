#include "action_analysis.h"
#include "resource.h"
#include "bf-p4c/common/slice.h"

void ActionAnalysis::initialize_phv_field(const IR::Expression *expr) {
    if (!phv.field(expr))
        return;

    if (isWrite()) {
        if (field_action.write_found) {
            BUG("Multiple write in a single instruction?");
        }
        ActionParam write(ActionParam::PHV, expr);
        field_action.setWrite(write);
    } else {
        field_action.reads.emplace_back(ActionParam::PHV, expr);
    }
}

void ActionAnalysis::initialize_action_data(const IR::Expression *expr) {
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, expr);
}

/** Similar to phv.field, it returns the IR structure that corresponds to actiondata,
 *  If it is an ActionArg, then the type is ACTIONDATA
 *  If it is an ActionDataConstant, then the type is CONSTANT
 */
const IR::Expression *ActionAnalysis::isActionParam(const IR::Expression *e,
        bitrange *bits_out, ActionParam::type_t *type) {
    bitrange bits = { 0, e->type->width_bits() - 1};
    if (auto *sl = e->to<IR::Slice>()) {
        bits.lo = sl->getL();
        bits.hi = sl->getH();
        e = sl->e0;;
        if (e->is<IR::MAU::ActionDataConstant>())
            BUG("No ActionDataConstant should be a member of a Slice");
    }
    if (e->is<IR::ActionArg>() || e->is<IR::MAU::ActionDataConstant>()) {
        if (bits_out)
            *bits_out = bits;
        if (e->is<IR::ActionArg>() && type)
            *type = ActionParam::ACTIONDATA;
        if (e->is<IR::MAU::ActionDataConstant>() && type)
            *type = ActionParam::CONSTANT;
        return e;
    }
    return nullptr;
}

void ActionAnalysis::ActionParam::dbprint(std::ostream &out) const {
    out << expr;
}

const IR::Expression *ActionAnalysis::ActionParam::unsliced_expr() const {
    if (expr == nullptr)
        return expr;
    if (auto *sl = expr->to<IR::Slice>())
        return sl->e0;
    return expr;
}

void ActionAnalysis::FieldAction::dbprint(std::ostream &out) const {
    out << name << " ";
    out << write;
    for (auto read : reads)
        out << ", " << read;
}

bool ActionAnalysis::preorder(const IR::MAU::Instruction *instr) {
    field_action.clear();
    field_action.name = instr->name;
    return true;
}

bool ActionAnalysis::preorder(const IR::ActionArg *arg) {
    if (!findContext<IR::MAU::Instruction>())
        return false;

    initialize_action_data(arg);
    return false;
}

bool ActionAnalysis::preorder(const IR::Constant *constant) {
    field_action.reads.emplace_back(ActionParam::CONSTANT, constant);
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::ActionDataConstant *adc) {
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, adc);
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::HashDist *) {
    // Currently unhandled
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::AttachedOutput *) {
    // ignore these for now as well
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::StatefulAlu *) {
    return false;
}

bool ActionAnalysis::preorder(const IR::Primitive *) {
    return false;
}

bool ActionAnalysis::preorder(const IR::Slice *sl) {
    if (phv.field(sl)) {
        initialize_phv_field(sl);
    } else if (isActionParam(sl)) {
        initialize_action_data(sl);
    } else {
        ERROR("Slice is of IR structure not handled by ActionAnalysis");
    }
    // Constants should not be in slices ever, they should just be either refactored into
    // action data, or already separately split constants with different values
    return false;
}

bool ActionAnalysis::preorder(const IR::Expression *expr) {
    if (phv.field(expr)) {
        initialize_phv_field(expr);
    } else {
        ERROR("IR structure not yet handled by the ActionAnalysis pass");
    }
    return false;
}


/** Responsible for adding the instruction into which containers they actually affect.
 *  Thus multiple field based actions can be added to the same container, and then evalauted
 *  later.
 */
void ActionAnalysis::postorder(const IR::MAU::Instruction *instr) {
    if (!field_action.write_found) {
        ERROR("Nothing written in the instruction " << instr);
    }

    if (phv_alloc) {
        bitrange bits;

        auto *field = phv.field(field_action.write.expr, &bits);
        int split_count = 0;
        field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &) {
            split_count++;
        });

        bool split = true;
        if (split_count == 1)
            split = false;
        if (split_count == 0)
            ERROR("PHV not allocated for this field");
        if (split_count > 1 && field_action.write.expr->is<IR::Slice>())
            BUG("Unhandled action bitmask constraint");

        field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &alloc) {
            auto container = alloc.container;
            if (container_actions_map->find(container) == container_actions_map->end()) {
                ContainerAction cont_action;
                container_actions_map->emplace(container, cont_action);
            }
            if (!split) {
                (*container_actions_map)[container].field_actions.push_back(field_action);
            } else {
                FieldAction field_action_split;
                field_action_split.name = field_action.name;
                field_action_split.requires_split = true;
                auto *write_slice = MakeSlice(field_action.write.expr, alloc.field_bit,
                                              alloc.field_hi());
                ActionParam write_split(field_action.write.type, write_slice);
                field_action_split.setWrite(write_split);
                for (auto &read : field_action.reads) {
                    auto read_slice = MakeSlice(read.expr, alloc.field_bit, alloc.field_hi());
                    field_action_split.reads.emplace_back(read.type, read_slice);
                }
                (*container_actions_map)[container].field_actions.push_back(field_action_split);
            }
        });
    } else {
        (*field_actions_map)[instr] = field_action;
    }
}

/** PHV allocation is not known by the time of this verification.  This check just guarantees
 *  that the action is even at all possible within Tofino.  If not, the compiler should just
 *  fail at this point.
 */
bool ActionAnalysis::verify_P4_action_without_phv() {
    ordered_set<const PhvInfo::Field *> written_fields;
    for (auto field_action_info : *field_actions_map) {
        auto &field_action = field_action_info.second;
        if (written_fields.find(phv.field(field_action.write.expr)) != written_fields.end())
            ERROR("Tofino action has repeated lvalue.");
        written_fields.insert(phv.field(field_action.write.expr));

        int non_phv_count = 0;
        for (auto read : field_action.reads) {
            if (read.type == ActionParam::ACTIONDATA || read.type == ActionParam::CONSTANT)
                non_phv_count++;
            if (non_phv_count > 1)
                ERROR("Action requires multiple action data parameters, requiring a split");
        }

        for (auto read : field_action.reads) {
            if (read.type == ActionParam::CONSTANT) continue;
            if (read.size() != field_action.write.size())
                ERROR("Sizing of the write and read do not match up");
        }
    }

    return true;
}

/** This function checks the alignment of PHV reads to PHV writes, on an instruction by
 *  instruction basis.  Essentially if the PHV read is spread across multiple container while
 *  the write is only in one container, this action is impossible.  This verifies that the
 *  read is within one container, and adds container alignment information to the
 *  phv_alignment structure.
 */
bool ActionAnalysis::verify_phv_read_instr(const ActionParam &write, const ActionParam &read,
        ContainerAction &cont_action) {
    if (read.expr->type->width_bits() != write.expr->type->width_bits()) {
        // Have to handle IR::Cast eventually
        return false;
    }

    bitrange read_range;
    bitrange write_range;
    auto *read_field = phv.field(read.expr, &read_range);
    auto *write_field = phv.field(write.expr, &write_range);

    if (read_field == nullptr || write_field == nullptr)
        return false;


    int read_count = 0;
    bitvec write_bits;  bitvec read_bits;
    PHV::Container read_container;
    read_field->foreach_alloc(read_range, [&](const PhvInfo::Field::alloc_slice &alloc) {
        read_count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        read_bits.setrange(alloc.container_bit, alloc.width);
        read_container = alloc.container;
    });

    if (read_count > 1) {
        return false;
    }

    int write_count = 0;
    write_field->foreach_alloc(write_range, [&](const PhvInfo::Field::alloc_slice &alloc) {
        write_count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        write_bits.setrange(alloc.container_bit, alloc.width);
    });

    if (write_count > 1)
        BUG("Instruction has issue with splitting writes?");

    auto &phv_alignment = cont_action.phv_alignment;
    if (phv_alignment.find(read_container) == phv_alignment.end()) {
        TotalAlignment ta;
        ta.add_alignment(write_bits, read_bits);
        phv_alignment[read_container] = ta;
        cont_action.counts[ActionParam::PHV]++;
    } else {
        phv_alignment[read_container].add_alignment(write_bits, read_bits);
    }

    return true;
}

/** This function checks whether or not the action data in a function can correctly line up with
 *  All action data within an individual container
 *  the PHV write.  If the action data size does not match up with the PHV write or alignment
 *  issues are found, then this function returns false.  This should only be true if the
 *  action data was allocated before PHV allocation.  If the function returns false, it should
 *  backtrack to action_format in order to have a correct action format.
 *
 *  This function is only called if action data has been allocated.  It also holds alignment
 *  information in the ActionDataInfo structure.
 */

bool ActionAnalysis::verify_action_data_instr(const ActionParam &write, const ActionParam &read,
         ContainerAction &cont_action, cstring action_name, PHV::Container container) {
    auto &action_format = tbl->resources->action_format;

    auto &placements = action_format.arg_placement.at(action_name);
    const safe_vector<ActionFormat::ActionDataPlacement> *action_data_format = nullptr;
    const safe_vector<ActionFormat::ActionDataPlacement> *immediate_format = nullptr;
    action_data_format = &(action_format.action_data_format.at(action_name));

    if (tbl->layout.action_data_bytes_in_overhead > 0)
        immediate_format = &(action_format.immediate_format.at(action_name));

    bitrange read_range;
    ActionParam::type_t type = ActionParam::ACTIONDATA;
    auto action_arg = isActionParam(read.expr, &read_range, &type);
    if (action_arg == nullptr)
        BUG("Action argument not converted correctly");

    cstring arg_name;
    if (type == ActionParam::ACTIONDATA)
        arg_name = action_arg->to<IR::ActionArg>()->name;
    else if (type == ActionParam::CONSTANT)
        arg_name = action_arg->to<IR::MAU::ActionDataConstant>()->name;

    auto pair = std::make_pair(arg_name, read_range.lo);
    if (placements.find(pair) == placements.end())
        return false;
    auto &arg_placement = placements.at(pair);
    bool is_immediate;


    bitrange write_range;
    bitvec write_bits;
    int write_count = 0;
    auto *write_field = phv.field(write.expr, &write_range);

    write_field->foreach_alloc(write_range, [&](const PhvInfo::Field::alloc_slice &alloc) {
        write_count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        write_bits.setrange(alloc.container_bit, alloc.width);
    });

    if (write_count > 1)
        BUG("Instruction has issue with splitting writes?");

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

            if (!(lo <= read_range.lo && hi >= read_range.hi)) continue;
            auto &adi = cont_action.adi;

            if (cont_action.counts[ActionParam::ACTIONDATA] == 0) {
                adi.initialize(adp.get_action_name(), is_immediate, adp.start,
                               adp.arg_locs.size());
                adi.ad_alignment.add_alignment(write_bits, arg_loc.data_loc);
                cont_action.counts[ActionParam::ACTIONDATA] = 1;
            } else if (adi.start != adp.start || adi.immediate != is_immediate) {
                cont_action.counts[ActionParam::ACTIONDATA]++;
            } else {
                adi.field_affects++;
                adi.ad_alignment.add_alignment(write_bits, arg_loc.data_loc);
            }
            return true;
        }
    }
    return false;
}

/** This is a check to guarantee that the instruction using a constant is being setup
 *  correctly, and if so, saves information about the value of this constant so that
 *  
 */
bool ActionAnalysis::verify_constant_instr(const ActionParam &write, const ActionParam &read,
         ContainerAction &cont_action) {
    if (cont_action.is_shift()) {
        return true;
    }

    bitrange write_range;
    bitvec write_bits;
    int write_count = 0;
    auto *write_field = phv.field(write.expr, &write_range);

    write_field->foreach_alloc(write_range, [&](const PhvInfo::Field::alloc_slice &alloc) {
        write_count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        write_bits.setrange(alloc.container_bit, alloc.width);
    });

    if (write_count > 1)
        BUG("Instruction has issue with splitting writes?");
    auto *constant = read.expr->to<IR::Constant>();
    if (constant == nullptr)
        return false;

    if (!cont_action.constant_set) {
        cont_action.constant_used = constant->asInt();
        cont_action.constant_set = true;
    }

    cont_action.constant_alignment.add_alignment(write_bits, write_bits);
    cont_action.counts[ActionParam::CONSTANT]++;
    return true;
}

/** Action data analysis before action data has been fully allocated to spaces in an action
 *  data table.  The alignment is still check by the tofino compliance, in case we need
 *  to configure bitmasked-sets/PHV allocation will not work.  This simply sets up
 *  the ability to do Tofino compliance.
 */
void ActionAnalysis::action_data_align(const ActionParam &write, ContainerAction &cont_action) {
    bitrange write_range;
    bitvec write_bits;
    int write_count = 0;
    auto *write_field = phv.field(write.expr, &write_range);
    write_field->foreach_alloc(write_range, [&](const PhvInfo::Field::alloc_slice &alloc) {
        write_count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        write_bits.setrange(alloc.container_bit, alloc.width);
    });

    if (write_count > 1)
        BUG("Instruction has issue with splitting writes?");

    auto &adi = cont_action.adi;
    // Assume write happens at the same point.  This may be changed by action_format after
    // it is determined
    adi.ad_alignment.add_alignment(write_bits, write_bits);
    cont_action.counts[ActionParam::ACTIONDATA] = 1;
}

/** After the container_actions_map structure is built, this analyzes each of the individual actions
 *  within a container, as well as the entire action to the container as an individual object.
 *  PHV allocation is assumed to be completed at this point.
 *
 *  The individual checks just verify that the reads can be correctly aligned to the write PHV.
 *     - For PHVs, this means that the total read PHV is completely capture in the write
 *     - For ActionData, whether the action data format is correctly aligned with the PHV
 *     - For Constants, TBD
 *
 *  The total container action also goes through a large verification step, which checks
 *  general constraints on total number of PHVs, ActionData and Constants used.  It'll then
 *  mark an instruction currently impossible or not yet implemented if it is either. 
 */
bool ActionAnalysis::verify_P4_action_with_phv(cstring action_name) {
    for (auto &container_action : *container_actions_map) {
        auto &container = container_action.first;
        auto &cont_action = container_action.second;
        cstring instr_name;
        int index = 0;
        for (auto &field_action : cont_action.field_actions) {
            if (index == 0)
                instr_name = field_action.name;
            else if (instr_name != field_action.name)
                cont_action.error_code |= ContainerAction::MULTIPLE_CONTAINER_ACTIONS;
        }

        cont_action.name = instr_name;
        for (auto &field_action : cont_action.field_actions) {
            auto &write = field_action.write;
            for (auto &read : field_action.reads) {
                if (read.type == ActionParam::PHV
                    && !verify_phv_read_instr(write, read, cont_action)) {
                    cont_action.error_code |= ContainerAction::READ_PHV_MISMATCH;
                } else if (read.type == ActionParam::ACTIONDATA) {
                    if (ad_alloc) {
                       if (!verify_action_data_instr(write, read, cont_action, action_name,
                                                     container)) {
                            cont_action.error_code |= ContainerAction::ACTION_DATA_MISMATCH;
                       }
                    } else {
                       action_data_align(write, cont_action);
                    }
                } else if (read.type == ActionParam::CONSTANT) {
                    // Probably need a verify constant
                    if (!verify_constant_instr(write, read, cont_action))
                        cont_action.error_code |= ContainerAction::CONSTANT_MISMATCH;
                }
            }
        }
        if (cont_action.error_code != ContainerAction::NO_PROBLEM)
            continue;

        bool verify = check_constant_to_actiondata(cont_action, container);
        if (!verify)
            continue;
        verify = verify_container_action(cont_action, container);
        if (!verify)
            continue;
    }

    for (auto &container_action : *container_actions_map) {
        auto &cont_action = container_action.second;
        if ((cont_action.error_code & ContainerAction::ACTION_DATA_MISMATCH) != 0
            || (cont_action.error_code & ContainerAction::MULTIPLE_ACTION_DATA) != 0) {
            action_data_misaligned = true;
            break;
        }
    }
    return true;
}

/** Is the bitvec rotationally contiguous, and thus can it perform as a read in a PHV set.
    Unused but useful, so kept
 */
/*
bool ActionAnalysis::ContainerAction::is_contig_rotate(bitvec check, int &shift, int size) {
    shift = 0;
    int start = check.ffs();
    int end = check.ffz(start);

    if (end == check.max().index())
        return true;

    int second_start = check.ffs(end);
    int second_end = check.ffz(second_start);

    if (start == 0 && second_end == size) {
        shift = end - start;
        return true;
    }
    return false;
}
*/

/** Rotate a bitvec so that it is now contiguous, rather than rotationally contiguous.  Not used
 *  yet as it is too difficult within the IR::Slice process.
 */
/*
bitvec ActionAnalysis::ContainerAction::rotate_contig(bitvec orig, int shift, int size) {
    bitvec subtract(0, shift);
    bitvec rv = (orig - subtract) << shift;

    rv |= (subtract >> (size - shift));
    return rv;
}
*/


bitvec ActionAnalysis::ContainerAction::total_write() const {
    bitvec total_write_;
    for (auto tot_align_info : phv_alignment)
        total_write_ |= tot_align_info.second.write_bits;
    total_write_ |= adi.ad_alignment.write_bits;
    total_write_ |= constant_alignment.write_bits;

    return total_write_;
}

bool ActionAnalysis::ContainerAction::verify_one_alignment(TotalAlignment &tot_alignment,
        int size, int &unaligned_count, bool bitmasked_set) {
    (void) size;
    if (tot_alignment.write_bits.popcount() != tot_alignment.read_bits.popcount()) {
        error_code |= IMPOSSIBLE_ALIGNMENT;
        return false;
    }

    if (!bitmasked_set &&
       (!tot_alignment.write_bits.is_contiguous() || !tot_alignment.read_bits.is_contiguous())) {
        // FIXME: Eventually can support rotational shifts, but not yet with IR::Slice setup
        // || !is_contig_rotate(tot_alignment.read_bits, read_rot_shift, size)) {
        error_code |= IMPOSSIBLE_ALIGNMENT;
        return false;
    }

    if ((tot_alignment.write_bits - tot_alignment.read_bits).popcount() != 0)
        unaligned_count++;
    return true;
    /*
    // FIXME: Verify on an individual field by field basis on the instruction on alignment
    bitvec write_rotate = rotate_contig(tot_alignment.write_bits, write_rot_shift, size);
    bitvec read_rotate = rotate_contig(tot_alignment.read_bits, read_rot_shift, size);
    */
}

/** Checks that the alignment of the of the reads and writes within a PHV container are possible
 *  given the action that was going to run within the container.  With this restriction, only
 *  one field in a set can be unaligned, and if the set contains action data, then no
 *  PHVs can be unaligned.
 */
bool ActionAnalysis::ContainerAction::verify_all_alignment(bool bitmasked_set) {
    int unaligned_count = 0;

    if (bitmasked_set && phv_alignment.size() > 0)
        P4C_UNIMPLEMENTED("Alignment check of bitmasked-set with a PHV background unsupported");

    for (auto &tot_align_info : phv_alignment) {
        auto &curr_container = tot_align_info.first;
        auto &tot_alignment = tot_align_info.second;
        // Verify on an individual field by field basis on the instruction on alignment
        bool verify = verify_one_alignment(tot_alignment, curr_container.size(),
                                           unaligned_count, bitmasked_set);
        if (!verify)
            return false;
    }

    int max_unaligned;
    if (name == "set" && counts[ActionParam::PHV] == 2)
        max_unaligned = 1;
    else if (name == "set" && counts[ActionParam::PHV] == 1 && total_types() == 1)
        max_unaligned = 1;
    else
        max_unaligned = 0;

    if (unaligned_count > max_unaligned) {
        error_code |= IMPOSSIBLE_ALIGNMENT;
        return false;
    }

    if (counts[ActionParam::ACTIONDATA] > 0) {
        bool verify = verify_one_alignment(adi.ad_alignment, adi.size, unaligned_count,
                                           bitmasked_set);
        if (!verify)
            return false;

        if (bitmasked_set && unaligned_count > 0)
            return false;
    }
    return true;
}

/** Checks to see if all bits of the container will be affected, could be updated for liveness
 *  or unused container space as well with more support from PHV allocation
 */
bool ActionAnalysis::ContainerAction::total_overwritten(PHV::Container container) {
    bitvec total_write_bits;
    for (auto &tot_align_info : phv_alignment) {
        total_write_bits |= tot_align_info.second.write_bits;
    }

    total_write_bits |= adi.ad_alignment.write_bits;
    total_write_bits |= constant_alignment.write_bits;

    if (total_write_bits.popcount() != static_cast<int>(container.size()))
        return false;

    return true;
}

/** A verification of the constant used in a ContainerAction to make sure that it can
 *  be used without being converted to action data
 */
bool ActionAnalysis::tofino_instruction_constant(int value, int max_shift, int container_size) {
    int max_value = (1 << max_shift);
    int complement = (1 << (container_size - 1));

    if ((value <= max_value - 1 && value >= -max_value)
        || value >= complement - max_value || value <= -complement + max_value - 1)
        return true;
    return false;
}

/** A check to guarantee that the use of constant is legal in the action within a container.
 *  The constant does not have to be converted to action data if:
 *
 *  the constant is used in a set instruction
 *      - if the constant covers the whole container, when the container is 8 or 16 bit size
 *      - if the constant covers the whole container, the container is a 32 bit size, and
 *        the constant is between -(2^19) <= value <= 2^19 - 1
 *      - if the constant doesn't cover the whole container, and the constant is between
 *        -8 <= value <= 7
 *
 *  the constant is used in another instruction, where the constant convers the whole container,
 *  and the constant is between -8 <= value <= 7
 *
 *  This range also applies to the complement of the range i.e. an 8 bit container converts to
 *  value >= 255 - 7 OR value < -255 + 8
 *
 *  These ranges are due to instruction formats of load-consts, and one of the src fields in
 *  every instruction
 *
 *  A constant must be converted to action data if it doesn't meet the requirements, or:
 *      - the container also requires action data
 *      - multiple constants are used
 */
bool ActionAnalysis::check_constant_to_actiondata(ContainerAction &cont_action,
        PHV::Container container) {
    auto &counts = cont_action.counts;

    if (counts[ActionParam::CONSTANT] == 1
        && cont_action.constant_alignment.write_bits.popcount()
           != static_cast<int>(container.size())) {
        if (!cont_action.constant_set)
            BUG("Constant not setup by the program correctly");

        if (cont_action.name == "set") {
            if (!(tofino_instruction_constant(cont_action.constant_used, CONST_SRC_MAX,
                  container.size()))) {
                cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
                return false;
            }
        } else {  // At this point probably impossible
            cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
            return false;
        }
    }

    if (counts[ActionParam::CONSTANT] == 1) {
        // Load const constraint
        if (!cont_action.constant_set)
            BUG("Constant not setup by the program correctly");

        if (cont_action.name == "set") {
            if (container.size() == 32 &&
                !(tofino_instruction_constant(cont_action.constant_used, LOADCONST_MAX,
                  container.size()))) {
                cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
                return false;
            }
        } else if (cont_action.operands() == 2) {
            if (!(tofino_instruction_constant(cont_action.constant_used, CONST_SRC_MAX,
                container.size()))) {
                cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
                return false;
            }
        }
    }


    // Could be combined into one constant potentially, rather than converted into action_data
    if (counts[ActionParam::CONSTANT] > 1) {
        cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
        cont_action.constant_to_ad = true;
        return false;
    }

    if (counts[ActionParam::ACTIONDATA] > 0 && counts[ActionParam::CONSTANT] > 0) {
        cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
        cont_action.unhandled_action = true;
        return false;
    }

    if (counts[ActionParam::ACTIONDATA] > 1 && ad_alloc) {
        cont_action.error_code |= ContainerAction::MULTIPLE_ACTION_DATA;
        return false;
    }

    return true;
}

/** Specifically for checking instruction that use 2 PHV fields as sources.  Must be converted
 *  to a deposit-field if necessary
 */
bool ActionAnalysis::check_2_PHV_instruction(ContainerAction &cont_action,
                                             PHV::Container container) {
    auto &counts = cont_action.counts;
    if (counts[ActionParam::ACTIONDATA] > 0 || counts[ActionParam::CONSTANT] > 0) {
        cont_action.error_code |= ContainerAction::TOO_MANY_SOURCES;
        cont_action.impossible = true;
        return false;
    }

    if (cont_action.name == "set")
        cont_action.to_deposit_field = true;

    if (!cont_action.verify_all_alignment()) {
        cont_action.impossible = true;
        return false;
    }

    if (!cont_action.total_overwritten(container)) {
        cont_action.impossible = true;
        return false;
    }
    return true;
}

/** Checks instructions that only have 1 PHV field as a source.  Second source may not be used,
 *  or may be action data/constant.  Sets in the second case are converted to deposit-field
 */
bool ActionAnalysis::check_1_PHV_instruction(ContainerAction &cont_action,
                                             PHV::Container container) {
    auto &counts = cont_action.counts;
    if (cont_action.name == "set") {
        if (counts[ActionParam::CONSTANT] > 0) {
            cont_action.to_deposit_field = true;
            cont_action.constant_to_ad = true;
            if (!(cont_action.verify_all_alignment() && cont_action.total_overwritten(container)))
                return false;
            cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
            return false;
        } else if (counts[ActionParam::ACTIONDATA] > 0) {
            cont_action.to_deposit_field = true;
            if (!cont_action.verify_all_alignment() && cont_action.total_overwritten(container))
                return false;
        } else if (!cont_action.verify_all_alignment()) {
            return false;
        }
    } else {
        // Not converted to a deposit-fieldd
        if (!cont_action.total_overwritten(container)) {
            return false;
        }
    }
    return true;
}

/** Verification of instructions that use no PHV sources, specifically only action data.
 *  If the action data is not contiguous, must be transformed to a bitmasked-set
 */
bool ActionAnalysis::check_0_PHV_instruction(ContainerAction &cont_action) {
    auto &counts = cont_action.counts;
    // In theory, bitmasked-set could have a single PHV source, but Glass equivalency?
    if (cont_action.name == "set") {
        if (counts[ActionParam::ACTIONDATA] > 0 || counts[ActionParam::CONSTANT] > 0) {
            bitvec all_ad = cont_action.adi.ad_alignment.write_bits;
            all_ad |= cont_action.constant_alignment.write_bits;
            if (!all_ad.is_contiguous()) {
                cont_action.to_bitmasked_set = true;
            }
        }
    }

    if (!cont_action.verify_all_alignment(cont_action.to_bitmasked_set)) {
        return false;
    }
    return true;
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
bool ActionAnalysis::verify_container_action(ContainerAction &cont_action,
        PHV::Container container) {
    auto &counts = cont_action.counts;

    if (cont_action.adi.total_field_affects != cont_action.adi.field_affects) {
        ERROR("Action format does not match the placement");
    }

    if (counts[ActionParam::PHV] > 2) {
        cont_action.error_code |= ContainerAction::TOO_MANY_SOURCES;
        cont_action.impossible = true;
        return false;
    }

    if (counts[ActionParam::PHV] == 2) {
        return check_2_PHV_instruction(cont_action, container);
    }

    if (counts[ActionParam::PHV] == 1) {
        return check_1_PHV_instruction(cont_action, container);
    }

    if (counts[ActionParam::PHV] == 0) {
        return check_0_PHV_instruction(cont_action);
    }
    return true;
}

void ActionAnalysis::verify_P4_action_for_tofino(cstring action_name) {
    if (phv_alloc)
        verify_P4_action_with_phv(action_name);
    else
        verify_P4_action_without_phv();
}

void ActionAnalysis::postorder(const IR::MAU::Action *act) {
    verify_P4_action_for_tofino(act->name);
}
