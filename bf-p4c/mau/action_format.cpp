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

/** General naming scheme used for finding information on either immediate or action data
 *  table location of a particular field, which needs to be coordinated in the action data
 *  table format, the action data bus, and the action format itself within the assembly code
 */
cstring ActionFormat::Use::get_format_name(int start_byte, cont_type_t type,
        bool immediate, bool bitmasked_set /* = false */) const {
    int byte_sz = CONTAINER_SIZES[type] / 8;
    // Based on assumption, immediate is contiguous.  May have to be changed later
    cstring ret_name;
    if (immediate) {
        if (!total_layouts_immed[type].getrange(start_byte, byte_sz))
            BUG("Impossible immediate format name lookup");
        bitvec lookup = immediate_mask;
        int lo = start_byte * 8;
        if (bitmasked_set)
            lo += CONTAINER_SIZES[type];
        ret_name = "immediate(" +  std::to_string(lo) + "..";
        int hi = lo + CONTAINER_SIZES[type] - 1;
        if (lookup.max().index() < hi)
            hi = lookup.max().index();
        ret_name += std::to_string(hi) + ")";
    } else {
        bitvec lookup = total_layouts[type];
        ret_name = "$adf_";
        if (type == BYTE)
            ret_name += "b";
        else if (type == HALF)
            ret_name += "h";
        else
            ret_name += "f";
        int adf_offset;
        if (!bitmasked_set)
            adf_offset = lookup.getslice(0, start_byte).popcount() / byte_sz;
        else
            adf_offset = lookup.getslice(0, start_byte + byte_sz).popcount() / byte_sz;
        ret_name += std::to_string(adf_offset);
    }
    return ret_name;
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


    if (immediate_possible) {
        action_counts.clear();
        setup_action_counts(true);
        LOG2("Setup immediate containers");
        space_all_immediate_containers();
        LOG2("Space immediate containers");
        align_immediate_layouts();
        LOG2("Alignment immediate");
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
    ConstantRenames constant_renames;
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
                cstring arg_name;
                if (auto *sl = read.expr->to<IR::Slice>())
                    arg_name = sl->e0->to<IR::ActionArg>()->name;
                else
                    arg_name = read.expr->to<IR::ActionArg>()->name;

                adp.arg_locs.emplace_back(arg_name, data_location, 0, single_loc);
                adp.size = container_size;
                adp.range = data_location;
                adp_vector.push_back(adp);
                bits_allocated += data_location.popcount();
            }
        }
    }

    use->action_data_format[action_name] = adp_vector;
    use->constant_locations[action_name] = constant_renames;
}

/** Creates an ActionDataPlacement from an ActionArg, correctly verified from the PHV allocation
 */
void ActionFormat::create_from_actiondata(ActionDataPlacement &adp,
        const ActionAnalysis::ActionParam &read, int container_bit) {
    bitvec data_location;
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

/** Creates an ActionDataPlacement from a Constant that has to be converted into ActionData.
 *  This constant will later be converted to a ActionDataConstant in the InstructionAdjustment
 *  pass.
 */
void ActionFormat::create_from_constant(ActionDataPlacement &adp,
         const ActionAnalysis::ActionParam &read, int field_bit, int container_bit,
         int &constant_to_ad_count, PHV::Container container, ConstantRenames &constant_renames) {
    bitvec data_location;
    bool single_loc = true;

    data_location.setrange(container_bit, read.size());
    auto constant_key = std::make_pair(container.toString(), container_bit);
    auto arg_name = "$constant" + std::to_string(constant_to_ad_count);
    adp.arg_locs.emplace_back(arg_name, data_location, field_bit,
                              single_loc);
    adp.range |= data_location;
    constant_renames[constant_key] = arg_name;
    constant_to_ad_count++;

    int constant_value = read.expr->to<IR::Constant>()->asInt();
    adp.arg_locs.back().set_as_constant(constant_value);
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
    int constant_to_ad_count = 0;
    ConstantRenames constant_renames;
    for (auto &container_action_info : container_actions_map) {
        auto container = container_action_info.first;
        auto &cont_action = container_action_info.second;
        ActionDataPlacement adp;
        // Every instruction in the container process has to have its action data stored
        // in the same action data slot
        bool initialized = false;
        for (auto &field_action : cont_action.field_actions) {
            PhvInfo::Field::bitrange bits;
            auto *write_field = phv.field(field_action.write.expr, &bits);
            int container_bit = 0;
            int write_count = 0;

            write_field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &alloc) {
                write_count++;
                BUG_CHECK(alloc.container_bit >= 0, "Invalid negative container bit");
                container_bit = alloc.container_bit;
            });

            if (write_count > 1)
                BUG("Splitting of writes handled incorrectly");

            for (auto &read : field_action.reads) {
                if (read.type == ActionAnalysis::ActionParam::ACTIONDATA) {
                    create_from_actiondata(adp, read, container_bit);
                    initialized = true;
                } else if (read.type == ActionAnalysis::ActionParam::CONSTANT
                    && cont_action.convert_constant_to_actiondata()) {
                    create_from_constant(adp, read, bits.lo, container_bit, constant_to_ad_count,
                                         container, constant_renames);
                    initialized = true;
                }
            }
        }
        if (initialized) {
            adp.size = container.size();
            if (cont_action.to_bitmasked_set)
                adp.bitmasked_set = true;
            adp_vector.push_back(adp);
        }
    }

    use->action_data_format[action_name] = adp_vector;
    use->constant_locations[action_name] = constant_renames;
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
        for (auto placement : *placement_vec) {
            bool odd_container_size = true;
            for (int i = 0; i < CONTAINER_TYPES; i++) {
                if (placement.size == CONTAINER_SIZES[i]) {
                    aci.counts[i]++;
                    if (placement.bitmasked_set) {
                        aci.counts[i]++;
                        aci.bitmasked_sets[i]++;
                    }
                    if (aci.minmaxes[i] > placement.range.max().index() + 1)
                        aci.minmaxes[i] = placement.range.max().index() + 1;
                    odd_container_size = false;
                    break;
                }
            }
            if (odd_container_size)
                BUG("What happened here? %d", placement.size);
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

        // Due to action bus constraint, any 32 bit operation must be contained within a 8-bit
        // section of the action format for an ease of allocation
        int half_ends = max_small_bytes;
        if (aci.bitmasked_sets[FULL] > 0) {
            half_ends = check_full_bitmasked(aci, max_small_bytes);
        }

        for (int i = 0; i < count_half; i++) {
            aci.layouts[HALF].setrange(half_ends - 2 * i - 2, 2);
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

/** A small check to guarantee that if a full word requires a bitmasked-set, then the
 *  bitmasked pair will be on an even-odd pairing to ease the placement on the action data bus
 */
int ActionFormat::check_full_bitmasked(ActionContainerInfo &aci, int max_small_bytes) {
    int diff = max_bytes - max_small_bytes;
    if ((CONTAINER_SIZES[FULL] / 8) * aci.bitmasked_sets[FULL] < diff)
        return max_small_bytes;

    int small_sizes_needed = aci.counts[BYTE] + aci.counts[HALF] * 2;
    return (small_sizes_needed - 1) / 4;
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
        auto &placement_vec = use->action_data_format[aci.action];
        bitvec bitmasked_reservations[CONTAINER_TYPES];
        int starts[CONTAINER_TYPES] = {0, 0, 0};

        // Handle bitmasked-set requirements first, as they have to be on an even-odd pair,
        // Algorithm is to place all bitmasked-set required placements, as those are constrained
        // Once those are placed, fill in the other non bitmasked-sets
        for (auto &placement : placement_vec) {
            if (!placement.bitmasked_set) continue;
            int byte_sz = placement.size / 8;
            int index = placement.gen_index();
            int lookup = starts[index];
            int loc;
            int max = aci.layouts[index].max().index() + 1;
            do {
                if ((lookup % byte_sz) != 0)
                    BUG("Action formats are setup incorrectly");
                loc = aci.layouts[index].ffs(lookup);
                lookup = loc + byte_sz;
            } while ((loc % ((byte_sz) * 2)) != 0 && lookup < max);

            if (aci.layouts[index].getrange(loc, byte_sz) == 0)
                BUG("Misalignment on the action data format");
            placement.start = loc;
            starts[index] = loc + byte_sz;
            bitmasked_reservations[index].setrange(loc, byte_sz * 2);
            if (index == FULL)
                use->full_layout_bitmasked.setrange(loc, byte_sz * 2);
        }

        std::fill(starts, starts + CONTAINER_TYPES, 0);
        for (auto &placement : placement_vec) {
            if (placement.bitmasked_set) continue;
            int byte_sz = placement.size / 8;
            int index = placement.gen_index();
            int lookup = starts[index];
            int loc;
            int max = aci.layouts[index].max().index() + 1;
            do {
                if ((lookup % byte_sz) != 0)
                    BUG("Action formats are setup incorrectly");
                loc = aci.layouts[index].ffs(lookup);
                lookup = loc + byte_sz;
            } while (bitmasked_reservations[index].getbit(loc) == true && lookup < max);

            if (aci.layouts[index].getrange(loc, byte_sz) == 0)
                BUG("Misalignment on the action data format");
            placement.start = loc;
            starts[index] = loc + byte_sz;
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
        auto &placement_vec = use->immediate_format.at(aci.action);
        bitvec bitmasked_reservations[CONTAINER_TYPES];
        int starts[CONTAINER_TYPES] = {0, 0, 0};
        bool already_maxed[CONTAINER_TYPES] = {false, false, false};

        // Handle bitmasked-set requirements first, as they have to be on an even-odd pair,
        // Algorithm is to place all bitmasked-set required placements, as those are constrained
        // Once those are placed, fill in the other non bitmasked-sets
        for (auto &placement : placement_vec) {
            if (!placement.bitmasked_set) continue;
            int byte_sz = placement.size / 8;
            int index = placement.gen_index();
            // Deals with a particular bitmasked-set case of 3 8-bit fields, ensuring that
            // the bitmasked-set is on an even odd pair
            if (placement.range.max().index() + 1 == aci.minmaxes[index]
                && aci.total_bytes() % 2 == 0) {
                // Bitmasked-set should be the last parameter
                int start = aci.layouts[index].max().index();
                start -= byte_sz * 2 - 1;
                placement.start = start;
                already_maxed[index] = true;
                bitmasked_reservations[index].setrange(start, byte_sz * 2);
            } else {
                // Bitmasked-set should not be the last parameter.  Minimize immediate
                int lookup = starts[index];
                int loc;
                int max = aci.layouts[index].max().index() + 1;
                do {
                    if ((lookup % byte_sz) != 0)
                        BUG("Action formats are setup incorrectly");
                    loc = aci.layouts[index].ffs(lookup);
                    lookup = loc + byte_sz;
                } while ((loc % ((byte_sz) * 2)) != 0 && lookup < max);

                if (aci.layouts[index].getrange(loc, byte_sz) == 0)
                    BUG("Misalignment on the action data format");
                placement.start = loc;
                starts[index] = loc + byte_sz;
                bitmasked_reservations[index].setrange(loc, byte_sz * 2);
            }
            if (placement.start > IMMEDIATE_BYTES)
                BUG("Somehow immediate bytes have 4 bytes");
        }


        std::fill(starts, starts + CONTAINER_TYPES, 0);
        for (auto &placement : placement_vec) {
            if (placement.bitmasked_set) continue;
            int byte_sz = placement.size / 8;
            int index = placement.gen_index();
            if (placement.range.max().index() + 1 == aci.minmaxes[index]
                && !already_maxed[index]) {
                // Normal parameter should be last field to minimize immediate
                int start = aci.layouts[index].max().index();
                start -= byte_sz - 1;
                placement.start = start;
                already_maxed[index] = true;
            } else {
                // Normal parameter should not be last field to minimize immediate
                int lookup = starts[index];
                int loc;
                int max = aci.layouts[index].max().index() + 1;
                do {
                    if ((lookup % byte_sz) != 0)
                        BUG("Action formats are setup incorrectly");
                    loc = aci.layouts[index].ffs(lookup);
                    lookup = loc + byte_sz;
                } while (bitmasked_reservations[index].getbit(loc) == true && lookup < max);
                if (aci.layouts[index].getrange(loc, byte_sz) == 0)
                    BUG("Misalignment on the action data format");
                placement.start = loc;
                starts[index] = loc + byte_sz;
            }
            if (placement.start > IMMEDIATE_BYTES)
                BUG("Somehow immediate bytes have 4 bytes");
        }
        sort_and_asm_name(placement_vec, true);
        ArgPlacementData &apd = use->arg_placement[aci.action];
        calculate_placement_data(placement_vec, apd, true);
    }
    /* FIXME: Due to complication on action_bus, no longer allowed holes
    if (tbl->layout.no_match_data()) {
        auto max = use->immediate_mask.max();
        if (max != use->immediate_mask.end())
            use->immediate_mask.setrange(0, max.index());
    }
    */
    auto max = use->immediate_mask.max();
    if (max != use->immediate_mask.end())
        use->immediate_mask.setrange(0, max.index());
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
    int mask_index = 0;
    for (auto &placement : placement_vec) {
        int byte_sz = placement.size  / 8;
        if (placement.arg_locs.size() > 1) {
            placement.action_name = "$data" + std::to_string(index);
            if (placement.bitmasked_set) {
                placement.mask_name = "$mask" + std::to_string(mask_index++);
            }
            index++;
        } else if (placement.arg_locs.size() < 1) {
            placement.action_name = "$no_arg";
        }
        if (immediate) {
            use->immediate_mask |= (placement.range << (placement.start * 8));
            if (placement.bitmasked_set)
                use->immediate_mask |= (placement.range << ((placement.start + byte_sz) * 8));
        }
    }
}

/** A way to perform an easy lookup of where the action data parameter is contained within the
 *  entire action data placement
 */
void ActionFormat::calculate_placement_data(vector<ActionDataPlacement> &placement_vec,
                                            ArgPlacementData &apd, bool immediate) {
    int index = 0;
    for (auto &container : placement_vec) {
        for (auto arg_loc : container.arg_locs) {
            apd[std::make_pair(arg_loc.name, arg_loc.field_bit)].emplace_back(index, immediate);
        }
        index++;
    }
}
