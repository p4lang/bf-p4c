#include "action_analysis.h"
#include "resource.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/device.h"
#include "bf-p4c/phv/phv_fields.h"

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
    if (field_action.reads.back().unsliced_expr()->is<IR::MAU::AttachedOutput>())
        field_action.reads.back().speciality = ActionParam::ATTACHED_OUTPUT;
    if (field_action.reads.back().unsliced_expr()->is<IR::MAU::HashDist>())
        field_action.reads.back().speciality = ActionParam::HASH_DIST;
}

/** Similar to phv.field, it returns the IR structure that corresponds to actiondata,
 *  If it is an ActionArg, HashDist, or AttachedOutput then the type is ACTIONDATA
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
    if (e->is<IR::ActionArg>() || e->is<IR::MAU::ActionDataConstant>()
        || e->is<IR::MAU::AttachedOutput>() || e->is<IR::MAU::HashDist>()) {
        if (bits_out)
            *bits_out = bits;
        if ((e->is<IR::ActionArg>() || e->is<IR::MAU::AttachedOutput>()
            || e->is<IR::MAU::HashDist>()) && type)
            *type = ActionParam::ACTIONDATA;
        if (e->is<IR::MAU::ActionDataConstant>() && type)
            *type = ActionParam::CONSTANT;
        return e;
    }
    return nullptr;
}


std::ostream &operator<<(std::ostream &out, const ActionAnalysis::ActionParam &ap) {
    out << ap.expr;
    return out;
}


const IR::Expression *ActionAnalysis::ActionParam::unsliced_expr() const {
    if (expr == nullptr)
        return expr;
    if (auto *sl = expr->to<IR::Slice>())
        return sl->e0;
    return expr;
}


std::ostream &operator<<(std::ostream &out, const ActionAnalysis::FieldAction &fa) {
    out << fa.name << " ";
    out << fa.write;
    for (auto &read : fa.reads)
        out << ", " << read;
    return out;
}

std::ostream &operator<<(std::ostream &out, const ActionAnalysis::ContainerAction &ca) {
    out << "{ ";
    for (auto &fa : ca.field_actions) {
        out << fa << "; ";
    }
    out << "}";
    return out;
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

bool ActionAnalysis::preorder(const IR::MAU::HashDist *hd) {
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, hd, ActionParam::HASH_DIST);
    return false;
}

bool ActionAnalysis::preorder(const IR::MAU::AttachedOutput *ao) {
    field_action.reads.emplace_back(ActionParam::ACTIONDATA, ao, ActionParam::ATTACHED_OUTPUT);
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

bool ActionAnalysis::preorder(const IR::Cast *) {
    BUG("No casts should ever reach this point in the Tofino backend");
}

bool ActionAnalysis::preorder(const IR::Expression *expr) {
    if (phv.field(expr)) {
        initialize_phv_field(expr);
    } else {
        BUG("IR structure not yet handled by the ActionAnalysis pass");
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
        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &) {
            split_count++;
        });

        bool split = true;
        if (split_count == 1)
            split = false;
        if (split_count == 0)
            ERROR("PHV not allocated for this field");
        if (split_count > 1 && field_action.write.expr->is<IR::Slice>())
            BUG("Unhandled action bitmask constraint");

        field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
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
                ActionParam write_split(field_action.write.type, write_slice,
                                        field_action.write.speciality);
                field_action_split.setWrite(write_split);
                for (auto &read : field_action.reads) {
                    auto read_slice = MakeSlice(read.expr, alloc.field_bit, alloc.field_hi());
                    field_action_split.reads.emplace_back(read.type, read_slice, read.speciality);
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
 *  fail at this point.  To ensure that an action is possible in Tofino:
 *    - The operation must be able to run in parallel (i.e. no repeated lvalues, a write read
 *      later in the operation)
 *    - The operands must be in the same size
 *    - Only one action data per instruction
 */
bool ActionAnalysis::verify_P4_action_without_phv(cstring action_name) {
    ordered_map<const PHV::Field *, bitvec> written_fields;

    for (auto field_action_info : *field_actions_map) {
        auto &field_action = field_action_info.second;

        // Check reads before writes for this, as field can be used in it's own instruction
        for (auto read : field_action.reads) {
            if (read.type != ActionParam::PHV) continue;
            bitrange read_bitrange = {0, 0};
            auto field = phv.field(read.expr, &read_bitrange);
            bitvec read_bits(read_bitrange.lo, read_bitrange.size());
            BUG_CHECK(field, "Cannot convert an instruction read to a PHV field reference");
            if (written_fields.find(field) == written_fields.end()) continue;
            if (written_fields[field].intersects(read_bits)) {
                ::warning("Action %s has a read of a field %s after it already has been written",
                          action_name, cstring::to_cstring(read));
                warning = true;
            }
        }

        bitrange bits = {0, 0};
        auto field = phv.field(field_action.write.expr, &bits);
        bitvec write_bits(bits.lo, bits.size());
        BUG_CHECK(field, "Cannot convert an instruction write to a PHV field reference");
        if (written_fields.find(field) != written_fields.end()) {
            if (written_fields[field].intersects(write_bits)) {
                ::warning("Action %s has repeated lvalue %s", action_name, field->name);
                warning = true;
            }
            written_fields[field] |= write_bits;
        } else {
            written_fields[field] = write_bits;
        }

        int non_phv_count = 0;
        for (auto read : field_action.reads) {
            if (read.type == ActionParam::ACTIONDATA || read.type == ActionParam::CONSTANT)
                non_phv_count++;
            if (non_phv_count > 1) {
                ::warning("In action %s, the following instruction has multiple action data "
                          "parameters: %s", action_name, cstring::to_cstring(field_action));
                warning = true;
            }
        }

        for (auto read : field_action.reads) {
            if (read.size() != field_action.write.size()) {
                ::warning("In action %s, write %s and read %s sizes do not match up",
                          action_name, cstring::to_cstring(field_action.write),
                          cstring::to_cstring(read));
                warning = true;
            }
        }
    }

    return true;
}

/** The purpose of this function is calculate the location of the alignments of both PHV
 *  and action data for a single FieldAction in a ContainerAction.  Before action data
 *  allocation (done by the ActionFormat structure), we just align the write_bits and
 *  read_bits.  After action data allocation, we pull directly from the structures that hold
 *  this information for values.
 *
 *  This function will return false if the parameters are not the same size, or if the
 *  PHV allocation is done in a way where a single read field is actually found over two
 *  PHV containers, and thus cannot be aligned by itself, i.e. a single write requires two
 *  reads.  This may be too tight, but is a good initial warning check.
 */
bool ActionAnalysis::initialize_alignment(const ActionParam &write, const ActionParam &read,
    ContainerAction &cont_action, cstring &error_message, PHV::Container container,
    cstring action_name) {
    error_message = "In the ALU operation over container " + container.toString() +
                    " in action " + action_name + ", ";
    if (write.expr->type->width_bits() != read.expr->type->width_bits()) {
        error_message += "the number of bits in the write and read aren't equal";
        cont_action.error_code |= ContainerAction::DIFFERENT_READ_SIZE;
        return false;
    }

    bitrange range;
    auto *field = phv.field(write.expr, &range);
    BUG_CHECK(field, "Write in an instruction has no PHV location");

    int count = 0;
    bitvec write_bits;
    field->foreach_alloc(range, [&](const PHV::Field::alloc_slice &alloc) {
        count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        write_bits.setrange(alloc.container_bit, alloc.width);
    });

    BUG_CHECK(count == 1, "ActionAnalysis did not split up container by container");

    bool initialized;
    if (read.type == ActionParam::PHV) {
        initialized = init_phv_alignment(read, cont_action, write_bits, error_message);
    } else if (read.type == ActionParam::ACTIONDATA && ad_alloc) {
        initialized = init_ad_alloc_alignment(read, cont_action, write_bits, action_name,
                                              container);
    } else {
        initialized = init_simple_alignment(read, cont_action, write_bits);
    }

    if (!initialized)
        cont_action.set_mismatch(read.type);

    return initialized;
}

/** This initializes the alignment of a particular PHV field.  It also guarantees that there
 *  is only one PHV read per PHV write.
 */
bool ActionAnalysis::init_phv_alignment(const ActionParam &read, ContainerAction &cont_action,
        bitvec write_bits, cstring &error_message) {
    bitrange range;
    auto *field = phv.field(read.expr, &range);

    BUG_CHECK(field, "PHV read has no allocation");
    bitvec read_bits;
    PHV::Container read_container;
    int count = 0;
    field->foreach_alloc(range, [&](const PHV::Field::alloc_slice &alloc) {
        count++;
        BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
        read_bits.setrange(alloc.container_bit, alloc.width);
        read_container = alloc.container;
    });

    if (count != 1) {
        error_message += "an individual read phv is contained within multiple containers, and"
                         " is considered impossible";
        return false;
    }

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

/** This initializes the alignment of action data, given that the action data allocation has
 *  taken place.  Action data allocation can take place before or after phv allocation, and
 *  thus the information in the ActionDataPlacement may not match up with the actual phv
 *  allocation.  Thus this function could potentially return false.
 */
bool ActionAnalysis::init_ad_alloc_alignment(const ActionParam &read, ContainerAction &cont_action,
        bitvec write_bits, cstring action_name, PHV::Container container) {
    if (read.speciality != ActionParam::NO_SPECIAL)
        return init_simple_alignment(read, cont_action, write_bits);

    auto &action_format = tbl->resources->action_format;

    auto &placements = action_format.arg_placement.at(action_name);

    // Information on where fields are stored
    auto action_data_format = action_format.action_data_format.at(action_name);
    // const safe_vector<ActionFormat::ActionDataPlacement> *immediate_format = nullptr;

    bitrange read_range;
    ActionParam::type_t type = ActionParam::ACTIONDATA;
    auto action_arg = isActionParam(read.expr, &read_range, &type);
    if (action_arg == nullptr)
    BUG_CHECK(action_arg != nullptr, "Action argument not converted correctly in the "
                                     "ActionAnalysis pass");
    cstring arg_name;
    if (type == ActionParam::ACTIONDATA)
        arg_name = action_arg->to<IR::ActionArg>()->name;
    else if (type == ActionParam::CONSTANT)
        arg_name = action_arg->to<IR::MAU::ActionDataConstant>()->name;

    auto pair = std::make_pair(arg_name, read_range.lo);
    BUG_CHECK(placements.find(pair) != placements.end(), "Action argument is not found to be "
              "allocated in the action format");
    auto &arg_placement = placements.at(pair);

    for (auto vector_loc : arg_placement) {
        auto adp = action_data_format.at(vector_loc);

        // Look through and ensure that the slice of the arg location is correct.
        for (auto arg_loc : adp.arg_locs) {
            if (arg_loc.name != arg_name) continue;
            if (static_cast<size_t>(adp.size) != container.size()) continue;
            int lo = arg_loc.is_constant ? 0 : arg_loc.field_bit;
            int hi = lo + arg_loc.data_loc.popcount() - 1;

            if (!(lo <= read_range.lo && hi >= read_range.hi)) continue;
            auto &adi = cont_action.adi;

            if (cont_action.counts[ActionParam::ACTIONDATA] == 0) {
                adi.initialize(adp.get_action_name(), adp.immediate, adp.start,
                               adp.arg_locs.size());
                adi.ad_alignment.add_alignment(write_bits, arg_loc.data_loc);
                cont_action.counts[ActionParam::ACTIONDATA] = 1;
            } else if (adi.start != adp.start || adi.immediate != adp.immediate) {
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

/** For action data before PHV allocation or constants.  Just guarantees that the write bits
 *  match up directly with the read bits
 */
bool ActionAnalysis::init_simple_alignment(const ActionParam &read,
         ContainerAction &cont_action, bitvec write_bits) {
    if (read.type == ActionParam::ACTIONDATA)
        BUG_CHECK(isActionParam(read.expr), "Action Data parameter not configured properly "
                                             "in ActionAnalysis pass");
    else if (read.type == ActionParam::CONSTANT)
        BUG_CHECK(read.expr->is<IR::Constant>(), "Constant parameter not configured properly "
                                                  "in ActionAnalysis pass");

    bitvec read_bits = write_bits;
    if (read.type == ActionParam::ACTIONDATA) {
        cont_action.adi.ad_alignment.add_alignment(write_bits, read_bits);
    } else if (read.type == ActionParam::CONSTANT) {
        cont_action.constant_alignment.add_alignment(write_bits, read_bits);
        if (!cont_action.constant_set) {
            cont_action.constant_used = read.expr->to<IR::Constant>()->asLong();
            cont_action.constant_set = true;
        }
    }
    cont_action.counts[read.type]++;
    return true;
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
        bool same_action = true;
        BUG_CHECK(cont_action.field_actions.size() > 0, "Somehow a container action has no "
                                                        "field actions allocated to it");
        instr_name = cont_action.field_actions[0].name;
        for (auto &field_action : cont_action.field_actions) {
            if (instr_name != field_action.name) {
                cont_action.error_code |= ContainerAction::MULTIPLE_CONTAINER_ACTIONS;
                same_action = false;
            }
        }

        if (!same_action && error_verbose) {
            ::warning("In action %s over container %s, the action has multiple operand types %s",
                      action_name, container.toString(), cstring::to_cstring(cont_action));
            warning = true;
        }

        if (!same_action)
            continue;

        cont_action.name = instr_name;
        bool total_init = true;
        for (auto &field_action : cont_action.field_actions) {
            auto &write = field_action.write;
            for (auto &read : field_action.reads) {
                cstring init_error_message;
                bool init = initialize_alignment(write, read, cont_action, init_error_message,
                                                 container, action_name);
                if (!init && error_verbose) {
                    ::warning("%s: %s", init_error_message, cstring::to_cstring(cont_action));
                    warning = true;
                }
                total_init &= init;
            }
        }

        if (!total_init)
            continue;


        cstring error_message;
        bool verify = cont_action.verify_possible(error_message, container, action_name, phv);
        if (!verify && error_verbose) {
            ::warning("%s: %s", error_message, cstring::to_cstring(cont_action));
            warning = true;
        }
        check_constant_to_actiondata(cont_action, container);
    }

    // Specifically for backtracking, as ActionFormat can be configured before PHV allocation,
    // and may not be correct.
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

/** Guarantees that a single alignment is aligned correctly.  The checks are:
 *    - The number of bits in the write and read are the same
 *    - The write and reads are contiguous, unless the operation is a bitmasked set
 *
 *  It also checks if the fields are unaligned
 */
bool ActionAnalysis::ContainerAction::verify_one_alignment(TotalAlignment &tot_alignment,
        int size, int &unaligned_count, bool bitmasked_set) {
    (void) size;
    if (tot_alignment.write_bits.popcount() != tot_alignment.read_bits.popcount()) {
        return false;
    }

    if (!bitmasked_set &&
       (!tot_alignment.write_bits.is_contiguous() || !tot_alignment.read_bits.is_contiguous())) {
        // FIXME: Eventually can support rotational shifts, but not yet with IR::Slice setup
        // || !is_contig_rotate(tot_alignment.read_bits, read_rot_shift, size)) {
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

/** Verifies all stored alignments, i.e. PHV and action data.  The following constraints must
 *  be checked:
 *    - If the instruction is anything but a deposit field, (a set that isn't a bitmasked-set)
 *      then all sources must be directly aligned with the write
 *    - If the operation is a deposit-field, then at most one source can be misaligned.  If the
 *      operation has action data, then the PHV has to be aligned.  Otherwise, one of the two
 *      PHV fields can be misaligned
 *
 *  Only in deposit-field can a portion of a source (PHV container or action data bus), can be
 *  shifted.
 *
 *  This function also saves which parameters get classified as a src1.  An instruction at most
 *  can have two sources.  Src2 is always a PHV container.  Src1 can be much more loosely defined
 *  Src1 can be from action data, a small constant, or a PHV alu.  Specifically in deposit-field
 *  instruction, src1 is the only source that doesn't have to bit-aligned either.  This
 *  information is used when creating instructions in InstructionAdjustment, specifically right
 *  now MergeInstructions
 */
bool ActionAnalysis::ContainerAction::verify_alignment(int max_phv_unaligned,
        int max_ad_unaligned, bool bitmasked_set, PHV::Container container) {
    int unaligned_count = 0;

    for (auto &tot_align_info : phv_alignment) {
        auto &tot_alignment = tot_align_info.second;
        // Verify on an individual field by field basis on the instruction on alignment
        bool verify = verify_one_alignment(tot_alignment, container.size(),
                                           unaligned_count, false);
        if (!verify)
            return false;
    }

    if (unaligned_count > max_phv_unaligned)
        return false;

    unaligned_count = 0;
    if (counts[ActionParam::ACTIONDATA] > 0) {
        bool verify = verify_one_alignment(adi.ad_alignment, container.size(), unaligned_count,
                                           bitmasked_set);
        if (!verify)
            return false;

        if (unaligned_count > max_ad_unaligned)
            return false;
    }

    // If no src1 has been assigned, then PHV is the src1 information.  If a PHV write and read
    // bits are unaligned, then that PHV field is src1, else either PHV source could be
    // considered src1.
    bool src1_assigned = false;
    if (counts[ActionParam::CONSTANT] > 0) {
        constant_alignment.is_src1 = true;
        src1_assigned = true;
    }
    if (counts[ActionParam::ACTIONDATA] > 0) {
        adi.ad_alignment.is_src1 = true;
        src1_assigned = true;
    }

    if (!src1_assigned) {
        for (auto &tot_align_info : phv_alignment) {
            auto &tot_alignment = tot_align_info.second;
            if (!tot_alignment.aligned()) {
                tot_alignment.is_src1 = true;
                src1_assigned = true;
            }
        }
    }

    if (!src1_assigned) {
        for (auto &tot_align_info : phv_alignment) {
            auto &tot_alignment = tot_align_info.second;
            tot_alignment.is_src1 = true;
            src1_assigned = true;
            break;
        }
    }

    return true;
}

/** For nearly all instructions, the ALU operation acts over all bits in the container.  The only
 *  instruction where this doesn't apply is the deposit-field instruction.  That instruction
 *  can have a portion masked.  Any other operation currently acts on the entire container, and
 *  all fields could be potentially affected.
 */
bool ActionAnalysis::ContainerAction::verify_overwritten(PHV::Container container,
          const PhvInfo &phv) {
    bitvec container_occupancy = phv.bits_allocated(container);
    bitvec total_write_bits;
    for (auto &tot_align_info : phv_alignment) {
        total_write_bits |= tot_align_info.second.write_bits;
    }

    total_write_bits |= adi.ad_alignment.write_bits;
    total_write_bits |= constant_alignment.write_bits;

    if (total_write_bits != container_occupancy)
        return false;

    if (static_cast<size_t>(total_write_bits.popcount()) != container.size())
        error_code |= PARTIAL_OVERWRITE;
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
void ActionAnalysis::check_constant_to_actiondata(ContainerAction &cont_action,
        PHV::Container container) {
    auto &counts = cont_action.counts;
    if (counts[ActionParam::ACTIONDATA] > 1 && ad_alloc) {
        cont_action.error_code |= ContainerAction::MULTIPLE_ACTION_DATA;
    }

    if (counts[ActionParam::CONSTANT] == 0)
        return;

    if (!cont_action.constant_set)
        BUG("Constant not setup by the program correctly");

    if (counts[ActionParam::ACTIONDATA] > 0 && counts[ActionParam::CONSTANT] > 0) {
        cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
    } else if (counts[ActionParam::CONSTANT] > 1) {
        // Could potentially be combined into a single constant
        cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
    } else if (counts[ActionParam::CONSTANT] == 1) {
        if (cont_action.name == "set" && cont_action.constant_alignment.write_bits.popcount()
                                         == static_cast<int>(container.size())) {
            if (!(tofino_instruction_constant(cont_action.constant_used, LOADCONST_MAX,
                                              container.size()))) {
                cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
            }
        } else if (!cont_action.is_shift()) {  // At this point probably impossible
            if (!(tofino_instruction_constant(cont_action.constant_used, CONST_SRC_MAX,
                                              container.size()))) {
                cont_action.error_code |= ContainerAction::CONSTANT_TO_ACTION_DATA;
            }
        }
    }
}

void ActionAnalysis::ContainerAction::move_source_to_bit(safe_vector<int> &bit_uses,
        ActionAnalysis::TotalAlignment &ta) {
    for (auto alignment : ta.indiv_alignments) {
        for (auto bit : alignment.write_bits) {
            bit_uses[bit]++;
        }
    }
}

/** This checks to make sure that all bits are operated correctly, i.e. if the operation is
 *  a set, every bit in the write is either set once or not at all or e.g. add, subtract, or,
 *  each write bit has  either two read bits, or no read bits affecting it (overwrite
 *  constraints are checked in a different verification)
 */
bool ActionAnalysis::ContainerAction::verify_source_to_bit(int operands,
        PHV::Container container) {
    safe_vector<int> bit_uses(container.size(), 0);

    for (auto &phv_ta : phv_alignment) {
        move_source_to_bit(bit_uses, phv_ta.second);
    }

    move_source_to_bit(bit_uses, adi.ad_alignment);
    move_source_to_bit(bit_uses, constant_alignment);

    for (size_t i = 0; i < container.size(); i++) {
        if (!(bit_uses[i] == operands || bit_uses[i] == 0))
            return false;
    }

    return true;
}

/** Each PHV ALU can only pull from a local group of 16 PHVs in an operation.  This guarantees
 *  that this clustering constraint is met.
 */
bool ActionAnalysis::ContainerAction::verify_phv_mau_group(PHV::Container container) {
    for (auto phv_ta : phv_alignment) {
        auto read_container = phv_ta.first;
        if (read_container.type() != container.type())
            return false;
        int group_size = Device::phvSpec().mauGroupNumAndSize(container.type()).second;
        if (read_container.index() / group_size != container.index() / group_size)
            return false;
    }
    return true;
}

void ActionAnalysis::ContainerAction::verify_speciality(PHV::Container container,
         cstring action_name) {
    bool speciality_found = false;
    int ad_params = 0;
    for (auto field_action : field_actions) {
        for (auto read : field_action.reads) {
            if (read.type == ActionParam::ACTIONDATA || read.type == ActionParam::CONSTANT)
                ad_params++;
            if (read.speciality != ActionParam::NO_SPECIAL)
                speciality_found = true;
        }
    }
    if (ad_params > 1 && speciality_found)
        P4C_UNIMPLEMENTED("In the ALU operation over container %s in action %s, the packing is "
                          "too complicated due to either hash distribution or attached outputs "
                          "combined with other action data", container.toString(), action_name);
}

/** The goal of this function is to validate a container operation given the allocation
 *  the write fields and the sources of the particular operation.  The following checks are:
 *    - If the ALU operation requires too many sources
 *    - If the ALU operation has the wrong number of operands per bit
 *    - If the number of operands matches instruction number
 *    - If the PHV clustering algorithm is incorrect
 *    - If the alignment of the bits are allowed
 *    - If an overwriting operation overwrites the entire container
 *
 *  The reason these constraints exists are due to the Action ALU Instruction Set Architecture.
 *  If any of these are not true, then this instruction is not possible on Tofino.
 */
bool ActionAnalysis::ContainerAction::verify_possible(cstring &error_message,
        PHV::Container container, cstring action_name, const PhvInfo &phv) {
    if (is_shift()) {
        return true;
    }

    verify_speciality(container, action_name);
    int actual_ad = std::min(1, counts[ActionParam::ACTIONDATA] + counts[ActionParam::CONSTANT]);
    int sources_needed = counts[ActionParam::PHV] + actual_ad;
    error_message = "In the ALU operation over container " + container.toString() +
                    " in action " + action_name + ", ";

    if (sources_needed > 2) {
        if (actual_ad) {  // If action data as a source
            error_code |= PHV_AND_ACTION_DATA;
            error_message += "Action " + action_name + " writes fields using the same assignment "
                "type but different source operands (both action parameter and phv)";
        } else {          // no action data sources
            error_code |= TOO_MANY_PHV_SOURCES;
            error_message += "over 2 PHV sources for the ALU operation are required, thus rendering"
                " the action impossible";
        }
        return false;
    }

    bool source_to_bit_correct = verify_source_to_bit(operands(), container);
    if (!source_to_bit_correct) {
        error_code |= BIT_COLLISION;
        error_message += "every write bit does not have a corresponding "
                         + cstring::to_cstring(operands()) + " or 0 read bits.";
        return false;
    }

    if (name != "set" && sources_needed != operands()) {
        error_code |= OPERAND_MISMATCH;
        error_message += "the number of operands does not match the number of sources";
        return false;
    }

    bool phv_group_correct = verify_phv_mau_group(container);
    if (!phv_group_correct) {
        error_code |= MAU_GROUP_MISMATCH;
        error_message += "a read phv is in an incompatible PHV group";
        return false;
    }

    bitvec ad_bitmask = adi.ad_alignment.write_bits | constant_alignment.write_bits;
    if (sources_needed == 2 && name == "set")
        to_deposit_field = true;
    if (name == "set" && ad_bitmask.popcount() > 0 && !ad_bitmask.is_contiguous())
        to_bitmasked_set = true;

    bool can_phv_be_unaligned = (name == "set" && (actual_ad == 0));
    int phv_unaligned = can_phv_be_unaligned ? 1 : 0;

    bool can_ad_be_unaligned = name == "set" && actual_ad > 0 && ad_bitmask.is_contiguous();
    int ad_unaligned = can_ad_be_unaligned ? 1 : 0;

    bool aligned = verify_alignment(phv_unaligned, ad_unaligned, to_bitmasked_set, container);

    if (!aligned) {
        error_code |= IMPOSSIBLE_ALIGNMENT;
        error_message += "the alignment of fields within the container renders the action "
                         "impossible";
        return false;
    }


    if (name != "set" || to_deposit_field) {
        bool total_overwrite_possible = verify_overwritten(container, phv);
        if (!total_overwrite_possible) {
            error_code |= ILLEGAL_OVERWRITE;
            error_message += "the container is not completely overwritten when the operand is "
                             "over the entire container";
            return false;
        }
    } else if (to_bitmasked_set) {
        error_code |= PARTIAL_OVERWRITE;
    }

    return true;
}

void ActionAnalysis::verify_P4_action_for_tofino(cstring action_name) {
    if (phv_alloc)
        verify_P4_action_with_phv(action_name);
    else if (error_verbose)
        verify_P4_action_without_phv(action_name);
}

void ActionAnalysis::postorder(const IR::MAU::Action *act) {
    verify_P4_action_for_tofino(act->name);
}
