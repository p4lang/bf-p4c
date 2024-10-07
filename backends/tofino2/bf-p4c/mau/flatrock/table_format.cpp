#include "bf-p4c/mau/flatrock/table_format.h"
#include "lib/big_int_util.h"

namespace Flatrock {

/** This fills out the use object, as well as the global structures for keeping track of the
 *  format.  This does this for both match and version information.
 */
void TableFormat::fill_out_use(int group, const safe_vector<ByteInfo> &alloced) {
    Log::TempIndent indent;
    LOG5("Filling out match byte and group use for group " << group << indent);
    auto &group_use = use->match_groups[group];
    for (const auto& info : alloced) {
        bitvec match_location = info.bit_use << (8 * info.byte_location);
        group_use.match[info.byte] = match_location;
        group_use.mask[MATCH] |= match_location;
        group_use.match_byte_mask.setbit(info.byte_location);
        match_byte_use.setbit(info.byte_location);
        total_use |= match_location;
        LOG6("Total Use: " << total_use << ", group use: " << group_use
                << ", match byte use: " << match_byte_use);
    }
}

/** Given a number of overhead entries, this algorithm determines how many match groups
 *  can fully fit into that particular RAM line.
 *  TODO: Wide matches
 */
void TableFormat::allocate_full_fits(int width_sect, int group) {
    Log::TempIndent indent;
    LOG4("Allocating Full Fits on RAM word " << width_sect << " search bus "
         << search_bus_per_width[width_sect] << " for group " << group << indent);
    safe_vector<ByteInfo> allocation_needed;
    safe_vector<ByteInfo> alloced;
    find_bytes_to_allocate(width_sect, allocation_needed);
    bitvec byte_attempt;
    bitvec bit_attempt;

    if (group == -1) return;
    int groups_allocated = 0;
    int allocate_single_group = (group >= 0);
    while (true) {
        alloced.clear();
        byte_attempt.clear();
        bit_attempt.clear();
        // if (!allocate_single_group)
        //     group = determine_group(width_sect, groups_allocated);
        // if (group == -1) break;
        LOG4("Attempting Entry " << group);
        for (const auto& info : allocation_needed) {
            if (!allocate_match_byte(info, alloced, width_sect, byte_attempt, bit_attempt))
                break;
        }

        if (allocation_needed.size() != alloced.size()) break;

        LOG6("Bytes used for match 0x"
             << byte_attempt.getslice(width_sect * SINGLE_RAM_BYTES, SINGLE_RAM_BYTES));

        LOG4("Entry " << group << " fully fits on RAM word");

        groups_allocated++;
        full_match_groups_per_RAM[width_sect]++;
        fill_out_use(group, alloced);
        LOG4("Entry usage: " << total_use);

        if (allocate_single_group) break;
    }
}

bool TableFormat::allocate_match_with_algorithm(int group) {
    Log::TempIndent indent;
    LOG5("Allocate match with algorithm for group " << group << indent);
    for (int width_sect = 0; width_sect < layout_option.way.width; width_sect++) {
        allocate_full_fits(width_sect, group);
    }

#if 0
    // Flatrock search busses are tied to the XMUs, so there's no need to "allocate"
    // them
    //
    // Determine if everything is fully allocated
    safe_vector<int> search_bus_alloc(match_ixbar->search_buses_single(), 0);
    for (int width_sect = 0; width_sect < layout_option.way.width; width_sect++) {
        int search_bus = search_bus_per_width[width_sect];
        if (search_bus < 0)
            continue;
        search_bus_alloc[search_bus] += full_match_groups_per_RAM[width_sect];
    }
#endif
    return true;
}

bool TableFormat::allocate_match_byte(const ByteInfo &info, safe_vector<ByteInfo> &alloced,
    int width_sect, bitvec &byte_attempt, bitvec &bit_attempt) {
    Log::TempIndent indent;
    LOG5("Allocate Match Byte" << indent);
    // Need to increment by entry size
    // Entry size = 1/2 1/4 of a set
    // Set size 1, 2, 4, 8, 16, 32, 64, 128 (sets per word)
    // Set enable 4 way lookup always
    // for (int i = 0; i < SINGLE_RAM_BYTES; i+=((SINGLE_RAM_BITS/MAX_GROUPS_PER_LAMB)/8))
    for (int i = 0; i < SINGLE_RAM_BYTES; i++) {
        if (initialize_byte(i, width_sect, info, alloced, byte_attempt, bit_attempt))
            return true;
    }
    LOG6("Alloced : " << alloced);
    return false;
}

void TableFormat::classify_match_bits() {
    Log::TempIndent indent;
    LOG5("Classifying match bits" << indent);
    // The pair below consists of the IXBar byte and its associated
    // mask extracted from the @hash_mask() annotation.  When the
    // annotation is not specified, all bits are considered by
    // setting the mask to byte.bit_use.
    //
    // Masking with @hash_mask() is currently unimplemented for Flatrock.
    // The byte.bit_use is always used for the mask.
    safe_vector<std::pair<IXBar::Use::Byte, bitvec>> potential_ghost;

    for (const auto& byte : single_match) {
        potential_ghost.push_back({byte, byte.bit_use});
    }

    if (ghost_bits_count > 0)
        choose_ghost_bits(potential_ghost);

    std::set<int> search_buses;

    for (const auto& [byte, hash_mask] : potential_ghost) {
        search_buses.insert(byte.search_bus);
        match_bytes.emplace_back(byte, byte.bit_use);
    }

    for (auto sb : search_buses) {
        BUG_CHECK(std::count(search_bus_per_width.begin(), search_bus_per_width.end(), sb) > 0,
                  "Byte on search bus %d appears as a match byte when no search bus is "
                  "provided on match", sb);
    }

    for (const auto& info : ghost_bytes) {
        LOG6("\t\tGhost " << info.byte);
        use->ghost_bits[info.byte] = info.bit_use;
    }
}

/*************************************************************************************************
Flatrock Action Format For LAMB's
- Entry constituents
  - Match bits must be aligned to the container in input xbar
  - Immediate must be byte aligned, they are byte rotated
    (0-16 & 16 byte mask which enables / disables each byte) for extraction (without a shift)
  - Next bits can be present anywhere within the entry
  - Action bits can be present anywhere within the entry(?)
- Entries and Sets
  - Entries cannot be a wide match and span multiple words (BPH & STM only)
  - Each entry is grouped in the following order
    [ Match bits - Immediate bits - (Next Table Bits / Action bits / Indirect Pointers / Valid Bits in any order) ]
    This order can be modified once we gain more understanding of what HW allows
  - 1 or more entries (max 4) can be grouped into sets
  - 1 or more sets (power of 2 - 1,2,4,8,16,32,64,128) can be present in a 128 bit lamb / STM word
  - In a word multiple sets are accessed as sub words based on index bits
  - How are index bits alloted? In the hash function (first n bits for 2^n subwords)
- For a direct lookup
  - No. of entries per set is always 1
  - No. of sets per word can be 1 or more based on packing
  - Subword (set) is used as a single entry
  - No match bits are allocated in the entry
  - May need a valid bit per entry (option to enable?) - Never a miss because direct
- For a cuckoo match
  - No. of entries per set is more than 1
  - No. of sets per word can be 1 or more based on packing
  - Subword (set) is used as multiple entries
  - Match bits which are non ghosted are allocated
  - Need a valid bit per entry (Use disable_versioning to disable valid bit)
*************************************************************************************************/
bool TableFormat::allocate_sram_match() {
    Log::TempIndent indent;
    LOG5("Allocating SRAM Match" << indent);
    BUG_CHECK(overhead_groups_per_RAM.size() == 1,
        "Cannot allocate wide RAMS in Flatrock. Invalid size %1%",
        overhead_groups_per_RAM.size());

    auto &layout = layout_option.layout;
    for (int group = 0; group < layout_option.way.match_groups; group++)
        use->match_groups[group].clear_match();

    match_bytes.clear();
    ghost_bytes.clear();
    std::fill(full_match_groups_per_RAM.begin(), full_match_groups_per_RAM.end(), 0);

    use->ghost_bits.clear();
    match_byte_use.clear();

    // Set ghost bits count
    ghost_bits_count += layout.get_subword_bits();
    classify_match_bits();

    return allocate_overhead(!layout.is_lamb_direct());
}

bool TableFormat::allocate_overhead(bool alloc_match) {
    Log::TempIndent indent;
    LOG5("Allocate overhead with match(" << (alloc_match ? "Y" : "N") << ")" << indent);
    auto &layout = layout_option.layout;
    int total_groups = layout_option.way.match_groups;
    // Ternary Indirection table only need a valid overhead format for a single entry
    if (layout_option.layout.ternary)
        total_groups = 1;
    else if (layout.is_lamb_direct())
        total_groups = layout.sets_per_word;

    int per_group_width = 0;
    int group = 0;
    auto allocate_overhead_bits = [&](const type_t t, const int align = 0) {
        int alloc_bits = bits_necessary(t);
        if (alloc_bits > 0) {
            int start = total_use.max().index() + 1;
            if ((align > 1) && (start % align))
                start = ((start / align) + 1) * align;
            bitvec alloc_mask(start, alloc_bits);
            use->match_groups[group].mask[t] |= alloc_mask;
            total_use |= alloc_mask;
        }
    };

    while ((per_group_width * (group + 1) <= SINGLE_RAM_BITS)
            && group < total_groups) {
        // Pad to next group start
        if (per_group_width > 0) {
            auto pad_range = ((per_group_width * group) - 1) - total_use.max().index();
            total_use.setrange(total_use.max().index() + 1, pad_range);
        }
        // Dont allocate match bits overhead for direct lookup
        if (alloc_match)
            if (!allocate_match_with_algorithm(group)) return false;
        allocate_overhead_bits(VALID);
        allocate_overhead_bits(IMMEDIATE);
        allocate_overhead_bits(NEXT);
        allocate_overhead_bits(ACTION);

        per_group_width = (per_group_width == 0) ?
            (1ULL << (ceil_log2(total_use.max().index() + 1))) : per_group_width;

        group++;
    }
    LOG3("Allocating for total groups: " << total_groups << ", allocated: " << group <<
         ", per_group_width: " << per_group_width);
    if (group == total_groups) return true;
    return false;
}

/** Pull out all bytes that coordinate to a particular search bus
 */
void TableFormat::find_bytes_to_allocate(int /* width_sect */, safe_vector<ByteInfo> &unalloced) {
    Log::TempIndent indent;
    LOG5("Find bytes to allocate" << indent);

    // FIXME
    // Flatrock needs these ordered based on how they are in the input_xbar -- so sorting
    // by size (as tofino does) is bad.  Do we need to reorder to get the word_xbar match
    // first, followed by byte_xbar?  Do we need to ensure they're densely packed on the
    // ixbar or insert gaps?  Not clear what exactly is required here.
    //
    // For now we attempt to order word_xbar match first followed by byte_xbar The word containers
    // go on the word xbar while half word and byte containers go on the byte xbar. This may not
    // work for all cases and this code may need to be revised to identify and reorder accordingly.
    // Inefficient ordering will limit packing options while allocating match and overhead.
    for (const auto& info : match_bytes) {
        if (info.byte.loc.group == IXBar::Loc::WORD) {
            LOG6("Add to Unalloced Match : " << info);
            unalloced.push_back(info);
        }
    }
    for (const auto& info : match_bytes) {
        if (info.byte.loc.group == IXBar::Loc::BYTE) {
            LOG6("Add to Unalloced Match : " << info);
            unalloced.push_back(info);
        }
    }
    LOG5("Unalloced bytes: " << unalloced);
}

bool TableFormat::analyze_layout_option() {
    // FIXME: In total needs some information variable passed about ghosting
    LOG2("  Layout option { pack : " << layout_option.way.match_groups << ", width : "
         << layout_option.way.width << ", entries: " << layout_option.entries << " }");

    // FIXME -- can't do wide layouts in cuckoo (revisit for BPH)
    if (layout_option.way.width > 1) return false;

    // If table has @dynamic_table_key_masks pragma, the driver expects all bits
    // to be available in the table pack format, so we disable ghosting
    if (!tbl->dynamic_key_masks &&
        !layout_option.layout.proxy_hash && layout_option.entries > 0) {
        int min_way_size = *std::min_element(layout_option.way_sizes.begin(),
                                             layout_option.way_sizes.end());
        ghost_bits_count = layout_option.layout.get_ram_ghost_bits()
                            + floor_log2(min_way_size);
    }

    use->only_one_result_bus = layout_option.layout.atcam;

    // Initialize all information
    overhead_groups_per_RAM.resize(layout_option.way.width, 0);
    full_match_groups_per_RAM.resize(layout_option.way.width, 0);
    shared_groups_per_RAM.resize(layout_option.way.width, 0);
    search_bus_per_width.resize(layout_option.way.width, 0);
    use->match_group_map.resize(layout_option.way.width);

    for (int i = 0; i < layout_option.way.match_groups; i++) {
        use->match_groups.emplace_back();
    }

    single_match = *(match_ixbar->match_hash()[0]);

    for (size_t i = 0; i < overhead_groups_per_RAM.size(); i++) {
        bool result_bus_needed = overhead_groups_per_RAM[i] > 0;
        use->result_bus_needed.push_back(result_bus_needed);
    }
    LOG3("  Search buses per word " << search_bus_per_width);
    LOG3("  Overhead groups per word " << overhead_groups_per_RAM);

    // Unsure if more code will be required here in the future
    return true;
}

void TableFormat::choose_ghost_bits(
            safe_vector<std::pair<IXBar::Use::Byte, bitvec>> &potential_ghost) {
    int ghost_bits_allocated = 0;
    while (ghost_bits_allocated < ghost_bits_count) {
        int diff = ghost_bits_count - ghost_bits_allocated;
        auto it = potential_ghost.begin();
        if (it == potential_ghost.end())
            break;
        bitvec masked_bit_use = it->first.bit_use & it->second;
        if (diff >= masked_bit_use.popcount()) {
            if (masked_bit_use.popcount())
                ghost_bytes.emplace_back(it->first, masked_bit_use);
            ghost_bits_allocated += masked_bit_use.popcount();
            bitvec match_bits = it->first.bit_use - masked_bit_use;
            if (match_bits.popcount())
                match_bytes.emplace_back(it->first, match_bits);
        } else {
            bitvec ghosted_bits;
            int start = masked_bit_use.ffs();
            int split_bit = -1;
            do {
                int end = masked_bit_use.ffz(start);
                if (end - start + ghosted_bits.popcount() < diff) {
                    ghosted_bits.setrange(start, end - start);
                } else {
                    split_bit = start + (diff - ghosted_bits.popcount()) - 1;
                    ghosted_bits.setrange(start, split_bit - start + 1);
                }
                start = masked_bit_use.ffs(end);
            } while (start >= 0);
            BUG_CHECK(split_bit >= 0, "Could not correctly split a byte into a ghosted and "
                      "match section");
            bitvec match_bits = masked_bit_use - ghosted_bits;
            if (ghosted_bits.popcount())
                ghost_bytes.emplace_back(it->first, ghosted_bits);
            ghost_bits_allocated += ghosted_bits.popcount();
            match_bytes.emplace_back(it->first, match_bits);
        }
        it = potential_ghost.erase(it);
    }
}

}
