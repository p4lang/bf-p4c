#include "table_format.h"


/* Overall analysis for the exact match layout option, to determine in which RAMs of table
   format will contain particular match data, and which RAMs contain the overhead data. 
   Responsible for balancing entries if they require more than 1 match group */
bool TableFormat::analyze_layout_option() {
    // FIXME: In total needs some information variable passed about ghosting

    int min_way_size = *std::min_element(layout_option.way_sizes.begin(),
                                         layout_option.way_sizes.end());

    ghost_bits_count = RAM_GHOST_BITS + floor_log2(min_way_size);
    int per_RAM = layout_option.way->match_groups / layout_option.way->width;
    vector<std::pair<int, int>> sizes = match_ixbar.bits_per_group_single();

    vector<int> empty;
    for (int i = 0; i < layout_option.way->match_groups; i++) {
        match_group_info.push_back(empty);
        use->match_groups.emplace_back();
    }

    single_match = match_ixbar.match_hash_single();

    if (per_RAM > 0) {
        bool rv = analyze_skinny_layout_option(per_RAM, sizes);
        if (!rv) return false;
    } else {
        bool rv = analyze_wide_layout_option(sizes);
        if (!rv) return false;
    }

    // Unsure if more code will be required here in the future
    return true;
}

/* Specifically for the allocation of groups that only require one RAM.  If it requires
   multiple match groups, then balance these match groups and corresponding overhead */
bool TableFormat::analyze_skinny_layout_option(int per_RAM, vector<std::pair<int, int>> &sizes) {
    if (match_ixbar.groups_single() > 1) {
        return false;  // FIXME: deal with this later, essentially potentially can ghost
                       // the extra group of if possible/have enough space
    }

    int total = 0;
    for (int i = 0; i < layout_option.way->width; i++) {
        match_groups_per_RAM.push_back(per_RAM);
        overhead_groups_per_RAM.push_back(per_RAM);
        total += per_RAM;
    }

    int i = match_groups_per_RAM.size() - 1;
    while (total < layout_option.way->match_groups) {
        balanced = false;
        match_groups_per_RAM[i]++;
        overhead_groups_per_RAM[i]++;
        i--;
        total++;
    }

    int index = 0; int min_total = 0;
    for (int i = 0; i < layout_option.way->match_groups; i++) {
        if (min_total == match_groups_per_RAM[index])
            index++;
        match_group_info[i].push_back(index);
        min_total++;
    }

    for (int i = 0; i < layout_option.way->width; i++) {
        ixbar_group_per_width.push_back(sizes[0].first);
    }
    return true;
}

/* Specifically for the allocation of groups that require multiple RAMs.  Determine where
   the overhead has to be, and which RAMs contain the particular match groups */
bool TableFormat::analyze_wide_layout_option(vector<std::pair<int, int>> &sizes) {
    int RAM_per = layout_option.way->width / layout_option.way->match_groups;
    if (layout_option.way->width % layout_option.way->match_groups == 0
        && layout_option.way->match_groups != 1) {
        BUG("Ridiculous layout chosen.  Must be shrunken down");
    }
    if (match_ixbar.groups_single() > RAM_per) {
        return false;  // FIXME: Again, can potentially be saved by ghosting off certain bits
    }

    // Too much overhead means that even though only one hash group requires wide group
    if (sizes.size() < RAM_per) {
        sizes.insert(sizes.begin(), sizes[0]);
    }

    // Whichever one has the least amount of bits will be the group in which the overhead
    // is stored
    std::sort(sizes.begin(), sizes.end(),
        [=](const std::pair<int, int> &a, const std::pair<int, int> &b) {
        int t;
        if ((t = a.second - b.second) != 0) return a.second > b.second;
        if ((t = a.first - b.first) != 0) return a.first < b.first;
        return true;
    });

    // Check to see if two match groups can share the space within an individual RAM
    if (layout_option.way->match_groups > 1) {
        if (2 * (sizes.back().second + VERSION_BITS + layout_option.layout->overhead_bits)
            > SINGLE_RAM_BITS) {
            return false;
        }
    }

    // Assigns the match group, overhead, and ixbar group information to the particular RAM
    int overhead_start = 0;
    bool single = layout_option.way->match_groups == 1;
    for (int i = 0; i < layout_option.way->width; i++) {
        if (i < layout_option.way->match_groups * RAM_per) {
            ixbar_group_per_width.push_back(sizes[i % RAM_per].first);
            match_groups_per_RAM.push_back(1);
            if (single && i == layout_option.way->width - 1)
                overhead_groups_per_RAM.push_back(1);
            else
                overhead_groups_per_RAM.push_back(0);
            match_group_info[i / RAM_per].push_back(i);
        } else {
            ixbar_group_per_width.push_back(sizes.back().first);
            match_groups_per_RAM.push_back(2);
            overhead_groups_per_RAM.push_back(2);
            match_group_info[overhead_start].push_back(i);
            match_group_info[overhead_start + 1].push_back(i);
            overhead_start += 2;
        }
    }
    return true;
}

/* General algorithms for finding the formats for all tables.  Separate algorithms for no match,
   ternary tables, and exact match tables */
bool TableFormat::find_format(Use *u) {
    use = u;
    LOG3("Find format for table " << tbl->name);
    if (layout_option.layout->ternary) {
        overhead_groups_per_RAM.push_back(1);
        use->match_groups.emplace_back();
        if (!layout_option.layout->ternary_indirect_required())
            return true;
        if (!allocate_next_table())
            return false;
        if (!allocate_all_indirect_ptrs())
            return false;
        if (!allocate_all_immediate(false))
            return false;
        if (!allocate_all_instr_selection())
            return false;
        return true;
    }

    if (layout_option.layout->no_match_data()) {
        overhead_groups_per_RAM.push_back(1);
        use->match_groups.emplace_back();
        if (!allocate_all_immediate(true))
            return false;
        return true;
    }

    if (!analyze_layout_option())
        return false;
    LOG3("Layout option");
    if (!allocate_next_table())
        return false;
    LOG3("Next Table");
    if (!allocate_all_indirect_ptrs())
        return false;
    LOG3("Indirect Pointers");
    if (!allocate_all_immediate(false))
        return false;
    LOG3("Immediate");
    if (!allocate_all_instr_selection())
        return false;
    LOG3("Instruction Selection");
    if (!allocate_all_match())
        return false;
    LOG3("Match");
    if (!allocate_all_version())
        return false;
    LOG3("Version");
    verify();
    return true;
}

/* Bits for selecting the next table from an action chain table must be in the lower part
   of the overhead.  This is specifically to handle this corner case.  If this is run,
   then instruction selection does not necessarily need to be run */
bool TableFormat::allocate_next_table() {
    int group = 0;

    for (auto &next : tbl->next) {
        if (next.first[0] != '$')
            next_table = true;
    }

    if (!next_table)
        return true;
    int next_table_bits = ceil_log2(tbl->actions.size());

    for (int i = 0; i < overhead_groups_per_RAM.size(); i++) {
        for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
            size_t start = total_use.ffz(i * SINGLE_RAM_BITS);
            if (start + next_table_bits >= OVERHEAD_BITS + i * SINGLE_RAM_BITS)
                return false;
            bitvec ptr_mask(start, next_table_bits);
            use->match_groups[group].mask[ACTION] |= ptr_mask;
            total_use |= ptr_mask;
        }
    }
    return true;
}

/* Finds space for an individual indirect pointer.  Bases it on the type.  Total is the
   number of bits needed */
bool TableFormat::allocate_indirect_ptr(int total, type_t type, int group, int RAM) {
    size_t start = total_use.ffz(RAM * SINGLE_RAM_BITS);
    if (start + total >= OVERHEAD_BITS + RAM * SINGLE_RAM_BITS)
        return false;
    bitvec ptr_mask;
    ptr_mask.setrange(start, total);
    use->match_groups[group].mask[type] |= ptr_mask;
    total_use |= ptr_mask;
    return true;
}

/* Algorithm to find the space for any indirect pointers.  Allocated back to back, as they are
   easiest to pack.  No gaps are possible at all within the indirect pointers */
bool TableFormat::allocate_all_indirect_ptrs() {
     int group = 0;
     for (int i = 0; i < overhead_groups_per_RAM.size(); i++) {
         for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
             int total;
             if ((total = layout_option.layout->counter_overhead_bits) != 0) {
                 if (!allocate_indirect_ptr(total, COUNTER, group, i))
                     return false;
             }

             if ((total = layout_option.layout->meter_overhead_bits) != 0) {
                 if (!allocate_indirect_ptr(total, METER, group, i))
                     return false;
             }

             if ((total = layout_option.layout->indirect_action_overhead_bits) != 0) {
                 if (!allocate_indirect_ptr(total, INDIRECT_ACTION, group, i))
                     return false;
             }
             if ((total = layout_option.layout->selector_overhead_bits) != 0) {
                 if (!allocate_indirect_ptr(total, SELECTOR, group, i))
                     return false;
             }
             group++;
         }
     }

     return true;
}

/* Algorithm to find space for the immediate data.  Immediate information may have gaps, i.e. a 9
   bit field has 7 free bits which can potentially be allocated into.  Thus the spaces
   are left open for space to be filled by either instr selection or match bytes */
bool TableFormat::allocate_all_immediate(bool no_match) {
    if (layout_option.layout->action_data_bytes_in_overhead == 0)
        return true;

    // Determine the spaces within the immediate format.  Must be the same for each entry
    int max_size = 0;
    bitvec immediate_mask;
    for (auto action : Values(tbl->actions)) {
        vector<int> arg_sizes;
        arg_sizes.clear();
        for (auto arg : action->args) {
            arg_sizes.push_back(arg->type->width_bits());
        }
        std::sort(arg_sizes.begin(), arg_sizes.end(), [=](const int &a, const int &b) {
            return a > b;
        });

        int total_required = 0;
        for (size_t i = 0; i < arg_sizes.size(); i++) {
            immediate_mask.setrange(total_required, arg_sizes[i]);
            if (i == arg_sizes.size() - 1)
                total_required += arg_sizes[i];
            else
                total_required += (arg_sizes[i] + 7U) / 8U * 8;
        }

        if (max_size < total_required)
            max_size = total_required;
    }

    // For asm generation, there can be no gaps in immediate mask for action only tables
    if (no_match) {
        immediate_mask.setrange(0, immediate_mask.max());
    }

    use->immed_mask = immediate_mask;

    // Allocate the immediate mask for each overhead section
    int group = 0;
    for (int i = 0; i < overhead_groups_per_RAM.size(); i++) {
        int start = total_use.ffz(i * SINGLE_RAM_BITS);
        for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
            int shift = start + j * max_size;
            bitvec immediate_shift = immediate_mask << shift;
            if (start + max_size >= OVERHEAD_BITS + i * SINGLE_RAM_BITS)
                return false;
            total_use |= immediate_shift;
            use->match_groups[group].mask[IMMEDIATE] |= immediate_shift;
            group++;
        }
    }
    return true;
}

/* Algorithm to find space for the instruction selection bits required.  Try to pack this
   information into spaces of the immediate.  Otherwise just push to the lowest part of
   the result bus.  FIXME: This could be combined with the calculation of ghost bits. */
bool TableFormat::allocate_all_instr_selection() {
    if (next_table)
        return true;
    if (tbl->actions.size() == 1)
        return true;

    int instr_select = ceil_log2(tbl->actions.size());
    bitvec instr_mask;
    instr_mask.setrange(0, instr_select);
    int group = 0;
    for (int i = 0; i < overhead_groups_per_RAM.size(); i++) {
        for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
            int start = use->match_groups[group].mask[IMMEDIATE].ffs();
            if (start == -1)
                start = i * SINGLE_RAM_BITS;
            int hole_start = total_use.ffz(start);
            int hole_end = total_use.ffs(hole_start);
            while (hole_end >= 0 && hole_end - hole_start < instr_select) {
                hole_start = total_use.ffz(hole_end);
                hole_end = total_use.ffs(hole_start);
            }
            bitvec instr_shift = instr_mask << hole_start;
            total_use |= instr_shift;
            use->match_groups[group].mask[ACTION] |= instr_shift;
            group++;
        }
    }
    return true;
}

/* This section of match group information is responsible for allocating the bytes that
   are designated to be simple, essentialy bytes that 8 bits total and have no ghosting 
   issues.  Create a vector of these easy bytes and try to allocate them all at once */
bool TableFormat::allocate_easy_bytes(bitvec &unaligned_bytes, bitvec &chosen_ghost_bytes,

    int &easy_size) {
    vector<ByteInfo> easy_match_bytes;
    bitvec difficult_bytes = unaligned_bytes | chosen_ghost_bytes;
    int index = -1;
    for (auto &byte : single_match) {
        index++;
        if (difficult_bytes.getbit(index)) continue;
        easy_match_bytes.emplace_back(byte, 8, index);
    }

    easy_size = easy_match_bytes.size();
    bool rv = allocate_byte_vector(easy_match_bytes, 0, false);

    // Potential for splits?
    if (!rv)
        return false;

    int group = 0;
    for (int i = 0; i < match_groups_per_RAM.size(); i++) {
        for (int j = 0; j < match_groups_per_RAM[i]; j++) {
            for (auto mg : use->match_groups[group].match) {
                LOG4("Group " << group << " Byte " << mg.first << " location "
                     << mg.second.second << " size " << mg.second.first);
            }
            group = determine_next_group(group, i);
        }
    }
    return true;
}

/* Fills in the vectors used and dsecribed in the allocate_difficult_bytes function call. */
void TableFormat::determine_difficult_vectors(vector<ByteInfo> &unaligned_match,
    vector<ByteInfo> &unaligned_ghost, vector<ByteInfo> &ghost_anywhere,
    bitvec &unaligned_bytes, bitvec &chosen_ghost_bytes, int ghosted_group) {

    int unaligned_ghost_bits = 0;
    int index = -1;

    // Only bytes that are contained in the group that is determined to be ghosted can be
    // This is for fitting wide match data with its overhead
    for (auto byte : single_match) {
        index++;
        if (!unaligned_bytes.getbit(index)) continue;
        int size = byte.hi - byte.lo + 1;
        if (byte.loc.group == ghosted_group) {
            unaligned_ghost.emplace_back(byte, size, index);
            unaligned_ghost_bits += size;
        } else {
            unaligned_match.emplace_back(byte, size, index);
        }
    }

    int ghost_bits_allowed = ghost_bits_count;
    std::sort(unaligned_ghost.begin(), unaligned_ghost.end(),
        [=](const ByteInfo &a, const ByteInfo &b){
        int t;
        if ((t = a.bit_count - b.bit_count) != 0)
            return a.bit_count < b.bit_count;

        return a.byte < b.byte;
    });

    // If the bits of non 8 bit fields > total allowed ghost bits from the way sizes,
    // this loop decides which fields must be actually matched upon, and how to split them up
    while (unaligned_ghost_bits > ghost_bits_allowed) {
        int difference = unaligned_ghost_bits - ghost_bits_allowed;
        int match_added = unaligned_ghost.back().bit_count;
        if (match_added < difference) {
            unaligned_match.push_back(unaligned_ghost.back());
            unaligned_ghost.pop_back();
            unaligned_ghost_bits -= match_added;
        } else {
            int ghosted_bits = match_added - difference;
            ByteInfo &last_ghost = unaligned_ghost.back();
            last_ghost.bit_count = ghosted_bits;
            unaligned_match.emplace_back(last_ghost.byte, difference, last_ghost.use_index);
            unaligned_ghost_bits -= ghosted_bits;
        }
    }

    // If the bits of non 8 bit fields < total allowed ghost bits from the way sizes,
    // this loop selects an 8 bit field to split into ghosted and non-ghosted
    if (unaligned_ghost_bits < ghost_bits_allowed) {
        int difference = ghost_bits_allowed - unaligned_ghost_bits;
        int ghosted_bits = difference % 8;

        int index = -1;
        bool match_allocated = false;
        for (auto byte : single_match) {
            index++;
            if (!chosen_ghost_bytes.getbit(index)) continue;
            if (!match_allocated) {
                unaligned_ghost.emplace_back(byte, ghosted_bits, index);
                ghost_anywhere.emplace_back(byte, 8 - ghosted_bits, index);
                match_allocated = true;
            } else {
                unaligned_ghost.emplace_back(byte, 8, index);
            }
        }
    }
}

/* This section deals with the so-called difficult bytes.  These are bytes that do not use
   all of the 8 bits, as well any bits that are decided to be ghosted.  The algorithm tries
   to ghost all these less than 8 bit vectors, as these require a total match byte but don't
   use all individual bits of that byte.  After that, a full 8 bit is selected to be partially
   ghosted and partially matched. */
bool TableFormat::allocate_difficult_bytes(bitvec &unaligned_bytes, bitvec &chosen_ghost_bytes,
    int easy_size) {
    int o_index = std::max_element(overhead_groups_per_RAM.begin(),
                                   overhead_groups_per_RAM.end())
                      - overhead_groups_per_RAM.begin();
    int ghosted_group = ixbar_group_per_width[o_index];
    vector<ByteInfo> unaligned_ghost;  // All non 8-bit IXBar Bytes we can ghost
    vector<ByteInfo> unaligned_match;  // All non 8-bit IXBar Bytes we have to include in the match
    vector<ByteInfo> ghost_anywhere;   // Specifically the 8 bit byte that can select any of its
                                       // bits to ghost

    determine_difficult_vectors(unaligned_match, unaligned_ghost, ghost_anywhere,
                                unaligned_bytes, chosen_ghost_bytes, ghosted_group);

    bool rv = allocate_byte_vector(unaligned_match, easy_size, false);
    if (!rv)
        return false;

    rv = allocate_byte_vector(ghost_anywhere, easy_size + unaligned_match.size(), true);
    if (!rv)
        return false;

    // Fill out ghost byte information
    for (auto byte : unaligned_ghost) {
        if (ghost_anywhere.size() > 0 && ghost_anywhere[0].byte == byte.byte)
            use->ghost_bits[byte.byte]
                 = std::make_pair(byte.bit_count, bitvec(0, 8) - ghost_start);
        else
            use->ghost_bits[byte.byte] = std::make_pair(byte.bit_count, bitvec(0, 8));
    }
    return true;
}

/* Function for packing an individual byte into a table.  Fills out all TableFormat bitvecs
   appropriately.  Protect is used to preserve space on the lower 4 bytes for gateway space,
   and the upper 2 bits for version information.  Ghost anywhere is specifically for the 8 bit
   value that has to determine a mask. */
void TableFormat::easy_byte_fill(int RAM, int group, ByteInfo &byte, int &starting_byte,
    bool protect, bool ghost_anywhere) {
    int begin = starting_byte;
    int RAM_offset = SINGLE_RAM_BYTES * RAM;
    for (int i = begin; i < RAM_offset + SINGLE_RAM_BYTES; i++) {
        starting_byte++;
        if ((i < RAM_offset + GATEWAY_BYTES) && protect) continue;
        if ((i >= RAM_offset + VERSION_BYTES) && protect) continue;
        int byte_offset = i;
        // If the ghost anywhere is not set, we reserve the whole byte, as we do not know
        // the PHV alignment.  At some point we could combine this analysis after PHV allocation,
        // but this is probably not a limiting constraint currently
        int bits_needed = ghost_anywhere ? byte.bit_count : 8;
        if (8 - byte_use[byte_offset].popcount() < bits_needed) continue;
        bitvec match_mask;
        if (ghost_anywhere) {
            // This is a very sub-optimal solution that determines the mask of the
            // match for the ghost anywhere bits.  Could be done at a later point.
            bitvec temp_mask;
            temp_mask.setrange(byte_offset * 8, 8);
            // FIXME: Global ghost start determined here.  Ghosted bits have to be the same
            // for each match group.  Would be more optimal to do at a different place
            if (ghost_start.popcount() == 0) {
                 match_mask = temp_mask - byte_use[byte_offset];
                 while (match_mask.popcount() > bits_needed) {
                     match_mask.clrbit(match_mask.ffs());
                 }
                 ghost_start = match_mask >> (byte_offset * 8);
            } else {
                match_mask = ghost_start << (byte_offset * 8);
                if ((match_mask & byte_use[byte_offset]).popcount() != 0) continue;
            }
        } else {
            match_mask.setrange(byte_offset * 8, 8);
        }
        // Fill out the appropriate bit vectors
        use->match_groups[group].match[byte.byte] = std::make_pair(byte.bit_count, match_mask);
        total_use |= match_mask;
        match_byte_use |= i;
        byte_use[byte_offset] |= match_mask;
        use->match_groups[group].mask[MATCH] |= match_mask;
        use->match_groups[group].match_byte_mask |= i;
        use->match_groups[group].allocated_bytes.setbit(byte.use_index);
        return;
    }
}

/* Specifically for the iteration through match group in byte vector allocation.  Coordination
   of which IXBar groups coordinate to which RAM.  Specifically different for wide matches.
   Essentially, an individual match group can be in multiple RAMs, and group cannot be 
   simply incremented */
int TableFormat::determine_next_group(int current_group, int RAM) {
    int per_RAM = layout_option.way->match_groups / layout_option.way->width;

    if (per_RAM > 0)
        return current_group + 1;

    int RAM_per = layout_option.way->width / layout_option.way->match_groups;

    if (RAM >= RAM_per * layout_option.way->match_groups)
        return current_group + 1;
    if (RAM % RAM_per == RAM_per - 1) {
        if (RAM == RAM_per * layout_option.way->match_groups - 1)
            return 0;
        else
            return current_group + 1;
    } else {
        return current_group;
    }
}

/* For allocating every byte in the vector, which are filled by the allocation vectors.
   Bytes are coordinated to which IXBar groups as well as how many match groups are
   contained within the individual RAM */
bool TableFormat::allocate_byte_vector(vector<ByteInfo> &bytes, int prev_allocated,
    bool ghost_anywhere) {
    // Save space for the lower 4 bytes and upper 2 bytes for potential gateway allocation
    int group = 0;
    for (int i = 0; i < match_groups_per_RAM.size(); i++) {
        int starting_byte = i * SINGLE_RAM_BYTES;
        for (int j = 0; j < match_groups_per_RAM[i]; j++) {
            bitvec all_bits = use->match_groups[group].allocated_bytes;
            for (auto byte : bytes) {
                if (all_bits.getbit(byte.use_index)) continue;
                if (byte.byte.loc.group != ixbar_group_per_width[i]) continue;
                easy_byte_fill(i, group, byte, starting_byte, true, ghost_anywhere);
            }
            group = determine_next_group(group, i);
        }
    }

    group = 0;
    // Use all space within a RAM, i.e. the lower 4 bytes and upper 2 bytes.
    for (int i = 0; i < match_groups_per_RAM.size(); i++) {
        int starting_byte = i * SINGLE_RAM_BYTES;
        for (int j = 0; j < match_groups_per_RAM[i]; j++) {
            bitvec all_bits = use->match_groups[group].allocated_bytes;
            if (all_bits.popcount() == bytes.size() + prev_allocated) {
                group = determine_next_group(group, i);
                continue;
            }
            for (auto byte : bytes) {
                if (all_bits.getbit(byte.use_index)) continue;
                if (byte.byte.loc.group != ixbar_group_per_width[i]) continue;
                easy_byte_fill(i, group, byte, starting_byte, false, ghost_anywhere);
            }
            group = determine_next_group(group, i);
        }
    }

    // Check to see if all match groups have allocated total space
    group = 0;
    for (int i = 0; i < match_groups_per_RAM.size(); i++) {
        for (int j = 0; j < match_groups_per_RAM[i]; j++) {
            bitvec all_bits = use->match_groups[group].allocated_bytes;
            if (all_bits.popcount() != bytes.size() + prev_allocated) {
                // FIXME: Not yet doing sharing of groups that are too small
                return false;
            }
            group = determine_next_group(group, i);
        }
    }
    return true;
}


/* Analysis for chosen which bytes are easy and which are difficult.  This information is
   used for determining how to allocate bytes */
void TableFormat::determine_byte_types(bitvec &unaligned_bytes, bitvec &chosen_ghost_bytes) {
    int o_index = std::max_element(overhead_groups_per_RAM.begin(),
                                   overhead_groups_per_RAM.end())
                      - overhead_groups_per_RAM.begin();
    int ghosted_group = ixbar_group_per_width[o_index];

    int unaligned_bits = 0;
    for (auto byte : single_match) {
        if (byte.loc.group != ghosted_group) continue;
        int difference = byte.hi - byte.lo + 1;
        if (difference != 8)
            unaligned_bits += difference;
    }

    int full_bytes_ghosted = std::max((ghost_bits_count - unaligned_bits + 7) / 8, 0);
    int full_bytes_remain = full_bytes_ghosted;

    for (int i = single_match.size() - 1; i >= 0; i--) {
        int difference = single_match[i].hi - single_match[i].lo;
        if (difference == 7 && full_bytes_remain > 0) {
            if (single_match[i].loc.group != ghosted_group) continue;
            full_bytes_remain--;
            chosen_ghost_bytes.setbit(i);
        }

        if (difference != 7) {
            unaligned_bytes.setbit(i);
        }
    }
}

/* Total allocation scheme for all match data */
bool TableFormat::allocate_all_match() {
    for (int i = 0; i < SINGLE_RAM_BITS / 8 * layout_option.way->width; i++) {
        byte_use.push_back(total_use.getslice(i*8, 8));
    }

    bool rv;
    int easy_size = 0;
    bitvec unaligned_bytes; bitvec chosen_ghost_bytes;
    determine_byte_types(unaligned_bytes, chosen_ghost_bytes);
    if (!allocate_easy_bytes(unaligned_bytes, chosen_ghost_bytes, easy_size))
        return false;
    if (!allocate_difficult_bytes(unaligned_bytes, chosen_ghost_bytes, easy_size))
        return false;

    return true;
}

/* Specifically allocates one version for a byte.  Only looks in the upper 4 nibbles of the RAM
   This isn't what I want to do, but it's a first draft so I can test the other pieces */
bool TableFormat::allocate_one_version(int starting_byte, int group) {
    bool allocated = false;
    int version_check = starting_byte + VERSION_BYTES;
    for (int i = 0; i < VERSION_NIBBLES; i++) {
        int version_index = version_check * 8 + i * VERSION_BITS;
        if (total_use.getrange(version_check * 8 + i * VERSION_BITS, VERSION_BITS)) continue;
        bitvec vers_mask(0, VERSION_BITS);
        vers_mask <<= version_check * 8 + i * VERSION_BITS;
        use->match_groups[group].mask[VERS] |= vers_mask;
        total_use |= vers_mask;
        byte_use[version_check + i / 2] |= vers_mask;
        allocated = true;
        break;
    }
    return allocated;
}

/* Allocates the version for all match groups.  Again, this is a relatively simpler version */
bool TableFormat::allocate_all_version() {
    for (int i = 0; i < match_group_info.size(); i++) {
        bool allocated = false;
        for (int j = 0; j < match_group_info[i].size(); j++) {
            int starting_byte = match_group_info[i][j] * SINGLE_RAM_BYTES;
            if (allocate_one_version(starting_byte, i)) {
                allocated = true; break;
            }
        }
        if (!allocated) return false;
    }
    return true;
}

/* This is a verification pass that guarantees that we don't have overlap.  More constraints can
   be checked as well.  */
void TableFormat::verify() {
    int group = 0;
    bitvec verify_mask;

    for (int i = 0; i < layout_option.way->match_groups; i++) {
        for (int j = ACTION; j <= SELECTOR; j++) {
            if ((verify_mask & use->match_groups[i].mask[j]).popcount() != 0)
                BUG("Overlap of multiple things in the format");
            verify_mask |= use->match_groups[i].mask[j];
        }
    }

    for (int i = 0; i < layout_option.way->match_groups; i++) {
        for (auto byte_info : use->match_groups[i].match) {
            std::pair<int, bitvec> &byte_mask = byte_info.second;
            if ((verify_mask & byte_mask.second).popcount() != 0)
                BUG("Overlap of a match byte in the format");
            verify_mask |= byte_mask.second;
        }
    }
}
