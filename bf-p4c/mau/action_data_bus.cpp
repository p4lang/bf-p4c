#include "bf-p4c/mau/action_data_bus.h"
#include "bf-p4c/mau/resource.h"

constexpr int ActionDataBus::ADB_STARTS[];
constexpr int ActionDataBus::IMMED_DIVIDES[];
constexpr int ActionDataBus::CSR_SECTION[];

/** Clears all of the allocation within the ActionDataBus, for the TableSummary
 */
void ActionDataBus::clear() {
    cont_use.clear();
    total_use.clear();
    for (auto &in_use : cont_in_use)
        in_use.clear();
    total_in_use.clear();
    allocated_attached.clear();
    reduction_or_mapping.clear();
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

/** The input xbar of the action data bus is constrained as described in section 5.2.5.1,
 *  Action Output HV Xbar Programming.  Each RAM has potentially 16 bytes of RAM word to
 *  multiplex onto the ADB.  These 16 bytes of RAM word are broken down into smaller
 *  sections, and these smaller sections are then muxed independently.
 *
 *  The size of these sections are dependent on where they go on the action data bus.  The
 *  action data bus is broken down into 16 byte regions.  Each 16 byte region has it's own
 *  registers for sections of RAM word to be muxed through.
 *
 *  Let's walk through an example, based on the figure in the above section.  For action
 *  data bus bytes 0-15, there are four sections of RAM word that can be individually muxed
 *  to different places on the RAM word.  They are:
 *      RAM word bytes 0-1
 *      RAM word bytes 2-3
 *      RAM word bytes 4-7
 *      RAM word bytes 8-15
 *
 *  So let's say we have two bytes of action data at RAM word bytes 4 and 5, and a half
 *  word of action data at RAM word bytes 6-7.  Remember, this is at bytes 0-15 of the action
 *  data bus, so only BYTE ALUs can access this region.  When we put bytes 4 and 5 on the
 *  action data bus, because all 4 bytes between bytes 4-7 are written, we also have to
 *  reserve space for bytes 6-7, even though they will not be used by any BYTE ALU for this
 *  action.
 *
 *  What is described above are the general constraints of action data bus allocation.  The
 *  dimensions of the multiplexers are per RAM word section per 16 byte region on the action
 *  data bus.  The number of multiplexers vary per action data bus regions, as the RAM word
 *  section sizes vary based on what ALUs can access these particular bytes.  These
 *  individual multiplexers are referred in the algorithm as CSRs.
 *
 *  Furthermore, these CSRs are limited in that they only can be used once per RAM word
 *  section.  Let's take the following example:  Say for some reason, two bytes of action
 *  data had been allocated at bytes 0 and 1 of the RAM word, and the algorithm decided
 *  to allocate these bytes to byte 0-15 on the action data bus.  The algorithm decided to
 *  put RAM word byte 0 at ADB byte 0, and RAM word byte 1 at ADB byte 3.  This would be
 *  impossible in Tofino, because the CSR would have to send this 2 byte region to bytes 0-1,
 *  and bytes 2-3.
 *
 *  The previous scenario is fairly ridiculous, as one could just put the bytes at either
 *  bytes 0-1, or bytes 2-3, save action data bus space, and not break any constraints.
 *  However, where this comes into play is when the algorithm has to allocate both bytes and
 *  full words to a regions, and possibly might hit a constraint.  Though this is rare, it
 *  may come up with things like bitmasked-set.
 *
 *  Immediate regions are a little different.  Similar to the action data bus, there are CSRs
 *  per section.  However, immediate bytes are only 4 bytes maximum, and there is no dimension
 *  per RAM word section.  Instead, the immediates are always handled in 4 byte sections,
 *  and potentially masked within their own regions.  There are only 3 ADB regions for immediate,
 *  unlike for action data tables,  which have 128 bytes / 16 bytes of range = 8.  The
 *  regions are broken down into bytes 0-15, bytes 16-63, and bytes 64-127.
 */

/** Given a byte offset within a RAM, and the type of the CSR, which boolean is supposed to
 *  be checked.
 */
int ActionDataBus::csr_index(int byte_offset, ActionFormat::cont_type_t type) {
    BUG_CHECK(byte_offset >= 0 && byte_offset < 16, "Action Data Bus allocation can only work in "
              "16 byte chunks");
    if (type == ActionFormat::BYTE) {
        return byte_offset == 0 ? 0 : floor_log2(byte_offset);
    } else if (type == ActionFormat::HALF) {
        if (byte_offset < 4)
            return 0;
        else if (byte_offset < 8)
            return 1;
        else
            return 2;
    } else {
        return byte_offset / 8;
    }
}

/** Given the description of CSRs, verifies that the CSR is available to be used
 */
bool ActionDataBus::is_csr_reserved(int start_byte, bitvec adjacent, int byte_offset,
                                    ActionFormat::ad_source_t source) {
    if (source == ActionFormat::IMMED)
        return is_immed_csr_reserved(start_byte);
    else
        return is_adf_csr_reserved(start_byte, adjacent, byte_offset);
}

bool ActionDataBus::is_adf_csr_reserved(int start_byte, bitvec adjacent, int byte_offset) {
    auto &action_ixbar = action_ixbars[byte_offset / BYTES_PER_RAM];
    auto &csr = action_ixbar[start_byte / CSR_RANGE];
    int index = csr_index(byte_offset % BYTES_PER_RAM, csr.type);
    if (!csr.reserved[index])
        return false;
    if (csr.type == ActionFormat::BYTE && adjacent.max().index() >= 2
        && (byte_offset % BYTES_PER_RAM) == 0)
        if (!csr.reserved[index + 1])
            return false;
    return true;
}

bool ActionDataBus::is_immed_csr_reserved(int start_byte) {
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        if (start_byte < IMMED_DIVIDES[i]) {
            return reserved_immed[i];
        }
    }
    return false;
}

/** Reserves the CSR for the action data bus so that nothing else can be allocated to that
 *  region
 */
void ActionDataBus::reserve_csr(int start_byte, bitvec adjacent, int byte_offset,
                                ActionFormat::ad_source_t source) {
    if (source == ActionFormat::IMMED)
        reserve_immed_csr(start_byte);
    else
        reserve_adf_csr(start_byte, adjacent, byte_offset);
}

void ActionDataBus::reserve_adf_csr(int start_byte, bitvec adjacent, int byte_offset) {
    auto &action_ixbar = action_ixbars[byte_offset / BYTES_PER_RAM];
    auto &csr = action_ixbar[start_byte / CSR_RANGE];
    int index = csr_index(byte_offset % BYTES_PER_RAM, csr.type);
    csr.reserved[index] = true;
    if (csr.type == ActionFormat::BYTE && adjacent.max().index() >= 2
        && (byte_offset % BYTES_PER_RAM) == 0)
        csr.reserved[index + 1] = true;
}


void ActionDataBus::reserve_immed_csr(int start_byte) {
    for (int i = 0; i < 3; i++) {
        if (start_byte < IMMED_DIVIDES[i]) {
            reserved_immed[i] = true;
            return;
        }
    }
}

/** Allocation of the action data table.  Based on the rules in section 5.2.5.1.  Attempts
 *  the allocate bytes, then halves, then fulls.  Because the bytes and halves have mutually
 *  exclusive regions on the action data bus, if either one fails, then the allocation scheme
 *  will fail without consideration to other.  Because the action data bus constraints are based
 *  on a per Action Data Ram format basis, the algorithm breaks up wide action tables into its
 *  action data table units, as they come from different home row action data busses, and from
 *  128 bit rams, thus 16 byte regions.
 */
bool ActionDataBus::alloc_ad_table(const bitvec *total_layouts,
                                   const bitvec full_layout_bitmasked, Use &use, cstring name) {
    LOG2(" Total Layouts for Action Data Table");
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG2(" Layout for type " << i << " is " << total_layouts[i]);
    }
    bitvec byte_layout = total_layouts[ActionFormat::BYTE];
    bitvec half_layout = total_layouts[ActionFormat::HALF];
    bitvec full_layout = total_layouts[ActionFormat::FULL];

    int max = std::max(std::max(byte_layout.max().index(), half_layout.max().index()),
                       full_layout.max().index());

    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        initialize_action_ixbar();
    }

    max = byte_layout.max().index();
    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layout = (byte_layout.getslice(i, BYTES_PER_RAM));
        bitvec combined_layout = combined(total_layouts).getslice(i, BYTES_PER_RAM);
        bool allocated = alloc_bytes(use, layout, combined_layout, i, name,
                ActionFormat::ADT);
        if (!allocated) return false;
    }
    LOG3("    Allocated Byte Section");

    max = half_layout.max().index();

    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layout = (half_layout.getslice(i, BYTES_PER_RAM));
        bitvec combined_layout = combined(total_layouts).getslice(i, BYTES_PER_RAM);
        bool allocated = alloc_halves(use, layout, combined_layout, i, name,
                ActionFormat::ADT);
        if (!allocated) return false;
    }
    LOG3("    Allocated Half Section");

    max = full_layout.max().index();

    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layouts[ActionFormat::CONTAINER_TYPES];
        for (int j = 0; j < ActionFormat::CONTAINER_TYPES; j++) {
            layouts[j] = total_layouts[j].getslice(i, BYTES_PER_RAM);
        }
        bitvec full_bitmasked = full_layout_bitmasked.getslice(i, BYTES_PER_RAM);
        bool allocated = alloc_fulls(use, layouts, full_bitmasked, i, name,
                ActionFormat::ADT);
        if (!allocated) return false;
    }
    LOG3("    Allocated Full Section");
    return true;
}

// allocate action data bus for meter output, check if the meter is already allocated,
// if so, use the previous allocation to enable sharing action data bus for the same
// meter output for tables in the same stage.
bool ActionDataBus::alloc_meter_output(const bitvec *total_layouts, Use &use, cstring name) {
    LOG2(" Total Layouts for Meter Output");
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG2(" Layout for type " << i << " is " << total_layouts[i]);
    }
    bitvec byte_layout = total_layouts[ActionFormat::BYTE];
    bitvec half_layout = total_layouts[ActionFormat::HALF];
    bitvec full_layout = total_layouts[ActionFormat::FULL];

    int max = std::max(std::max(byte_layout.max().index(), half_layout.max().index()),
                       full_layout.max().index());

    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        initialize_action_ixbar();
    }

    max = byte_layout.max().index();
    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layout = (byte_layout.getslice(i, BYTES_PER_RAM));
        bitvec combined_layout = combined(total_layouts).getslice(i, BYTES_PER_RAM);
        bool allocated = alloc_bytes(use, layout, combined_layout, i, name,
                ActionFormat::METER);
        if (!allocated) return false;
    }
    LOG3("    Allocated Byte Section");

    max = half_layout.max().index();

    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layout = (half_layout.getslice(i, BYTES_PER_RAM));
        bitvec combined_layout = combined(total_layouts).getslice(i, BYTES_PER_RAM);
        bool allocated = alloc_halves(use, layout, combined_layout, i, name,
                ActionFormat::METER);
        if (!allocated) return false;
    }
    LOG3("    Allocated Half Section");

    max = full_layout.max().index();

    for (int i = 0; i <= max; i += BYTES_PER_RAM) {
        bitvec layouts[ActionFormat::CONTAINER_TYPES];
        for (int j = 0; j < ActionFormat::CONTAINER_TYPES; j++) {
            layouts[j] = total_layouts[j].getslice(i, BYTES_PER_RAM);
        }
        bitvec full_layout_bitmasked;  /* not used */
        bool allocated = alloc_fulls(use, layouts, full_layout_bitmasked, i, name,
                ActionFormat::METER);
        if (!allocated) return false;
    }
    LOG3("    Allocated Full Section");
    return true;
}

/** This function sets up the action data table CSRs.  Because the CSRs are on an action bus
 *  home row basis, wide action tables each have their own CSRs.  Thus a vector of CSR
 *  reservations are created sized at how many Action Data RAM rows are needed
 */
void ActionDataBus::initialize_action_ixbar() {
    ActionIXBar action_ixbar;
    int type_ref = 0;
    for (int i = 0; i < ADB_BYTES; i += CSR_RANGE) {
        if (i == IMMED_DIVIDES[type_ref])
            type_ref++;
        ActionFormat::cont_type_t type = (ActionFormat::cont_type_t) type_ref;
        action_ixbar.emplace_back(type);
    }
    action_ixbars.push_back(action_ixbar);
}

/** Based on the algorithm provided to the allocation algorithm, will set up the correct
 *  pre-requisite values for the search algorithm
 */
bool ActionDataBus::find_location(bitvec combined_adjacent, int diff,
                                  ActionFormat::cont_type_t init_type, loc_alg_t loc_alg,
                                  ActionFormat::ad_source_t source, int byte_offset,
                                  int &start_byte) {
    bool initialized = true;
    int initial_adb_byte = -1;
    int final_adb_byte = -1;
    ActionFormat::cont_type_t type = init_type;
    bool reset = false;
    switch (loc_alg) {
        // Allocating a full word in the half region
        case FIND_FULL_HALF:
            type = ActionFormat::HALF;
            break;
        // Allocating a full word in the byte region
        case FIND_FULL_BYTE:
            type = ActionFormat::BYTE;
            break;
        default:
            break;
    }


    switch (loc_alg) {
        case FIND_FULL_HALF:
        case FIND_FULL_BYTE:
        // Loop through all possible sections of either the BYTE or HALF word, preferring
        // the upper bytes if possible, as those have to generally be paired off
        case FIND_NORMAL:
            initial_adb_byte = output_to_byte(PAIRED_OFFSET, type);
            final_adb_byte = output_to_byte(PAIRED_OFFSET, type);
            reset = true;
            break;
        // Look in the lower 16 slots of either the BYTE or HALF region
        case FIND_LOWER:
            initial_adb_byte = output_to_byte(0, type);
            final_adb_byte = output_to_byte(PAIRED_OFFSET, type);
            break;
        // Look in the region exclusively for FULL WORD OUTPUTS
        case FIND_FULL:
            initial_adb_byte = ADB_STARTS[type];
            final_adb_byte = ADB_BYTES;
            break;
        // Look in the upper 16 slots of either the BYTE or HALF region
        case FIND_IMMED_UPPER:
            initial_adb_byte = output_to_byte(PAIRED_OFFSET, type);
            final_adb_byte = output_to_byte(OUTPUTS, type);
            break;
        default:
            initialized = false;
            break;
    }
    BUG_CHECK(initialized, "During the action data bus allocation, somehow initialization of "
              "the search algorithm was incorrect");
    return find_location(combined_adjacent, diff, initial_adb_byte, final_adb_byte, reset,
                         type, source, byte_offset, start_byte);
}

/** Unified search algorithm to look in particular regions of the action data bus.  Here is
 *  the definition of the algorithm:
 *      combined_adjacent - the bytes to be reserved on the action data bus
 *      diff - the size of a block to be reserved on the action data bus
 *      initial_adb_byte - the byte at which to begin the search
 *      final_adb_byte - the byte at which to end the search
 *      reset - if the search loops back on itself, i.e. a search starts in the middle, goes
 *          to a high point, and then reaches a low point
 *      type - the output region in which the search is conducted, either, the BYTE, HALF,
 *          or FULL region (full region meaning only bytes that can be used by the FULL bytes)
 *      byte_offset - the initial byte within the action data format.  Important for checking
 *          if the csr for this byte has been reserved
 *      start_byte - if the algorithm is to return true, this is the byte on the action
 *          data bus to start the reservation process
 *
 *  These values are pre-selected based on the search algorithm that the compiler has chosen
 *  to run for the particular use case
 */
bool ActionDataBus::find_location(bitvec combined_adjacent, int diff, int initial_adb_byte,
                                  int final_adb_byte, bool reset, ActionFormat::cont_type_t type,
                                  ActionFormat::ad_source_t source, int byte_offset,
                                  int &start_byte) {
    int starter = initial_adb_byte;
    bool found = false;
    do {
        if (is_csr_reserved(starter, combined_adjacent, byte_offset, source)) {
            starter += CSR_RANGE;
            continue;
        }

        if ((total_in_use & (combined_adjacent << starter)).popcount() == 0) {
            found = true;
            break;
        }
        starter += diff;
        if (reset && starter >= output_to_byte(OUTPUTS, type))
            starter -= OUTPUTS * find_byte_sz(type);
    } while (starter != final_adb_byte);
    start_byte = starter;
    return found;
}

/** Reserves the action data bus space within the bitvecs, and adds it to the Use structure
 *  for the region.  Must only reserve the spaces for the actual bytes, and comes up with
 *  the correct name for the assembly output.
 */
void ActionDataBus::reserve_space(Use &use, ActionFormat::cont_type_t type, bitvec adjacent,
                                  bitvec combined_adjacent, int start_byte, int byte_offset,
                                  ActionFormat::ad_source_t source, cstring name) {
    bitvec shift_mask = combined_adjacent << start_byte;
    total_in_use |= shift_mask;

    // The actual slots that have action data
    for (auto bitpos : adjacent) {
        if (bitpos % find_byte_sz(type) != 0) continue;
        Loc loc(start_byte + bitpos, type);
        use.action_data_locs.emplace_back(loc, byte_offset + bitpos, source);
    }

    // The slots that have to be reserved because of other container types
    for (auto bitpos : (combined_adjacent - adjacent)) {
        if (bitpos % find_byte_sz(type) != 0) continue;
        Loc loc(start_byte + bitpos, type);
        use.clobber_locs.emplace_back(loc, byte_offset + bitpos, source);
    }

    for (auto bitpos : shift_mask) {
        total_use[bitpos] = name;
        if ((bitpos & find_byte_sz(type)) != 0) continue;
        int output = byte_to_output(bitpos, type);
        cont_use[type][output] = name;
        cont_in_use[type].setbit(output);
    }

    reserve_csr(start_byte, adjacent, byte_offset, source);
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
                                    int init_byte_offset, int sec_begin, int size, cstring name,
                                    ActionFormat::ad_source_t source) {
    int start_byte = 0;
    int byte_offset = init_byte_offset + sec_begin;
    bool found = find_location(combined_adjacent, size, type, loc_alg, source, byte_offset,
                               start_byte);
    if (!found) return false;
    reserve_space(use, type, adjacent, combined_adjacent, start_byte, byte_offset, source, name);
    return true;
}

/**
 *  Implementing Table 6.10
 *  Allocation of a 16 byte section of an action data table for specifically byte outputs.
 *  Because of the way the action data muxes work, the traits are broken down into:
 *      - 8 byte alloc section for bytes 8-15
 *      - 4 byte alloc section for bytes 4-7
 *      - Depending on the needs, either a 4 byte alloc section for bytes 0-3, or two 2 byte
 *      - sections for bytes 0-1 and bytes 2-3, and allocates to a lower region
 */
bool ActionDataBus::alloc_bytes(Use &use, bitvec layout, bitvec combined_layout,
                                int init_byte_offset, cstring name,
                                ActionFormat::ad_source_t source) {
    ActionFormat::cont_type_t type = ActionFormat::BYTE;
    bitvec adjacent = layout.getslice(8 /* start byte 8 */, 8 /* size 8 */);
    bitvec combined_adjacent = combined_layout.getslice(8, 8);
    if (layout.max().index() > 8) {
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                     init_byte_offset, 8, 8, name, source);
        if (!found) return false;
    }

    adjacent = layout.getslice(4, 4);
    combined_adjacent = layout.getslice(4, 4);
    if (adjacent.popcount() > 0) {
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                     init_byte_offset, 4, 4, name, source);
        if (!found) return false;
    }

    adjacent = layout.getslice(0, 4);
    combined_adjacent = layout.getslice(0, 4);

    bitvec small_adj = adjacent.getslice(0, 2);
    bitvec combined_small_adj = combined_adjacent.getslice(0, 2);

    if (small_adj == adjacent && adjacent.popcount() > 0) {
        // Put the lower 2 bits as a separate section
        bool found = fit_adf_section(use, small_adj, combined_small_adj, type, FIND_LOWER,
                                    init_byte_offset, 0, 2, name, source);
        if (found) return true;
        // Couldn't fit within the lower BYTE section, try upper half
        found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                    init_byte_offset, 0, 4, name, source);
        return found;
    } else if (adjacent.popcount() > 0) {
        // Attempt to put together as a 4 bit section
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                    init_byte_offset, 0, 4, name, source);
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
                                 int init_byte_offset, cstring name,
                                 ActionFormat::ad_source_t source) {
    ActionFormat::cont_type_t type = ActionFormat::HALF;
    bitvec adjacent = layout.getslice(8, 8);
    bitvec combined_adjacent = combined_layout.getslice(8, 8);
    if (layout.max().index() > 8) {
        bool found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                     init_byte_offset, 8, 8, name, source);
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
                                     init_byte_offset, 0, 8, name, source);
        if (!found) return false;
    } else if (adj_hi.popcount() > 0) {
        bool found = fit_adf_section(use, adj_hi, comb_adj_hi, type, FIND_LOWER,
                                     init_byte_offset, 4, 4, name, source);
        // Couldn't fit within the lower HALF section, try the upper half
        if (found) return true;
        found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                init_byte_offset, 0, 8, name, source);
        return found;
    } else if (adj_lo.popcount() > 0) {
        bool found = fit_adf_section(use, adj_lo, comb_adj_lo, type, FIND_LOWER,
                                     init_byte_offset, 0, 4, name, source);
        if (found) return true;
        // Couldn't fit within the lower HALF section, try the upper half
        found = fit_adf_section(use, adjacent, combined_adjacent, type, FIND_NORMAL,
                                init_byte_offset, 0, 8, name, source);
        return found;
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
                                       int add_byte_offset, ActionFormat::ad_source_t source) {
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
                && rs.byte_offset < byte_offset + byte_sz && rs.source == source))
                continue;
            byte_locations.setrange(rs.location.byte, small_byte_sz);
        }

        for (auto rs : use.clobber_locs) {
            int byte_offset = init_byte_offset + add_byte_offset;
            if (!(rs.location.type == j && rs.byte_offset >= byte_offset
                && rs.byte_offset < byte_offset + byte_sz && rs.source == source))
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
                                        int init_byte_offset,
                                        ActionFormat::ad_source_t source) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    int byte_sz = find_byte_sz(type);
    for (int i = 0; i < BYTES_PER_RAM; i += byte_sz) {
        if (layouts[ActionFormat::FULL].getslice(i, 4).popcount() == 0) continue;
        analyze_full_share(use, layouts, full_shares[i / byte_sz], init_byte_offset, i, source);
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
                                    bitvec full_bitmasked,
                                    ActionFormat::ad_source_t source) {
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
        // Try full region, then half region, then byte region
        bool found = false;
        for (auto region : { FIND_FULL, FIND_FULL_HALF, FIND_FULL_BYTE }) {
            found = fit_adf_section(use, unshared_adj, combined_layout, type, region,
                                    init_byte_offset, begin * byte_sz, 8, name, source);
            if (found) break;
        }
        if (!found)
            return false;
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
                      i * byte_sz + init_byte_offset, source, name);
    }
    return true;
}

/** Algorithm for allocation full sections of a 16 byte section of the action data format of
 *  an action table.  Breaks the sections into two 8 byte sections, as this hits all possible
 *  constraints in this particular region.
 */
bool ActionDataBus::alloc_fulls(Use &use, bitvec layouts[ActionFormat::CONTAINER_TYPES],
                                bitvec full_bitmasked, int init_byte_offset, cstring name,
                                ActionFormat::ad_source_t source) {
    ActionFormat::cont_type_t type = ActionFormat::FULL;
    bitvec layout = layouts[type];
    bitvec combined_layouts = combined(layouts);
    FullShare full_shares[4];
    analyze_full_shares(use, layouts, full_bitmasked, full_shares, init_byte_offset, source);

    int begin = 8 / find_byte_sz(type);
    if (layouts[type].max().index() > 8) {
        bitvec full_bitmasked_sect = full_bitmasked.getslice(8, 8);
        bitvec combined_adj = combined_layouts.getslice(8, 8);
        bool found = alloc_full_sect(use, full_shares, combined_adj, begin, init_byte_offset, name,
                                     full_bitmasked_sect, source);
        if (!found) return false;
    }

    begin = 0;
    if (layouts[type].getslice(0, 8).popcount() > 0) {
        bitvec full_bitmasked_sect = full_bitmasked.getslice(0, 8);
        bitvec combined_adj = combined_layouts.getslice(0, 8);
        bool found = alloc_full_sect(use, full_shares, combined_adj, begin, init_byte_offset, name,
                                     full_bitmasked_sect, source);
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
    bool found = find_location(combined_layout, IMMED_SECT, type, loc_alg,
            ActionFormat::IMMED, 0, start_byte);
    if (!found) return false;
    reserve_space(use, type, layout, combined_layout, start_byte, 0,
            ActionFormat::IMMED, name);
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
    analyze_full_share(use, layouts, full_share, 0, 0, ActionFormat::IMMED);
    auto combined_layouts = combined(layouts);

    if (full_share.full_in_use) {
        if (full_share.shared_status == 0) {
            // Try full section, then half section, then byte section
            bool found = false;
            for (auto region : { FIND_FULL, FIND_FULL_HALF, FIND_FULL_BYTE }) {
                found = fit_immed_sect(use, layouts[type], combined_layouts, type, region, name);
                if (found) break;
            }
            if (!found)
                return false;
        } else {
            int start_byte = -1;
            if ((full_share.shared_status & (1 << ActionFormat::HALF)) != 0)
                start_byte = full_share.shared_byte[ActionFormat::HALF];
            else if ((full_share.shared_status & (1 << ActionFormat::BYTE)) != 0)
                start_byte = full_share.shared_byte[ActionFormat::BYTE];
            reserve_space(use, type, layouts[type], layouts[type], start_byte, 0,
                    ActionFormat::IMMED, name);
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
    LOG2(" Total Layouts for Action Format Immediate");
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG2(" Layout for type " << i << " is " << total_layouts[i]);
    }

    auto type = ActionFormat::BYTE;
    auto layout = total_layouts[type];
    auto combined_layout = combined(total_layouts);

    bool found = alloc_unshared_immed(use, type, layout, combined_layout, name);
    if (!found) return false;
    LOG3("    Allocate Byte Section" << " " << layout << " " << combined_layout);

    type = ActionFormat::HALF;
    layout = total_layouts[type];
    found = alloc_unshared_immed(use, type, layout, combined_layout, name);
    if (!found) return false;
    LOG3("    Allocate Half Section" << " " << layout << " " << combined_layout);

    bitvec layouts[ActionFormat::CONTAINER_TYPES];
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++)
        layouts[i] = total_layouts[i];
    found = alloc_shared_immed(use, layouts, name);
    if (!found) return false;
    LOG3("    Allocate Full Section");
    return true;
}

/** The Random Number Generator is specified within section 6.2.5.2 Additional Action
 *  Outputs.  Specifically, each MAU stage can generate 64 bits of random numbers, divided
 *  into 2 32 bit sections.  Any byte of either 32 bit section can be muxed into any logical
 *  tables 32 bit immediate action data.
 *
 *  Currently, every RandomNumber IR structure gets it's own section of 64 bits of Random
 *  Number Generation.  This is to guarantee that each Random Number is different, which
 *  is semantically what each random.get should mean from a P4 level.  However, this
 *  is too restrictive.  The guarantee should be that each packet would have it's own
 *  set of random number.  Therefore if two mutually exclusive tables both require a Random
 *  Number, they could share the section of Random Number Generator, as this random number
 *  would be on separate packets.
 *
 *  Fortunately, the random.get is rarely used in P4, so these optimizations are low
 *  priority for the time being.
 */
bool ActionDataBus::alloc_rng(const bitvec rand_num_layouts[ActionFormat::CONTAINER_TYPES],
                              Use &use, const ActionFormat::RandNumALUFormat &format,
                              cstring name) {
    bitvec total_layout;
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        total_layout |= rand_num_layouts[i];
    }

    if (total_layout.empty())
        return true;

    bool found = false;
    int rng_index;
    for (rng_index = 0; rng_index < RANDOM_NUMBER_GENERATORS; rng_index++) {
        if ((rng_in_use[rng_index] & total_layout).empty()) {
            found = true;
            break;
        }
    }

    if (!found)
        return false;

    for (auto bit : total_layout) {
        rng_use[rng_index][bit] = name;
    }
    rng_in_use[rng_index] |= total_layout;

    for (auto &rng_entry : format) {
        auto *rn = rng_entry.first;
        auto &rn_vec = rng_entry.second;
        bitvec rn_layout;
        for (auto &alu_plac : rn_vec) {
            rn_layout.setrange(alu_plac.start, alu_plac.alu_size / 8);
        }
        Use::RandomNumberGenerator rng(rng_index, rn_layout);
        use.rng_locs.emplace(rn, rng);
    }
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
bool ActionDataBus::alloc_action_data_bus(const IR::MAU::Table *tbl, const ActionFormat::Use *use,
                                          TableResourceAlloc &alloc) {
    LOG1("Allocating action data bus for " << tbl->name);
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        auto ad = at->to<IR::MAU::ActionData>();
        if (ad == nullptr) continue;

        auto pos = allocated_attached.find(ad);
        if (pos != allocated_attached.end()) {
            alloc.action_data_xbar = pos->second;
            LOG2(" Action data bus shared on action profile " << ad->name);
            return true;
        }
    }

    LOG2(" Initial Action Data Bus");
    LOG2(" " << hex(total_in_use.getrange(96, 32)) << "|" << hex(total_in_use.getrange(64, 32))
         << "|" << hex(total_in_use.getrange(32, 32)) << "|" << hex(total_in_use.getrange(0, 32)));

    auto &ad_xbar = alloc.action_data_xbar;

    // Immediate allocation
    bitvec immed_layouts[ActionFormat::CONTAINER_TYPES];
    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        immed_layouts[i].clear();
        immed_layouts[i] |= use->total_layouts[ActionFormat::IMMED][i];
        immed_layouts[i] |= use->hash_dist_layouts[i];
        immed_layouts[i] |= use->rand_num_layouts[i];
    }


    bool allocated = alloc_immediate(immed_layouts, ad_xbar, tbl->name);
    if (!allocated) return false;

    // Action data table allocation
    allocated = alloc_ad_table(use->total_layouts[ActionFormat::ADT],
            use->full_layout_bitmasked, ad_xbar, tbl->name);
    if (!allocated) return false;

    allocated = alloc_rng(use->rand_num_layouts, ad_xbar, use->rand_num_placement, tbl->name);
    if (!allocated) return false;

    LOG2(" Action data bus for " << tbl->name);
    for (auto &rs : ad_xbar.action_data_locs) {
        LOG2(" Reserved " << rs.location.byte << " for offset " << rs.byte_offset << " of type "
             << rs.location.type);
    }

    return true;
}

/**
 * Implement the action data bus allocation logic here for meter alu output.
 */
bool ActionDataBus::alloc_action_data_bus(const IR::MAU::Table *tbl, const MeterFormat::Use *use,
        TableResourceAlloc &alloc) {
    const IR::MAU::AttachedMemory* am = nullptr;
    const IR::MAU::StatefulAlu *salu = nullptr;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;

        auto mtr = at->to<IR::MAU::Meter>();
        salu = at->to<IR::MAU::StatefulAlu>();

        if ((mtr && mtr->alu_output()) || salu) {
            am = at;
            break;
        }
    }

    if (am == nullptr)
        return true;

    LOG1("Allocating action data bus for " << tbl->name << " for meter output of " << am->name);
    // Do not allocate if this meter/stateful alu has been previously allocated, as it has
    // been shared with a table in this stage.  Instead, link it with this allocation
    auto pos = allocated_attached.find(am);
    if (pos != allocated_attached.end()) {
        alloc.meter_xbar = pos->second;
        LOG2(" Action data bus shared on meter_adr user " << am->name);
        return true;
    }


    if (salu && salu->reduction_or_group) {
        auto red_pos = reduction_or_mapping.find(salu->reduction_or_group);
        if (red_pos != reduction_or_mapping.end()) {
            alloc.meter_xbar = red_pos->second;
            LOG2(" Action data bus shared through reduction or group " << salu->reduction_or_group);
            return true;
        }
    }


    LOG2(" Initial Action Data Bus");
    LOG2(" " << hex(total_in_use.getrange(96, 32)) << "|" << hex(total_in_use.getrange(64, 32))
         << "|" << hex(total_in_use.getrange(32, 32)) << "|" << hex(total_in_use.getrange(0, 32)));

    auto &meter_xbar = alloc.meter_xbar;

    for (int i = 0; i < ActionFormat::CONTAINER_TYPES; i++) {
        LOG2(" Layout for type " << i << " is " << use->total_layouts[i]);
    }
    bool allocated = alloc_meter_output(use->total_layouts, meter_xbar, tbl->name);
    if (!allocated) return false;

    LOG2(" Action data bus for " << tbl->name);
    for (auto &rs : meter_xbar.action_data_locs) {
        LOG2(" Reserved " << rs.location.byte << " for offset " << rs.byte_offset << " of type "
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

void ActionDataBus::update(cstring name, const Use::RandomNumberGenerator &rng) {
    for (auto bit : rng.bytes) {
        if (!rng_use[rng.unit][bit].isNull()) {
            BUG("Conflicting allocation in the random number generator between %s and %s at "
                "unit %d and byte %d", name, rng_use[rng.unit][bit], rng.unit, bit);
        }
        rng_use[rng.unit][bit] = name;
    }
    rng_in_use[rng.unit] |= rng.bytes;
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

    for (auto &rng : alloc.rng_locs) {
        update(name, rng.second);
    }
}

void ActionDataBus::update_action_data(cstring name, const TableResourceAlloc *alloc,
                                       const IR::MAU::Table *tbl) {
    const IR::MAU::ActionData *ad = nullptr;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        ad = at->to<IR::MAU::ActionData>();
        if (ad != nullptr)
            break;
    }
    if (ad) {
        if (allocated_attached.count(ad) > 0)
            return;
    }

    update(name, alloc->action_data_xbar);
    if (ad)
        allocated_attached.emplace(ad, alloc->action_data_xbar);
}

void ActionDataBus::update_meter(cstring name, const TableResourceAlloc *alloc,
                                 const IR::MAU::Table *tbl) {
    const IR::MAU::AttachedMemory *am = nullptr;
    const IR::MAU::StatefulAlu *salu = nullptr;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        auto mtr = at->to<IR::MAU::Meter>();
        salu = at->to<IR::MAU::StatefulAlu>();
        if ((mtr && mtr->alu_output()) || salu) {
            am = at;
            break;
        }
    }

    if (am) {
        if (allocated_attached.count(am) > 0)
            return;
    } else {
        return;
    }

    if (salu && salu->reduction_or_group) {
        if (reduction_or_mapping.count(salu->reduction_or_group)) {
            return;
        }
    }

    // Only update if the meter/stateful alu use is not previously accounted for
    update(name + "$" + am->name, alloc->meter_xbar);

    if (salu && salu->reduction_or_group) {
        reduction_or_mapping.emplace(salu->reduction_or_group, alloc->meter_xbar);
    }

    allocated_attached.emplace(am, alloc->meter_xbar);
}

void ActionDataBus::update(cstring name, const TableResourceAlloc *alloc,
                           const IR::MAU::Table *tbl) {
    update_action_data(name, alloc, tbl);
    update_meter(name, alloc, tbl);
}

void ActionDataBus::update(const IR::MAU::Table *tbl) {
    if (tbl->layout.atcam && tbl->is_placed()) {
        auto orig_name = tbl->name.before(tbl->name.findlast('$'));
        if (atcam_updates.count(orig_name))
            return;
        atcam_updates.emplace(orig_name);
    }
    update(tbl->name, tbl->resources, tbl);
}
