#include "action_format.h"
#include "lib/log.h"

constexpr int ActionFormat::CONTAINER_SIZES[];

void ActionFormat::ActionContainerInfo::reset() {
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        counts[i] = 0; layouts[i].clear();
        minmaxes[i] = CONTAINER_SIZES[i] + 1;
    }
}

void ActionFormat::ActionContainerInfo::finalize_min_maxes() {
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        minmaxes[i] = minmaxes[i] == (CONTAINER_SIZES[i] + 1) ? 0 : minmaxes[i];
    }
}

int ActionFormat::ActionContainerInfo::find_maximum_immed() {
    int max_byte = counts[BYTE] > 0 ? (counts[BYTE] - 1) * 8 + minmaxes[BYTE] : 0;
    int max_half = counts[HALF] > 0 ? (counts[HALF] - 1) * 16 + minmaxes[HALF] : 0;
    int max_full = counts[HALF] > 0 ? (counts[FULL] - 1) * 32 + minmaxes[FULL] : 0;
    int maximum = 0;

    if (max_byte > 0 && max_half > 0) {
        if (max_byte > max_half) {
            order = FIRST_8;
            maximum = max_half + 16;
        } else {
            order = FIRST_16;
            maximum = max_byte + 16;
        }
    } else {
        order = NOT_SET;
        maximum = std::max(std::max(max_byte, max_half), max_full);
    }
    return maximum;
}


cstring ActionFormat::ActionDataPlacement::adf_name() const {
    cstring name = "$adf_";
    if (size == 8)
        name += "b";
    else if (size == 16)
        name += "h";
    else
        name += "f";
    name += std::to_string(adf_offset);
    return name;
}

/** Determining the names generated in the asm_output name for any action data stored as
 *  immediate.  If there are multiple fields packed into an individual container, both the
 *  container and the individual fields require a location within the immediate.  Also
 *  verifies that the alignment of the immediate data matches with the masks. 
 */
cstring ActionFormat::ActionDataPlacement::immed_name() const {
    if (arg_locs.size() == 1) {
        return arg_locs[0].immed_plac.immed_name();
    }
    bool index_set = false;
    bool is_indexed = false;
    int immed_index = -1;
    int lo = 33; int hi = 0;
    for (auto &arg_loc : arg_locs) {
        if (arg_loc.immed_plac.indexed) {
            if (!index_set) {
                immed_index = arg_loc.immed_plac.index;
                index_set = true;
                is_indexed = true;
            } else if (!is_indexed) {
                BUG("Index alignment issues");
            } else if (immed_index != arg_loc.immed_plac.indexed) {
                ERROR("Immed index doesn't line up for a bitmasked-set");
                return arg_locs[0].immed_plac.immed_name();
            }
        } else {
            if (!index_set)
                is_indexed = false;
            else if (is_indexed)
                BUG("Index alignment issues");
        }

        if (lo > arg_loc.immed_plac.lo)
            lo = arg_loc.immed_plac.lo;
        if (hi < arg_loc.immed_plac.hi)
            hi = arg_loc.immed_plac.hi;
    }

    cstring name = "immediate";
    if (is_indexed) {
        name += std::to_string(immed_index);
    }
    name += "(" + std::to_string(lo) + ".." + std::to_string(hi) +")";
    return name;
}

/** The allocation scheme for the action data format and immediate format.
 */
void ActionFormat::allocate_format(Use *u) {
    LOG2("Allocating Table Format for " << tbl->name);
    use = u;
    analyze_all_actions();
    LOG2("Analysis finished");

    if (immediate_possible) {
        setup_immediate_format();
        LOG2("Immediate format setup " << tbl->name);
    }

    space_all_containers();
    LOG2("Space all containers");
    align_action_data_layouts();
    LOG2("Alignment");
    determine_format_name();


    if (immediate_possible) {
        action_counts.clear();
        setup_action_counts(true);
        LOG2("Setup immediate containers");
        space_all_immediate_containers();
        LOG2("Space immediate containers");
        align_immediate_layouts();
        LOG2("Alignment immediate");
        determine_immed_format_name();
    }
}

/** Based on the field_actions returned for the ActionAnalysis pass, this function makes
 *  a best guess on the action data requirements, and fills out the ActionDataPlacement
 *  vector fo this action with the appropriate information.
 *
 *  The information provided are what arguments are in what action data slot, and the
 *  necessary sizes of the action data slots.
 */
void ActionFormat::create_placement_non_phv(ActionAnalysis::FieldActionsMap &field_actions_map,
                                            cstring action_name) {
    // FIXME: Verification on some argument limitations still required
    vector<ActionDataPlacement> adp_vector;
    for (auto &field_action_info : field_actions_map) {
        auto &field_action = field_action_info.second;
        for (auto &read : field_action.reads) {
            if (read.type != ActionAnalysis::ActionParam::ACTIONDATA) continue;
            int bits_needed = read.expr->type->width_bits();
            int bits_allocated = 0;
            bool single_loc = true;
            bitvec data_location;
            // Best guess at action data slot needs, may be corrected after PHV allocation
            while (bits_allocated < bits_needed) {
                data_location.clear();
                int container_size;
                if (bits_allocated + CONTAINER_SIZES[FULL] < bits_needed) {
                    container_size = CONTAINER_SIZES[FULL];
                    single_loc = false;
                    data_location.setrange(0, CONTAINER_SIZES[FULL]);
                } else {
                    int diff = bits_needed - bits_allocated;
                    container_size = (1 << ceil_log2(diff));
                    if (container_size < CONTAINER_SIZES[BYTE])
                        container_size = CONTAINER_SIZES[BYTE];
                    data_location.setrange(0, diff);
                }
                ActionDataPlacement adp;
                auto arg_name = read.expr->to<IR::ActionArg>()->name;
                adp.arg_locs.emplace_back(arg_name, data_location, 0, single_loc);
                adp.size = container_size;
                adp.range = data_location;
                adp_vector.push_back(adp);
                bits_allocated += data_location.popcount();
            }
        }
    }

    use->action_data_format[action_name] = adp_vector;
}

/** Run after PHV allocation has completed.  Based on how fields are packed into the PHV,
 *  action data affecting multiple fields might have to be in the same container, i.e. if two
 *  fields that are written by action data are in the same container, then the action data
 *  parameters have to be in the same action data slot.
 *
 *  The function goes through every single use of action data in the function, and will
 *  determine what types of action data slots are needed as well as where action data is stored
 *  within the slots.  This will be saved in a vector of ActionDataPlacement
 */
void ActionFormat::create_placement_phv(ActionAnalysis::ContainerActionsMap &container_actions_map,
                                        cstring action_name) {
    vector<ActionDataPlacement> adp_vector;
    for (auto &container_action_info : container_actions_map) {
        auto container = container_action_info.first;
        auto &cont_action = container_action_info.second;
        if (cont_action.counts[ActionAnalysis::ActionParam::ACTIONDATA] == 0) continue;
        ActionDataPlacement adp;
        // Every instruction in the container process has to have its action data stored
        // in the same action data slot
        for (auto &field_action : cont_action.field_actions) {
            auto *write_field = phv.field(field_action.write.expr);
            int container_bit = 0;
            write_field->foreach_alloc([&](const PhvInfo::Field::alloc_slice &alloc) {
                container_bit = alloc.container_bit;
            });

            bitvec data_location;
            for (auto &read : field_action.reads) {
                data_location.clear();
                if (read.type != ActionAnalysis::ActionParam::ACTIONDATA) continue;
                bool single_loc = true;
                int field_bit = 0;
                if (auto *sl = read.expr->to<IR::Slice>()) {
                    single_loc = false;
                    field_bit = sl->getL();
                }
                data_location.setrange(container_bit, read.size());
                auto arg_name = read.unsliced_expr()->to<IR::ActionArg>()->name;
                adp.arg_locs.emplace_back(arg_name, data_location, field_bit,
                                          single_loc);
                adp.range |= data_location;
            }
        }
        adp.size = container.size();
        adp_vector.push_back(adp);
    }

    use->action_data_format[action_name] = adp_vector;
}

/** Performs the argument analyzer and initializes the vector of ActionContainerInfo
 */
void ActionFormat::analyze_all_actions() {
    ActionAnalysis::FieldActionsMap field_actions_map;
    ActionAnalysis::ContainerActionsMap container_actions_map;

    for (auto action : Values(tbl->actions)) {
        field_actions_map.clear();
        container_actions_map.clear();

        ActionAnalysis aa(phv, alloc_done, false, tbl);
        aa.set_field_actions_map(&field_actions_map);
        aa.set_container_actions_map(&container_actions_map);

        action->apply(aa);

        if (!alloc_done)
            create_placement_non_phv(field_actions_map, action->name);
        else
            create_placement_phv(container_actions_map, action->name);
    }

    setup_action_counts(false);

    if (max_bytes <= 4)
        immediate_possible = true;
}

/** Based on the container information found in the ActionDataPlacement, determines the number of
 *  8, 16, and 32 bit action data slots need for each individual action.  These values are also
 *  maximized in the max_total ActionContainerInfo, as the action data table must have the maximum
 *  of each of these action data slot reserved.  For immediate data, the minmax of the length
 *  of the container is saved.  Essentially the minimum of each container is saved, and the maximum
 *  minimum is saved in max total
 */
void ActionFormat::setup_action_counts(bool immediate) {
    max_total.reset();
    max_total.finalize_min_maxes();
    for (auto action : Values(tbl->actions)) {
        ActionContainerInfo aci;
        aci.action = action->name;
        auto *placement_vec = &(use->action_data_format.at(action->name));
        if (immediate)
            placement_vec = &(use->immediate_format.at(action->name));
        int index = 0;
        // Build the ACI;
        for (auto container : *placement_vec) {
            bool odd_container_size = true;
            for (int i = 0; i < CONTAINER_TYPES; i++) {
                if (container.size == CONTAINER_SIZES[i]) {
                    aci.counts[i]++;
                    if (aci.minmaxes[i] > container.range.max().index() + 1)
                        aci.minmaxes[i] = container.range.max().index() + 1;
                    odd_container_size = false;
                    break;
                }
            }
            if (odd_container_size)
                BUG("What happened here? %d", container.size);
            index++;
        }
        // Analysis of the ACI
        if (max_bytes < aci.total_bytes())
            max_bytes = aci.total_bytes();

        aci.finalize_min_maxes();
        if (immediate) {
            max_total.maximum = std::max(max_total.maximum, aci.find_maximum_immed());
        } else {
            max_total.maximize(aci);
        }
        action_counts.push_back(aci);
    }
}

/** Very basically saves all of the information into the immediate placement.  At later revision
 *  of action format, we can potentially split data between immediate and action data table, and
 *  some intelligence will have to go into that
 */
void ActionFormat::setup_immediate_format() {
    for (auto action_placement : use->action_data_format) {
        auto name = action_placement.first;
        auto placement_vec = action_placement.second;
        use->immediate_format[name] = placement_vec;
    }
}


/** For non-overlapping action data formats:
 *     - Algorithm finds locations of 8's and 16's first
 *     - Go through the fields in needs of 32 bit containers most to least
 *     - Essentially by knowing how many actions require 32 bit containers, we now know that
 *       how many 32 byte chunks we have to pack this 8 and 16 bit container chunks into
 *     -

 *  General algorithm for action data table:
 *  The general thought process is to put the 8 bit data closer to the lsb and the 16 bits
 *  closer to the msb of the action data format.  Then because 32s can potentially overlap
 *  locations on the action data bus, fit the 32 bit containers at the most optimal place for
 *  each individual action.  Thus if the max requirements for a table are 4 8 bit and 2 16 bit
 *  actions, the layout will look like:
 *  
 *  lsb: 8 8 8 8 16 16 msb

 *  The major issue with this algorithm can be described by the following scenario.  Say we have two
 *  actions with the following action data layouts:

 *  8 8 8 8 16 16
 *  8 8 16  32

 *  Now if I allocate the second action containers to be aligned with the first containers, then
 *  I cannot fit the 32 bit container, as it has to be 32 bit aligned.  Thus an action that
 *  meets this offset constraint has two requirements.  First, the counts[BYTE] % 4 == 1 or 2
 *  and the counts[HALF] % 2 == 1, and second, the action must require all FULL words to be
 *  fully needed.
 */

/** This function checks to see which actions have the 8 8 16 constraint, marks these actions,
 *  and then calculates the total layouts based upon the maximum constraint as well as the
 *  8 8 16 constraint.
 */
int ActionFormat::offset_constraints_and_total_layouts() {
    for (auto &aci : action_counts) {
        if (((aci.counts[BYTE] % 4) == 1 || (aci.counts[BYTE] % 4) == 2)
             && (aci.counts[HALF] % 2) == 1) {
            if (aci.total_bytes() + 1 >= (1 << ceil_log2(max_bytes))) {
                aci.offset_constraint = true;
            }
        }
    }

    int max_small_bytes = max_total.counts[BYTE] + max_total.counts[HALF] * 2;
    max_small_bytes = (max_small_bytes + 3) & ~(0x3);
    if (max_small_bytes > (1 << ceil_log2(max_bytes)))
        max_small_bytes = (1 << ceil_log2(max_bytes));

    bitvec offset_locs;
    bitvec offset_8count;

    // Essentially find the location of the 8 16 split
    for (auto &aci : action_counts) {
        if (!aci.offset_constraint) continue;

        int aci_highest_8_full = (aci.counts[BYTE] - 1) / 4;
        aci.offset_full_word = aci_highest_8_full;

        offset_locs.setbit(aci.offset_full_word);
        if ((aci.counts[BYTE] % 4) == 2)
            offset_8count.setbit(aci.offset_full_word);
        // FIXME: This needs to check at the next PR if the 32 things are paired for bitmasked sets
    }

    use->total_layouts[BYTE].setrange(0, max_total.counts[BYTE]);
    int starting_16_loc = max_small_bytes - max_total.counts[HALF] * 2;
    use->total_layouts[HALF].setrange(starting_16_loc, max_total.counts[HALF] * 2);

    for (auto full_word : offset_locs) {
        int added = 0;
        if (offset_8count.getbit(full_word) == 0)
            added = 1;
        else
            added = 2;

        use->total_layouts[BYTE].setrange(full_word * 4, added);
        use->total_layouts[HALF].setrange(full_word * 4 + 2, 2);
    }
    return max_small_bytes;
}

/** Based on the total layouts calculated, and whether the ActionContainerInfo contains that
 *  8 8 16 constraint, this function selects the bytes that each action will use in the
 *  action data format.  This is done by the examination of the total layouts
 */
void ActionFormat::space_8_and_16_containers(int max_small_bytes) {
    for (auto &aci : action_counts) {
        int count_byte = aci.counts[BYTE];
        int count_half = aci.counts[HALF];
        if (aci.offset_constraint) {
            count_byte -= (aci.counts[BYTE] % 4);
            count_half -= 1;
        }

        // Coordinate this to total layouts
        for (int i = 0; i < count_byte; i++) {
            aci.layouts[BYTE].setbit(i);
        }

        for (int i = 0; i < count_half; i++) {
            aci.layouts[HALF].setrange(max_small_bytes - 2 * i - 2, 2);
        }

        if (aci.offset_constraint) {
            aci.layouts[BYTE].setrange(aci.offset_full_word * 4, (aci.counts[BYTE] % 4));
            aci.layouts[HALF].setrange(aci.offset_full_word * 4 + 2, 2);
        }

        LOG3("Aci layouts for action " << aci.action << " BYTE: "
             << aci.layouts[BYTE] << " HALF: " << aci.layouts[HALF]);

        if ((aci.layouts[BYTE] & aci.layouts[HALF]).popcount() != 0)
            BUG("Collision between bytes and half word on action data format");

        if ((use->total_layouts[BYTE] & aci.layouts[BYTE]).popcount() < aci.counts[BYTE])
            BUG("Error in the spread of bytes in action data format");

        if ((use->total_layouts[HALF] & aci.layouts[HALF]).popcount() < aci.counts[HALF] * 2)
            BUG("Error in the spread of half words in action data format");
    }
}

/** This function just fills in all of the 32 bit holes for each individual action.  Because
 *  the 32 bits can potentially overlap with either 8 or 16 bit containers, the algorithm can
 *  be more cavalier about where it places the 32 bit action data
 */
void ActionFormat::space_32_containers() {
    for (auto &aci : action_counts) {
        bitvec combined = aci.layouts[BYTE] | aci.layouts[HALF];
        int count_full = aci.counts[FULL];
        for (int i = (1 << ceil_log2(max_bytes)) - 4; i >= 0; i -= 4) {
            if (count_full == 0) break;
            if (combined.getrange(i, 4) != 0)
                continue;
            aci.layouts[FULL].setrange(i, 4);
            use->total_layouts[FULL].setrange(i, 4);
            count_full--;
        }
        if (count_full != 0)
            BUG("Could not allocate all full words in action data format");
    }
}

/** The container allocation algorithm for the action data tables
 */
void ActionFormat::space_all_containers() {
    if (max_bytes == 0)
        return;
    int max_small_bytes = offset_constraints_and_total_layouts();
    space_8_and_16_containers(max_small_bytes);
    space_32_containers();
}

/** This function links the action data arguments with containers spaced out for the action.
 *  Action arguments know their size and linked with the correct size.  The information contained
 *  in the ActionDataPlacement may result in the adjustment of the instructions within a pass after
 *  PHV allocation.
 */
void ActionFormat::align_action_data_layouts() {
    for (auto aci : action_counts) {
        int starts[CONTAINER_TYPES] = {0, 0, 0};
        auto &placement_vec = use->action_data_format[aci.action];
        for (auto &container : placement_vec) {
            int index = container.gen_index();
            int loc = aci.layouts[index].ffs(starts[index]);
            if (aci.layouts[index].getrange(loc, container.size / 8) == 0)
                BUG("Misalignment on the action data format");
            container.start = loc;
            starts[index] = loc + container.size / 8;
        }
        sort_and_asm_name(placement_vec, false);
        ArgPlacementData &apd = use->arg_placement[aci.action];
        calculate_placement_data(placement_vec, apd, false);
    }
    if (max_bytes != 0)
        use->action_data_bytes = (1 << ceil_log2(max_bytes));
}

/** The algorithm for immediate is much simpler.  Instead of trying to best pack the action data
 *  bytes, the overarching goal in iteration 1 is to simply just minimize the number of bits
 *  needed to be stored for an action data, as you can do bit alignment in the shift and mask
 *  portion of match central.  Because action data in the immediate is limited to 32 bits, this
 *  also makes this algorithm simple.
 *
 *  The only difficult action data is actions that contain 16 bit and 8 bit action data.  The
 *  algorithm must decide which action data comes first within the immediate format. 
 *
 *  This algorithm could be improved by taking a more global view of the containers.  However,
 *  because the immediate data is small and doesn't require that many action data bus slots,
 *  it wasn't worth it on the first iteration.
 */
void ActionFormat::space_individ_immed(ActionContainerInfo &aci) {
    if (aci.order == ActionContainerInfo::FIRST_8 || aci.order == ActionContainerInfo::FIRST_16) {
        int first = HALF; int second = BYTE;
        if (aci.order == ActionContainerInfo::FIRST_8) {
            first = BYTE;
            second = HALF;
        }
        if (aci.counts[first] > 0)
            aci.layouts[first] |= bitvec(0, aci.counts[first] * (CONTAINER_SIZES[first] / 8));
        else
             BUG("Should never be reached");
        if (aci.counts[second] > 0)
            aci.layouts[second] |= bitvec(2, aci.counts[second] * (CONTAINER_SIZES[second] / 8));
        else
            BUG("Should never be reached");
    } else {
        // TODO: Could do even better byte packing potentially, not currently saving a byte
        for (int i = 0; i < CONTAINER_TYPES; i++) {
            if (aci.counts[i] > 0) {
                aci.layouts[i] |= bitvec(0, aci.counts[i] * CONTAINER_SIZES[i] / 8);
            }
        }
    }

    if ((aci.layouts[BYTE] & aci.layouts[HALF] & aci.layouts[FULL]).popcount() != 0)
        BUG("Erroneous layout of immediate data");

    for (int i = 0; i < CONTAINER_TYPES; i++)
        use->total_layouts_immed[i] |= aci.layouts[i];
}


/** Simply find the action data formats for immediate data for every single action */
void ActionFormat::space_all_immediate_containers() {
    std::sort(action_counts.begin(), action_counts.end(),
            [](const ActionContainerInfo &a, const ActionContainerInfo &b) {
        int t;
        if (a.order != ActionContainerInfo::NOT_SET && b.order == ActionContainerInfo::NOT_SET)
            return true;
        if (b.order == ActionContainerInfo::NOT_SET && a.order != ActionContainerInfo::NOT_SET)
            return false;
        if ((t = a.counts[HALF] - b.counts[HALF]) != 0)
            return t > 0;
        if ((t = a.minmaxes[HALF] - b.minmaxes[HALF]) != 0)
            return t > 0;
        if ((t = a.counts[BYTE] - b.counts[BYTE]) != 0)
            return t > 0;
        return a.minmaxes[BYTE] > b.minmaxes[BYTE];
    });


    for (auto &aci : action_counts) {
        space_individ_immed(aci);
    }
}

/* Similar to the align action data format, this aligns the immediate container allocation of
 *  an action to the actual arguments.  Because we are trying to minimize immediate length,
 *  the algorithm puts the containers that require the least amount of size to the back.
 *
 *  At the end of the algorithm, a bitvec describing the immediate format is calculated.
 *  This is also suboptimal, as you could potentially optimally search for the best immediate
 *  format in the number of holes one could potentially have
 */
void ActionFormat::align_immediate_layouts() {
    for (auto aci : action_counts) {
        int starts[CONTAINER_TYPES] = {0, 0, 0};
        bool already_maxed[CONTAINER_TYPES] = {false, false, false};
        auto &placement_vec = use->immediate_format.at(aci.action);
        for (auto &container : placement_vec) {
            int index = container.gen_index();
            if (container.range.max().index() + 1 == aci.minmaxes[index]
                && !already_maxed[index]) {
                int start = aci.layouts[index].max().index();
                start -= (CONTAINER_SIZES[index] / 8) - 1;
                container.start = start;
                already_maxed[index] = true;
            } else {
                int loc = aci.layouts[index].ffs(starts[index]);
                if (aci.layouts[index].getrange(loc, container.size / 8) == 0)
                    BUG("Misalignment on the immediate data format");
                container.start = loc;
                starts[index] = loc + container.size / 8;
            }
        }
        sort_and_asm_name(placement_vec, true);
        ArgPlacementData &apd = use->arg_placement[aci.action];
        calculate_placement_data(placement_vec, apd, true);
    }
    if (tbl->layout.no_match_data()) {
        auto max = use->immediate_mask.max();
        if (max != use->immediate_mask.end())
            use->immediate_mask.setrange(0, max.index());
    }
    LOG3("Immediate mask calculated is " << use->immediate_mask);
}

/** This sorts the action data from lowest to highest bit position for easiest assembly output.
 *  It also verifies that two fields of action data within an individual action did not end up
 *  at the same point.  Lastly, if multiple action data parameters are contained within the same
 *  action data section, this must be renamed uniquely within the action for the assembler.
 *  Thus a unique asm_name could potentially be needed, and thus could be generated.
 */
void ActionFormat::sort_and_asm_name(vector<ActionDataPlacement> &placement_vec, bool immediate) {
    std::sort(placement_vec.begin(), placement_vec.end(),
            [](const ActionDataPlacement &a, const ActionDataPlacement &b) {
        // std::sort() in libc++ can compare an element with itself,
        // breaking our assertions below, so exit early in that case.
        if (&a == &b) return false;

        if (a.start == b.start) {
            BUG("Two containers in the same action are at the same place?");
        }

        if ((a.start + a.size / 8 - 1 > b.start && b.start > a.start)
            || (b.start + b.size / 8 - 1 > a.start && a.start > b.start)) {
            BUG("Two containers overlap in the same action");
        }
        return a.start < b.start;
    });
    int index = 0;
    for (auto &container : placement_vec) {
        if (container.arg_locs.size() > 1) {
            container.asm_name = "$data" + std::to_string(index);
            index++;
        } else if (container.arg_locs.size() == 1) {
            container.asm_name = container.arg_locs[0].name;
        } else {
            container.asm_name = "$no_arg";
        }
        if (immediate) {
            for (auto arg_loc : container.arg_locs) {
                use->immediate_mask |= (arg_loc.data_loc << (container.start * 8));
            }
        }
    }
}

void ActionFormat::calculate_placement_data(vector<ActionDataPlacement> &placement_vec,
                                            ArgPlacementData &apd, bool immediate) {
    int index = 0;
    for (auto &container : placement_vec) {
        for (auto arg_loc : container.arg_locs) {
            apd[arg_loc.name].emplace_back(index, immediate);
        }
        index++;
    }
}

/** Algorithm to determine the names of the action data contained within an individual table
 *  format.  It then coordinates these names back to the individual fields allocated within
 *  each action, and places them that way.
 */
void ActionFormat::determine_format_name() {
    vector<map<int, int>> format_locations;
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        int index = 0;
        format_locations.emplace_back();
        for (int j = 0; j <= use->total_layouts[i].max().index(); j += CONTAINER_SIZES[i] / 8) {
            if (use->total_layouts[i].getslice(j, CONTAINER_SIZES[i] / 8).popcount()
                == CONTAINER_SIZES[i] / 8) {
                format_locations[i].emplace(j, index);
                index++;
            }
        }
    }

    for (auto &ad_placement : use->action_data_format) {
        auto &placement_vec = ad_placement.second;
        for (auto &placement : placement_vec) {
            placement.adf_offset = format_locations[placement.gen_index()].at(placement.start);
        }
    }
}

/** Algorithm to determine the names of the action data contained within the immediate data.
 *  Both the general container name may be needed, as well as the individual fields within
 *  the container, if multiple fields are contained within the container
 */
void ActionFormat::determine_immed_format_name() {
    vector<std::pair<int, int>> immed_indices;
    int start = use->immediate_mask.ffs();
    bool beginning = true;
    do {
        int end = use->immediate_mask.ffz(start);
        if (beginning) {
            immed_indices.emplace_back(0, end - 1);
            beginning = false;
        } else {
            immed_indices.emplace_back(start, end - 1);
        }
        start = use->immediate_mask.ffs(end);
    } while (start != -1);

    for (auto &immed_placement : use->immediate_format) {
        auto &placement_vec = immed_placement.second;
        for (auto &placement : placement_vec) {
            int start_bit = placement.start * 8;
            for (auto &arg_loc : placement.arg_locs) {
                int data_start_bit = arg_loc.data_loc.ffs() + start_bit;
                int index = -1;
                for (auto immed_index : immed_indices) {
                    index++;
                    if (immed_index.first > data_start_bit || immed_index.second < data_start_bit)
                        continue;
                    int lo = data_start_bit - immed_index.first;
                    int hi = lo + arg_loc.data_loc.popcount() - 1;
                    if (immed_indices.size() == 1)
                        arg_loc.immed_plac.init(lo, hi);
                    else
                        arg_loc.immed_plac.init(index, lo, hi);
                }
            }
        }
    }
}
