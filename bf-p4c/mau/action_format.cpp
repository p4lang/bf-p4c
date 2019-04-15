#include "action_format.h"
#include "input_xbar.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"

constexpr int ActionFormat::CONTAINER_SIZES[];

void ActionFormat::ActionContainerInfo::reset() {
    order = NOT_SET;
    maximum = -1;
    for (int i = 0; i < LOCATIONS; i++) {
        for (int j = 0; j < CONTAINER_TYPES; j++) {
            counts[i][j] = 0;
            layouts[i][j].clear();
            bitmasked_sets[i][j] = 0;
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

int ActionFormat::ActionContainerInfo::find_maximum_immed(bool meter_color, int hash_dist_bytes) {
    int max_byte = counts[IMMED][BYTE] > 0
        ? (counts[IMMED][BYTE] - 1) * 8 + minmaxes[NORMAL][BYTE] : 0;
    int max_half = counts[IMMED][HALF] > 0
        ? (counts[IMMED][HALF] - 1) * 16 + minmaxes[NORMAL][HALF] : 0;
    int max_full = counts[IMMED][FULL] > 0
        ? (counts[IMMED][FULL] - 1) * 32 + minmaxes[NORMAL][FULL] : 0;

    int maximum = 0;
    if (max_byte > 0 && max_half > 0) {
        if ((max_byte > max_half || hash_dist_bytes == 1) && !meter_color) {
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

int ActionFormat::ActionContainerInfo::total(ad_source_t source, bitmasked_t bm,
        cont_type_t type) const {
    if (bm == BITMASKED)
        return bitmasked_sets[source][type];
    else
        return counts[source][type] - bitmasked_sets[source][type] * 2;
}

bool ActionFormat::ActionDataForSingleALU::ArgLoc::operator==(
        const ActionFormat::ActionDataForSingleALU::ArgLoc &a) const {
    if (name != a.name) return false;
    if (field_bit != a.field_bit) return false;
    if (phv_loc != a.phv_loc) return false;
    return true;
}

bool ActionFormat::ActionDataForSingleALU::operator==(
        const ActionFormat::ActionDataForSingleALU &a) const {
    if (alu_size != a.alu_size) return false;
    if (phv_bits != a.phv_bits) return false;
    for (auto arg_loc : arg_locs) {
        if (std::find(a.arg_locs.begin(), a.arg_locs.end(), arg_loc) == a.arg_locs.end())
            return false;
    }

    return true;
}

/** If all the arguments are contained within another ALU op, all at the same shift position
 */
bool ActionFormat::ActionDataForSingleALU::contained_within(
        const ActionFormat::ActionDataForSingleALU &a) const {
    bool found = true;
    bool shift_set = false;
    int shift_offset = 0;

    bitvec arg_loc_bits;
    bitvec comp_arg_loc_bits;
    for (auto &arg_loc : arg_locs) {
        bool single_found = false;
        for (auto comp_arg_loc : a.arg_locs) {
            if (arg_loc.name != comp_arg_loc.name)
                continue;
            if (arg_loc.field_bit < comp_arg_loc.field_bit ||
                arg_loc.field_hi() > comp_arg_loc.field_hi())
                continue;

            int arg_shift = arg_loc.phv_loc.min().index();
            int comp_arg_shift = comp_arg_loc.phv_loc.min().index();

            int field_diff = arg_loc.field_bit - comp_arg_loc.field_bit;
            int potential_shift_offset = (arg_shift - comp_arg_shift) - field_diff;

            if (!shift_set) {
                shift_offset = potential_shift_offset;
                shift_set = true;
            } else if (shift_offset != potential_shift_offset) {
                continue;
            }
            single_found = true;
        }
        found &= single_found;
        if (!found)
            break;
    }
    return found;
}

/** If all arguments are contained at the exact location in order to maintain alignment
 *  with the PHV fields.
 */
bool ActionFormat::ActionDataForSingleALU::contained_exactly_within(
        const ActionFormat::ActionDataForSingleALU &a) const {
    for (auto &arg_loc : arg_locs) {
        if (std::find(a.arg_locs.begin(), a.arg_locs.end(), arg_loc) == a.arg_locs.end())
            return false;
    }
    return true;
}

/** Rules to condense:
 *  ISOLATED into ISOLATED: Have to be exactly the same, because the action data will overwrite
 *      the whole container
 *  BITMASKED_SET into ISOLATED: Just has to be within exactly, as the bitmasked-set has to be
 *      aligned, but the ISOLATED wouldn't have an impact on the mask.
 *  BITMASKED_SET into BITMASKED_SET: Have to be equivalent, as the masks have to be exactly
 *      equivalent
 *  NONE into ALL: Just has to be contained within, because the data can be shifted around
 */
bool ActionFormat::ActionDataForSingleALU::can_condense_into(
        const ActionFormat::ActionDataForSingleALU &a) const {
    if (is_constrained(ISOLATED)) {
        BUG_CHECK(a.is_constrained(ISOLATED), "Can only condense an isolated into a isolated");
        return (*this) == a;
    } else if (is_constrained(BITMASKED_SET)) {
        BUG_CHECK(a.is_constrained(ISOLATED) || a.is_constrained(BITMASKED_SET), "Can only "
                  "condense a bitmasked set into another bitmasked set or isolated");
        if (a.is_constrained(ISOLATED))
            return contained_exactly_within(a);
        else
            return (*this) == a;
    } else {
        return contained_within(a);
    }
}

void ActionFormat::ActionDataForSingleALU::shift_slot_bits(int shift) {
    slot_bits = phv_bits >> shift;
    for (auto &arg_loc : arg_locs) {
        arg_loc.slot_loc = arg_loc.phv_loc >> shift;
    }
}

void ActionFormat::ActionDataForSingleALU::set_slot_bits(const ActionDataForSingleALU &a) {
    for (auto &arg_loc : arg_locs) {
        bool single_found = false;
        for (auto &comp_arg_loc : a.arg_locs) {
            if (arg_loc.name != comp_arg_loc.name)
                continue;
            if (arg_loc.field_bit < comp_arg_loc.field_bit ||
                arg_loc.field_hi() > comp_arg_loc.field_hi())
                continue;

            single_found = true;
            arg_loc.slot_loc = comp_arg_loc.slot_loc;
            int diff;
            if ((diff = arg_loc.field_bit - comp_arg_loc.field_bit) > 0) {
                arg_loc.slot_loc.clrrange(arg_loc.slot_loc.min().index(), diff);
            }
            if ((diff = comp_arg_loc.field_hi() - arg_loc.field_hi()) > 0) {
                arg_loc.slot_loc.clrrange(arg_loc.slot_loc.max().index() - diff + 1, diff);
            }

            BUG_CHECK((slot_bits & arg_loc.slot_loc).empty(), "Incorrectly overlapping action "
                      "data when setting slot bits.");
            slot_bits |= arg_loc.slot_loc;
        }
        BUG_CHECK(single_found, "Could not find the location of an argument");
    }
}

ActionFormat::ActionDataFormatSlot::ActionDataFormatSlot(ActionDataForSingleALU *ad_alu)
    : slot_size(ad_alu->alu_size), bitmasked_set(ad_alu->bitmasked_set),
      global_constraints(ad_alu->constraints), specialities(ad_alu->specialities) {
    action_data_alus.push_back(ad_alu);
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
                hi -= (hi % CONTAINER_SIZES[type]) - range.max().index();
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

bool ActionFormat::Use::in_layouts(int byte_offset, const bitvec layouts[CONTAINER_TYPES]) const {
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        if (layouts[i].getrange(byte_offset, (CONTAINER_SIZES[i] / 8)))
            return true;
    }
    return false;
}

/** Will determine which hash distribution unit is on the action bus at a particular
 *  byte offset.
 */
bool ActionFormat::Use::is_hash_dist(int byte_offset, const IR::MAU::HashDist **hd,
        int &field_lo, int &field_hi) const {
    if (!in_layouts(byte_offset, hash_dist_layouts))
        return false;

    bool found = false;
    for (auto &hd_placement : hash_dist_placement) {
        for (auto &adp : hd_placement.second) {
            if (adp.start == byte_offset) {
                found = true;
                *hd = hd_placement.first;
                field_lo = adp.arg_locs[0].field_bit;
                field_hi = adp.arg_locs[0].field_hi();
            }
        }
    }

    BUG_CHECK(found, "Could not find associated hash distribution even though action format "
                     "is set up to be hash dist");
    return found;
}

/** Checks to see if a particular byte of a layout is one contained by the Random Number
 *  Generator
 */
bool ActionFormat::Use::is_rand_num(int byte_offset, const IR::MAU::RandomNumber **rn_ptr) const {
    if (!in_layouts(byte_offset, rand_num_layouts))
        return false;

    bool found = false;
    for (auto &rand_num_entry : rand_num_placement) {
        for (auto &adp : rand_num_entry.second) {
            if (adp.start == byte_offset) {
                found = true;
                *rn_ptr = rand_num_entry.first;
                break;
            }
        }
    }
    BUG_CHECK(found, "Could not find associated random number, even though the action format "
                     "has allocated space for that random number");
    return found;
}

/** Given a random number IR node, and a slice of field_lo and field_hi, this will determine
 *  which section of the 32 bits the random number for this ALU is.
 */
void ActionFormat::Use::find_rand_num(const IR::MAU::RandomNumber *rn, int field_lo,
        int field_hi, int &rng_lo, int &rng_hi) const {
    auto rn_placement = rand_num_placement.at(rn);

    bitvec field_bv(field_lo, field_hi - field_lo + 1);
    bool found = false;
    for (auto &placement : rn_placement) {
        auto &arg_loc = placement.arg_locs[0];
        bitvec arg_loc_bv(arg_loc.field_bit, arg_loc.width());
        if ((arg_loc_bv & field_bv) == arg_loc_bv) {
            rng_lo = placement.start * 8 + field_lo - arg_loc.field_bit;
            rng_hi = arg_loc.width() + rng_lo - 1;
            found = true;
            break;
        }
    }
    BUG_CHECK(found, "Cannot find random number correctly");
}

/** Meter color reserved in the top byte of immediate */
bool ActionFormat::Use::is_meter_color(int start_byte, bool immediate) const {
    return meter_reserved && immediate && start_byte == (IMMEDIATE_BYTES - 1);
}

/** During output to assembly, the hash distribution unit in the allocation needs to be
 *  resolved on its location.  The purpose of this function is to coordinate the field range,
 *  which is the range used in an action, to the position within the 32 possible bits of
 *  immediate from.
 *
 *  if the instruction was:
 *      set f1 (8 bit field), hash_dist
 *
 *  Let's say that the hash_dist field appears in bits 8..15 of the immediate data bits.
 *  The field_range would be 0..7, and the hash_dist_range that will be returned will be
 *  the position in the immeidate data bits, 0..7
 *
 *  The hash distribution units are in 16 bit sections of 6 sections.  The sections are defined
 *  in the input xbar allocation of the hash distribution unit.  The unit indexes returned are
 *  the index of 16 bit sections stored in the input xbar allocation
 *
 *  If only one index is used, then the section in which the hash distribution is used will
 *  be the index of which section is used.  If only bits 0..15 are used, then section = 0,
 *  if only bits 16..31 are used then section = 1
 *
 *  This is also based on the assumption that the hash dist allocation is identical to the
 *  slot location of the arg_loc.  One in theory could adjust the slot loc to better fit
 *  into the input xbar, but this is not yet done.
 */
safe_vector<int> ActionFormat::Use::find_hash_dist(const IR::MAU::HashDist *hd,
       le_bitrange field_range, bool bit_required, le_bitrange &hash_dist_range,
       int &section) const {
    BUG_CHECK(hash_dist_placement.find(hd) != hash_dist_placement.end(), "Hash Dist IR cannot "
              "be found within the action format");

    bool found = false;
    auto &hd_vec = hash_dist_placement.at(hd);
    bitvec field_bv = bitvec(field_range.lo, field_range.size());
    bitvec hash_dist_output;
    bitvec hash_dist_bv;
    bitvec all_hash_dist_bv;
    int alu_size = -1;

    safe_vector<int> unit_indexes;

    // Currently assumed to be a single slot, as the packing does not pack multiple hash
    // dist slots together.  Once the allocation is more fine-grained, this will have to change.
    for (auto &placement : hd_vec) {
        auto &arg_loc = placement.arg_locs[0];
        all_hash_dist_bv |= arg_loc.slot_loc << (placement.start * 8);
        bitvec arg_loc_bv(arg_loc.field_bit, arg_loc.width());
        if ((arg_loc_bv & field_bv) == arg_loc_bv) {
            BUG_CHECK(!found, "Hash distribution splitting too complicated");
            hash_dist_bv |= arg_loc.slot_loc << (placement.start * 8);
            found = true;
            alu_size = placement.alu_size;
        } else if ((arg_loc_bv & field_bv).empty()) {
            continue;
        } else {
            BUG("Cannot find hash distribution correctly");
        }
    }
    BUG_CHECK(found, "Cannot find hash distribution correctly");

    int unit_index = 0;
    for (int i = 0; i < IMMEDIATE_BYTES * 8; i += IXBar::HASH_DIST_BITS) {
        bitvec hash_dist_slice(i, IXBar::HASH_DIST_BITS);
        if (!(hash_dist_slice & hash_dist_bv).empty())
            unit_indexes.push_back(unit_index);
        unit_index++;
    }

    int mod_value = unit_indexes.size() * IXBar::HASH_DIST_BITS;

    int hash_lo = -1;
    int hash_hi = -1;
    // Bit granularity needed for action outputs
    if (bit_required) {
        hash_lo = hash_dist_bv.min().index() % mod_value;
        hash_hi = hash_dist_bv.max().index() % mod_value;
    } else {
        // Slot granularity needed for action data bus output
        hash_lo = ((hash_dist_bv.min().index() / alu_size) * alu_size) % mod_value;
        hash_hi = (hash_lo + alu_size - 1) % mod_value;
    }
    hash_dist_range = { hash_lo, hash_hi };

    if (unit_indexes.size() == 1) {
        section = hash_dist_bv.min().index() / IXBar::HASH_DIST_BITS;
    }
    return unit_indexes;
}

/** The allocation scheme for the action data format and immediate format.
 */
void ActionFormat::allocate_format(safe_vector<Use> &uses, bool immediate_allowed) {
    LOG2("Allocating Table Format for " << tbl->name);
    if (!analyze_all_actions())
        return;
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
 *  The information provided are what arguments are in what action data slot, and the
 *  necessary sizes of the action data slots.
 */
void ActionFormat::create_placement_non_phv(const ActionAnalysis::FieldActionsMap &field_actions,
                                            cstring action_name) {
    // FIXME: Verification on some argument limitations still required
    safe_vector<ActionDataForSingleALU> adp_vector;
    for (auto &field_action_info : field_actions) {
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
                ActionDataForSingleALU adp;
                cstring arg_name;
                if (auto *sl = read.expr->to<IR::Slice>())
                    arg_name = sl->e0->to<IR::MAU::ActionArg>()->name;
                else
                    arg_name = read.expr->to<IR::MAU::ActionArg>()->name;

                adp.arg_locs.emplace_back(arg_name, data_location, 0, single_loc);
                adp.alu_size = container_size;
                adp.phv_bits = data_location;
                adp_vector.push_back(adp);
                bits_allocated += data_location.popcount();
            }
        }
    }

    init_alu_format[action_name] = adp_vector;
}

/** Creates an ActionDataPlacement from an MAU::ActionArg, correctly verified from the PHV allocation
 */
void ActionFormat::create_from_actiondata(ActionDataForSingleALU &adp,
        const ActionAnalysis::ActionParam &read, int container_bit,
        const IR::MAU::HashDist **hd, const IR::MAU::RandomNumber **rn) {
    bitvec data_location;
    bool single_loc = true;
    int field_bit = 0;
    if (auto *sl = read.expr->to<IR::Slice>()) {
        single_loc = false;
        field_bit = sl->getL();
    }

    data_location.setrange(container_bit, read.size());
    cstring arg_name;
    if (read.speciality == ActionAnalysis::ActionParam::HASH_DIST) {
        arg_name = "hash_dist";
        *hd = read.unsliced_expr()->to<IR::MAU::HashDist>();
    } else if (read.speciality == ActionAnalysis::ActionParam::RANDOM) {
        arg_name = "random";
        *rn = read.unsliced_expr()->to<IR::MAU::RandomNumber>();
    } else if (read.speciality == ActionAnalysis::ActionParam::NO_SPECIAL) {
        arg_name = read.unsliced_expr()->to<IR::MAU::ActionArg>()->name;
    } else if (read.speciality == ActionAnalysis::ActionParam::METER_COLOR) {
        arg_name = "meter";
    } else {
        BUG("Currently cannot handle the speciality %d in ActionFormat creation",
            read.speciality);
    }

    adp.arg_locs.emplace_back(arg_name, data_location, field_bit, single_loc);
    adp.arg_locs.back().speciality = read.speciality;

    if (read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL)
        adp.specialities |= 1 << read.speciality;
    adp.phv_bits |= data_location;
}

/** Creates an ActionDataPlacement from a Constant that has to be converted into ActionData.
 *  This constant will later be converted to a ActionDataConstant in the InstructionAdjustment
 *  pass.
 */
void ActionFormat::create_from_constant(ActionDataForSingleALU &adp,
         const ActionAnalysis::ActionParam &read, int field_bit, int container_bit,
         int &constant_to_ad_count) {
    bitvec data_location;
    bool single_loc = true;

    data_location.setrange(container_bit, read.size());
    auto arg_name = "$constant" + std::to_string(constant_to_ad_count);
    adp.arg_locs.emplace_back(arg_name, data_location, field_bit,
                              single_loc);
    adp.phv_bits |= data_location;
    constant_to_ad_count++;

    auto constant_value = read.expr->to<IR::Constant>()->asUint64();
    BUG_CHECK(constant_value <= UINT_MAX,
              "constant out of range for 32 bits: %ld", constant_value);
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
void ActionFormat::create_placement_phv(
        const ActionAnalysis::ContainerActionsMap &container_actions,
        cstring action_name) {
    safe_vector<ActionDataForSingleALU> adp_vector;
    int constant_to_ad_count = 0;
    for (auto &container_action_info : container_actions) {
        auto container = container_action_info.first;
        auto &cont_action = container_action_info.second;
        ActionDataForSingleALU adp;
        adp.container_valid = true;
        // Every instruction in the container process has to have its action data stored
        // in the same action data slot
        bool initialized = false;
        const IR::MAU::HashDist *hd = nullptr;
        const IR::MAU::RandomNumber *rn = nullptr;
        if (cont_action.action_data_isolated())
            adp.set_constraint(ISOLATED);
        if (cont_action.convert_instr_to_bitmasked_set)
            adp.set_constraint(BITMASKED_SET);

        for (auto &field_action : cont_action.field_actions) {
            le_bitrange bits;
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
                adp.container = alloc.container;
            });

            if (write_count > 1)
                BUG("Splitting of writes handled incorrectly");

            for (auto &read : field_action.reads) {
                if (read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL &&
                    read.speciality != ActionAnalysis::ActionParam::METER_COLOR &&
                    read.speciality != ActionAnalysis::ActionParam::RANDOM &&
                    read.speciality != ActionAnalysis::ActionParam::HASH_DIST)
                    continue;
                if (read.type == ActionAnalysis::ActionParam::ACTIONDATA) {
                    create_from_actiondata(adp, read, container_bits.lo, &hd, &rn);
                    initialized = true;
                    if (cont_action.unresolved_ad())
                        adp.single_rename = true;
                } else if (read.type == ActionAnalysis::ActionParam::CONSTANT
                    && cont_action.convert_constant_to_actiondata()) {
                    create_from_constant(adp, read, bits.lo, container_bits.lo,
                                         constant_to_ad_count);
                    initialized = true;
                }
            }
        }
        adp.alu_size = container.size();

        if (hd) {
           if (cont_action.convert_instr_to_bitmasked_set)
               P4C_UNIMPLEMENTED("Can't yet handle a hash distribution unit in a bitmasked-set");
           auto &hash_dist_vec = init_hd_alu_placement[hd];
           hash_dist_vec.push_back(adp);
        } else if (rn) {
           if (cont_action.convert_instr_to_bitmasked_set)
               P4C_UNIMPLEMENTED("Can't yet handle a random number in a bitmasked-set");
           auto &rand_num_vec = init_rn_alu_placement[rn];
           rand_num_vec.push_back(adp);
        } else if (initialized) {
            if (cont_action.convert_instr_to_bitmasked_set)
                adp.bitmasked_set = true;
            adp_vector.push_back(adp);
        }
    }

    init_alu_format[action_name] = adp_vector;
}

/** Performs the argument analyzer and initializes the vector of ActionContainerInfo
 */
bool ActionFormat::analyze_all_actions() {
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


    optimize_sharing();
    initialize_action_counts();
    bool hash_fits = initialize_global_params_counts();
    return hash_fits;
}

/** The purpose of this function is to potentially share action bits on a RAM between multiple
 *  ALU operation, as well as set at what bit position each Action Argument is going to be
 *
 *  Action Arguments come with 3 levels of constraints:
 *
 *  ISOLATED - the action argument is headed to a non-set operation, and thus cannot be packed
 *      with any other argument.  The argument must be aligned with it's PHV operation
 *  BITMASKED_SET - the action arguments must be placed at the location of their PHV, as the
 *      bitmasked_set operation has no ability to move anything around
 *  NONE - the argument is used in a set operation, and can be moved anywhere within the container
 *         as long as the bits are in the same position post-shift
 */
void ActionFormat::optimize_sharing() {
    init_slot_format.clear();
    SingleActionSlotPlacement empty_sasp;
    for (auto &single_action : init_alu_format) {
        init_slot_format[single_action.first] = empty_sasp;
        for (auto &alu_ad : single_action.second) {
            init_slot_format[single_action.first].emplace_back(&alu_ad);
        }
    }

    for (auto &single_action : init_slot_format) {
        condense_action_data(single_action.second);
        set_slot_bits(single_action.second);
        pack_slot_bits(single_action.second);
    }
}

/** This function tries to combine ActionDataFormatSlots if the parameters in those particular slots
 *  overlap.  Initially all ActionDataForSingleALU is given it's own slot on the memory algorithm
 *  and then if the parameters overlap correctly, the slots are combined.  This deals with
 *  the following example:
 *
 *      hdr.f1 = param1;
 *      hdr.f2 = param1;
 *
 *  These two ActionDataForSingleALU functions would be combined into one ActionDataFormatSlot
 *  after this function is completed.
 *
 *  Currently this function only combines the action data if they are in the same slot size,
 *  meaning that hdr.f1 and hdr.f2 have to be in the same container size.
 *
 *  Furthermore, the algorithm only will condense less constrained slots into more constrained
 *  slots, i.e. an ISOLATED can only be condensed into another ISOLATED, and a no constrained
 *  can be condensed into anything
 */
void ActionFormat::condense_action_data(SingleActionSlotPlacement &info) {
    for (size_t i = 0; i < info.size(); i++) {
        for (size_t j = 0; j < info.size(); j++) {
            if (i == j) continue;
            // Trying to fully condense the original slot on the comparison slot
            auto &orig_sap = info[i];
            auto &comp_sap = info[j];

            if (comp_sap.deletable) continue;
            // Do not condense a more constrained slot on a less constrained slot
            if (orig_sap.global_constraints > comp_sap.global_constraints)
                continue;
            if (orig_sap.slot_size != comp_sap.slot_size)
                continue;

            bool can_condense = true;
            for (auto &alu_ad : orig_sap.action_data_alus) {
                for (auto &comp_alu_ad : comp_sap.action_data_alus) {
                    if (alu_ad->constraints > comp_alu_ad->constraints) continue;
                    can_condense &= alu_ad->can_condense_into(*comp_alu_ad);
                    if (!can_condense)
                        break;
                }
                if (!can_condense)
                    break;
            }

            if (!can_condense)
                continue;

            comp_sap.action_data_alus.insert(comp_sap.action_data_alus.end(),
                                             orig_sap.action_data_alus.begin(),
                                             orig_sap.action_data_alus.end());
            comp_sap.global_constraints |= orig_sap.global_constraints;

            // Mark as removable, as the slot has been condensed
            orig_sap.deletable = true;
            break;
        }
    }

    auto it = info.begin();
    while (it != info.end()) {
        if (it->deletable) {
            it = info.erase(it);
        } else {
            it++;
        }
    }
}

/** Sets the location of each of the arguments in an AD ALU.  This does not yet potentially
 *  combine sets of the same size.
 */
void ActionFormat::set_slot_bits(SingleActionSlotPlacement &info) {
    for (auto &sap : info) {
        // Find the most constrained ALU op, and build the action data information from there
        ActionDataForSingleALU *most_const = nullptr;
        for (auto ad_alu : sap.action_data_alus) {
            if (most_const == nullptr) {
                most_const = ad_alu;
            } else {
                if (ad_alu->constraints > most_const->constraints)
                    most_const = ad_alu;
                else if (ad_alu->phv_bits.popcount() > most_const->phv_bits.popcount())
                    most_const = ad_alu;
            }
        }

        if (most_const->constraints == 0U && most_const->specialities == 0U) {
            int shift = most_const->phv_bits.min().index();
            most_const->shift_slot_bits(shift);
        } else {
            most_const->shift_slot_bits(0);
        }

        for (auto ad_alu : sap.action_data_alus) {
            if (ad_alu != most_const) {
                ad_alu->set_slot_bits(*most_const);
            }
            sap.total_range |= ad_alu->slot_bits;
        }
    }
}

void ActionFormat::ActionDataFormatSlot::shift_up(int shift_bits) {
    for (auto &ad_alu : action_data_alus) {
        for (auto &arg_loc : ad_alu->arg_locs) {
            arg_loc.slot_loc <<= shift_bits;
        }
        ad_alu->slot_bits <<= shift_bits;
    }
    total_range <<= shift_bits;
}

/** If two action data parameters are only used in move operations, and do not require
 *  isolation, then can be packed within the same slot on the RAM line.  This currently will
 *  only pack data that is in the same sized slot, as the algorithm requires each action data
 *  slot size to be packed separately.
 *
 *  The whole action data packing could really use either a SAT solving approach or an
 *  approach like PHV in order to really tightly pack information in
 */
void ActionFormat::pack_slot_bits(SingleActionSlotPlacement &info) {
    for (size_t i = 0; i < info.size(); i++) {
        for (size_t j = 0; j < info.size(); j++) {
            if (i == j) continue;
            auto &orig_sap = info[i];
            auto &comp_sap = info[j];
            if (orig_sap.global_constraints != 0 || orig_sap.specialities != 0)
                break;
            if (comp_sap.global_constraints != 0 || comp_sap.specialities != 0)
                continue;
            if (comp_sap.deletable) continue;
            if (orig_sap.slot_size != comp_sap.slot_size)
                continue;

            int orig_sap_max = orig_sap.total_range.max().index() + 1;
            int comp_sap_max = comp_sap.total_range.max().index() + 1;

            if (orig_sap_max + comp_sap_max > orig_sap.slot_size)
                continue;

            orig_sap.shift_up(comp_sap_max);
            comp_sap.action_data_alus.insert(comp_sap.action_data_alus.end(),
                                             orig_sap.action_data_alus.begin(),
                                             orig_sap.action_data_alus.end());
            comp_sap.total_range |= orig_sap.total_range;
            orig_sap.deletable = true;
            break;
        }
    }

    auto it = info.begin();
    while (it != info.end()) {
        if (it->deletable) {
            it = info.erase(it);
        } else {
            it++;
        }
    }
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
        auto &placement_vec = init_slot_format.at(action->name);
        for (auto &placement : placement_vec) {
            bool valid_container_size = false;
            for (int i = 0; i < CONTAINER_TYPES; i++) {
                valid_container_size |= placement.slot_size == CONTAINER_SIZES[i];
            }
            BUG_CHECK(valid_container_size, "Action data packed in slot that is not a valid "
                                            "size: %d", placement.slot_size);
            int index = placement.gen_index();
            if ((placement.specialities & (1 << ActionAnalysis::ActionParam::METER_COLOR)) != 0) {
                BUG_CHECK(index == BYTE, "Due to complexity in action bus, can only currently "
                          "handle meter color in an 8 bit ALU operation, and nothing else.");
                aci.meter_reserved = true;
                meter_color = true;
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
                                                    placement.total_range.max().index() + 1);
        }
        aci.finalize_min_maxes();
        init_action_counts.push_back(aci);
    }
}

/** Global parameters are action data that is enabled for every single action.  Essentially
 *  data from hash distribution, the random number generator, and meter color (not actually sure)
 *  are not enabled per action, but will OR into the immediate 32 bits no matter if the
 *  ALUs use that particular piece of action data.
 */
bool ActionFormat::initialize_global_params_counts() {
    for (auto &hd_vec_pair : init_hd_alu_placement) {
        for (auto &alu_hd : hd_vec_pair.second) {
             alu_hd.shift_slot_bits(0);
             init_hd_slot_placement[hd_vec_pair.first].emplace_back(&alu_hd);
        }
    }

    for (auto &rn_vec_pair : init_rn_alu_placement) {
        for (auto &alu_rn : rn_vec_pair.second) {
            alu_rn.shift_slot_bits(0);
            init_rn_slot_placement[rn_vec_pair.first].emplace_back(&alu_rn);
        }
    }

    for (auto &hd_vec : Values(init_hd_slot_placement)) {
        for (auto &adp : hd_vec) {
            int index = adp.gen_index();
            global_params.counts[IMMED][index]++;
        }
    }

    for (auto &rn_vec : Values(init_rn_slot_placement)) {
        for (auto &adp : rn_vec) {
            int index = adp.gen_index();
            global_params.counts[IMMED][index]++;
        }
    }


    int immediate_bytes_available = IMMEDIATE_BYTES;
    if (meter_color)
        immediate_bytes_available--;


    if (global_params.total_bytes(IMMED) > immediate_bytes_available) {
        error("In table %s, the number of bytes required to go through the immediate pathway %d "
              "is greater than the available bytes %d, and can not be allocated", tbl->name,
               global_params.total_bytes(IMMED), immediate_bytes_available);
        return false;
    }
    return true;
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
    use->phv_alloc = alloc_done;
    LOG2("Action data bytes IMMED: " << use->action_data_bytes[IMMED] << " ADT: "
         << use->action_data_bytes[ADT] << " in table " << tbl->name);
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

    int hash_dist_bytes = global_params.total_bytes(IMMED);

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
        int max_immediate_bytes = IMMEDIATE_BYTES - hash_dist_bytes;
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
        int local_maximum = aci.find_maximum_immed(meter_color, global_params.total_bytes(IMMED));
        max_total.maximum = std::max(local_maximum, max_total.maximum);
    }
}

/** Find a spot for all Action Data Table and Immediate bytes
 */
void ActionFormat::space_containers() {
    space_all_table_containers();
    int start_byte = space_global_params();
    space_all_immediate_containers(start_byte);
    space_all_meter_color();
    resolve_container_info();

    for (auto &aci : action_counts) {
        LOG3("Action info " << aci);
    }

    for (int i = 0; i < CONTAINER_TYPES; i++) {
        LOG3("Layout ADT: 0x" << use->total_layouts[ADT][i] << " IMMED: "
             << use->total_layouts[IMMED][i]);
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

        bitvec half_range;
        for (int i = 0; i < count_half; i++) {
            half_range.setrange(half_ends - 2 * i - 2, 2);
        }
        aci.layouts[ADT][HALF] |= half_range;
        // Due to bitmasked-sets of FULL words being packed together the location of where
        // half words can be per word might not fit within the pre-calculated range
        use->total_layouts[ADT][HALF] |= half_range;

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

void ActionFormat::resolve_container_info() {
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        for (int j = 0; j < LOCATIONS; j++) {
            use->total_layouts[j][i].clear();
        }
    }

    for (auto &aci : action_counts) {
        for (int i = 0; i < CONTAINER_TYPES; i++) {
            for (int j = 0; j < LOCATIONS; j++) {
                use->total_layouts[j][i] |= aci.layouts[j][i];
            }
        }
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
void ActionFormat::space_individ_immed(ActionContainerInfo &aci, int min_start) {
    if (aci.order == ActionContainerInfo::FIRST_8 || aci.order == ActionContainerInfo::FIRST_16) {
        int first = HALF; int second = BYTE;
        if (aci.order == ActionContainerInfo::FIRST_8) {
            first = BYTE;
            second = HALF;
        }
        if (aci.counts[IMMED][first] > 0) {
            if (min_start > 0)
                BUG_CHECK(first == BYTE && aci.counts[IMMED][first] == 1, "Miscoordination of "
                          "hash distribution fields and normal fields");
            aci.layouts[IMMED][first]
                |= bitvec(min_start, aci.counts[IMMED][first] * (CONTAINER_SIZES[first] / 8));
        } else {
             BUG("Should never be reached");
        }
        if (aci.counts[IMMED][second] > 0)
            aci.layouts[IMMED][second]
                |= bitvec(2, aci.counts[IMMED][second] * (CONTAINER_SIZES[second] / 8));
        else
            BUG("Should never be reached");
    } else {
        // TODO: Could do even better byte packing potentially, not currently saving a byte
        for (int i = 0; i < CONTAINER_TYPES; i++) {
            if (aci.counts[IMMED][i] > 0) {
                int container_bytes = CONTAINER_SIZES[i] / 8;
                int start_byte = min_start;
                if (start_byte % container_bytes != 0)
                    start_byte += (container_bytes - (start_byte % container_bytes));
                aci.layouts[IMMED][i]
                    |= bitvec(start_byte, aci.counts[IMMED][i] * CONTAINER_SIZES[i] / 8);
            }
        }
    }

    if ((aci.layouts[IMMED][BYTE] & aci.layouts[IMMED][HALF]
         & aci.layouts[IMMED][FULL]).popcount() != 0)
        BUG("Erroneous layout of immediate data");
}

/** Simply just reserves the upper byte of immediate for meter color. */
void ActionFormat::space_all_meter_color() {
    for (auto &aci : action_counts) {
        if (!aci.meter_reserved) continue;
        aci.layouts[IMMED][BYTE].setbit(IMMEDIATE_BYTES - 1);
        use->total_layouts[IMMED][BYTE] |= aci.layouts[IMMED][BYTE];
        use->meter_reserved = true;
    }
}

/** Reserves spaces for all the hash distribution format.  Returns the first byte to start
 *  allocating standard immediate data in.  Allocates 32 bits, then 16 bits, then 8 bits
 *  last until out of space.
 */
int ActionFormat::space_global_params() {
    int start_byte = 0;
    for (int i = FULL; i >= BYTE; i--) {
        for (int j = 0; j < global_params.counts[IMMED][i]; j++) {
            global_params.layouts[IMMED][i] |= bitvec(start_byte, CONTAINER_SIZES[i] / 8);
            start_byte += CONTAINER_SIZES[i] / 8;
        }
    }

    for (int i = 0 ; i < CONTAINER_TYPES; i++) {
        use->global_param_layouts[i] |= global_params.layouts[IMMED][i];
    }

    return start_byte;
}

/** Simply find the action data formats for immediate data for every single action */
void ActionFormat::space_all_immediate_containers(int start_byte) {
    max_bytes = action_bytes[IMMED];
    if (max_bytes == 0)
        return;
    for (auto aci : action_counts) {
        BUG_CHECK(aci.total_bytes(IMMED) <= max_bytes, "Somehow have more bytes than "
                  "possibly allocate");
    }

    // XXX(hanw): used where?
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
        space_individ_immed(aci, start_byte);
        for (int i = 0; i < CONTAINER_TYPES; i++)
            use->total_layouts[IMMED][i] |= aci.layouts[IMMED][i];
    }
}

/** Goes through each hash distribution action format and pick a space within the action
 *  for it
 */
void ActionFormat::align_global_params(bitvec global_params_layouts[CONTAINER_TYPES]) {
    auto hd_slot_placement = init_hd_slot_placement;
    auto rn_slot_placement = init_rn_slot_placement;
    int placed[BITMASKED_TYPES][CONTAINER_TYPES] = {{0, 0, 0}, {0, 0, 0}};

    bitvec layouts_placed[CONTAINER_TYPES];
    for (int i = 0; i < CONTAINER_TYPES; i++) {
        layouts_placed[i] = global_params_layouts[i];
    }

    for (auto &hd_info : hd_slot_placement) {
        SingleActionSlotPlacement output_vec;
        auto hd = hd_info.first;
        auto hd_vec = hd_info.second;
        align_section(hd_vec, output_vec, global_params, IMMED, NORMAL, layouts_placed,
                      placed);
        verify_placement(output_vec, use->hash_dist_placement[hd], hd_vec);
    }

    for (int i = 0; i < CONTAINER_TYPES; i++) {
        use->hash_dist_layouts[i] = layouts_placed[i] - global_params_layouts[i];
        global_params_layouts[i] = layouts_placed[i];
    }


    for (auto &rn_info : rn_slot_placement) {
        SingleActionSlotPlacement output_vec;
        auto rn = rn_info.first;
        auto rn_vec = rn_info.second;
        align_section(rn_vec, output_vec, global_params, IMMED, NORMAL, layouts_placed,
                      placed);
        verify_placement(output_vec, use->rand_num_placement[rn], rn_vec);
    }

    for (int i = 0; i < CONTAINER_TYPES; i++) {
        use->rand_num_layouts[i] = layouts_placed[i] - global_params_layouts[i];
        global_params_layouts[i] = layouts_placed[i];
    }
}

/** Simple placement of the upper byte of immediate for each action tthat requires a meter color.
 */
void ActionFormat::reserve_meter_color(SingleActionSlotPlacement &placement_vec,
        SingleActionSlotPlacement &output_vec, ActionContainerInfo &aci,
        bitvec layouts_placed[CONTAINER_TYPES]) {
    if (!aci.meter_reserved)
        return;
    int byte_sz = CONTAINER_SIZES[BYTE];
    auto it = placement_vec.begin();
    while (it != placement_vec.end()) {
        if (it->specialities & (1 << ActionAnalysis::ActionParam::METER_COLOR)) {
            it->byte_start = IMMEDIATE_BYTES - 1;
            it->immediate = true;
            layouts_placed[BYTE].setrange(IMMEDIATE_BYTES - 1, byte_sz);
            output_vec.push_back(*it);
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
void ActionFormat::align_section(SingleActionSlotPlacement &placement_vec,
        SingleActionSlotPlacement &output_vec, ActionContainerInfo &aci,
        ActionFormat::ad_source_t source,
        bitmasked_t bm, bitvec layouts_placed[CONTAINER_TYPES],
        int placed[BITMASKED_TYPES][CONTAINER_TYPES]) {
    int multiplier = static_cast<int>(bm) + 1;

    auto it = placement_vec.begin();
    while (it != placement_vec.end()) {
        if ((it->bitmasked_set && bm != BITMASKED) || (!it->bitmasked_set && bm == BITMASKED)) {
            it++;
            continue;
        }
        auto index = it->gen_index();

        if (placed[bm][index] >= aci.total(source, bm, static_cast<cont_type_t>(index))) {
            it++;
            continue;
        }

        int byte_sz = CONTAINER_SIZES[index] / 8;
        int lookup = 0;
        int init_byte = 0;
        int max = aci.layouts[source][index].max().index() + 1;
        bool found = false;

        // Find the location of a placement, given an action's placement within actions
        do {
            found = true;
            init_byte = aci.layouts[source][index].ffs(lookup);
            lookup = init_byte + byte_sz;
            if (layouts_placed[index].getrange(init_byte, byte_sz * multiplier) != 0) {
                found = false;
            } else if (aci.layouts[source][index].getslice(
                    init_byte, byte_sz * multiplier).popcount()
                != byte_sz * multiplier) {
                found = false;
            } else if ((init_byte % (byte_sz * multiplier)) != 0) {
                found = false;
            }
        } while (found == false && lookup < max);
        BUG_CHECK(found, "Could not match up action data allocation byte");

        it->byte_start = init_byte;
        it->immediate = (source == IMMED) ? true : false;
        layouts_placed[index].setrange(init_byte, byte_sz * multiplier);
        placed[bm][index]++;

        output_vec.push_back(*it);
        // use->action_data_format.at(aci.action).push_back(*it);
        it = placement_vec.erase(it);
    }
}

/** For immediate section, in order to conserve space, the algorithm tries to find the
 *  action data that has the lowest lsb, and allocate that particular slice of action data
 *  last in order to better maximize packing.
 */
void ActionFormat::find_immed_last(SingleActionSlotPlacement &placement_vec,
        SingleActionSlotPlacement &output_vec, ActionContainerInfo &aci,
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
        if (it->total_range.max().index() + 1 != aci.minmaxes[NORMAL][max_index]) {
            it++;
            continue;
        }
        it->byte_start = init_byte;
        it->immediate = true;
        layouts_placed[index].setrange(init_byte, byte_sz);
        placed[NORMAL][index]++;

        output_vec.push_back(*it);
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
    TotalSlotPlacement format = init_slot_format;
    bitvec global_params_layouts[CONTAINER_TYPES];
    align_global_params(global_params_layouts);

    for (auto aci : action_counts) {
        SingleActionSlotPlacement output_vec;
        for (int i = IMMED; i >= ADT; i--) {
            int placed[BITMASKED_TYPES][CONTAINER_TYPES] = {{0, 0, 0}, {0, 0, 0}};
            auto loc = static_cast<ad_source_t>(i);
            bitvec layouts_placed[CONTAINER_TYPES];
            if (i == IMMED) {
                for (int i = 0; i < CONTAINER_TYPES; i++) {
                    layouts_placed[i] |= global_params_layouts[i];
                }
            }
            if (i == IMMED)
                reserve_meter_color(format[aci.action], output_vec, aci, layouts_placed);
            align_section(format[aci.action], output_vec, aci, loc, BITMASKED, layouts_placed,
                          placed);
            if (i == IMMED)
                find_immed_last(format[aci.action], output_vec, aci, layouts_placed, placed);
            align_section(format[aci.action], output_vec, aci, loc, NORMAL, layouts_placed,
                          placed);
        }
        verify_placement(output_vec, use->action_data_format[aci.action], format[aci.action]);
    }

    for (auto aci : action_counts) {
        determine_asm_name(use->action_data_format.at(aci.action));
        use->arg_placement[aci.action] = ArgPlacementData();
        use->constant_locations[aci.action] = ConstantRenames();
        calculate_placement_data(use->action_data_format.at(aci.action),
                                 use->arg_placement[aci.action],
                                 use->constant_locations[aci.action]);
    }
    calculate_immed_mask();
}



void ActionFormat::verify_placement(SingleActionSlotPlacement &slot_placement,
        SingleActionALUPlacement &alu_placement, SingleActionSlotPlacement &orig_placement) {
    BUG_CHECK(orig_placement.empty(), "Did not fully allocation action data for an action");
    std::sort(slot_placement.begin(), slot_placement.end(),
        [=](const ActionDataFormatSlot &a, const ActionDataFormatSlot &b) {
        // std::sort() in libc++ can compare an element with itself,
        // breaking our assertions below, so exit early in that case.
        if (&a == &b) return false;

        if (a.immediate == b.immediate) {
            if (a.byte_start == b.byte_start) {
                BUG("Two containers in the same action are at the same place?");
            }

            if ((a.byte_start + a.slot_size / 8 - 1 > b.byte_start
                    && b.byte_start > a.byte_start)
                || (b.byte_start + b.slot_size / 8 - 1 > a.byte_start
                    && a.byte_start > b.byte_start)) {
                BUG("Two containers overlap in the same action");
            }
        }
        if (a.immediate != b.immediate)
            return !a.immediate;
        return a.byte_start < b.byte_start;
    });


    for (auto &slot : slot_placement) {
        for (auto &alu : slot.action_data_alus) {
            alu_placement.push_back(*alu);
            alu_placement.back().immediate = slot.immediate;
            alu_placement.back().start = slot.byte_start;
        }
    }
}


/** This sorts the action data from lowest to highest bit position for easiest assembly output.
 *  It also verifies that two fields of action data within an individual action did not end up
 *  at the same point.  Lastly, if multiple action data parameters are contained within the same
 *  action data section, this must be renamed uniquely within the action for the assembler.
 *  Thus a unique asm_name could potentially be needed, and thus could be generated.
 */
void ActionFormat::determine_asm_name(SingleActionALUPlacement &placement_vec) {
    int index = 0;
    int mask_index = 0;
    for (auto &placement : placement_vec) {
        if (placement.arg_locs.size() > 1) {
            placement.action_name = "$data" + std::to_string(index++);
            if (placement.bitmasked_set) {
                placement.mask_name = "$mask" + std::to_string(mask_index++);
            }
        } else if (placement.single_rename) {
            placement.action_name = "$data" + std::to_string(index++);
        } else if (placement.arg_locs.size() < 1) {
            placement.action_name = "$no_arg";
        }
    }
}

/** A way to perform an easy lookup of where the action data parameter is contained within the
 *  entire action data placement
 */
void ActionFormat::calculate_placement_data(SingleActionALUPlacement &placement_vec,
                                            ArgPlacementData &apd, ConstantRenames &cr) {
    int placement_index = 0;
    for (auto &placement : placement_vec) {
        int arg_index = 0;
        for (auto arg_loc : placement.arg_locs) {
            ArgValue av(placement_index, arg_index);
            ArgKey ak;
            int field_bit = arg_loc.field_bit;
            if (arg_loc.is_constant)
                field_bit = 0;

            ak.init(arg_loc.name, field_bit, placement.container_valid,
                    placement.container, arg_loc.phv_cont_lo());
            apd[ak].push_back(av);
            arg_index++;
        }
        placement_index++;
    }

    placement_index = 0;
    for (auto &placement : placement_vec) {
        int arg_index = 0;
        for (auto &arg_loc : placement.arg_locs) {
            ArgValue av(placement_index, arg_index);
            arg_index++;
            if (!arg_loc.is_constant)
                continue;
            ArgKey ak;
            ak.init_constant(placement.container, arg_loc.phv_cont_lo());
            cr.emplace(ak, av);
        }
        placement_index++;
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
            use->immediate_mask |= (placement.slot_bits << (placement.start * 8));
            if (placement.bitmasked_set) {
                int mask_start = placement.start + placement.alu_size / 8;
                use->immediate_mask |= (placement.slot_bits << (mask_start * 8));
            }
        }
    }

    if (!use->immediate_mask.empty())
        use->immediate_mask.setrange(0, use->immediate_mask.max().index());

    LOG2("Immediate mask " << use->immediate_mask);
}
