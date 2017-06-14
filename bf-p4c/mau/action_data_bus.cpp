#include "tofino/mau/action_data_bus.h"

constexpr int ActionDataBus::ADB_STARTS[];

/** Clears all of the allocation within the ActionDataBus, for the TableSummary
 */
void ActionDataBus::clear() {
    cont_use.clear();
    total_use.clear();
    for (auto &in_use : cont_in_use)
        in_use.clear();
    total_in_use.clear();
}

/** Generates the name printed out by asm_output for this particular action data table position.
 *  The name that appears in the action data format and action data bus is:
 *  $adf_(type)(name_offset)
 */
cstring ActionDataBus::find_adf_name(ActionFormat::cont_type_t type, int name_offset) {
    cstring name = "$adf_";
    if (type == ActionFormat::BYTE)
        name += "b";
    else if (type == ActionFormat::HALF)
        name += "h";
    else
        name += "f";
    name += std::to_string(name_offset);
    return name;
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

/** Allocation of the action data table.  Based on the rules in section 5.2.5.1.  Attempts
 *  the allocate bytes, then halves, then fulls.  Because the bytes and halves have mutually
 *  exclusive regions on the action data bus, if either one fails, then the allocation scheme
 *  will fail without consideration to other.  Because the action data bus constraints are based
 *  on a per Action Data Ram format basis, the algorithm breaks up wide action tables into its
 *  action data table units, as they come from different home row action data busses, and from
 *  128 bit rams, thus 16 byte regions.
 */
bool ActionDataBus::alloc_ad_table(const bitvec total_layouts[ActionFormat::CONTAINER_TYPES],
                                   vector<Use::ReservedSpace> &reserved_spaces, cstring name) {
    LOG2("Total Layouts for Action Data Table");
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG2("Layout for type " << i << " is " << total_layouts[i]);
    }
    bitvec byte_layout = total_layouts[ActionFormat::BYTE];
    int max = byte_layout.max().index();
    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layout = (byte_layout.getslice(i, BYTES_PER_RAM));
        int name_offset = begin_offset(byte_layout, i, ActionFormat::BYTE);
        bool allocated = alloc_bytes(reserved_spaces, layout, i, name_offset, name);
        if (!allocated) return false;
    }

    bitvec half_layout = total_layouts[ActionFormat::HALF];
    max = half_layout.max().index();

    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layout = (half_layout.getslice(i, BYTES_PER_RAM));
        int name_offset = begin_offset(half_layout, i, ActionFormat::BYTE);
        bool allocated = alloc_halves(reserved_spaces, layout, i, name_offset, name);
        if (!allocated) return false;
    }


    bitvec full_layout = total_layouts[ActionFormat::FULL];
    max = full_layout.max().index();
    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layouts[ActionFormat::CONTAINER_TYPES];
        for (int j = 0; j < ActionFormat::CONTAINER_TYPES; j++) {
            layouts[j] = total_layouts[j].getslice(i, BYTES_PER_RAM);
        }
        int name_offset = begin_offset(full_layout, i, ActionFormat::FULL);
        bool allocated = alloc_fulls(reserved_spaces, layouts, i, name_offset, name);
        if (!allocated) return false;
    }
    return true;
}

/** Find a location for a particular type within an action data region.  Tested in diff
 *  size chunks.  In the higher regions, past the PAIRED_OFFSET region, because the region
 *  doubles up the chunks, and I'm not sure if the runtime supports a sharing of the double
 *  regions.  More research needs to be done enough.
 */
bool ActionDataBus::find_location(ActionFormat::cont_type_t type, bitvec adjacent, int diff,
                                  int &start_byte) {
    int starter = output_to_byte(PAIRED_OFFSET, type);
    bool found = false;
    do {
        bitvec total_mask = paired_space(type, adjacent, starter);
        if ((total_in_use & (total_mask << starter)).popcount() == 0) {
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

/** An algorithm to find a space in the region below the paired offset region.  
 */
bool ActionDataBus::find_lower_location(ActionFormat::cont_type_t type, bitvec adjacent,
                                        int diff, int &start_byte) {
    int starter = ADB_STARTS[type];
    bool found = false;
    do {
        if ((total_in_use & (adjacent << starter)).popcount() == 0) {
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
bool ActionDataBus::find_full_location(bitvec adjacent, int diff, int &start_byte) {
    int starter = ADB_STARTS[ActionFormat::FULL];
    bool found = false;
    do {
        if ((total_in_use & (adjacent << starter)).popcount() == 0) {
            found = true;
            break;
        }
        starter += diff;
    } while (starter < ADB_BYTES);
    start_byte = starter;
    return found;
}

/** Any output in either the byte or half region greater than or equal to PAIRED_OFFSET output,
 *  16, are actually paired together and output together on the action data bus.  This function
 *  checks this constraint, and reserves both outputs, even if only one is actually in use by
 *  the ALUs.  In theory, one would not need to reserve both spaces, but instead make sure
 *  that the action data format for that particular actions has all zeros, as this would OR
 *  with any other action data brought in by a separate action and thus have no effect.
 *  However, without a way to necessarily specify runtime support for this, instead the
 *  algorithm just currently reserves both in the meantime.  This can be adjusted later.
 *
 *  The purpose of the function is to return a bitvec that reflects the need to reserve both
 *  spaces
 */
bitvec ActionDataBus::paired_space(ActionFormat::cont_type_t type, bitvec adjacent,
                                   int start_byte) {
    int byte_sz = find_byte_sz(type);
    bitvec total_mask = adjacent;

    if ((type == ActionFormat::BYTE || type == ActionFormat::HALF)
        && output_to_byte(PAIRED_OFFSET, type) <= start_byte) {
        for (auto bitpos : adjacent) {
            if (bitpos % (byte_sz * 2) == 0) {
                total_mask.setrange(bitpos + byte_sz, byte_sz);
            } else if (bitpos % (byte_sz * 2) == byte_sz) {
                total_mask.setrange(bitpos - byte_sz, byte_sz);
            }
        }
    }
    return total_mask;
}

/** This finds the adf_(type)(name_offset), name_offset of a particular region of the format.
 *  This is so the naming of these fields can be properly updated.
 */
int ActionDataBus::begin_offset(bitvec adjacent, int sec_begin, ActionFormat::cont_type_t type) {
    int offset = 0;
    for (auto bitpos : adjacent) {
        if (bitpos % find_byte_sz(type) != 0) continue;
        if (bitpos >= sec_begin) break;
        offset++;
    }
    return offset;
}

/** Reserves the action data bus space within the bitvecs, and adds it to the Use structure
 *  for the region.  Must only reserve the spaces for the actual bytes, and comes up with 
 *  the correct name for the assembly output.
 */
void ActionDataBus::reserve_space(vector<Use::ReservedSpace> &reserved_spaces,
                                  ActionFormat::cont_type_t type, bitvec adjacent,
                                  int start_byte, int byte_offset, int name_offset, bool immed,
                                  cstring name) {
    // auto &use = cont_use[index];
    // auto &in_use = cont_in_use[index];
    // Because the reservations are paired, must pair up with the other portions of the table
    bitvec total_mask = paired_space(type, adjacent, start_byte);
    bitvec shift_mask = total_mask << start_byte;
    total_in_use |= shift_mask;

    // Other shifting of information
    int byte_add = 0;
    for (auto bitpos : adjacent) {
        if (bitpos % find_byte_sz(type) != 0) continue;
        Loc loc(start_byte + bitpos, type);
        if (!immed) {
            cstring ab_name = find_adf_name(type, name_offset + byte_add);
            reserved_spaces.emplace_back(loc, byte_offset + bitpos, name_offset + byte_add,
                                         ab_name);
        } else {
            reserved_spaces.emplace_back(loc, byte_offset + bitpos, immed);
            reserved_spaces.back().name = find_immed_name(byte_offset + bitpos, type);
        }
        byte_add++;
    }

    for (auto bitpos : shift_mask) {
        total_use[bitpos] = name;
        if ((bitpos & find_byte_sz(type)) != 0) continue;
        int output = byte_to_output(bitpos, type);
        cont_use[type][output] = name;
        cont_in_use[type].setbit(output);
    }
}

/** Allocate an individual region of an action data table or immediate.  To clear things up
 *     - adjacent - the bytes that are directly need to be allocated for this particular region
 *                  of the action data format
 *     - layout - the total bytes needed for a particular type on 16 byte region of the action
 *                data format
 *     - init_byte_offset - if the action format is wide, then this specifies which section
 *                          the allocation is on, useful for pairing
 *     - init_name_offset - if the action format is wide, then specifies which asm name to begin
 *                          using as a starting point
 *     - sec_begin - the byte offset within the 16 byte region that adjacent begins at
 *     - size - number of bytes to update by in the location algorithm
 */
bool ActionDataBus::fit_adf_section(vector<Use::ReservedSpace> &reserved_spaces, bitvec adjacent,
                                    bitvec layout, ActionFormat::cont_type_t type,
                                    loc_alg_t loc_alg, int init_byte_offset,
                                    int init_name_offset, int sec_begin, int size, cstring name) {
    bool found = false;
    int start_byte = 0;
    if (loc_alg == FIND_NORMAL)
        found = find_location(type, adjacent, size, start_byte);
    else if (loc_alg == FIND_LOWER)
        found = find_lower_location(type, adjacent, size, start_byte);
    else if (loc_alg == FIND_FULL)
        found = find_full_location(adjacent, size, start_byte);
    if (!found) return false;
    int name_offset = begin_offset(layout, sec_begin, type);
    reserve_space(reserved_spaces, type, adjacent, start_byte, init_byte_offset + sec_begin,
                  init_name_offset + name_offset, false, name);
    return true;
}

/** Allocation of a 16 byte section of an action data table for specifically byte outputs.
 *  Because of the way the action data muxes work, the traits are broken down into:
 *      - 8 byte alloc section for bytes 8-15
 *      - 4 byte alloc section for bytes 4-7
 *      - Depending on the needs, either a 4 byte alloc section for bytes 0-3, or two 2 byte
 *      - sections for bytes 0-1 and bytes 2-3, and allocates to a lower region
 */
bool ActionDataBus::alloc_bytes(vector<Use::ReservedSpace> &reserved_spaces,
                                bitvec layout, int init_byte_offset, int init_name_offset,
                                cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::BYTE;
    bitvec adjacent = layout.getslice(8, 8);
    if (layout.max().index() > 8) {
        bool found = fit_adf_section(reserved_spaces, adjacent, layout, type, FIND_NORMAL,
                                     init_byte_offset, init_name_offset, 8, 8, name);
        if (!found) return false;
    }

    adjacent = layout.getslice(4, 4);
    if (adjacent.popcount() > 0) {
        bool found = fit_adf_section(reserved_spaces, adjacent, layout, type, FIND_NORMAL,
                                     init_byte_offset, init_name_offset, 4, 4, name);
        if (!found) return false;
    }

    adjacent = layout.getslice(0, 4);
    bitvec small_adj = adjacent.getslice(0, 2);

    if (small_adj == adjacent && adjacent.popcount() > 0) {
        bool found = fit_adf_section(reserved_spaces, small_adj, layout, type, FIND_LOWER,
                                    init_byte_offset, init_name_offset, 0, 2, name);
        if (!found) return false;
    } else if (adjacent.popcount() > 0) {
        // Attempt to put together as a 4 bit section
        bool found = fit_adf_section(reserved_spaces, adjacent, layout, type, FIND_NORMAL,
                                    init_byte_offset, init_name_offset, 0, 4, name);
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
bool ActionDataBus::alloc_halves(vector<Use::ReservedSpace> &reserved_spaces,
                                 bitvec layout, int init_byte_offset, int init_name_offset,
                                 cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::HALF;
    bitvec adjacent = layout.getslice(8, 8);
    if (layout.max().index() > 8) {
        bool found = fit_adf_section(reserved_spaces, adjacent, layout, type, FIND_NORMAL,
                                     init_byte_offset, init_name_offset, 8, 8, name);
        if (!found) return false;
    }

    adjacent = layout.getslice(0, 8);
    bitvec adj_lo = layout.getslice(0, 4);
    bitvec adj_hi = layout.getslice(4, 4);
    if (adj_lo.popcount() < adjacent.popcount() && adj_hi.popcount() < adjacent.popcount()) {
        bool found = fit_adf_section(reserved_spaces, adjacent, layout, type, FIND_NORMAL,
                                     init_byte_offset, init_name_offset, 0, 8, name);
        if (!found) return false;
    } else if (adj_hi.popcount() > 0) {
        bool found = fit_adf_section(reserved_spaces, adj_hi, layout, type, FIND_LOWER,
                                     init_byte_offset, init_name_offset, 4, 4, name);
        if (!found) return false;
    } else if (adj_lo.popcount() > 0) {
        bool found = fit_adf_section(reserved_spaces, adj_lo, layout, type, FIND_LOWER,
                                     init_byte_offset, init_name_offset, 0, 4, name);
        if (!found) return false;
    }
    return true;
}

/** Analysis of what bytes full sections can potentially share with either half sections or
 *  byte sections.  The algorithm parses through the allocations of the table's half and byte
 *  sections in order to determine if the bytes were to share, would they be properly aligned
 *  within the action data bus.
 */
void ActionDataBus::analyze_full_share(vector<Use::ReservedSpace> &reserved_spaces,
                                       bitvec layouts[ActionFormat::CONTAINER_TYPES],
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
        for (auto rs : reserved_spaces) {
            int byte_offset = init_byte_offset + add_byte_offset;
            if (!(rs.location.type == j && rs.byte_offset >= byte_offset
                && rs.byte_offset < byte_offset + byte_sz && rs.immediate == immed))
                continue;
            byte_locations.setrange(rs.location.byte, small_byte_sz);
        }

        // Spread over multiple regions, and thus not in one 32 bit section
        if (byte_locations.max().index() - byte_locations.min().index() >= byte_sz)
            continue;
        under = paired_space(static_cast<ActionFormat::cont_type_t>(j), under,
                             byte_locations.min().index());
        if (under.popcount() == byte_sz) {
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
void ActionDataBus::analyze_full_shares(vector<Use::ReservedSpace> &reserved_spaces,
                                        bitvec layouts[ActionFormat::CONTAINER_TYPES],
                                        FullShare full_shares[4],
                                        int init_byte_offset) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    int byte_sz = find_byte_sz(type);
    for (int i = 0; i < 16; i += byte_sz) {
        if (layouts[ActionFormat::FULL].getslice(i, 4).popcount() == 0) continue;
        analyze_full_share(reserved_spaces, layouts, full_shares[i / byte_sz],
                           init_byte_offset, i, false);
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
bool ActionDataBus::alloc_full_sect(vector<Use::ReservedSpace> &reserved_spaces,
                                    FullShare full_shares[4], bitvec layout, int begin,
                                    int init_byte_offset, int init_name_offset, cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    int byte_sz = find_byte_sz(type);
    bitvec unshared_adj;
    for (int i = begin; i < begin + 2; i++) {
        if (!full_shares[i].full_in_use)
            continue;
        if (full_shares[i].full_in_use == true && full_shares[i].shared_status != 0)
            continue;
        unshared_adj.setrange((i - begin) * byte_sz, byte_sz);
    }
    if (unshared_adj.popcount() != 0) {
        // Obviously have to expand this over the entire xbar region rather than only
        // the 32 bit section
        int name_offset_adj = begin_offset(layout, unshared_adj.min().index(), type);
        bool found = fit_adf_section(reserved_spaces, unshared_adj, layout, type, FIND_FULL,
                                     init_byte_offset, init_name_offset + name_offset_adj,
                                     begin * byte_sz, 8, name);
        if (!found) return false;
    }
    for (int i = begin; i < begin + 2; i++) {
        if (full_shares[i].shared_status == 0) continue;
        bitvec shared_adj(0, 4);
        int start_byte = -1;
        if ((full_shares[i].shared_status & (1 << ActionFormat::HALF)) != 0)
            start_byte = full_shares[i].shared_byte[ActionFormat::HALF];
        else if ((full_shares[i].shared_status & (1 << ActionFormat::BYTE)) != 0)
            start_byte = full_shares[i].shared_byte[ActionFormat::BYTE];

        int name_offset = begin_offset(layout, i * byte_sz, type);
        reserve_space(reserved_spaces, type, shared_adj, start_byte,
                      i * byte_sz + init_byte_offset, name_offset + init_name_offset,
                      false, name);
    }
    return true;
}

/** Algorithm for allocation full sections of a 16 byte section of the action data format of
 *  an action table.  Breaks the sections into two 8 byte sections, as this hits all possible
 *  constraints in this particular region.
 */
bool ActionDataBus::alloc_fulls(vector<Use::ReservedSpace> &reserved_spaces,
                                bitvec layouts[ActionFormat::CONTAINER_TYPES],
                                int init_byte_offset, int init_name_offset, cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    bitvec layout = layouts[type];
    FullShare full_shares[4];
    analyze_full_shares(reserved_spaces, layouts, full_shares, init_byte_offset);

    int begin = 8 / find_byte_sz(type);
    if (layouts[type].max().index() > 8) {
        bool found = alloc_full_sect(reserved_spaces, full_shares, layout, begin,
                                     init_byte_offset, init_name_offset, name);
        if (!found) return false;
    }

    begin = 0;
    if (layouts[type].getslice(0, 8).popcount() > 0) {
        bool found = alloc_full_sect(reserved_spaces, full_shares, layout, begin,
                                     init_byte_offset, init_name_offset, name);
        if (!found) return false;
    }
    return true;
}

/** A breakdown of the immediate mask in order to determine the correct naming of the immediates
 *  on the action data bus asm output.
 */
void ActionDataBus::find_immed_starts(const bitvec immed_mask) {
    int start = immed_mask.ffs();
    if (start == -1)
        BUG("Immediate mask is configure improperly");
    do {
        int end = immed_mask.ffz(start);
        immed_starts.emplace_back(start, end - 1);
        start = immed_mask.ffs(end);
    } while (start != -1);
}

/** Naming scheme of immediate fields coming through the action data bus.  Essentially the
 *  name on the action data bus has to be the first byte region in use on the bus, and everything
 *  after this will get picked up by the action data bus.
 */
cstring ActionDataBus::find_immed_name(int start_byte, ActionFormat::cont_type_t type) {
    int byte_sz = find_byte_sz(type);
    bool requires_index = true;
    ssize_t index = -1;
    cstring name = "immediate";
    if (immed_starts.size() == 1) {
        requires_index = false;
        index = 0;
    } else {
        bool found = false;
        for (size_t i = 0; i < immed_starts.size(); i++) {
            if (immed_starts[i].first > start_byte * 8) {
                found = true;
                index = i - 1;
            }
        }
        if (!found)
            index = immed_starts.size() - 1;
    }

    if (requires_index)
        name += std::to_string(index);

    int begin = start_byte * 8 - immed_starts[index].first;
    int diff = immed_starts[index].second - immed_starts[index].first;
    BUG_CHECK(begin >= 0, "Invalid begin for immediate slice");
    BUG_CHECK(byte_sz > 0, "Invalid size for immediate slice");
    BUG_CHECK(diff >= begin, "Invalid end for immediate slice");
    name += "(" +  std::to_string(begin) + "..";
    if (diff <= begin + byte_sz * 8) {
        name += std::to_string(diff);
    } else {
        name += std::to_string(begin + byte_sz * 8 - 1);
    }
    name += ")";
    return name;
}

/** Similar to fit_adf_section, for fitting action immediate data onto the action data bus.
 *  Because for all immediates section are allocated on a mod 4 basis, there is no difference
 *  on the allocation section between bytes, halves, and full words, and is specified in the
 *  IMMED_SECT definition.
 */
bool ActionDataBus::fit_immed_sect(vector<Use::ReservedSpace> &reserved_spaces, bitvec layout,
                                   ActionFormat::cont_type_t type, loc_alg_t loc_alg,
                                   cstring name) {
    int start_byte = 0;
    bool found = false;
    if (loc_alg == FIND_NORMAL)
        found = find_location(type, layout, IMMED_SECT, start_byte);
    else if (loc_alg == FIND_LOWER)
        found = find_lower_location(type, layout, IMMED_SECT, start_byte);
    else if (loc_alg == FIND_FULL)
        found = find_full_location(layout, IMMED_SECT, start_byte);
    if (!found) return false;
    reserve_space(reserved_spaces, type, layout, start_byte, 0, -1, true, name);
    return true;
}

/** Allocation of both the byte and half word requirements of the immediate section, specified
 *  by type.  Because of the nature of the mod 4 per byte on the action immediate constraint, 
 *  the algorithms are extremely similar for halves and bytes
 */
bool ActionDataBus::alloc_unshared_immed(vector<Use::ReservedSpace> &reserved_spaces,
                                         ActionFormat::cont_type_t type, bitvec layout,
                                         cstring name) {
    int byte_sz = find_byte_sz(type);
    if (layout.popcount() == 0)
        return true;

    bool fully_paired = true;
    for (int i = 0; i < IMMED_SECT; i += byte_sz * 2) {
        if ((layout.getslice(i, byte_sz * 2).popcount() % (byte_sz * 2)) != 0) {
            fully_paired = false;
            break;
        }
    }

    bool found = false;
    if (!fully_paired) {
        found = fit_immed_sect(reserved_spaces, layout, type, FIND_LOWER, name);
        if (!found)
            found = fit_immed_sect(reserved_spaces, layout, type, FIND_NORMAL, name);
        if (!found) return false;
    } else {
        found = fit_immed_sect(reserved_spaces, layout, type, FIND_NORMAL, name);
        if (!found) return false;
    }
    return true;
}

/** Alloction of the full region in the immediate section.  Like the full section of the action
 *  data table, the algorithm tries to share, and if it cannot share then simply allocates within
 *  the full section if possible.
 *
 *  TODO: Full sections being added to either the byte or half region as unshared is not yet
 *        possible
 */
bool ActionDataBus::alloc_shared_immed(vector<Use::ReservedSpace> &reserved_spaces,
                                       bitvec layouts[ActionFormat::CONTAINER_TYPES],
                                       cstring name) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    if (layouts[type].popcount() == 0)
        return true;

    FullShare full_share;
    analyze_full_share(reserved_spaces, layouts, full_share, 0, 0, true);

    if (full_share.full_in_use) {
        if (full_share.shared_status == 0) {
            bool found = fit_immed_sect(reserved_spaces, layouts[type], type, FIND_FULL, name);
            if (!found) return false;
        } else {
            int start_byte = -1;
            if ((full_share.shared_status & (1 << ActionFormat::HALF)) != 0)
                start_byte = full_share.shared_byte[ActionFormat::HALF];
            else if ((full_share.shared_status & (1 << ActionFormat::BYTE)) != 0)
                start_byte = full_share.shared_byte[ActionFormat::BYTE];
            reserve_space(reserved_spaces, type, layouts[type], start_byte, 0, -1, true, name);
        }
    }
    return true;
}

/** Allocation of the immediate sections of the action data table.  Again bytes and halves are
 *  allocated first, and their allocation is used in the analysis of the full section in terms
 *  of potentially sharing bytes.
 */
bool ActionDataBus::alloc_immediate(const bitvec total_layouts[ActionFormat::CONTAINER_TYPES],
                                    vector<Use::ReservedSpace> &reserved_spaces,
                                    const bitvec immed_mask, cstring name) {
    LOG2("Total Layouts for Action Format Immediate");
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG2("Layout for type " << i << " is " << total_layouts[i]);
    }

    find_immed_starts(immed_mask);
    ActionFormat::cont_type_t type = ActionFormat::BYTE;
    bitvec layout = total_layouts[type];
    bool found = alloc_unshared_immed(reserved_spaces, type, layout, name);
    if (!found) return false;

    type = ActionFormat::HALF;
    layout = total_layouts[type];
    found = alloc_unshared_immed(reserved_spaces, type, layout, name);
    if (!found) return false;


    bitvec layouts[ActionFormat::CONTAINER_TYPES];
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++)
        layouts[i] = total_layouts[i];
    found = alloc_shared_immed(reserved_spaces, layouts, name);
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
        bool allocated = alloc_immediate(act_format.total_layouts_immed, ad_xbar.reserved_spaces,
                                         act_format.immediate_mask, tbl->name);
        if (!allocated) return false;
    } else if (lo->layout.action_data_bytes > 0) {
        bool allocated = alloc_ad_table(act_format.total_layouts, ad_xbar.reserved_spaces,
                                        tbl->name);
        if (!allocated) return false;
    }

    LOG2("Action data bus for " << tbl->name);
    for (auto &rs : ad_xbar.reserved_spaces) {
        LOG2("Reserved " << rs.location.byte << " for " << rs.name << " of type "
             << rs.location.type);
    }

    return true;
}

/** The update procedure for all previously allocated tables in a stage.  This fills in the
 *  bitvecs correctly in order to be tested against in the allocation of the current table.
 */
void ActionDataBus::update(cstring name, const Use &alloc) {
    for (auto rs : alloc.reserved_spaces) {
        int byte_sz = find_byte_sz(rs.location.type);
        for (int i = rs.location.byte; i < rs.location.byte + byte_sz; i++) {
            if (!total_use[i].isNull() && total_use[i] != name)
                BUG("Conflicting alloc in the action data xbar between %s and %s at byte %d",
                    name, total_use[i], rs.location.byte);
            total_use[i] = name;
        }

        total_in_use.setrange(rs.location.byte, byte_sz);
        if (!((rs.location.type == ActionFormat::BYTE || rs.location.type == ActionFormat::HALF)
            && rs.location.byte >= output_to_byte(PAIRED_OFFSET, rs.location.type)))
            continue;

        int output = byte_to_output(rs.location.byte, rs.location.type);
        cont_use[rs.location.type][output] = name;
        cont_in_use[rs.location.type].setbit(output);

        int paired_mod = rs.location.byte % (byte_sz * 2);
        int paired_byte = (rs.location.byte / (byte_sz * 2)) * (byte_sz * 2);
        paired_byte += (byte_sz - paired_mod);

        for (int i = paired_byte; i < paired_byte + byte_sz; i++) {
            if (!total_use[i].isNull() && total_use[i] != name)
                BUG("Conflicting allocation in the action data xbar between %s and %s at byte %d",
                    name, total_use[i], rs.location.byte);
            total_use[i] = name;
        }

        int paired_output = byte_to_output(paired_byte, rs.location.type);
        cont_use[rs.location.type][paired_output] = name;
        cont_in_use[rs.location.type].setbit(paired_output);
    }
}

void ActionDataBus::update(cstring name, const TableResourceAlloc *alloc) {
    update(name, alloc->action_data_xbar);
}

