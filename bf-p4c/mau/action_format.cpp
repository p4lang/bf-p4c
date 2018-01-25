#include "action_format.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"

constexpr int ActionFormat::CONTAINER_SIZES[];

/*
void ActionFormat::ActionContainerInfo::maximize(ActionContainerInfo &a) {
    for (int i = 0; i < LOCATIONS; i++) {
        for (int j = 0; j < CONTAINER_TYPES; j++) {
            if (a.counts[i][j] > counts[i][j])
                counts[i][j] = a.counts[i][j];
        }
    }
}
*/

void ActionFormat::ActionContainerInfo::reset() {
    order = NOT_SET;
    maximum = -1;
    for (int i = 0; i < LOCATIONS; i++) {
        for (int j = 0; j < CONTAINER_TYPES; j++) {
            counts[i][j] = 0;
            layouts[i][j].clear();
            bitmasked_sets[i][j] = 0;
            minmaxes[i][j] = CONTAINER_SIZES[i] + 1;
        }
    }

    for (int i = 0; i < BITMASKED_TYPES; i++) {
        for (int j = 0; j < CONTAINER_TYPES; j++) {
            minmaxes[i][j] = CONTAINER_SIZES[i] + 1;
        }
    }
}

void ActionFormat::ActionContainerInfo::finalize_min_maxes() {
    for (int i = 0; i < BITMASKED_TYPES; i++) {
        for (int j = 0; j < CONTAINER_TYPES; j++) {
            minmaxes[i][j] = minmaxes[i][j] == (CONTAINER_SIZES[j] + 1) ? 0 : minmaxes[i][j];
        }
    }
}

int ActionFormat::ActionContainerInfo::find_maximum_immed(bool meter_color) {
    int max_byte = counts[IMMED][BYTE] > 0
        ? (counts[IMMED][BYTE] - 1) * 8 + minmaxes[NORMAL][BYTE] : 0;
    int max_half = counts[IMMED][HALF] > 0
        ? (counts[IMMED][HALF] - 1) * 16 + minmaxes[NORMAL][HALF] : 0;
    int max_full = counts[IMMED][FULL] > 0
        ? (counts[IMMED][FULL] - 1) * 32 + minmaxes[NORMAL][FULL] : 0;

    int maximum = 0;
    if (max_byte > 0 && max_half > 0) {
        if (max_byte > max_half || meter_color) {
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

int ActionFormat::ActionContainerInfo::total(location_t loc, bitmasked_t bm,
        cont_type_t type) const {
    if (bm == BITMASKED)
        return bitmasked_sets[loc][type];
    else
        return counts[loc][type] - bitmasked_sets[loc][type] * 2;
}

bool ActionFormat::ActionDataPlacement::ArgLoc::operator==(
        const ActionFormat::ActionDataPlacement::ArgLoc &a) const {
    if (name != a.name) return false;
    if (field_bit != a.field_bit) return false;
    if (data_loc != a.data_loc) return false;
    return true;
}

bool ActionFormat::ActionDataPlacement::operator==(
        const ActionFormat::ActionDataPlacement &a) const {
    if (size != a.size) return false;
    if (range != a.range) return false;
    for (auto arg_loc : arg_locs) {
        if (std::find(a.arg_locs.begin(), a.arg_locs.end(), arg_loc) == a.arg_locs.end())
            return false;
    }
    return true;
}

/** General naming scheme used for finding information on either immediate or action data
 *  table location of a particular field, which needs to be coordinated in the action data
 *  table format, the action data bus, and the action format itself within the assembly code
 */
cstring ActionFormat::Use::get_format_name(int start_byte, cont_type_t type,
        bool immediate, bitvec range, bool use_range, bool bitmasked_set /* = false */) const {
    int byte_sz = CONTAINER_SIZES[type] / 8;
    // Based on assumption, immediate is contiguous.  May have to be changed later
    cstring ret_name;
    if (immediate) {
        if (!total_layouts[IMMED][type].getrange(start_byte, byte_sz))
            BUG("Impossible immediate format name lookup");
        bitvec lookup = immediate_mask;
        int lo = start_byte * 8;
        if (bitmasked_set)
            lo += CONTAINER_SIZES[type];
        int hi = lo + CONTAINER_SIZES[type] - 1;
        if (lookup.max().index() < hi)
            hi = lookup.max().index();
        if (use_range) {
            if ((lo % CONTAINER_SIZES[type]) < range.min().index())
                lo += range.min().index();
            if ((hi % CONTAINER_SIZES[type]) > range.max().index())
                hi -= (hi - range.max().index());
        }
        ret_name = "immediate(" +  std::to_string(lo) + "..";
        ret_name += std::to_string(hi) + ")";
    } else {
        bitvec lookup = total_layouts[ADT][type];
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
        if (use_range) {
            if (range.max().index() - range.min().index() + 1 < CONTAINER_SIZES[type]) {
                int lo = range.min().index();
                int hi = range.max().index();
                ret_name += "(" + std::to_string(lo) + ".." + std::to_string(hi) + ")";
            }
        }
    }
    return ret_name;
}

/** Meter color reserved in the top byte of immediate */
bool ActionFormat::Use::is_meter_color(int start_byte, bool immediate) const {
    return meter_reserved && immediate && start_byte == (IMMEDIATE_BYTES - 1);
}

/** The allocation scheme for the action data format and immediate format.
 */
void ActionFormat::allocate_format(safe_vector<Use> &uses, bool immediate_allowed) {
    LOG2("Allocating Table Format for " << tbl->name);
    analyze_all_actions();
    LOG2("Analysis finished");

    while (true) {
        LOG2("Action Format attempt");
        bool finished = false;
        if (!new_action_format(immediate_allowed, finished)) {
            if (finished)
                break;
            continue;
        }
        setup_use(uses);
        space_containers();
        LOG2("Space containers");
        align_action_data_layouts();
        LOG2("Align layouts");
    }

    LOG2("Action Formats possible " << uses.size());
}

/** Based on the field_actions returned for the ActionAnalysis pass, this function makes
 *  a best guess on the action data requirements, and fills out the ActionDataPlacement
 *  vector fo this action with the appropriate information.
 *
    assert(have_action || (tbl->layout.action_data_bytes_in_table 
                           tbl->layout.action_data_bytes_in_overhead));
 *  The information provided are what arguments are in what action data slot, and the
 *  necessary sizes of the action data slots.
 */
void ActionFormat::create_placement_non_phv(ActionAnalysis::FieldActionsMap &field_actions_map,
                                            cstring action_name) {
    // FIXME: Verification on some argument limitations still required
    safe_vector<ActionDataPlacement> adp_vector;
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

    init_format[action_name] = adp_vector;
    renames[action_name] = constant_renames;
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
    cstring arg_name;
    if (read.speciality == ActionAnalysis::ActionParam::NO_SPECIAL)
        arg_name = read.unsliced_expr()->to<IR::ActionArg>()->name;
    else if (read.speciality == ActionAnalysis::ActionParam::METER_COLOR)
        arg_name = "meter";
    else
        BUG("Currently cannot handle the speciality %d in ActionFormat creation",
            read.speciality);

    adp.arg_locs.emplace_back(arg_name, data_location, field_bit,
                              single_loc);
    adp.arg_locs.back().speciality = read.speciality;

    if (read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL)
        adp.specialities |= 1 << read.speciality;
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
    safe_vector<ActionDataPlacement> adp_vector;
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
            bitrange bits;
            auto *write_field = phv.field(field_action.write.expr, &bits);
            le_bitrange container_bits;
            int write_count = 0;

            write_field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
                write_count++;
                container_bits = alloc.container_bits();
                BUG_CHECK(container_bits.lo >= 0, "Invalid negative container bit");
                if (!alloc.container)
                    ERROR("Phv field " << write_field->name << " written in action "
                          << action_name << " is not allocated?");
            });

            if (write_count > 1)
                BUG("Splitting of writes handled incorrectly");

            for (auto &read : field_action.reads) {
                if (read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL &&
                    read.speciality != ActionAnalysis::ActionParam::METER_COLOR)
                    continue;
                if (read.type == ActionAnalysis::ActionParam::ACTIONDATA) {
                    create_from_actiondata(adp, read, container_bits.lo);
                    initialized = true;
                } else if (read.type == ActionAnalysis::ActionParam::CONSTANT
                    && cont_action.convert_constant_to_actiondata()) {
                    create_from_constant(adp, read, bits.lo, container_bits.lo,
                                         constant_to_ad_count, container,
                                         constant_renames);
                    initialized = true;
                }
            }
        }
        if (initialized) {
            adp.size = container.size();
            if (cont_action.to_bitmasked_set)
                adp.bitmasked_set = true;
            // FIXME: This is a hack to get switch_l2 to fit quickly.  This could be done
            // in a much better analysis of sharing action data
            if (std::find(adp_vector.begin(), adp_vector.end(), adp) != adp_vector.end())
                continue;
            adp_vector.push_back(adp);
        }
    }

    init_format[action_name] = adp_vector;
    renames[action_name] = constant_renames;
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
    initialize_action_counts();
}

/** Calculate how much action data space is needed per actions.
 *
 *  FIXME: Could be optimized in order to save space by either pairing placements that
 *  are different sizes to better pack the action data sizes
 */
void ActionFormat::initialize_action_counts() {
    for (auto action : Values(tbl->actions)) {
        ActionContainerInfo aci;
        aci.action = action->name;
        auto &placement_vec = init_format.at(action->name);
        for (auto &placement : placement_vec) {
            bool valid_container_size = false;
            for (int i = 0; i < CONTAINER_TYPES; i++) {
                valid_container_size |= placement.size == CONTAINER_SIZES[i];
            }
            BUG_CHECK(valid_container_size, "Action data packed in slot that is not a valid "
                                            "size: %d", placement.size);
            int index = placement.gen_index();
            if ((placement.specialities & (1 << ActionAnalysis::ActionParam::METER_COLOR)) != 0) {
                BUG_CHECK(index == BYTE, "Due to complexity in action bus, can only currently "
                          "handle meter color in an 8 bit ALU operation, and nothing else.");
                aci.meter_reserved = true;
                meter_color = true;
                if (placement.bitmasked_set && placement.arg_locs.size() == 1)
                P4C_UNIMPLEMENTED("Currently too difficult of an operation on meter color "
                                  "to handle within the compiler");
                continue;
            }

            aci.counts[ADT][index]++;
            int bm_type = placement.bitmasked_set ? BITMASKED : NORMAL;
            // Double requirements for bitmasked_sets
            if (placement.bitmasked_set) {
                aci.counts[ADT][index]++;
                aci.bitmasked_sets[ADT][index]++;
            }
            aci.minmaxes[bm_type][index] = std::min(aci.minmaxes[bm_type][index],
                                                placement.range.max().index() + 1);
        }
        aci.finalize_min_maxes();
        init_action_counts.push_back(aci);
    }
}

/** This is the algorithm to choose which bytes to move from the action data table to
 *  immediate.  The bytes provided is the number of bytes that have to be moved from
 *  action data table to immediate.
 *
 *  If, for example there are 3 bytes, then at least one byte word exists, and must be the
 *  one to be moved from immediate.
 *
 *  This generally ignores the fact that even if a full word is 4 bytes for instance, the
 *  actual number of bits in that full word may be less and could potentially be more
 *  impactful on the format
 */
ActionFormat::cont_type_t
    ActionFormat::ActionContainerInfo::best_candidate_to_move(int bytes) {
    safe_vector<ActionFormat::cont_type_t> cont_types;
    BUG_CHECK(bytes > 0 && bytes <= 4, "Must allocate between 0 and 4 bytes in immediate");
    if (bytes % 2 == 1) {
        if (counts[ActionFormat::ADT][ActionFormat::BYTE] > 0)
            cont_types.push_back(ActionFormat::BYTE);
    } else if (bytes % 4 == 2) {
        if (counts[ActionFormat::ADT][ActionFormat::BYTE] >= 2)
            cont_types.push_back(ActionFormat::BYTE);
        if (counts[ActionFormat::ADT][ActionFormat::HALF] >= 1)
            cont_types.push_back(ActionFormat::HALF);
    } else if (bytes % 4 == 0) {
        if (counts[ActionFormat::ADT][ActionFormat::BYTE]
            + counts[ActionFormat::ADT][ActionFormat::HALF] * 2 >= 4) {
            if (counts[ActionFormat::ADT][ActionFormat::BYTE] >= 2)
                cont_types.push_back(ActionFormat::BYTE);
            if (counts[ActionFormat::ADT][ActionFormat::HALF] >= 1)
                cont_types.push_back(ActionFormat::HALF);
        }
        if (counts[ActionFormat::ADT][ActionFormat::FULL] >= 1) {
            cont_types.push_back(ActionFormat::FULL);
        }
    }

    // Of the containers that are able to be moved, pick the best candidate
    std::sort(cont_types.begin(), cont_types.end(),
        [=](const ActionFormat::cont_type_t &a, const ActionFormat::cont_type_t &b) {
        int t;
        if (total_bytes(IMMED) == 0)
            if ((t = minmaxes[NORMAL][a] % 8 - minmaxes[NORMAL][b] % 8) != 0)
                return t < 0;
        // Do not prefer FULL, if not minmaxed.  FULL are easy to share
        if (a == ActionFormat::FULL)
            return false;
        if (b == ActionFormat::FULL)
            return true;
        else if ((t = counts[ADT][a] % 2 - counts[ADT][b] % 2) != 0)
            return t > 0;
        else if ((t = counts[ADT][a] % 4 - counts[ADT][b] % 4) != 0)
            return t > 0;
        return CONTAINER_SIZES[a] > CONTAINER_SIZES[b];
    });

    if (cont_types.size() > 0)
        return cont_types[0];
    return ActionFormat::CONTAINER_TYPES;
}

void ActionFormat::setup_use(safe_vector<Use> &uses) {
    uses.emplace_back();
    use = &(uses.back());
    use->action_data_bytes[ADT] = action_bytes[ADT];
    use->action_data_bytes[IMMED] = action_bytes[IMMED];
    LOG2("Action data bytes IMMED: " << use->action_data_bytes[IMMED] << " ADT: "
         << use->action_data_bytes[IMMED]);
    use->constant_locations = renames;
    calculate_maximum();
}

/** This function will iterate through all possible action data table sizes where
 *  the required number of immediate bytes will be less than 4.  The action data table
 *  in bytes is in powers of 2, so shrinking an action data table by a small amount may
 *  be able to save significant space.
 *
 *  The first iteration is action data table only.  After that, the number of action data
 *  bytes in the table is shrunk by half until that number of action data bytes hits 0.  The
 *  function will return true if the number of immediate bytes is less than 4.
 *
 *  The actions that have more action data bytes than can fit within the action data table
 *  must have their action data split into two locations, action data table and immediate
 *
 *  FIXME: Future improvements to this algorithm: Analysis could be done to actions that
 *  could completely fit within the action data table, but could save space on the action
 *  data bus if the byte had been moved to immediate
 */
bool ActionFormat::new_action_format(bool immediate_allowed, bool &finished) {
    action_counts.clear();
    action_counts = init_action_counts;
    int total_bytes = 0;
    for (auto aci : init_action_counts) {
        total_bytes = std::max(total_bytes, aci.total_action_data_bytes());
        // FIXME: In order to maintain that there is no overlapping in any actions, even though
        // only byte is needed, possibly more are reserved if the meter output is used in a
        // larger ALU.  This needs to be figured out as part of a larger PR
    }

    action_data_bytes = total_bytes;
    // First allocation has no immediate data
    if (!split_started) {
        split_started = true;
        if (total_bytes != 0)
            action_bytes[ADT] = (1 << ceil_log2(total_bytes));
        return true;
    }

    if (!immediate_allowed || action_bytes[ADT] == 0) {
        finished = true;
        return false;
    }

    action_bytes[ADT] /= 2;
    int overhead_attempt = total_bytes - action_bytes[ADT];

    if (overhead_attempt > IMMEDIATE_BYTES) {
        return false;
    }

    ActionContainerInfo min_total = max_total;
    for (auto &aci : action_counts) {
        if (aci.total_action_data_bytes() > action_bytes[ADT]) {
            for (int i = 0; i < CONTAINER_TYPES; i++)
                min_total.counts[ADT][i] = std::min(aci.counts[ADT][i], min_total.counts[ADT][i]);
        }
    }
    bool overhead_increase = false;
    bool found = false;

    while (!found) {
        // Increase the total number of action data bytes
        action_counts = init_action_counts;
        if (overhead_increase) {
            overhead_attempt++;
            overhead_increase = false;
        }

        // Currently save an upper byte for meter color, if it is required
        int max_immediate_bytes = IMMEDIATE_BYTES;
        if (meter_color)
            max_immediate_bytes--;

        if (overhead_attempt > max_immediate_bytes)
            return false;

        // Shrink each action that has more action data that can fit within the table
        for (auto &aci : action_counts) {
            while (action_bytes[ADT] < aci.total_bytes(ADT)) {
                int diff = aci.total_bytes(ADT) - action_bytes[ADT];
                auto candidate = aci.best_candidate_to_move(diff);
                if (candidate == CONTAINER_TYPES) {
                    overhead_increase = true;
                    break;
                }
                aci.counts[IMMED][candidate]++;
                aci.counts[ADT][candidate]--;
            }
            if (overhead_increase)
                break;
        }

        if (overhead_increase)
            continue;

        // Ensure that if a bitmasked-set is required, then the action parameters are either
        // both in immediate, or on the action data table
        for (auto &aci : action_counts) {
            if (aci.total_bytes(IMMED) == 0) continue;
            for (int i = 0; i < CONTAINER_TYPES; i++) {
                while (aci.counts[ADT][i] < 2 * aci.bitmasked_sets[ADT][i]) {
                    aci.bitmasked_sets[ADT][i]--;
                    aci.bitmasked_sets[IMMED][i]++;
                }
                if (aci.counts[IMMED][i] < 2 * aci.bitmasked_sets[IMMED][i]) {
                    overhead_increase = true;
                    break;
                }
            }
            if (overhead_increase)
                break;
        }
        found = overhead_increase == false;
    }

    action_bytes[IMMED] = overhead_attempt;
    return true;
}

/** Based on the split between action data tables and immediate, gather the total placement
 *  requirements of these regions.
 */
void ActionFormat::calculate_maximum() {
    max_total.reset();
    for (auto &aci : action_counts) {
        for (int i = 0; i < LOCATIONS; i++) {
            for (int j = 0; j < CONTAINER_TYPES; j++) {
                max_total.counts[i][j] = std::max(aci.counts[i][j], max_total.counts[i][j]);
            }
        }
    }

    for (auto &aci : action_counts) {
        if (aci.total_bytes(IMMED) == 0) continue;
        max_total.maximum = std::max(aci.find_maximum_immed(meter_color), max_total.maximum);
    }
}

/** Find a spot for all Action Data Table and Immediate bytes
 */
void ActionFormat::space_containers() {
    space_all_table_containers();
    space_all_immediate_containers();
    space_all_meter_color();
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
        if (((aci.counts[ADT][BYTE] % 4) == 1 || (aci.counts[ADT][BYTE] % 4) == 2)
             && (aci.counts[ADT][HALF] % 2) == 1) {
            if (aci.total_bytes(ADT) + 1 >= (1 << ceil_log2(max_bytes))) {
                aci.offset_constraint = true;
            }
        }
    }

    int max_small_bytes = max_total.counts[ADT][BYTE] + max_total.counts[ADT][HALF] * 2;
    max_small_bytes = (max_small_bytes + 3) & ~(0x3);
    if (max_small_bytes > (1 << ceil_log2(max_bytes)))
        max_small_bytes = (1 << ceil_log2(max_bytes));

    bitvec offset_locs;
    bitvec offset_8count;

    // Essentially find the location of the 8 16 split
    for (auto &aci : action_counts) {
        if (!aci.offset_constraint) continue;

        int aci_highest_8_full = (aci.counts[ADT][BYTE] - 1) / 4;
        aci.offset_full_word = aci_highest_8_full;

        offset_locs.setbit(aci.offset_full_word);
        if ((aci.counts[ADT][BYTE] % 4) == 2)
            offset_8count.setbit(aci.offset_full_word);
    }

    use->total_layouts[ADT][BYTE].setrange(0, max_total.counts[ADT][BYTE]);
    int starting_16_loc = max_small_bytes - max_total.counts[ADT][HALF] * 2;
    use->total_layouts[ADT][HALF].setrange(starting_16_loc, max_total.counts[ADT][HALF] * 2);

    for (auto full_word : offset_locs) {
        int added = 0;
        if (offset_8count.getbit(full_word) == 0)
            added = 1;
        else
            added = 2;

        use->total_layouts[ADT][BYTE].setrange(full_word * 4, added);
        use->total_layouts[ADT][HALF].setrange(full_word * 4 + 2, 2);
    }
    return max_small_bytes;
}

/** Based on the total layouts calculated, and whether the ActionContainerInfo contains that
 *  8 8 16 constraint, this function selects the bytes that each action will use in the
 *  action data format.  This is done by the examination of the total layouts
 */
void ActionFormat::space_8_and_16_containers(int max_small_bytes) {
    for (auto &aci : action_counts) {
        int count_byte = aci.counts[ADT][BYTE];
        int count_half = aci.counts[ADT][HALF];
        if (aci.offset_constraint) {
            count_byte -= (aci.counts[ADT][BYTE] % 4);
            count_half -= 1;
        }

        // Coordinate this to total layouts
        for (int i = 0; i < count_byte; i++) {
            aci.layouts[ADT][BYTE].setbit(i);
        }

        // Due to action bus constraint, any 32 bit operation must be contained within a 8-bit
        // section of the action format for an ease of allocation
        int half_ends = max_small_bytes;
        if (aci.bitmasked_sets[ADT][FULL] > 0) {
            half_ends = check_full_bitmasked(aci, max_small_bytes);
        }

        for (int i = 0; i < count_half; i++) {
            aci.layouts[ADT][HALF].setrange(half_ends - 2 * i - 2, 2);
        }

        if (aci.offset_constraint) {
            aci.layouts[ADT][BYTE].setrange(aci.offset_full_word * 4,
                                           (aci.counts[ADT][BYTE] % 4));
            aci.layouts[ADT][HALF].setrange(aci.offset_full_word * 4 + 2, 2);
        }

        if ((aci.layouts[ADT][BYTE] & aci.layouts[ADT][HALF]).popcount() != 0)
            BUG("Collision between bytes and half word on action data format");

        if ((use->total_layouts[ADT][BYTE] & aci.layouts[ADT][BYTE]).popcount()
            < aci.counts[ADT][BYTE])
            BUG("Error in the spread of bytes in action data format");

        if ((use->total_layouts[ADT][HALF] & aci.layouts[ADT][HALF]).popcount()
            < aci.counts[ADT][HALF] * 2)
            BUG("Error in the spread of half words in action data format");
    }
}

/** A small check to guarantee that if a full word requires a bitmasked-set, then the
 *  bitmasked pair will be on an even-odd pairing to ease the placement on the action data bus
 */
int ActionFormat::check_full_bitmasked(ActionContainerInfo &aci, int max_small_bytes) {
    int diff = max_bytes - max_small_bytes;
    if ((CONTAINER_SIZES[FULL] / 8) * aci.bitmasked_sets[ADT][FULL] < diff)
        return max_small_bytes;

    int small_sizes_needed = aci.counts[ADT][BYTE] + aci.counts[ADT][HALF] * 2;
    return (small_sizes_needed + 3) & ~(0x3);
}

/** This function just fills in all of the 32 bit holes for each individual action.  Because
 *  the 32 bits can potentially overlap with either 8 or 16 bit containers, the algorithm can
 *  be more cavalier about where it places the 32 bit action data
 */
void ActionFormat::space_32_containers() {
    for (auto &aci : action_counts) {
        bitvec combined = aci.layouts[ADT][BYTE] | aci.layouts[ADT][HALF];
        int count_full = aci.counts[ADT][FULL];
        for (int i = (1 << ceil_log2(max_bytes)) - 4; i >= 0; i -= 4) {
            if (count_full == 0) break;
            if (combined.getrange(i, 4) != 0)
                continue;
            aci.layouts[ADT][FULL].setrange(i, 4);
            use->total_layouts[ADT][FULL].setrange(i, 4);
            count_full--;
        }
        if (count_full != 0)
            BUG("Could not allocate all full words in action data format");
    }
}

/** The container allocation algorithm for the action data tables
 */
void ActionFormat::space_all_table_containers() {
    max_bytes = action_bytes[ADT];
    if (max_bytes == 0)
        return;
    for (auto aci : action_counts) {
        BUG_CHECK(aci.total_bytes(ADT) <= max_bytes, "Somehow have more bytes than "
                  "possibly allocate");
    }


    int max_small_bytes = offset_constraints_and_total_layouts();
    space_8_and_16_containers(max_small_bytes);
    space_32_containers();
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
        if (aci.counts[IMMED][first] > 0)
            aci.layouts[IMMED][first]
                |= bitvec(0, aci.counts[IMMED][first] * (CONTAINER_SIZES[first] / 8));
        else
             BUG("Should never be reached");
        if (aci.counts[IMMED][second] > 0)
            aci.layouts[IMMED][second]
                |= bitvec(2, aci.counts[IMMED][second] * (CONTAINER_SIZES[second] / 8));
        else
            BUG("Should never be reached");
    } else {
        // TODO: Could do even better byte packing potentially, not currently saving a byte
        for (int i = 0; i < CONTAINER_TYPES; i++) {
            if (aci.counts[IMMED][i] > 0) {
                aci.layouts[IMMED][i]
                    |= bitvec(0, aci.counts[IMMED][i] * CONTAINER_SIZES[i] / 8);
            }
        }
    }

    if ((aci.layouts[IMMED][BYTE] & aci.layouts[IMMED][HALF]
         & aci.layouts[IMMED][FULL]).popcount() != 0)
        BUG("Erroneous layout of immediate data");
}

/** Simply just reserves the upper byte of immediate for meter color. */
void ActionFormat::space_all_meter_color() {
    for (auto aci : action_counts) {
        if (!aci.meter_reserved) continue;
        aci.layouts[IMMED][BYTE].setbit(IMMEDIATE_BYTES - 1);
        use->total_layouts[IMMED][BYTE] |= aci.layouts[IMMED][BYTE];
        use->meter_reserved = true;
    }
}

/** Simply find the action data formats for immediate data for every single action */
void ActionFormat::space_all_immediate_containers() {
    max_bytes = action_bytes[IMMED];
    if (max_bytes == 0)
        return;
    for (auto aci : action_counts) {
        BUG_CHECK(aci.total_bytes(IMMED) <= max_bytes, "Somehow have more bytes than "
                  "possibly allocate");
    }

    std::sort(action_counts.begin(), action_counts.end(),
            [](const ActionContainerInfo &a, const ActionContainerInfo &b) {
        int t;
        if (a.order != ActionContainerInfo::NOT_SET && b.order == ActionContainerInfo::NOT_SET)
            return true;
        if (b.order == ActionContainerInfo::NOT_SET && a.order != ActionContainerInfo::NOT_SET)
            return false;
        if ((t = a.counts[IMMED][HALF] - b.counts[IMMED][HALF]) != 0)
            return t > 0;
        if ((t = a.minmaxes[IMMED][HALF] - b.minmaxes[IMMED][HALF]) != 0)
            return t > 0;
        if ((t = a.counts[IMMED][BYTE] - b.counts[IMMED][BYTE]) != 0)
            return t > 0;
        return a.minmaxes[IMMED][BYTE] > b.minmaxes[IMMED][BYTE];
    });


    for (auto &aci : action_counts) {
        space_individ_immed(aci);
        for (int i = 0; i < CONTAINER_TYPES; i++)
            use->total_layouts[IMMED][i] |= aci.layouts[IMMED][i];
    }
}

/** Simple placement of the upper byte of immediate for each action tthat requires a meter color.
 */
void ActionFormat::reserve_meter_color(ArgFormat &format, ActionContainerInfo &aci,
                                       bitvec layouts_placed[CONTAINER_TYPES]) {
    if (!aci.meter_reserved)
        return;
    int byte_sz = CONTAINER_SIZES[BYTE];
    auto &placement_vec = format[aci.action];
    auto it = placement_vec.begin();
    while (it != placement_vec.end()) {
        if (it->specialities & (1 << ActionAnalysis::ActionParam::METER_COLOR)) {
            it->start = IMMEDIATE_BYTES - 1;
            it->immediate = true;
            layouts_placed[BYTE].setrange(IMMEDIATE_BYTES - 1, byte_sz);
            use->action_data_format.at(aci.action).push_back(*it);
            it = placement_vec.erase(it);
            return;
        }
        it++;
    }
    BUG("Meter color thought to be reserved, but no action operand for the meter color");
}

/** This is to allocate a section of either immediate or action data table section, and
 *  assign action data parameters to their reserved slots.  In the algorithm, the bitmasked
 *  set object are allocated before all others, as those fields are required to be allocated
 *  in pairs.
 */
void ActionFormat::align_section(ArgFormat &format, ActionContainerInfo &aci, location_t loc,
        bitmasked_t bm, bitvec layouts_placed[CONTAINER_TYPES],
        int placed[BITMASKED_TYPES][CONTAINER_TYPES]) {
    int multiplier = static_cast<int>(bm) + 1;
    auto &placement_vec = format[aci.action];

    auto it = placement_vec.begin();
    while (it != placement_vec.end()) {
        if ((it->bitmasked_set && bm != BITMASKED) || (!it->bitmasked_set && bm == BITMASKED)) {
            it++;
            continue;
        }
        auto index = it->gen_index();

        if (placed[bm][index] >= aci.total(loc, bm, static_cast<cont_type_t>(index))) {
            it++;
            continue;
        }

        int byte_sz = CONTAINER_SIZES[index] / 8;
        int lookup = 0;
        int init_byte = 0;
        int max = aci.layouts[loc][index].max().index() + 1;
        bool found = false;

        // Find the location of a placement, given an action's placement within actions
        do {
            found = true;
            init_byte = aci.layouts[loc][index].ffs(lookup);
            lookup = init_byte + byte_sz;
            if (layouts_placed[index].getrange(init_byte, byte_sz * multiplier) != 0) {
                found = false;
            } else if (aci.layouts[loc][index].getslice(init_byte, byte_sz * multiplier).popcount()
                != byte_sz * multiplier) {
                found = false;
            } else if ((init_byte % (byte_sz * multiplier)) != 0) {
                found = false;
            }
        } while (found == false && lookup < max);
        BUG_CHECK(found, "Could not match up action data allocation byte");

        it->start = init_byte;
        it->immediate = loc == IMMED ? true : false;
        layouts_placed[index].setrange(init_byte, byte_sz * multiplier);
        placed[bm][index]++;

        use->action_data_format.at(aci.action).push_back(*it);
        it = placement_vec.erase(it);
    }
}

/** For immediate section, in order to conserve space, the algorithm tries to find the
 *  action data that has the lowest lsb, and allocate that particular slice of action data
 *  last in order to better maximize packing.
 */
void ActionFormat::find_immed_last(ArgFormat &format, ActionContainerInfo &aci,
        bitvec layouts_placed[CONTAINER_TYPES], int placed[BITMASKED_TYPES][CONTAINER_TYPES]) {
    int max = 0;
    int max_index = CONTAINER_TYPES;
    // Determine which size of action data would be the best to conserve
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        auto layout = aci.layouts[IMMED][i];
        if (layout.max().index() > max) {
            max = layout.max().index();
            max_index = i;
        }
    }

    if (max == 0)
        return;
    if ((aci.layouts[IMMED][max_index] - layouts_placed[max_index]).max().index() < max)
        return;

    auto byte_sz = CONTAINER_SIZES[max_index] / 8;
    int init_byte = max - byte_sz + 1;

    auto &placement_vec = format[aci.action];
    auto it = placement_vec.begin();
    bool found = false;
    while (it != placement_vec.end() && !found) {
        if (it->bitmasked_set) {
            it++;
            continue;
        }
        auto index = it->gen_index();
        if (index != max_index) {
            it++;
            continue;
        }
        if (it->range.max().index() + 1 != aci.minmaxes[NORMAL][max_index]) {
            it++;
            continue;
        }
        it->start = init_byte;
        it->immediate = true;
        layouts_placed[index].setrange(init_byte, byte_sz);
        placed[NORMAL][index]++;

        use->action_data_format.at(aci.action).push_back(*it);
        it = placement_vec.erase(it);
        found = true;
    }
    BUG_CHECK(found, "Minmaxes not properly configured to match up minimum sized immediate");
}

/** Find a location for all action data parameters within the reserved slots for each of the
 *  sizes.  First allocate for bitmasked-sets, as those have to be reserved in pairs, then
 *  in immediate, reserve the lowest bit slot, and then lastly fill in all the remaining
 *  spots with the associated action data.
 */
void ActionFormat::align_action_data_layouts() {
    ArgFormat format = init_format;
    for (auto aci : action_counts) {
        safe_vector<ActionDataPlacement> adp_vector;
        use->action_data_format[aci.action] = adp_vector;
        for (int i = IMMED; i >= ADT; i--) {
            int placed[BITMASKED_TYPES][CONTAINER_TYPES] = {{0, 0, 0}, {0, 0, 0}};
            auto loc = static_cast<location_t>(i);
            bitvec layouts_placed[CONTAINER_TYPES];
            if (i == IMMED)
                reserve_meter_color(format, aci, layouts_placed);
            align_section(format, aci, loc, BITMASKED, layouts_placed, placed);
            if (i == IMMED)
                find_immed_last(format, aci, layouts_placed, placed);
            align_section(format, aci, loc, NORMAL, layouts_placed, placed);
        }
    }

    for (auto aci : action_counts) {
        BUG_CHECK(format.at(aci.action).empty(), "Did not fully allocate the action data for "
                  "an action %s", aci.action);
        sort_and_asm_name(use->action_data_format.at(aci.action));
        calculate_placement_data(use->action_data_format.at(aci.action),
                                 use->arg_placement[aci.action]);
    }
    calculate_immed_mask();
}



/** This sorts the action data from lowest to highest bit position for easiest assembly output.
 *  It also verifies that two fields of action data within an individual action did not end up
 *  at the same point.  Lastly, if multiple action data parameters are contained within the same
 *  action data section, this must be renamed uniquely within the action for the assembler.
 *  Thus a unique asm_name could potentially be needed, and thus could be generated.
 */
void ActionFormat::sort_and_asm_name(safe_vector<ActionDataPlacement> &placement_vec) {
    std::sort(placement_vec.begin(), placement_vec.end(),
            [](const ActionDataPlacement &a, const ActionDataPlacement &b) {
        // std::sort() in libc++ can compare an element with itself,
        // breaking our assertions below, so exit early in that case.
        if (&a == &b) return false;

        if (a.immediate == b.immediate) {
            if (a.start == b.start) {
                BUG("Two containers in the same action are at the same place?");
            }

            if ((a.start + a.size / 8 - 1 > b.start && b.start > a.start)
                || (b.start + b.size / 8 - 1 > a.start && a.start > b.start)) {
                BUG("Two containers overlap in the same action");
            }
        }
        if (a.immediate != b.immediate)
            return !a.immediate;
        return a.start < b.start;
    });
    int index = 0;
    int mask_index = 0;
    for (auto &placement : placement_vec) {
        if (placement.arg_locs.size() > 1) {
            placement.action_name = "$data" + std::to_string(index);
            if (placement.bitmasked_set) {
                placement.mask_name = "$mask" + std::to_string(mask_index++);
            }
            index++;
        } else if (placement.arg_locs.size() < 1) {
            placement.action_name = "$no_arg";
        }
    }
}

/** A way to perform an easy lookup of where the action data parameter is contained within the
 *  entire action data placement
 */
void ActionFormat::calculate_placement_data(safe_vector<ActionDataPlacement> &placement_vec,
                                            ArgPlacementData &apd) {
    int index = 0;
    for (auto &container : placement_vec) {
        for (auto arg_loc : container.arg_locs) {
            int bit_location = arg_loc.field_bit;
            if (arg_loc.is_constant)
                bit_location = 0;
            apd[std::make_pair(arg_loc.name, bit_location)].push_back(index);
        }
        index++;
    }
}

/** Calculates the immediate mask needed to be reserved in the table format of either the
 *  exact match table or the ternary indirect table
 */
void ActionFormat::calculate_immed_mask() {
    for (auto &placement_vec : Values(use->action_data_format)) {
        for (auto &placement : placement_vec) {
            if (!placement.immediate) continue;
            if (placement.specialities != 0) continue;
            use->immediate_mask |= (placement.range << (placement.start * 8));
            if (placement.bitmasked_set) {
                int mask_start = placement.start + placement.size / 8;
                use->immediate_mask |= (placement.range << (mask_start * 8));
            }
        }
    }

    if (!use->immediate_mask.empty())
        use->immediate_mask.setrange(0, use->immediate_mask.max().index());

    LOG2("Immediate mask " << use->immediate_mask);
}
