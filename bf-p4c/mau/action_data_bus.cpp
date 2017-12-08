#include "bf-p4c/mau/action_data_bus.h"
#include "bf-p4c/mau/resource.h"

constexpr int ActionDataBus::ADB_STARTS[];
constexpr int ActionDataBus::IMMED_DIVIDES[];

/** Clears all of the allocation within the ActionDataBus, for the TableSummary
 */
void ActionDataBus::clear() {
    cont_use.clear();
    total_use.clear();
    for (auto &in_use : cont_in_use)
        in_use.clear();
    total_in_use.clear();
}


/** Conversion between a byte on the action data bus and the output of a particular type */
inline int ActionDataBus::byte_to_output(int byte, ActionFormat::cont_type_t type) {
    if (type == ActionFormat::FULL)
        return byte / find_byte_sz(type);
    else
        return (byte - ADB_STARTS[type]) / find_byte_sz(type);
}

/** Conversion between an output to a byte on the action data bus of a particular type */
inline int ActionDataBus::output_to_byte(int output, ActionFormat::cont_type_t type) {
    if (type == ActionFormat::FULL)
        return output * find_byte_sz(type);
    else
        return ADB_STARTS[type] + output * find_byte_sz(type);
}

/** Finds the byte size of particular container */
inline int ActionDataBus::find_byte_sz(ActionFormat::cont_type_t type) {
    return ActionFormat::CONTAINER_SIZES[type] / 8;
}

/** Combined layouts */
inline bitvec ActionDataBus::combined(const bitvec bv[ActionFormat::CONTAINER_TYPES]) {
     return bv[ActionFormat::BYTE] | bv[ActionFormat::HALF] | bv[ActionFormat::FULL];
}

/** Allocation of the action data table.  Based on the rules in section 5.2.5.1.  Attempts
 *  the allocate bytes, then halves, then fulls.  Because the bytes and halves have mutually
 *  exclusive regions on the action data bus, if either one fails, then the allocation scheme
 *  will fail without consideration to other.  Because the action data bus constraints are based
 *  on a per Action Data Ram format basis, the algorithm breaks up wide action tables into its
 *  action data table units, as they come from different home row action data busses, and from
 *  128 bit rams, thus 16 byte regions.
 */
bool ActionDataBus::alloc_ad_table(const bitvec total_layouts[ActionFormat::CONTAINER_TYPES],
                                   const bitvec full_layout_bitmasked, Use &use, cstring name) {
    LOG2("Total Layouts for Action Data Table");
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG2("Layout for type " << i << " is " << total_layouts[i]);
    }
    bitvec byte_layout = total_layouts[ActionFormat::BYTE];
    bitvec half_layout = total_layouts[ActionFormat::HALF];
    bitvec full_layout = total_layouts[ActionFormat::FULL];

    int max = byte_layout.max().index();
    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layout = (byte_layout.getslice(i, BYTES_PER_RAM));
        bitvec combined_layout = combined(total_layouts).getslice(i, BYTES_PER_RAM);
        bool allocated = alloc_bytes(use, layout, combined_layout, i, name);
        if (!allocated) return false;
    }

    max = half_layout.max().index();

    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layout = (half_layout.getslice(i, BYTES_PER_RAM));
        bitvec combined_layout = combined(total_layouts).getslice(i, BYTES_PER_RAM);
        bool allocated = alloc_halves(use, layout, combined_layout, i, name);
        if (!allocated) return false;
    }


    max = full_layout.max().index();
    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layouts[ActionFormat::CONTAINER_TYPES];
        for (int j = 0; j < ActionFormat::CONTAINER_TYPES; j++) {
            layouts[j] = total_layouts[j].getslice(i, BYTES_PER_RAM);
        }
        bitvec full_bitmasked = full_layout_bitmasked.getslice(i, BYTES_PER_RAM);
        bool allocated = alloc_fulls(use, layouts, full_bitmasked, i, name);
        if (!allocated) return false;
    }
    return true;
}

/** Find a location for a particular type within an action data region.  Tested in diff
 *  size chunks.
 */
bool ActionDataBus::find_location(ActionFormat::cont_type_t type, bitvec combined_adjacent,
                                  int diff, int &start_byte) {
    int starter = output_to_byte(PAIRED_OFFSET, type);
    bool found = false;
    do {
        bitvec total_mask = combined_adjacent;
        if ((total_in_use & (combined_adjacent << starter)).popcount() == 0) {
            found = true;
            break;
        }
        starter += diff;
        if (starter >= output_to_byte(OUTPUTS, type))
            starter -= OUTPUTS * find_byte_sz(type);
    } while (starter != output_to_byte(PAIRED_OFFSET, type));
    start_byte = starter;
    return found;
}

/** An algorithm to find a space in the region below the paired offset region */
bool ActionDataBus::find_lower_location(ActionFormat::cont_type_t type, bitvec combined_adjacent,
                                        int diff, int &start_byte) {
    int starter = ADB_STARTS[type];
    bool found = false;
    do {
        if ((total_in_use & (combined_adjacent << starter)).popcount() == 0) {
            found = true;
            break;
        }
        starter += diff;
    } while (starter != output_to_byte(PAIRED_OFFSET, type));
    start_byte = starter;
    return found;
}

/** An algorithm to find a spot within the full region only of the action data bus.  Has
 *  no possible sharing with either the half or byte region
 */
bool ActionDataBus::find_full_location(bitvec combined_adjacent, int diff, int &start_byte) {
    int starter = ADB_STARTS[ActionFormat::FULL];
    bool found = false;
    do {
        if ((total_in_use & (combined_adjacent << starter)).popcount() == 0) {
            found = true;
            break;
        }
        starter += diff;
    } while (starter < ADB_BYTES);
    start_byte = starter;
    return found;
}

bool ActionDataBus::find_immed_upper_location(ActionFormat::cont_type_t type,
                                              bitvec combined_adjacent, int diff,
                                              int &start_byte) {
    int starter = output_to_byte(PAIRED_OFFSET, type);
    bool found = false;
    do {
        bitvec total_mask = combined_adjacent;
        if ((total_in_use & (combined_adjacent << starter)).popcount() == 0) {
            found = true;
            break;
        }
        starter += diff;
    } while (starter != output_to_byte(PAIRED_OFFSET, type));
    start_byte = starter;
    return found;
}

/** Reserves the action data bus space within the bitvecs, and adds it to the Use structure
 *  for the region.  Must only reserve the spaces for the actual bytes, and comes up with
 *  the correct name for the assembly output.
 */
void ActionDataBus::reserve_space(Use &use, ActionFormat::cont_type_t type, bitvec adjacent,
                                  bitvec combined_adjacent, int start_byte, int byte_offset,
                                  bool immed, cstring name) {
    bitvec shift_mask = combined_adjacent << start_byte;
    total_in_use |= shift_mask;

    // The actual slots that have action data
    for (auto bitpos : adjacent) {
        if (bitpos % find_byte_sz(type) != 0) continue;
        Loc loc(start_byte + bitpos, type);
        use.action_data_locs.emplace_back(loc, byte_offset + bitpos, immed);
    }

    // The slots that have to be reserved because of other container types
    for (auto bitpos : (combined_adjacent - adjacent)) {
        if (bitpos % find_byte_sz(type) != 0) continue;
        Loc loc(start_byte + bitpos, type);
        use.clobber_locs.emplace_back(loc, byte_offset + bitpos, immed);
    }

    for (auto bitpos : shift_mask) {
        total_use[bitpos] = name;
        if ((bitpos & find_byte_sz(type)) != 0) continue;
        int output = byte_to_output(bitpos, type);
        cont_use[type][output] = name;
        cont_in_use[type].setbit(output);
    }

    if (!immed)
        return;

    for (int i = 0; i < 3; i++) {
        if (start_byte < IMMED_DIVIDES[i]) {
            reserved_immed[i] = true;
            break;
        }
    }
}

/** Allocate an individual region of an action data table or immediate.  To clear things up
 *     - adjacent - the bytes that are directly need to be allocated for this particular region
 *                  of the action data format
 *     - combined_adjacent - all action data slots within that particular region that have
 *                           an allocation, and will mux into the action data bus as well.
 *     - layout - the total bytes needed for a particular type on 16 byte region of the action
 *                data format
 *     - init_byte_offset - if the action format is wide, then this specifies which section
 *                          the allocation is on, useful for pairing
 *     - sec_begin - the byte offset within the 16 byte region that adjacent begins at
 *     - size - number of bytes to update by in the location algorithm
 */
bool ActionDataBus::fit_adf_section(Use &use, bitvec adjacent, bitvec combined_adjacent,
                                    ActionFormat::cont_type_t type, loc_alg_t loc_alg,
                                    int init_byte_offset, int sec_begin, int size, cstring name) {
    bool found = false;
    int start_byte = 0;
    if (loc_alg == FIND_NORMAL)
        found = find_location(type, combined_adjacent, size, start_byte);
    else if (loc_alg == FIND_LOWER)
        found = find_lower_location(type, combined_adjacent, size, start_byte);
    else if (loc_alg == FIND_FULL)
        found = find_full_location(combined_adjacent, size, start_byte);
    if (!found) return false;
    reserve_space(use, type, adjacent, combined_adjacent, start_byte,
                  init_byte_offset + sec_begin, false, name);
    return true;
}

/** Allocation of a 16 byte section of an action data table for specifically byte outputs.
 *  Because of the way the action data muxes work, the traits are broken down into:
 *      - 8 byte alloc section for bytes 8-15
 *      - 4 byte alloc section for bytes 4-7
 *      - Depending on the needs, either a 4 byte alloc section for bytes 0-3, or two 2 byte
 *      - sections for bytes 0-1 and bytes 2-3, and allocates to a lower region
 */
bool ActionDataBus::alloc_bytes(Use &use, bitvec layout, bitvec combined_layout,
                                int init_byte_offset, cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::BYTE;
    bitvec adjacent = layout.getslice(8, 8);
    bitvec combined_adjacent = combined_layout.getslice(8, 8);
    if (layout.max().index() > 8) {
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                     init_byte_offset, 8, 8, name);
        if (!found) return false;
    }

    adjacent = layout.getslice(4, 4);
    combined_adjacent = layout.getslice(4, 4);
    if (adjacent.popcount() > 0) {
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                     init_byte_offset, 4, 4, name);
        if (!found) return false;
    }

    adjacent = layout.getslice(0, 4);
    combined_adjacent = layout.getslice(0, 4);

    bitvec small_adj = adjacent.getslice(0, 2);
    bitvec combined_small_adj = combined_adjacent.getslice(0, 2);

    if (small_adj == adjacent && adjacent.popcount() > 0) {
        // Put the lower 2 bits as a separate section
        bool found = fit_adf_section(use, small_adj, combined_small_adj, type, FIND_LOWER,
                                    init_byte_offset, 0, 2, name);
        if (!found) return false;
    } else if (adjacent.popcount() > 0) {
        // Attempt to put together as a 4 bit section
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                    init_byte_offset, 0, 4, name);
        if (!found) return false;
    }
    return true;
}

/** Allocation of a 16 byte section of an action data table for half outputs.  Again, because
 *  of the structure of the muxes, the allocation takes place as the following algorithm:
 *     - 8 byte alloc section for bytes 8-15
 *     - Depending on the halves needed, either an 8-byte alloc section for bytes 0-7, or two
 *       4 byte sections for bytes 0-3 and 4-7 respectively
 */
bool ActionDataBus::alloc_halves(Use &use, bitvec layout, bitvec combined_layout,
                                 int init_byte_offset, cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::HALF;
    bitvec adjacent = layout.getslice(8, 8);
    bitvec combined_adjacent = combined_layout.getslice(8, 8);
    if (layout.max().index() > 8) {
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                     init_byte_offset, 8, 8, name);
        if (!found) return false;
    }

    adjacent = layout.getslice(0, 8);
    combined_adjacent = combined_layout.getslice(0, 8);

    bitvec adj_lo = layout.getslice(0, 4);
    bitvec comb_adj_lo = combined_layout.getslice(0, 4);

    bitvec adj_hi = layout.getslice(4, 4);
    bitvec comb_adj_hi = combined_layout.getslice(4, 4);

    if (adj_lo.popcount() < adjacent.popcount() && adj_hi.popcount() < adjacent.popcount()) {
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                     init_byte_offset, 0, 8, name);
        if (!found) return false;
    } else if (adj_hi.popcount() > 0) {
        bool found = fit_adf_section(use, adj_hi, comb_adj_hi, type, FIND_LOWER,
                                     init_byte_offset, 4, 4, name);
        if (!found) return false;
    } else if (adj_lo.popcount() > 0) {
        bool found = fit_adf_section(use, adj_lo, comb_adj_lo, type, FIND_LOWER,
                                     init_byte_offset, 0, 4, name);
        if (!found) return false;
    }
    return true;
}

/** Analysis of what bytes full sections can potentially share with either half sections or
 *  byte sections.  The algorithm parses through the allocations of the table's half and byte
 *  sections in order to determine if the bytes were to share, would they be properly aligned
 *  within the action data bus.
 */
void ActionDataBus::analyze_full_share(Use &use, bitvec layouts[ActionFormat::CONTAINER_TYPES],
                                       FullShare &full_share, int init_byte_offset,
                                       int add_byte_offset, bool immed) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    int byte_sz = find_byte_sz(type);
    full_share.full_in_use = true;
    for (int j = 0; j < ActionFormat::CONTAINER_TYPES - 1; j++) {
        int small_byte_sz = find_byte_sz(static_cast<ActionFormat::cont_type_t>(j));
        bitvec under = layouts[j].getslice(add_byte_offset, byte_sz);
        if (under.popcount() == 0) continue;
        bitvec byte_locations;
        for (auto rs : use.action_data_locs) {
            int byte_offset = init_byte_offset + add_byte_offset;
            if (!(rs.location.type == j && rs.byte_offset >= byte_offset
                && rs.byte_offset < byte_offset + byte_sz && rs.immediate == immed))
                continue;
            byte_locations.setrange(rs.location.byte, small_byte_sz);
        }

        for (auto rs : use.clobber_locs) {
            int byte_offset = init_byte_offset + add_byte_offset;
            if (!(rs.location.type == j && rs.byte_offset >= byte_offset
                && rs.byte_offset < byte_offset + byte_sz && rs.immediate == immed))
                continue;
            byte_locations.setrange(rs.location.byte, small_byte_sz);
        }

        // Spread over multiple regions, and thus not in one 32 bit section
        if (byte_locations.max().index() - byte_locations.min().index() >= byte_sz)
            continue;

        if (byte_locations.popcount() == byte_sz) {
            full_share.shared_status |= (1 << j);
            int lowest_byte = byte_locations.min().index();
            lowest_byte -= (lowest_byte % 4);
            full_share.shared_byte[j] = lowest_byte;
        }
    }
}

/** Essentially wrapper class to perform analysis on all possible full sections within a 16
 *  byte region
 */
void ActionDataBus::analyze_full_shares(Use &use, bitvec layouts[ActionFormat::CONTAINER_TYPES],
                                        bitvec full_bitmasked, FullShare full_shares[4],
                                        int init_byte_offset) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    int byte_sz = find_byte_sz(type);
    for (int i = 0; i < BYTES_PER_RAM; i += byte_sz) {
        if (layouts[ActionFormat::FULL].getslice(i, 4).popcount() == 0) continue;
        analyze_full_share(use, layouts, full_shares[i / byte_sz], init_byte_offset, i, false);
    }

    ///> Analysis for the constraint of two fulls in a bitmasked-set operation have to be
    ///> juxtaposed on the action data bus as an even odd pair
    for (int i = 0; i < BYTES_PER_RAM; i += byte_sz * 2) {
        if (!full_bitmasked.getrange(i, byte_sz * 2))
            continue;
        int index0 = i / byte_sz;
        int index1 = (i + byte_sz) / byte_sz;
        if (!full_shares[index0].shared_status || !full_shares[index1].shared_status)
            continue;
        int byte_index = -1;
        bool found = false;
        for (int j = 0; j < ActionFormat::CONTAINER_TYPES - 1; j++) {
            if ((full_shares[index0].shared_byte[j]
                 == full_shares[index1].shared_byte[j] - byte_sz)
                && (full_shares[index0].shared_byte[j] % (byte_sz * 2)) == 0) {
                found = true;
                byte_index = j;
                break;
            }
        }
        if (!found) continue;
        full_shares[index0].init_full_bitmask(byte_index);
        full_shares[index1].init_full_bitmask(byte_index);
        break;
    }
}

/** The allocation of an 8 byte alloc section in an action data table.  Attempts to share
 *  bytes whenever possible, and makes the assumption that the bytes are correctly aligned from
 *  the alloc_half and alloc_byte algorithm.  If sharing cannot happen, currently tries to
 *  allocate within the full section first.
 *
 *  Doesn't yet try to allocate within the byte and half region if no full space is available.
 *  Needs to be done shortly.
 */
bool ActionDataBus::alloc_full_sect(Use &use, FullShare full_shares[4], bitvec combined_layout,
                                    int begin, int init_byte_offset, cstring name,
                                    bitvec full_bitmasked) {
    bool fbi = full_bitmasked.popcount() > 0;
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    int byte_sz = find_byte_sz(type);
    bitvec unshared_adj;
    for (int i = begin; i < begin + 2; i++) {
        if (!full_shares[i].full_in_use)
            continue;
        if (!fbi && full_shares[i].full_in_use && full_shares[i].shared_status != 0)
            continue;
        if (fbi && full_shares[i].full_bitmasked_set)
            continue;
        unshared_adj.setrange((i - begin) * byte_sz, byte_sz);
    }

    if (unshared_adj.popcount() != 0) {
        // Obviously have to expand this over the entire xbar region rather than only
        // the 32 bit section
        bool found = fit_adf_section(use, unshared_adj, combined_layout, type, FIND_FULL,
                                     init_byte_offset, begin * byte_sz, 8, name);
        if (!found) return false;
    }
    for (int i = begin; i < begin + 2; i++) {
        if (full_shares[i].shared_status == 0) continue;
        if (fbi && !full_shares[i].full_bitmasked_set)
            continue;
        bitvec shared_adj(0, 4);
        int start_byte = -1;
        if (!fbi) {
            if ((full_shares[i].shared_status & (1 << ActionFormat::HALF)) != 0)
                start_byte = full_shares[i].shared_byte[ActionFormat::HALF];
            else if ((full_shares[i].shared_status & (1 << ActionFormat::BYTE)) != 0)
                start_byte = full_shares[i].shared_byte[ActionFormat::BYTE];
        } else {
            int lookup = full_shares[i].full_bitmasked_index;
            start_byte = full_shares[i].shared_byte[lookup];
        }
        reserve_space(use, type, shared_adj, shared_adj, start_byte,
                      i * byte_sz + init_byte_offset, false, name);
    }
    return true;
}

/** Algorithm for allocation full sections of a 16 byte section of the action data format of
 *  an action table.  Breaks the sections into two 8 byte sections, as this hits all possible
 *  constraints in this particular region.
 */
bool ActionDataBus::alloc_fulls(Use &use, bitvec layouts[ActionFormat::CONTAINER_TYPES],
                                bitvec full_bitmasked, int init_byte_offset, cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    bitvec layout = layouts[type];
    bitvec combined_layouts = combined(layouts);
    FullShare full_shares[4];
    analyze_full_shares(use, layouts, full_bitmasked, full_shares, init_byte_offset);

    int begin = 8 / find_byte_sz(type);
    if (layouts[type].max().index() > 8) {
        bitvec full_bitmasked_sect = full_bitmasked.getslice(8, 8);
        bitvec combined_adj = combined_layouts.getslice(8, 8);
        bool found = alloc_full_sect(use, full_shares, combined_adj, begin, init_byte_offset, name,
                                     full_bitmasked_sect);
        if (!found) return false;
    }

    begin = 0;
    if (layouts[type].getslice(0, 8).popcount() > 0) {
        bitvec full_bitmasked_sect = full_bitmasked.getslice(0, 8);
        bitvec combined_adj = combined_layouts.getslice(0, 8);
        bool found = alloc_full_sect(use, full_shares, combined_adj, begin, init_byte_offset, name,
                                     full_bitmasked_sect);
        if (!found) return false;
    }
    return true;
}


/** Similar to fit_adf_section, for fitting action immediate data onto the action data bus.
 *  Because for all immediates section are allocated on a mod 4 basis, there is no difference
 *  on the allocation section between bytes, halves, and full words, and is specified in the
 *  IMMED_SECT definition.
 */
bool ActionDataBus::fit_immed_sect(Use &use, bitvec layout, bitvec combined_layout,
                                   ActionFormat::cont_type_t type, loc_alg_t loc_alg,
                                   cstring name) {
    int start_byte = 0;
    bool found = false;
    if (loc_alg == FIND_IMMED_UPPER)
        found = find_immed_upper_location(type, combined_layout, IMMED_SECT, start_byte);
    else if (loc_alg == FIND_LOWER)
        found = find_lower_location(type, combined_layout, IMMED_SECT, start_byte);
    else if (loc_alg == FIND_FULL)
        found = find_full_location(combined_layout, IMMED_SECT, start_byte);
    if (!found) return false;
    reserve_space(use, type, layout, combined_layout, start_byte, 0, true, name);
    return true;
}

/** In the immediate section, potentially we have to allocate bytes in the half word region
 *  and half words in the full word region.  This is to calculate the pairing of these.
 */
bitvec ActionDataBus::paired_immediate(bitvec layout, ActionFormat::cont_type_t type) {
    bitvec paired_layout;
    if (type == ActionFormat::FULL)
        return layout;
    auto byte_sz = find_byte_sz(type);

    for (int i = 0; i < IMMED_SECT; i += byte_sz) {
        if (layout.getrange(i, byte_sz) == 0) continue;
        paired_layout.setrange(i, byte_sz);
        int paired_start = (i / (byte_sz * 2)) * byte_sz * 2;
        paired_start += (i + byte_sz) % (byte_sz * 2);
        paired_layout.setrange(paired_start, byte_sz);
    }
    return paired_layout;
}

/** Allocation of both the byte and half word requirements of the immediate section, specified
 *  by type.  Due to the fact that there are only 3 sections in which the immediate can go,
 *  and 3 sections in which to place the immediate.  If the mux for that particular section
 *  is being used, then it cannot be reallocated unless it is being shared.
 *
 *  If placing the layout in the section where it will have to be paired will require extra
 *  action data bus slots to be reserved by clobber locations, than that is the preferred
 *  destination
 */
bool ActionDataBus::alloc_unshared_immed(Use &use, ActionFormat::cont_type_t type, bitvec layout,
                                         bitvec combined, cstring name) {
    if (layout.empty())
        return true;

    auto paired_layout = paired_immediate(layout, type);
    int upper_type = static_cast<int>(type) + 1;
    if (layout == paired_layout) {
        bool found = false;
        if (!reserved_immed[upper_type])
            found = fit_immed_sect(use, layout, paired_layout & combined, type, FIND_IMMED_UPPER,
                                   name);
        if (found) return true;
        if (!reserved_immed[type])
            found = fit_immed_sect(use, layout, layout, type, FIND_LOWER, name);
        return found;
    } else {
        bool found = false;
        if (!reserved_immed[type])
            found = fit_immed_sect(use, layout, layout, type, FIND_LOWER, name);
        if (found) return true;
        if (!reserved_immed[upper_type])
            found = fit_immed_sect(use, layout, paired_layout & combined, type, FIND_IMMED_UPPER,
                                   name);
        return found;
    }
}

/** Alloction of the full region in the immediate section.  Like the full section of the action
 *  data table, the algorithm tries to share, and if it cannot share then simply allocates within
 *  the full section if possible.
 *
 *  TODO: Full sections being added to either the byte or half region as unshared is not yet
 *        possible
 */
bool ActionDataBus::alloc_shared_immed(Use &use, bitvec layouts[ActionFormat::CONTAINER_TYPES],
                                       cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    if (layouts[type].popcount() == 0)
        return true;

    FullShare full_share;
    analyze_full_share(use, layouts, full_share, 0, 0, true);
    auto combined_layouts = combined(layouts);

    if (full_share.full_in_use) {
        if (full_share.shared_status == 0) {
            // FIXME: Again, larger range for full match
            if (!reserved_immed[ActionFormat::FULL]) {
                bool found = fit_immed_sect(use, layouts[type], combined_layouts, type, FIND_FULL,
                                        name);
                if (!found) return false;
            } else {
                BUG("Should be impossible to reach, as either the full word section is "
                    "unallocated or two half words are already sharing");
            }
        } else {
            int start_byte = -1;
            if ((full_share.shared_status & (1 << ActionFormat::HALF)) != 0)
                start_byte = full_share.shared_byte[ActionFormat::HALF];
            else if ((full_share.shared_status & (1 << ActionFormat::BYTE)) != 0)
                start_byte = full_share.shared_byte[ActionFormat::BYTE];
            reserve_space(use, type, layouts[type], layouts[type], start_byte, 0, true, name);
        }
    }
    return true;
}

/** Allocation of the immediate sections of the action data table.  Again bytes and halves are
 *  allocated first, and their allocation is used in the analysis of the full section in terms
 *  of potentially sharing bytes.
 */
bool ActionDataBus::alloc_immediate(const bitvec total_layouts[ActionFormat::CONTAINER_TYPES],
                                    Use &use, cstring name) {
    LOG2("Total Layouts for Action Format Immediate");
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG2("Layout for type " << i << " is " << total_layouts[i]);
    }

    auto type = ActionFormat::BYTE;
    auto layout = total_layouts[type];
    auto combined_layout = combined(total_layouts);

    bool found = alloc_unshared_immed(use, type, layout, combined_layout, name);
    if (!found) return false;

    type = ActionFormat::HALF;
    layout = total_layouts[type];
    found = alloc_unshared_immed(use, type, layout, combined_layout, name);
    if (!found) return false;


    bitvec layouts[ActionFormat::CONTAINER_TYPES];
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++)
        layouts[i] = total_layouts[i];
    found = alloc_shared_immed(use, layouts, name);
    if (!found) return false;
    return true;
}

/** Total allocation of the action data bus for a particular table.  Again, based on the
 *  current fact that actions are either contained in the immediate or in an action data
 *  table, the algorithm performs them separately.  Once it can be simultaneous, the algorithm
 *  needs to be adapted to handle both at the same time.  Based on the current algorithm,
 *  hopefully the only change is here.
 *
 *  TODO: When action immediate and action data table can happen simultaneously, change here
 */
bool ActionDataBus::alloc_action_data_bus(const IR::MAU::Table *tbl, const LayoutOption *lo,
                                          TableResourceAlloc &alloc) {
    auto &act_format = alloc.action_format;
    auto &ad_xbar = alloc.action_data_xbar;
    LOG1("Allocating action data bus for " << tbl->name);
    if (lo->layout.action_data_bytes_in_overhead > 0) {
        bool allocated = alloc_immediate(act_format.total_layouts_immed, ad_xbar, tbl->name);
        if (!allocated) return false;
    } else if (lo->layout.action_data_bytes > 0) {
        bool allocated = alloc_ad_table(act_format.total_layouts, act_format.full_layout_bitmasked,
                                        ad_xbar, tbl->name);
        if (!allocated) return false;
    }

    LOG2("Action data bus for " << tbl->name);
    for (auto &rs : ad_xbar.action_data_locs) {
        LOG2("Reserved " << rs.location.byte << " for offset " << rs.byte_offset << " of type "
             << rs.location.type);
    }

    return true;
}

void ActionDataBus::update(cstring name, const Use::ReservedSpace &rs) {
    int byte_sz = find_byte_sz(rs.location.type);
    for (int i = rs.location.byte; i < rs.location.byte + byte_sz; i++) {
        if (!total_use[i].isNull() && total_use[i] != name)
            BUG("Conflicting alloc in the action data xbar between %s and %s at byte %d",
                name, total_use[i], rs.location.byte);
        total_use[i] = name;
    }

    total_in_use.setrange(rs.location.byte, byte_sz);
    int output = byte_to_output(rs.location.byte, rs.location.type);
    cont_use[rs.location.type][output] = name;
    cont_in_use[rs.location.type].setbit(output);
}

/** The update procedure for all previously allocated tables in a stage.  This fills in the
 *  bitvecs correctly in order to be tested against in the allocation of the current table.
 */
void ActionDataBus::update(cstring name, const Use &alloc) {
    for (auto &rs : alloc.action_data_locs) {
         update(name, rs);
    }

    for (auto &rs : alloc.clobber_locs) {
        update(name, rs);
    }
}

void ActionDataBus::update(cstring name, const TableResourceAlloc *alloc) {
    update(name, alloc->action_data_xbar);
}

void ActionDataBus::update(const IR::MAU::Table *tbl) {
    BUG_CHECK(tbl->is_placed(), "Cannot call update on a pre-placed table");
    if (tbl->layout.atcam) {
        auto orig_name = tbl->name.before(tbl->name.findlast('$'));
        if (atcam_updates.find(orig_name) != atcam_updates.end())
            return;
        atcam_updates.emplace(orig_name);
    }
    update(tbl->name, tbl->resources);
}
