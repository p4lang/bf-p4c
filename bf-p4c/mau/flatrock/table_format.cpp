#include "bf-p4c/mau/flatrock/table_format.h"
#include "lib/gmputil.h"

namespace Flatrock {

bool TableFormat::allocate_match_with_algorithm(int group) {
    for (int width_sect = 0; width_sect < layout_option.way.width; width_sect++) {
        allocate_full_fits(width_sect, group);
    }

    // Determine if everything is fully allocated
    safe_vector<int> search_bus_alloc(match_ixbar->search_buses_single(), 0);
    for (int width_sect = 0; width_sect < layout_option.way.width; width_sect++) {
        int search_bus = search_bus_per_width[width_sect];
        if (search_bus < 0)
            continue;
        search_bus_alloc[search_bus] += full_match_groups_per_RAM[width_sect];
    }
    return true;
}

bool TableFormat::allocate_match_byte(const ByteInfo &info, safe_vector<ByteInfo> &alloced,
    int width_sect, bitvec &byte_attempt, bitvec &bit_attempt) {
    // Need to increment by entry size
    // Entry size = 1/2 1/4 of a set
    // Set size 1, 2, 4, 8, 16, 32, 64, 128 (sets per word)
    // Set enable 4 way lookup always
    // for (int i = 0; i < SINGLE_RAM_BYTES; i+=((SINGLE_RAM_BITS/MAX_GROUPS_PER_LAMB)/8))
    for (int i = 0; i < SINGLE_RAM_BYTES; i++) {
       if (initialize_byte(i, width_sect, info, alloced, byte_attempt, bit_attempt))
           return true;
    }
    return false;
}

void TableFormat::classify_match_bits() {
    safe_vector<IXBar::Use::Byte> potential_ghost;

    for (const auto& byte : single_match) {
        potential_ghost.push_back(byte);
    }

    if (ghost_bits_count > 0)
        choose_ghost_bits(potential_ghost);

    std::set<int> search_buses;

    for (const auto& byte : potential_ghost) {
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
    BUG_CHECK(overhead_groups_per_RAM.size() == 1,
        "Cannot allocate wide RAMS in Flatrock. Invalid size %1%",
        overhead_groups_per_RAM.size());

    auto &layout = layout_option.layout;
    auto total_groups = layout_option.way.match_groups;
    for (auto group = 0; group < layout_option.way.match_groups; group++) {
        use->match_groups[group].clear_match();
    }
    if (layout.is_lamb_direct())
        total_groups = layout.sets_per_word;

    match_bytes.clear();
    ghost_bytes.clear();
    std::fill(full_match_groups_per_RAM.begin(), full_match_groups_per_RAM.end(), 0);

    use->ghost_bits.clear();
    match_byte_use.clear();

    // Set ghost bits count
    ghost_bits_count += layout.get_subword_bits();
    classify_match_bits();

    int per_group_width = 0;
    int group = 0;
    auto allocate_overhead_bits = [&](const type_t t, const int align = 0) {
        int alloc_bits = bits_necessary(t);
        if (alloc_bits > 0) {
            auto start = total_use.max().index() + 1;
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
        if (!layout.is_lamb_direct())
            if (!allocate_match_with_algorithm(group)) return false;
        allocate_overhead_bits(VALID);
        allocate_overhead_bits(IMMEDIATE);
        allocate_overhead_bits(NEXT);
        allocate_overhead_bits(ACTION);

        per_group_width = (per_group_width == 0) ?
            (1ULL << (ceil_log2(total_use.max().index() + 1))) : per_group_width;

        group++;
    }

    LOG3("Allocating for total groups: " << total_groups << ", allocated: " << group
            << ", per_group_width: " << per_group_width);
    if (group == total_groups) return true;
    return false;
}

/** Pull out all bytes that coordinate to a particular search bus
 */
void TableFormat::find_bytes_to_allocate(int width_sect, safe_vector<ByteInfo> &unalloced) {
    int search_bus = search_bus_per_width[width_sect];
    for (const auto& info : match_bytes) {
        if (info.byte.search_bus != search_bus)
            continue;
        unalloced.push_back(info);
    }
    // FIXME
    // flatrock needs these ordered based on how they are in the input_xbar -- so sorting
    // by size (as tofino does) is bad.  Do we need to reorder to get the word_xbar match
    // first, followed by byte_xbar?  Do we need to ensure they're densely packed on the
    // ixbar or insert gaps?  Not clear what exactly is required here.
}

}
