#include "table_format.h"
#include "memories.h"

/**
 * For ATCAM specifically, only one result bus is alloweed per match.  This is due to the
 * priority ranking.  Each RAM can at most hold 5 entries, and those entries, numbered 0-4
 * are ranked in a priority.
 *
 * Because multiple entries could potentially match within an ATCAM table, (unlike exact or
 * proxy hash), the entry with the highest priority (i.e. 4 > 3) will win.
 *
 * Other rules apply to these priority structures.  Entries 0 and 1 are the only entries
 * allowed to be shared across multiple RAMs.  This is described in uArch section 6.4.3.1
 * Exact Match Physical Row Result Generation, and by the register match.merge.col.hitmap_ouptut.
 *
 * Thus in order to maintain sanity, the entries published in the table format are numbered
 * 0 .. highest entries <= 4.  The numbered entries are the priority ranking of these entries,
 * specifically only for ATCAM.
 *
 * When the ATCAM table has overhead, the result bus is easy to determine.  However, when
 * there is no overhead, the result bus is more difficult and must be wherever any entry
 * 2-4 resides.
 *
 * This matches bf-asm function 
 */
bitvec TableFormat::Use::no_overhead_atcam_result_bus_words() const {
    bitvec rv;
    int rb_word = -1;
    int shared_across_boundaries = 0;
    BUG_CHECK(!match_groups.empty(), "ATCAM table has no match data?");
    for (auto it = match_groups.rbegin(); it != match_groups.rend(); it++) {
        bitvec match_mask = it->match_bit_mask();
        int min_word = match_mask.min().index() / SINGLE_RAM_BITS;
        int max_word = match_mask.max().index() / SINGLE_RAM_BITS;
        if (rb_word < 0)
            rb_word = min_word;
        if (min_word != max_word)
            shared_across_boundaries++;
        else if (rb_word != min_word)
            shared_across_boundaries++;
    }
    BUG_CHECK(shared_across_boundaries <= MAX_SHARED_GROUPS, "ATCAM table has illegitimate "
        "format.  All words must chain to the same result bus");
    rv.setbit(rb_word);
    return rv;
}

/**
 * Result buses are required by SRAM based tables to get data from the RAM to match central.
 * This includes both overhead data, and vpn based data.  The result bus itself is an 83 bit
 * bus, 64 bits for bits 0-63 of the RAM line that matches, and 19 bits for a direct address
 * location.
 *
 * The rules of result bus requirements for each RAM word (an 128 bit section of RAM)
 *     1. If a word has overhead of any entry, then a result bus is required for that word
 *     2. If no entries have overhead, then any portion of each entries match must have
 *        a result bus.  If an entry is within a single RAM section, then this RAM requires
 *        a result bus.  If an entry is split across multiple RAMs, then one of those words
 *        requires a result bus
 *
 * This matches the considerations in bf-asm/sram_match/verify_format and
 * bf-asm/sram_match/no_overhead_determine_result_bus_words
 */
bitvec TableFormat::Use::result_bus_words() const {
    bitvec rv;
    bitvec overhead_mask;
    for (auto match_group : match_groups) {
        overhead_mask |= match_group.overhead_mask();
    }

    if (!overhead_mask.empty()) {
        for (int i = 0; i <= overhead_mask.max().index(); i+= SINGLE_RAM_BITS) {
            int word = i / SINGLE_RAM_BITS;
            if (!overhead_mask.getslice(i, SINGLE_RAM_BITS).empty())
                rv.setbit(word);
        }

        if (only_one_result_bus)
            BUG_CHECK(rv.popcount() == 1, "An ATCAM table can at most only have one result bus");
        return rv;
    }

    if (only_one_result_bus) {
        return no_overhead_atcam_result_bus_words();
    }

    for (auto match_group : match_groups) {
        bitvec match_mask = match_group.match_bit_mask();
        int min_word = match_mask.min().index() / SINGLE_RAM_BITS;
        int max_word = match_mask.max().index() / SINGLE_RAM_BITS;

        if (min_word != max_word)
            continue;
        rv.setbit(min_word);
    }

    // Try to reuse any result bus for a RAM that has been previously allocated
    for (auto match_group : match_groups) {
        bitvec match_mask = match_group.match_bit_mask();
        int min_word = match_mask.min().index() / SINGLE_RAM_BITS;
        int max_word = match_mask.max().index() / SINGLE_RAM_BITS;
        if (min_word == max_word)
            continue;
        bool group_has_result_bus = false;
        for (int word = min_word; word <= max_word; word++) {
            if (match_mask.getslice(word * SINGLE_RAM_BITS, SINGLE_RAM_BITS).empty())
                continue;
            if (rv.getbit(word)) {
                group_has_result_bus = true;
                break;
            }
        }

        if (group_has_result_bus)
            continue;
        rv.setbit(min_word);
    }
    return rv;
}

/** The goal of this code is to determine how to initial divide up the match data and the
 *  overhead, and which RAM correspond to which input xbar group.
 *
 *  If you look at section 6.2.3 Exact Match Row Vertical/Horizontal (VH) Xbars, one can
 *  the inputs to an individual RAM line.  There are two search buses per line, which
 *  themselves are 128 bits wide, the same as an individual RAM row.  Each search bus can
 *  select from one of 8 crossbar groups that come from the input crossbar.  Thus, the number
 *  of input xbars groups needed is the number of search buses needed.  (This is not entirely
 *  true, as in ATCAM a single xbar bytes is actually in multiple places on the RAM.  This
 *  information is tracked through the search_bus field in each IXBar::Byte)
 *
 *  Thus the algorithm is divided into two types, skinny and wide.  Skinny means that only
 *  one search bus is required, while wide means multiple search buses are required.
 *
 *  The analyze option assigns both a number of overhead entries per RAM as well as
 *  a search bus assigned to each width.  Thus only bytes with that search_bus value can
 *  be found at that particular location.
 */
bool TableFormat::analyze_layout_option() {
    // FIXME: In total needs some information variable passed about ghosting
    LOG2("  Layout option { pack : " << layout_option.way.match_groups << ", width : "
         << layout_option.way.width << ", entries: " << layout_option.entries << " }");

    // If table has @dynamic_table_key_masks pragma, the driver expects all bits
    // to be available in the table pack format, so we disable ghosting
    if (!tbl->layout.atcam && !tbl->dynamic_key_masks && !tbl->layout.proxy_hash &&
        layout_option.entries > 0) {
        int min_way_size = *std::min_element(layout_option.way_sizes.begin(),
                                             layout_option.way_sizes.end());
        ghost_bits_count = RAM_GHOST_BITS + floor_log2(min_way_size);
    }

    use->only_one_result_bus = tbl->layout.atcam;

    // Initialize all information
    overhead_groups_per_RAM.resize(layout_option.way.width, 0);
    full_match_groups_per_RAM.resize(layout_option.way.width, 0);
    shared_groups_per_RAM.resize(layout_option.way.width, 0);
    search_bus_per_width.resize(layout_option.way.width, 0);

    for (int i = 0; i < layout_option.way.match_groups; i++) {
        use->match_groups.emplace_back();
    }

    int per_RAM = layout_option.way.match_groups / layout_option.way.width;
    if (tbl->layout.proxy_hash) {
        analyze_proxy_hash_option(per_RAM);
        return true;
    }

    auto total_info = match_ixbar.bits_per_search_bus();

    for (auto gi : total_info[0].all_group_info)
         LOG4("   Group info " << gi);

    single_match = *(match_ixbar.match_hash()[0]);
    if (!is_match_entry_wide()) {
        bool rv = analyze_skinny_layout_option(per_RAM, total_info[0].all_group_info);
        if (!rv) return false;
    } else {
        bool rv = analyze_wide_layout_option(total_info[0].all_group_info);
        if (!rv) return false;
    }


    for (auto &hi : total_info) {
        safe_vector<int> ixbar_groups;
        std::sort(hi.all_group_info.begin(), hi.all_group_info.end(),
            [=](const IXBar::Use::GroupInfo &a, IXBar::Use::GroupInfo &b) {
            return a.search_bus < b.search_bus;
        });

        for (auto sb : search_bus_per_width) {
            if (sb >= 0)
                ixbar_groups.push_back(hi.all_group_info[sb].ixbar_group);
            else
                ixbar_groups.push_back(-1);
        }
        use->ixbar_group_per_width[hi.hash_group] = ixbar_groups;
    }

    for (size_t i = 0; i < overhead_groups_per_RAM.size(); i++) {
        bool result_bus_needed = overhead_groups_per_RAM[i] > 0;
        use->result_bus_needed.push_back(result_bus_needed);
    }
    LOG3("  Search buses per word " << search_bus_per_width);
    LOG3("  Overhead groups per word " << overhead_groups_per_RAM);

    // Unsure if more code will be required here in the future
    return true;
}

/**
 * Rather than the bytes coming from match data, the bytes have to be built from the
 * hash matrix.  Thus the bytes are built from the proxy_hash_key_use, on a byte by byte
 * basis.
 */
void TableFormat::analyze_proxy_hash_option(int per_RAM) {
    auto &ph = proxy_hash_ixbar.proxy_hash_key_use;
    BUG_CHECK(ph.allocated, "%s: Proxy Hash Table %s does not have an allocation for a proxy "
              "hash key", tbl->srcInfo, tbl->name);

    use->proxy_hash_group = ph.group;
    for (int i = 0; i < IXBar::HASH_MATRIX_SIZE; i += 8) {
        auto bv = ph.hash_bits.getslice(i, 8);
        if (bv.empty())
            continue;
        IXBar::Use::Byte b("proxy_hash", i);
        b.bit_use = bv;
        b.proxy_hash = true;
        b.search_bus = 0;
        single_match.push_back(b);
    }

    int total = 0;
    for (int i = 0; i < layout_option.way.width; i++) {
        overhead_groups_per_RAM[i] = per_RAM;
        total += per_RAM;
    }

    int index = 0;
    while (total < layout_option.way.match_groups) {
        overhead_groups_per_RAM[index]++;
        index++;
        total++;
    }

    for (int i = 0; i < layout_option.way.width; i++) {
        search_bus_per_width[i] = 0;
    }
}

/* Specifically for the allocation of groups that only require one RAM.  If it requires
   multiple match groups, then balance these match groups and corresponding overhead */
bool TableFormat::analyze_skinny_layout_option(int per_RAM,
        safe_vector<IXBar::Use::GroupInfo> &sizes) {
    // This checks to see if the algorithm  can possibly ghost off any extra search buses
    // to leave at most one search bus.  If that's the case, then choose_ghost_bits will
    // prioritize those search buses
    skinny = true;
    if (match_ixbar.search_buses_single() > 1) {
        std::sort(sizes.begin(), sizes.end(),
            [](const IXBar::Use::GroupInfo &a, const IXBar::Use::GroupInfo &b) {
            int t;
            if ((t = a.bits - b.bits) != 0) return a.bits < b.bits;
            return a.search_bus < b.search_bus;
        });

        int ghostable_search_buses = 0;
        int bits_seen = 0;
        for (auto group_info : sizes) {
            if (bits_seen + group_info.bits <= ghost_bits_count) {
                ghostable_search_buses++;
                fully_ghosted_search_buses.insert(group_info.search_bus);
                bits_seen += group_info.bits;
            } else {
                break;
            }
        }
        if (match_ixbar.search_buses_single() - ghostable_search_buses > 1)
            return false;
    }

    if (tbl->layout.atcam) {
        // ATCAM tables can only have one priority branch
        overhead_groups_per_RAM[0] = layout_option.way.match_groups;
    } else {
        // Evenly assign overhead information per RAM.  In the case of single sized RAMs, one
        // can later share match groups.
        int total = 0;
        for (int i = 0; i < layout_option.way.width; i++) {
            overhead_groups_per_RAM[i] = per_RAM;
            total += per_RAM;
        }

        int index = 0;
        while (total < layout_option.way.match_groups) {
            overhead_groups_per_RAM[index]++;
            index++;
            total++;
        }
    }

    // Every single RAM is assigned the same search bus, as there is only one
    for (int i = 0; i < layout_option.way.width; i++) {
        search_bus_per_width[i] = sizes.back().search_bus;
    }

    for (auto group_info : sizes) {
        ghost_bit_buses.push_back(group_info.search_bus);
    }

    return true;
}

/* Specifically for the allocation of groups that require multiple RAMs.  Determine where
   the overhead has to be, and which RAMs contain the particular match groups */
bool TableFormat::analyze_wide_layout_option(safe_vector<IXBar::Use::GroupInfo> &sizes) {
    skinny = false;
    size_t RAM_per = (layout_option.way.width + layout_option.way.match_groups - 1)
                     / layout_option.way.match_groups;
    if (layout_option.way.width % layout_option.way.match_groups == 0
        && layout_option.way.match_groups != 1) {
        ::warning("Format for table %s to be %d entries and %d width, when that allocation "
                  "could easily be split.", tbl->name, layout_option.way.match_groups,
                  layout_option.way.width);
    }
    if (size_t(match_ixbar.search_buses_single()) > RAM_per) {
        return false;  // FIXME: Again, can potentially be saved by ghosting off certain bits
    }

    // Whichever one has the least amount of bits will be the group in which the overhead
    // will be stored.  This is because we can ghost the most bits off in that section
    std::sort(sizes.begin(), sizes.end(),
        [=](const IXBar::Use::GroupInfo &a, const IXBar::Use::GroupInfo &b) {
        int t;
        if ((t = a.bits - b.bits) != 0) return a.bits < b.bits;
        return a.search_bus < b.search_bus;
    });

    bool search_bus_on_overhead = true;
    // full_RAMs are the number of RAMs that are dedicated to a non overhead RAMs
    int full_RAMs = layout_option.way.match_groups * (sizes.size() - 1);
    // Overhead RAMs are the number of RAMs that need to be dedicated to holding the overhead
    int overhead_RAMs = layout_option.way.width - full_RAMs;
    if (overhead_RAMs > layout_option.way.match_groups) {
        overhead_RAMs = layout_option.way.match_groups;
    }

    if (layout_option.way.width - overhead_RAMs > full_RAMs) {
        search_bus_on_overhead = false;
    }

    if (overhead_RAMs * MAX_SHARED_GROUPS < layout_option.way.match_groups)
        return false;

    if (overhead_RAMs > 1 && tbl->layout.atcam)
        return false;

    BUG_CHECK(overhead_RAMs <= layout_option.way.match_groups, "Allocation for %s has %d RAMs for "
              "overhead allocation, but it only requires %d.  Issue in width calculation.",
              tbl->name, overhead_RAMs, layout_option.way.match_groups);

    // Determine where the overhead groups go.  Evenly distribute the overhead.  At most, only
    // 2 sections of overhead can be within a wide match, as that is the maximum sharing
    for (auto group_info : sizes) {
        ghost_bit_buses.push_back(group_info.search_bus);
    }

    int total = 0;
    for (int i = 0; i < overhead_RAMs; i++) {
        overhead_groups_per_RAM[i] = 1;
        if (search_bus_on_overhead)
            search_bus_per_width[i] = sizes[0].search_bus;
        else
            search_bus_per_width[i] = -1;
        total++;
    }

    int index = 0;
    while (total < layout_option.way.match_groups) {
        BUG_CHECK(index < overhead_RAMs, "Overhead check should fail earlier");
        overhead_groups_per_RAM[index]++;
        index++;
        total++;
    }

    // Assign a search bus to the non overhead groups
    auto it = sizes.begin();
    if (search_bus_on_overhead)
        it++;

    int match_groups_set = 0;
    for (int i = overhead_RAMs; i < layout_option.way.width; i++) {
        if (it == sizes.end()) {
            match_groups_set = -1;
            LOG4("  Layout option wider than the number of ixbar groups");
        } else if (match_groups_set == layout_option.way.match_groups) {
            it++;
            match_groups_set = 0;
        }

        int search_bus = 0;
        if (it != sizes.end()) {
            search_bus = it->search_bus;
        } else {
            search_bus = -1;
            LOG4("   WARNING: Allocating an extra RAM with neither overhead nor match");
        }

        search_bus_per_width[i] = search_bus;
        match_groups_set++;
    }


    return true;
}

/** The algorithm find_format is to determine how to best pack the RAMs of match tables.  *  For any table using SRAMs only (i.e. exact match/atcam), this means determining how
 *  the RAM line is filled.  For tables using the TCAMs, (i.e. ternary), this is specifically
 *  for the ternary indirect packing.
 *
 *  The RAM is packed with two classes of information, match data and overhead.  Match data
 *  is anything that is to be directly compared with packet data.  Overhead is everything else.
 *  Overhead consists of anything that could go to match central as well as version bits.
 *
 *  When an entry hits within a table, the lower 64 bits of the RAM (or in the case of a wide
 *  match, one of the RAMs), are sent to match central for further processing.  Thus any
 *  information that is needed by match central for later processing is considered overhead,
 *  and must fit within the lower 64 bits.
 *
 *  The exception to the previous paragraph is what we call version bits.  These are bits
 *  that are matched not as part of the packet, but as a way to ensure that an entry is valid,
 *  and that all data is atomically written into the RAM.  Version bits are then appended
 *  on before the match, and thus can be anywhere within the RAM line.
 *
 *  Data from the packet comes in through the input xbar.  The algorithm is as follows.
 *      1. Analyze the estimate and calculate initial set up information based on the input
 *         xbar allocation and the estimate.
 *      2. Allocate all overhead that is not version bits
 *      3. Allocate all match and version bits.
 *      4. Verify that the algorithm works.
 *
 *  The constraints for these individual pieces will be described above the function which
 *  are part of the algorithm.
 *
 *  FIXME: Noted weaknesses in the algorithm to address in the future:
 *     1. Ghost bits could be worked in with overhead, so that holes in overhead could
 *        be filled with match data.  Glass currently does not do this, so no support
 *        necessary yet.
 */
bool TableFormat::find_format(Use *u) {
    use = u;
    LOG1("Find format for table " << tbl->name);
    LOG2("  Layout option action { adt_bytes: " << layout_option.layout.action_data_bytes_in_table
         << ", immediate_bits: " << layout_option.layout.immediate_bits << " }");
    if (layout_option.layout.ternary) {
        LOG3("Ternary table?");
        overhead_groups_per_RAM.push_back(1);
        use->match_groups.emplace_back();
        if (!allocate_all_ternary_match())
            return false;
        if (!allocate_overhead())
            return false;
        return true;
    }

    if (layout_option.layout.no_match_miss_path()) {
        overhead_groups_per_RAM.push_back(1);
        LOG3("No match miss");
        use->match_groups.emplace_back();
        if (!allocate_overhead())
            return false;
        return true;
    } else if (layout_option.layout.no_match_hit_path()) {
        overhead_groups_per_RAM.push_back(1);
        LOG3("No match hit");
        use->match_groups.emplace_back();
        if (!allocate_all_instr_selection())
            return false;
        if (!allocate_all_indirect_ptrs())
            return false;
        return true;
    }


    if (!analyze_layout_option())
        return false;
    if (!allocate_overhead()) {
        return false;
    }

    if (!allocate_match())
        return false;
    LOG3("Match and Version");
    if (tbl->layout.atcam) {
        redistribute_entry_priority();
    }
    redistribute_next_table();
    verify();
    LOG3("Table format is successful");
    return true;
}

/** Allocate all overhead data that could head to match central.  This includes the following
 *  information, if needed:
 *    1. Next table, if the table has multiple next table choices and cannot be specified by
 *       the action alone
 *    2. Instruction selection, the bits to indicate which action is to be run.
 *    3. Indirect Pointers: addresses for indirect tables, such as counters, meters, action,
 *       etc.  These needs are specified by the program
 *    4. Immediate: Action data that is stored with the match rather than in a separate action
 *       data table.
 *
 *  The current algorithm just packs as close to the bottom as it can, and does not leave
 *  any holes to put match data in.  This could be optimized to pack match data.
 */
bool TableFormat::allocate_overhead() {
    if (!allocate_next_table())
        return false;
    LOG3("Next Table");
    if (!allocate_selector_length())
        return false;
    LOG3("Selector Length");
    if (!allocate_all_instr_selection())
        return false;
    LOG3("Instruction Selection");
    if (!allocate_all_indirect_ptrs())
        return false;
    LOG3("Indirect Pointers");
    if (!allocate_all_immediate())
        return false;
    LOG3("Immediate");
    return true;
}

int TableFormat::hit_actions() {
    int extra_action_needed = gw_linked ? 1 : 0;
    return tbl->hit_actions() + extra_action_needed;
}

/* Bits for selecting the next table from an action chain table must be in the lower part
   of the overhead.  This is specifically to handle this corner case.  If this is run,
   then instruction selection does not necessarily need to be run.  This information has
   to be placed very specifically, according to section 6.4.1.3.2 Next Table Bits */

/** This algorithm is to allocate next table bits in the match overhead when necessary
 *  A table has multiple potential next tables for the following reasons:
 *     - A gateway has a true or false branch
 *     - The table has different behavior on hit and miss
 *     - Based on which actions ran, the table can choose different next pathways
 *
 *  The first two pathways do not require next table information stored in match overhead,
 *  as the next table is stored elsewhere.  Only when the next table is chained from different
 *  actions would the next table have to come from match overhead.
 *
 *  Next table bits, as 12 Stages * 16 = 196 next tables, may have to be up to
 *  ceil(log2(196)) = 8 bits.  On JBay, 20 stages actually leads to 9 bits, though only
 *  8 bits are able to be pulled in the next table extractor.  In order to save bits,
 *  match central has an 8 entry table called next_table_map_data per each logical table,
 *  described in section 6.4.3.3 Next Table Processing.  Thus if <= 8 next tables are not
 *  needed, one just needs to save the ceil_log2(next tables), as this map_data table can
 *  translate up to 3 bit address into an 8 bit next table.
 *
 *  The placement of next table bits are described in section 6.4.1.3.2 Next Table Bits of uArch.
 *  Up to 5 overhead entries exist for exact match.  The next tables bits must be within bits
 *  0 through (Entry # + 1) * 8 - 1, i.e. Entry 0 can be within bits 0-7, and Entry 4 can be
 *  within bits 0-39.  Thus when placing next tables within the entries, the algorithm always
 *  places next table first.
 *
 *  Brig takes advantage of an optimization.  Similar to next tables, instruction memory has
 *  a map_data table similar to next table.  If the number of instructions is under 8, then the
 *  same up to 3 bit pointer can be used for both the instruction selection and next table.  Only
 *  when this optimization cannot be used is this function called.
 */
bool TableFormat::allocate_next_table() {
    if (!tbl->action_chain() || hit_actions() <= NEXT_MAP_TABLE_ENTRIES) {
        return true;
    }

    int next_tables = tbl->action_next_paths();
    // If no default path is provided, then the default next table has to be included
    if (!tbl->has_default_path())
        next_tables++;

    int next_table_bits;
    if (next_tables <= NEXT_MAP_TABLE_ENTRIES) {
        next_table_bits = ceil_log2(next_tables);
    } else {
        next_table_bits = FULL_NEXT_TABLE_BITS;
    }

    int group = 0;
    for (size_t i = 0; i < overhead_groups_per_RAM.size(); i++) {
        for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
            size_t start = total_use.ffz(i * SINGLE_RAM_BITS);
            if (start + next_table_bits >= OVERHEAD_BITS + i * SINGLE_RAM_BITS)
                return false;
            bitvec ptr_mask(start, next_table_bits);
            use->match_groups[group].mask[NEXT] |= ptr_mask;
            total_use |= ptr_mask;
            group++;
        }
    }
    return true;
}

/**
 * Data-Plane selection works in the following way.
 *
 * Rather than a standard one-to-one mapping between match and action data, a single match entry
 * can have many possible action data entries, and must select one of these entries at runtime.
 * This we will refer to as a pool of action data entries.  Some entries in the pool may
 * be valid, while other may not be.
 *
 * Selection is the process of picking one of these possible action data entries.  The selector
 * holds a pool of single-bit entries, indicate whether that index of the pool is valid or invalid.
 * The input to a selector is a hash calculated from associated PHV fields and constants
 * and the value of this hash will indicate which of these valid entries to choose from.
 *
 * The action data pool has a base address at the beginning of the pool.  The valid index from the
 * selector pool, chosen by the hash, will be the offset into the pool of action data table entries.
 * This index from the selector is mathematically added to the base address in order to find the
 * location in the action data pool that the selector has chosen.
 *
 * Tofino selectors are broken into two sections, the selector ALU and the selector RAM.  The
 * RAM is a pool, with 120 members per RAM line.  The selector ALU takes in as input, a hash
 * from the input xbar as well as a selector RAM line, and will return the index of that RAM line.
 * 120 bits of pool require a 7-bit all 0 section of action data address in which the selector
 * address will OR into.  If the pool size is smaller, say 64 possible members, the selector
 * offset itself will only be 6-bits wide and thus require a 6-bit place to OR the offset into
 *
 * This works if the pool size is at most 120 entries.  If a pool size > 120 entries, then a
 * single RAM line will not suffice.  Thus, there is a second portion that requires a RAM line
 * select.  A second hash is used to determine an individual RAM line out of the possible
 * multiple RAM lines, and this selected RAM line is now considered the pool of 120 entries.
 *
 * The RAM line select works similar to action data address.  The selector pool has a base
 * address, and the calculated RAM line is ORed into another all 0-bit section of that
 * base address.  The number of 0s needed depends on the size of the pool.  This selector
 * RAM line offset also has to be ORed into the action data address as well.
 *
 * Because the pool size can vary by entry, a selector length can be extracted from the entry.
 * The length of the selector is then used as a max size of RAM lines coordinated as a single
 * pool, and a RAM line is chosen between 0 and the max size of the number of RAM lines.
 *
 * The relevant sections in the uArch are:
 *    - 6.2.8.4.7 - Selector RAM Addressing - The addresses that are generated for the selector
 *      and the action address, with the bits ORed in depending on the address
 *    - 6.2.10 - Selector Tables - Everything the compiler needs and then some on selectors.
 *      For wide selectors, sections 6.2.10.4 Large Selector Pools and 6.2.10.5.5 The Hash
 *      Word Selection Block are useful
 *   - 6.4.3.5.3 - Hash Distribution - Details the pathway for the hash mod calculation  
 */

/**
 * The selector length is the parameter used to determine the max size of the RAM lines in the
 * pool.  From this max size, an individual RAM line is chosen.
 *
 * As described in section 6.2.10.5.5 The Hash Word Selection Block, the selector length field
 * is an 8 bit field broken into two parts:
 *
 *    sel_len[4:0] = number of selector words
 *    sel_len[7:5] = selector address shift
 *
 * The calculation is as follows.  The number of possible words ranges from 0-31, which is used
 * the base of a mod operation.  The return of this mod can be shifted up to 5 times, and the bits
 * to the right of the shift are filled in by hash bits.
 *
 * The selector pool is calculated as:
 *
 * RAM_line
 *     = ((hash_value1 % (number_of_selector_words)) << selector_address_shift) | hash_value2
 *
 * where hash_value1 and hash_value2 come from the hash distribution as two portions of a 15 bit
 * hash.  hash_value1 is from bits[9:0] as an input to the mod, and the hash_value2 comes
 * from bits[14:10].  The number of bits used depends of the address shift, i.e.
 *
 *     if (selector_address_shift > 0)
 *     hash_value2 = bits[selector_address_shift-1:0];
 *
 * Thus, if one was to calculate the max selector pool size, it would be the following:
 *     - the max dividend of the mod is 31, meaning the max value of the mod calculation
 *       would be 30
 *     - the max shift is 5, and the thus the max hash_value2 = 2^5 - 1 = 31;
 *     - thus the (max_mod << max_shift) | max hash_value2 = (30 << 5) | 31 = 991
 *     - The pools range from 0-991, meaning a max pool size of 992.
 *
 * The oddity of this comes from the mod operation not being able to return a 31.  This is
 * doubly strange, as a mod by 0 is an impossible operation, and is a return 0 by the hardware.
 *
 * This structure of this calculation also leads to holes in the possible pool sizes.  A pool
 * size of 32 cannot be done by mod value only, as the mod value can at max go to 30 bits.
 * Thus the way this is accomplished is that a mod value of 16 is provided and shifted up one
 * bit leading to the RAM_line_index[4:1] range from 0-15 and RAM_line_index[0:0] = 0-1.
 *
 * However, with this limitation, one cannot come up a way for these bits to have a maximum pool
 * size of 33, because the shifted bits on the bottom are always possible to be 0 or 1, and by
 * guaranteeing a maximum, this requires the lower bit to always be 0.  Thus, one needs
 * to move to the next largest pool.
 *
 * The address formats for the different sizes are described in section 6.2.8.4.7.  These
 * indicate where the hash mod bits and hash shift bits are ORed into the addresses, both
 * for the meter_adr for the selector, and the action_adr for the selectors action data table.
 * It is the drivers responsiblity to write the RAM line addresses with 0s to be ORed into,
 * in order for the addresses not to collide.
 *
 * The 5 bit mod value, if enabled by the hash_value, is always ORed into the address.  This
 * works only if the driver has left space in the selector address and action address of all
 * 0s.  The upper bits of the mod value may also always be known to be zero.  Thus, by using
 * ORs on 0s, the full 5-bit mod can always be input in.
 */

/**
 * The selector length is done through a single extractor through the standard shift mask
 * default pathway.  However, the context JSON requires two fields for the selector length in
 * the pack format, broken into selector_length_shift and selector_length.
 *
 * The choice was to keep the context JSON by having separate fields in the format even though
 * both are extracted by the same extractor.
 *
 * The selector length is at most up to 8 bits, and because the mod operation is timing critical,
 * the length must be at bit 15 or below.  The next table for entry 0 has to go between bits 0-7,
 * so if the table needs both next table and selector length, then the selector length must be
 * in bits 8-15.
 *
 * The selector length has only one extractor per overhead, which is different than all other
 * address types, which have an extractor per entry.  Thus, the entries per RAM line of a table
 * using a programmable selector length is at most 1.  (Possible corner case.  If all entries in
 * an ATCAM partition want to use the same selector length, because they're all in the same RAM
 * row, this constraint goes away).
 */
bool TableFormat::allocate_selector_length() {
    const IR::MAU::Selector *sel = nullptr;
    for (auto ba : tbl->attached) {
        sel = ba->attached->to<IR::MAU::Selector>();
        if (sel != nullptr)
            break;
    }
    if (sel == nullptr)
        return true;
    int sel_len_mod_bits = SelectorModBits(sel);
    int sel_len_shift_bits = SelectorLengthShiftBits(sel);
    if (sel_len_mod_bits == 0 && sel_len_shift_bits == 0)
        return true;
    if (sel_len_shift_bits > 0)
        BUG_CHECK(sel_len_mod_bits == ceil_log2(StageUseEstimate::MAX_MOD),
                  "Errors in the selection mod calculation");
    int group = 0;
    for (size_t i = 0; i < overhead_groups_per_RAM.size(); i++) {
        for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
            size_t len_mod_start = total_use.ffz(i * SINGLE_RAM_BITS);
            if (len_mod_start + sel_len_mod_bits >= SELECTOR_LENGTH_MAX_BIT + i * SINGLE_RAM_BITS)
                return false;
            bitvec mask(len_mod_start, sel_len_mod_bits);
            use->match_groups[group].mask[SEL_LEN_MOD] |= mask;
            total_use |= mask;

            size_t shift_start = mask.max().index() + 1;
            if (shift_start + sel_len_shift_bits >= SELECTOR_LENGTH_MAX_BIT + i * SINGLE_RAM_BITS)
                return false;
            bitvec shift_mask(shift_start, sel_len_shift_bits);
            use->match_groups[group].mask[SEL_LEN_SHIFT] |= shift_mask;
            total_use |= shift_mask;
            group++;
        }
    }
    return true;
}

/* Finds space for an individual indirect pointer.  Bases it on the type.  Total is the
   number of bits needed */
bool TableFormat::allocate_indirect_ptr(int total, type_t type, int group, int RAM) {
    size_t start = total_use.ffz(RAM * SINGLE_RAM_BITS);
    if (start + total > size_t(OVERHEAD_BITS + RAM * SINGLE_RAM_BITS))
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
     const IR::MAU::AttachedMemory *meter_addr_user = nullptr;
     const IR::MAU::AttachedMemory *stats_addr_user = nullptr;

     IR::MAU::PfeLocation update_pfe_loc = tbl->layout.no_match_hit_path() ?
                                           IR::MAU::PfeLocation::GATEWAY_PAYLOAD :
                                           IR::MAU::PfeLocation::OVERHEAD;
     IR::MAU::TypeLocation update_type_loc = tbl->layout.no_match_hit_path() ?
                                             IR::MAU::TypeLocation::GATEWAY_PAYLOAD :
                                             IR::MAU::TypeLocation::OVERHEAD;

     for (auto *ba : tbl->attached) {
         if (ba->attached->is<IR::MAU::StatefulAlu>() && ba->use != IR::MAU::StatefulUse::NO_USE) {
             meter_addr_user = ba->attached;
         } else if (ba->attached->is<IR::MAU::Selector>() || ba->attached->is<IR::MAU::Meter>()) {
             meter_addr_user = ba->attached;
         } else if (ba->attached->is<IR::MAU::Counter>()) {
             stats_addr_user = ba->attached;
         }
     }

     int group = 0;
     for (size_t i = 0; i < overhead_groups_per_RAM.size(); i++) {
         for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
             int total;

             if (layout_option.layout.stats_addr.shifter_enabled > 0) {
                 if ((total = layout_option.layout.stats_addr.address_bits) != 0) {
                     if (!allocate_indirect_ptr(total, COUNTER, group, i))
                         return false;
                 }
                 bool move_to_overhead = gw_linked && !stats_addr_user->direct;

                 if (layout_option.layout.stats_addr.per_flow_enable || move_to_overhead) {
                     if (!allocate_indirect_ptr(1, COUNTER_PFE, group, i))
                         return false;
                     use->stats_pfe_loc = update_pfe_loc;
                 }
             }

             if (layout_option.layout.meter_addr.shifter_enabled > 0) {
                 if ((total = layout_option.layout.meter_addr.address_bits) != 0) {
                     if (!allocate_indirect_ptr(total, METER, group, i))
                         return false;
                 }

                 // FIXME: In general, this is currently used for both the per flow enable portion
                 // and the meter type portion.  The meter type could be reduced if there is only
                 // one meter type for the meter address user (1 stateful instruction or 1 type
                 // of color aware metering, or if the meter type of this logical table is possible
                 // to OR into the others, i.e. STFUL_INSTRUCTION_0
                 bool move_to_overhead = gw_linked &&
                                         !(meter_addr_user->direct ||
                                           meter_addr_user->is<IR::MAU::Selector>());

                 if (layout_option.layout.meter_addr.per_flow_enable || move_to_overhead) {
                     if (!allocate_indirect_ptr(1, METER_PFE, group, i))
                         return false;
                     use->meter_pfe_loc = update_pfe_loc;
                 }

                 if (layout_option.layout.meter_addr.meter_type_bits > 0 || move_to_overhead) {
                     total = 3;
                     if (!allocate_indirect_ptr(total, METER_TYPE, group, i))
                         return false;
                     use->meter_type_loc = update_type_loc;
                 }
             }

             if (layout_option.layout.action_addr.shifter_enabled) {
                 // FIXME: unsure if the defaulting of the Huffman bits happens for indirect
                 // action data addresses, as potentially it shouldn't be if the compiler
                 // was to have different sized action data.  Right now the full bits are
                 // reserved even if the size of the action profile does not warrant it
#if 0
                  const IR::MAU::ActionData *ad = nullptr;
                  for (auto back_at : tbl->attached) {
                      ad = back_at->to<IR::MAU::ActionData>();
                      if (ad != nullptr)
                          break;
                  }
                  BUG_CHECK(ad, "No action data table found with an associated action"
                            "address");
                  // Extra Huffman encoding required in the address, see section 6.2.8.4.3
                  if (ad->size > Memories::SRAM_DEPTH)
                      total += ActionDataHuffmanVPNBits(&layout_option.layout);
#endif
                 total = layout_option.layout.action_addr.address_bits;
                 total += ActionDataHuffmanVPNBits(&layout_option.layout);
                 if (!allocate_indirect_ptr(total, INDIRECT_ACTION, group, i))
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
bool TableFormat::allocate_all_immediate() {
    if (layout_option.layout.immediate_bits == 0)
        return true;
    use->immed_mask = immediate_mask;

    // Allocate the immediate mask for each overhead section
    int group = 0;
    for (size_t i = 0; i < overhead_groups_per_RAM.size(); i++) {
        size_t end = i * SINGLE_RAM_BITS;
        for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
            size_t start = total_use.ffz(end);
            bitvec immediate_shift = immediate_mask << start;
            if (start + immediate_mask.popcount() >= OVERHEAD_BITS + i * SINGLE_RAM_BITS)
                return false;
            total_use |= immediate_shift;
            use->match_groups[group].mask[IMMEDIATE] |= immediate_shift;
            end = immediate_shift.max().index();
            group++;
        }
    }
    return true;
}

/** This algorithm allocates the pointer to the instruction memory per table entry.  Because
 *  match central has 8 entry map_data table, described in section 6.4.3.5.5 Map Indirection
 *  Table, if the table only has at most 8 hit actions, an up to 3 bit address needs to be
 *  saved, rather than a full instruction memory address.
 *
 *  The full address is 6 bits, 5 for instruction memory line and 1 for color.  The bit for
 *  gress does not have to be saved, as it is added by match central.  This is described within
 *  the uArch in section 6.1.10.3 Action Instruction Memory.
 *
 *  Also, due to the optimization described over the allocate_all_next_table algorithm, it may
 *  be crucial that these action instruction comes first, if next table is not already allocated
 */
bool TableFormat::allocate_all_instr_selection() {
    // Because a gateway requires the 0 position in the action instruction 8 entry matrix, one must
    // add an extra action to a table if linked with a gateway.

    int instr_select = 0;
    if (hit_actions() == 0)
        instr_select = 0;
    else if (hit_actions() > 0 && hit_actions() <= IMEM_MAP_TABLE_ENTRIES)
        instr_select = ceil_log2(hit_actions());
    else
        instr_select = FULL_IMEM_ADDRESS_BITS;

    // If no action instruction bit is required return unless the table is
    // ternary in which case always a ternary indirect is used to specify
    // actions
    if (instr_select == 0) {
        if (tbl->layout.no_match_miss_path())
            instr_select++;
        else
            return true;
    }

    /* If actions cannot be fit inside a lookup table, the action instruction can be
       anywhere in the IMEM and will need entire imem bits. The assembler decides
       based on color scheme allocations. Assembler will flag an error if it fails
       to fit the action code in the given bits. */
    if (instr_select == 0)
        return true;

    bitvec instr_mask;
    instr_mask.setrange(0, instr_select);
    int group = 0;
    for (size_t i = 0; i < overhead_groups_per_RAM.size(); i++) {
        size_t end = i * SINGLE_RAM_BITS;
        for (int j = 0; j < overhead_groups_per_RAM[i]; j++) {
            size_t start = total_use.ffz(end);
            bitvec instr_shift = instr_mask << start;
            total_use |= instr_shift;
            if (start >= OVERHEAD_BITS + i * SINGLE_RAM_BITS)
                return false;
            use->match_groups[group].mask[ACTION] |= instr_shift;
            end = instr_shift.max().index();
            group++;
        }
    }
    return true;
}

/**
 * This function determines whether the table will require multiple search buses to be
 * matched against.  Wide does not mean that the the RAM match is wide, rather that each
 * individual match entry requires multiple RAMs.
 *
 * This match_entry_wide leads to different strategies during allocation
 */
bool TableFormat::is_match_entry_wide() const {
    return !(match_ixbar.search_buses_single() == 1 || layout_option.way.width == 1);
}

/** Save information on a byte by byte basis so that fill out use can correctly be used.
 *  Note that each individual byte from PHV requires an individual byte in the match format,
 *  and cannot be reused by a separate entry.
 */
bool TableFormat::initialize_byte(int byte_offset, int width_sect, ByteInfo &info,
        safe_vector<ByteInfo> &alloced, bitvec &byte_attempt, bitvec &bit_attempt) {
     int initial_offset = byte_offset + width_sect * SINGLE_RAM_BYTES;
     if (match_byte_use.getbit(initial_offset) || byte_attempt.getbit(initial_offset))
         return false;
     auto use_slice = total_use.getslice(initial_offset * 8, 8);
     use_slice |= bit_attempt.getslice(initial_offset * 8, 8);
     if (!(use_slice & info.bit_use).empty())
         return false;


     byte_attempt.setbit(initial_offset);
     bit_attempt.setrange(initial_offset * 8, 8);
     alloced.push_back(info);
     alloced.back().byte_location = initial_offset;
     return true;
}

bool TableFormat::allocate_match_byte(ByteInfo &info, safe_vector<ByteInfo> &alloced,
        int width_sect, bitvec &byte_attempt, bitvec &bit_attempt) {
    int lo = pa == SAVE_GW_SPACE ? GATEWAY_BYTES : 0;
    int hi = pa == SAVE_GW_SPACE ? VERSION_BYTES : SINGLE_RAM_BYTES;

    for (int i = 0; i < SINGLE_RAM_BYTES; i++) {
       if (i < lo || i >= hi)
           continue;
       if (initialize_byte(i, width_sect, info, alloced, byte_attempt, bit_attempt))
           return true;
    }

    for (int i = 0; i < SINGLE_RAM_BYTES; i++) {
       if (i >= lo && i < hi)
           continue;
       if (initialize_byte(i, width_sect, info, alloced, byte_attempt, bit_attempt))
           return true;
    }
    return false;
}

/** Pull out all bytes that coordinate to a particular search bus
 */
void TableFormat::find_bytes_to_allocate(int width_sect, safe_vector<ByteInfo> &unalloced) {
    int search_bus = search_bus_per_width[width_sect];
    for (auto info : match_bytes) {
        if (info.byte.search_bus != search_bus)
            continue;
        unalloced.push_back(info);
    }

    std::sort(unalloced.begin(), unalloced.end(), [=](const ByteInfo &a, const ByteInfo &b) {
        int t;
        if ((t = a.bit_use.popcount() - b.bit_use.popcount()) != 0)
            return t > 0;
        return a.byte < b.byte;
    });
}

/** Version bits are used to indicate whether an entry is valid or not.  For instance, during
 *  the addition of an entry, packets may be running while the entry is not fully added.  Thus
 *  the version bits are used in order to keep track of atomic adds.  Version bits are placed
 *  on the search bus after the input xbar, as specified by section 6.2.3 Exact Match Row
 *  Vertical/Horizontal (VH) Bar, and go anywhere within the 128 bits at a four byte
 *  alignment.
 *
 *  The other trick to version bits is that the upper two bytes of each RAM have nibble by
 *  nibble checks rather than byte by byte checks.  This means that in the upper two nibble,
 *  the algorithm does not have to burn an entire byte for 4 bits, but can fully use a
 *  nibble instead.
 *
 *  The algorithm first tries to put the version with bytes already allocated for that
 *  group.  Then if the algorithm is not try to save space, then the allocation tries
 *  to find places that version could overlap with overhead.  Finally, if that does not
 *  succeed, then try to place in the upper two bytes at nibble alignment
 */
bool TableFormat::allocate_version(int width_sect, const safe_vector<ByteInfo> &alloced,
                                   bitvec &version_loc, bitvec &byte_attempt,
                                   bitvec &bit_attempt) {
    bitvec lo_vers(0, VERSION_BITS);
    bitvec hi_vers(VERSION_BITS, VERSION_BITS);
    // Try to place with a match byte already
    for (auto &info : alloced) {
        if (info.byte_location / SINGLE_RAM_BITS != width_sect)
            continue;
        auto use_slice = total_use.getslice(info.byte_location * 8, 8);
        use_slice |= bit_attempt.getslice(info.byte_location * 8, 8);
        if (((info.bit_use | use_slice) & lo_vers).empty()) {
            version_loc = lo_vers << (8 * info.byte_location);
            bit_attempt |= version_loc;
            return true;
        } else if (((info.bit_use | use_slice) & hi_vers).empty()) {
            version_loc = hi_vers << (8 * info.byte_location);
            bit_attempt |= version_loc;
            return true;
        }
    }

    // Look for a corresponding place within the overhead

    for (int i = 0; i < OVERHEAD_BITS / 8; i++) {
        if (pa != PACK_TIGHT)
            break;
        int byte = width_sect * SINGLE_RAM_BYTES + i;
        if (byte_attempt.getbit(i) || match_byte_use.getbit(i)) continue;
        auto use_slice = total_use.getslice(byte * 8, 8);
        use_slice |= bit_attempt.getslice(byte * 8, 8);
        if ((use_slice & lo_vers).empty() && !(use_slice & hi_vers).empty()) {
            version_loc = lo_vers << (8 * byte);
            bit_attempt |= version_loc;
            byte_attempt |= byte;
            return true;
        }
        if ((use_slice & hi_vers).empty() && !(use_slice & lo_vers).empty()) {
            version_loc = hi_vers << (8 * byte);
            bit_attempt |= version_loc;
            byte_attempt |= byte;
            return true;
        }
    }

    // Look in the upper two nibbles.
    for (int i = 0; i < VERSION_NIBBLES; i++) {
        int initial_bit_offset = (width_sect * SINGLE_RAM_BYTES + VERSION_BYTES) * 8;
        initial_bit_offset += i * VERSION_BITS;
        auto use_slice = total_use.getslice(initial_bit_offset, VERSION_BITS);
        use_slice |= bit_attempt.getslice(initial_bit_offset, VERSION_BITS);
        if ((use_slice).empty()) {
            version_loc = lo_vers << initial_bit_offset;
            bit_attempt |= version_loc;
            return true;
        }
    }

    // Pick any available byte
    for (int i = 0; i < SINGLE_RAM_BYTES; i++) {
        bitvec version_bits(0, VERSION_BITS);
        int initial_byte = (width_sect * SINGLE_RAM_BYTES) + i;
        if (match_byte_use.getbit(initial_byte) || byte_attempt.getbit(initial_byte))
            continue;
        auto use_slice = total_use.getslice(initial_byte * 8, 8);
        use_slice |= bit_attempt.getslice(initial_byte * 8, 8);
        if (!(use_slice & version_bits).empty())
            continue;
        version_loc = version_bits << (initial_byte * 8);
        bit_attempt |= version_loc;
        byte_attempt.setbit(initial_byte);
        return true;
    }

    return false;
}

void TableFormat::classify_match_bits() {
    if (tbl->layout.atcam) {
        auto partition = match_ixbar.atcam_partition();
        for (auto byte : partition) {
            use->ghost_bits[byte] = byte.bit_use;
        }
    }

    safe_vector<IXBar::Use::Byte> potential_ghost;

    for (auto byte : single_match) {
        potential_ghost.push_back(byte);
    }

    if (ghost_bits_count > 0)
        choose_ghost_bits(potential_ghost);

    std::set<int> search_buses;

    for (auto byte : potential_ghost) {
        search_buses.insert(byte.search_bus);
        match_bytes.emplace_back(byte, byte.bit_use);
    }


    for (auto sb : search_buses) {
        BUG_CHECK(std::count(search_bus_per_width.begin(), search_bus_per_width.end(), sb) > 0,
                  "Byte on search bus %d appears as a match byte when no search bus is "
                  "provided on match", sb);
    }


    for (auto info : ghost_bytes) {
        LOG4("Ghost " << info.byte);
        use->ghost_bits[info.byte] = info.bit_use;
    }
}

/** Ghost bits are bits that are used in the hash to find the location of the entry, but are not
 *  contained within the match.  It is an optimization to save space on match bits.
 *
 *  The number of bits one can ghost is the minimum number of bits used to select a RAM row
 *  and a RAM on the hash bus.  One automatically gets 10 bits, for the 10 bits of hash that
 *  determines the RAM row.  Extra bits can be ghosted by the log2size of the minimum way.
 *
 *  This algorithm chooses which bits to ghost.  If the match requires multiple search buses
 *  then the search bus which is going to have the overhead is preferred.  Match requirements
 *  that don't require the full byte are preferred over bytes that require the full 8 bits.
 *  That way, the algorithm can eliminate more match bytes.
 *
 *  For examples, say the match has the following, which were all in separate PHV containers:
 *     3 3 bit fields
 *     1 1 bit field
 *     4 8 bit fields
 *
 *  It would be optimal to ghost off the 3 3 bit fields, and the 1 bit fields, as it would remove
 *  4 total PHV bytes to match on.
 */
void TableFormat::choose_ghost_bits(safe_vector<IXBar::Use::Byte> &potential_ghost) {
    std::sort(potential_ghost.begin(), potential_ghost.end(),
              [=](const IXBar::Use::Byte &a, const IXBar::Use::Byte &b){
        int t = 0;

        auto a_loc = std::find(ghost_bit_buses.begin(), ghost_bit_buses.end(), a.search_bus);
        auto b_loc = std::find(ghost_bit_buses.begin(), ghost_bit_buses.end(), b.search_bus);

        BUG_CHECK(a_loc != ghost_bit_buses.end() && b_loc != ghost_bit_buses.end(),
                  "Search bus must be found within possible ghost bit candidates");

        if (a_loc != b_loc)
            return a_loc < b_loc;
        if ((t = a.bit_use.popcount() - b.bit_use.popcount()) != 0)
            return t < 0;
        return a < b;
    });

    int ghost_bits_allocated = 0;
    while (ghost_bits_allocated < ghost_bits_count) {
        int diff = ghost_bits_count - ghost_bits_allocated;
        auto it = potential_ghost.begin();
        if (it == potential_ghost.end())
            break;
        if (diff >= it->bit_use.popcount()) {
            ghost_bytes.emplace_back(*it, it->bit_use);
            ghost_bits_allocated += it->bit_use.popcount();
        } else {
            bitvec ghosted_bits;
            int start = it->bit_use.ffs();
            int split_bit = -1;
            do {
                int end = it->bit_use.ffz(start);
                if (end - start + ghosted_bits.popcount() < diff) {
                    ghosted_bits.setrange(start, end - start);
                } else {
                    split_bit = start + (diff - ghosted_bits.popcount()) - 1;
                    ghosted_bits.setrange(start, split_bit - start + 1);
                }
                start = it->bit_use.ffs(end);
            } while (start >= 0);
            BUG_CHECK(split_bit >= 0, "Could not correctly split a byte into a ghosted and "
                      "match section");
            bitvec match_bits = it->bit_use - ghosted_bits;
            ghost_bytes.emplace_back(*it, ghosted_bits);
            ghost_bits_allocated += ghosted_bits.popcount();
            match_bytes.emplace_back(*it, match_bits);
        }
        it = potential_ghost.erase(it);
    }
}

/** Determines which match group that the algorithm is attempting to allocate, given where
 *  overhead is as well as whether the match is skinny or wide
 */
int TableFormat::determine_group(int width_sect, int groups_allocated) {
    if (skinny) {
        int overhead_groups_seen = 0;
        for (int i = 0; i < layout_option.way.width; i++) {
            if (width_sect == i) {
                if (groups_allocated == overhead_groups_per_RAM[i])
                    return -1;
                return overhead_groups_seen + groups_allocated;
            } else {
                overhead_groups_seen += overhead_groups_per_RAM[i];
            }
        }
    }

    // Could in theory put version bits at this position, so don't skip if:
    // the search_bus_per_width[width_sect] == -1
    int search_bus_seen = 0;
    for (int i = 0; i < layout_option.way.width; i++) {
        if (width_sect == i) {
            if (overhead_groups_per_RAM[i] > 0) {
                if (groups_allocated == overhead_groups_per_RAM[i])
                    return -1;
                return search_bus_seen + groups_allocated;
            } else {
                if (groups_allocated > 0)
                    return -1;
                return search_bus_seen;
            }
        }
        if (search_bus_per_width[width_sect] == search_bus_per_width[i]) {
            if (overhead_groups_per_RAM[i] > 0)
                search_bus_seen += overhead_groups_per_RAM[i];
            else
                search_bus_seen++;
        }
    }
    BUG("Should never reach this point in table format allocation");
    return -1;
}

/** This fills out the use object, as well as the global structures for keeping track of the
 *  format.  This does this for both match and version information.
 */
void TableFormat::fill_out_use(int group, const safe_vector<ByteInfo> &alloced,
                               bitvec &version_loc) {
    auto &group_use = use->match_groups[group];
    for (auto info : alloced) {
        bitvec match_location = info.bit_use << (8 * info.byte_location);
        group_use.match[info.byte] = match_location;
        group_use.mask[MATCH] |= match_location;
        group_use.match_byte_mask.setbit(info.byte_location);
        match_byte_use.setbit(info.byte_location);
        total_use |= match_location;
    }

    if (!version_loc.empty()) {
        group_use.mask[VERS] |= version_loc;
        total_use |= version_loc;
        version_allocated.setbit(group);
        auto byte_offset = (version_loc.min().index() / 8);
        if ((byte_offset % SINGLE_RAM_BYTES) < VERSION_BYTES)
            match_byte_use.setbit(byte_offset);
    }
}

/** Given a number of overhead entries, this algorithm determines how many match groups
 *  can fully fit into that particular RAM.  It both allocates match and version, as both
 *  of those have to be placed in order for the entry to fit.
 *
 *  For wide matches, this ensures that the entirety of the search bus is placed, but not
 *  necessarily version, as version can be placed in any of the wide match sections.
 */
void TableFormat::allocate_full_fits(int width_sect) {
    safe_vector<ByteInfo> allocation_needed;
    safe_vector<ByteInfo> alloced;
    find_bytes_to_allocate(width_sect, allocation_needed);
    bitvec byte_attempt;
    bitvec bit_attempt;

    int groups_allocated = 0;
    while (true) {
        alloced.clear();
        byte_attempt.clear();
        bit_attempt.clear();
        int group = determine_group(width_sect, groups_allocated);
        if (group == -1)
            break;
        for (auto info : allocation_needed) {
            if (!allocate_match_byte(info, alloced, width_sect, byte_attempt, bit_attempt)) {
                break;
            }
        }

        if (allocation_needed.size() != alloced.size())
            break;

        bitvec version_loc;
        if (requires_versioning()) {
            if (is_match_entry_wide()) {
                if (!version_allocated[group])
                    allocate_version(width_sect, alloced, version_loc, byte_attempt, bit_attempt);
            } else {
                if (!allocate_version(width_sect, alloced, version_loc, byte_attempt,
                                      bit_attempt)) {
                    break;
                }
            }
        }

        groups_allocated++;
        full_match_groups_per_RAM[width_sect]++;
        fill_out_use(group, alloced, version_loc);
    }
}

/** Given all the information about a group that currently has not been placed, try to fit
 *  that group within a current section.  If the group has never been attempted before, (which
 *  happens when the overhead section is found), then try to fit the information in all
 *  previous RAMs as well.
 */
void TableFormat::allocate_share(int width_sect, safe_vector<ByteInfo> &unalloced_group,
        safe_vector<ByteInfo> &alloced, bitvec &version_loc, bitvec &byte_attempt,
        bitvec &bit_attempt, bool overhead_section) {
    std::set<int> width_sections;
    int min_sect = width_sect;

    BUG_CHECK(shared_groups_per_RAM[width_sect] < MAX_SHARED_GROUPS, "Trying to share a group "
              "on a section that is already allocated");

    // Try all previous RAMs
    if (overhead_section) {
        min_sect = 0;
    }

    for (int current_sect = min_sect; current_sect <= width_sect; current_sect++) {
        if (shared_groups_per_RAM[width_sect] == MAX_SHARED_GROUPS)
            continue;
        auto it = unalloced_group.begin();
        while (it != unalloced_group.end()) {
            if (allocate_match_byte(*it, alloced, current_sect, byte_attempt, bit_attempt)) {
                width_sections.emplace(current_sect);
                it = unalloced_group.erase(it);
            } else {
                it++;
            }
        }
    }

    for (int current_sect = min_sect; current_sect <= width_sect; current_sect++) {
        if (shared_groups_per_RAM[current_sect] == MAX_SHARED_GROUPS)
            continue;
        if (!requires_versioning()) break;

        if (!version_loc.empty()) break;
        if (allocate_version(current_sect, alloced, version_loc, byte_attempt, bit_attempt)) {
            width_sections.emplace(current_sect);
            break;
        }
    }

    // Note that if a group has overhead on that section, it must be able to access the
    // match result bus that has that particular information, as specified in 6.4.1.4 Match
    // Overhead Enable
    bool on_current_section = false;
    for (auto section : width_sections) {
        shared_groups_per_RAM[section]++;
        on_current_section |= (section == width_sect);
    }

    if (!on_current_section && overhead_section) {
        shared_groups_per_RAM[width_sect]++;
    }
}


/** Given that no entry can fully fit within a particular RAM line, this allocation fills in
 *  the gaps within those RAMs will currently unallocated groups.  The constraint that comes
 *  from section 6.4.3.1 Exact Match Physical Row Result Generation is that at most 2 groups
 *  can be shared within a particular RAM, as only two hit signals will be able to merge.
 *
 *  The other constraint from the hardware is described in section 6.4.1.4 Match Overhead
 *  Enable.  This constraint says that if the overhead is contained within a particular
 *  RAM, then that match group must be either in the RAM, or a shared spot has to be open
 *  to access this overhead.  Thus these constraints have to be maintained while placing
 *  these shared groups.
 */
bool TableFormat::allocate_shares() {
    safe_vector<ByteInfo> unalloced;

    std::map<int, safe_vector<ByteInfo>> unalloced_groups;
    std::map<int, safe_vector<ByteInfo>> allocated;
    std::map<int, bitvec> version_locs;
    bitvec byte_attempt;
    bitvec bit_attempt;

    find_bytes_to_allocate(0, unalloced);

    int overhead_groups_seen = 0;
    // Initialize unallocated groups.  Group number is determined by what overhead is within
    // that section
    for (int width_sect = 0; width_sect < layout_option.way.width; width_sect++) {
        int total_groups = overhead_groups_per_RAM[width_sect]
                           - full_match_groups_per_RAM[width_sect];
        for (int i = 0; i < total_groups; i++) {
            int unallocated_group = overhead_groups_seen + full_match_groups_per_RAM[width_sect];
            unallocated_group += i;
            unalloced_groups[unallocated_group] = unalloced;
        }
        overhead_groups_seen += overhead_groups_per_RAM[width_sect];
    }

    // Groups currently partially allocated
    safe_vector<int> groups_begun;

    overhead_groups_seen = 0;
    for (int width_sect = 0; width_sect < layout_option.way.width; width_sect++) {
        // Groups that aren't allocated that will need sharing
        int groups_to_start = overhead_groups_per_RAM[width_sect]
                              - full_match_groups_per_RAM[width_sect];
        if (groups_to_start == 0 && groups_begun.size() == 0)
            continue;
        int shared_group_count = groups_to_start + groups_begun.size();
        // Cannot share the resources
        if (shared_group_count > MAX_SHARED_GROUPS)
            return false;

        // Try to complete all groups that have been previously placed, to try and get rid
        // of them as quickly as possible
        for (auto group : groups_begun) {
            if (shared_groups_per_RAM[width_sect] > MAX_SHARED_GROUPS)
                break;
            allocate_share(width_sect, unalloced_groups[group], allocated[group],
                           version_locs[group], byte_attempt, bit_attempt, false);
        }

        // Try to allocate new overhead groups
        for (int i = 0; i < groups_to_start; i++) {
            if (shared_groups_per_RAM[width_sect] > MAX_SHARED_GROUPS)
                break;
            int group = overhead_groups_seen + full_match_groups_per_RAM[width_sect];
            allocate_share(width_sect, unalloced_groups[group], allocated[group],
                           version_locs[group], byte_attempt, bit_attempt, true);
        }

        // Eliminate placed groups
        auto it = groups_begun.begin();
        while (it != groups_begun.end()) {
            if (unalloced_groups[*it].empty() && !version_locs[*it].empty())
                it = groups_begun.erase(it);
            else
                it++;
        }

        // Add new overhead groups that are not fully placed
        for (int i = 0; i < groups_to_start; i++) {
            int group = overhead_groups_seen + full_match_groups_per_RAM[width_sect];
            group += i;
            if (!unalloced_groups[group].empty() ||
                (requires_versioning() && version_locs[group].empty()))
                groups_begun.push_back(group);
        }
        overhead_groups_seen += overhead_groups_per_RAM[width_sect];
    }

    // If everything is not placed, then complain
    for (auto unalloced_group : unalloced_groups) {
        if (!unalloced_group.second.empty())
            return false;
    }

    if (requires_versioning()) {
        for (auto version_loc : version_locs) {
            if (version_loc.second.empty())
                return false;
        }
    }

    for (auto entry : allocated) {
        BUG_CHECK(entry.second.size() == unalloced.size(), "During sharing of match "
                  "groups, allocation for group %d not filled out", entry.first);
        BUG_CHECK(!requires_versioning() || !version_locs[entry.first].empty(),
                  "During sharing of match groups, allocation of version for group %d is "
                  "not filled out", entry.first);
        fill_out_use(entry.first, entry.second, version_locs[entry.first]);
    }
    return true;
}



/** This is a further optimization on allocating shares.  Because version is placed relatively
 *  early, occasionally this leads to a packing issue as versions in separate RAMs could be
 *  combined into an early upper nibble, and save an extra necessary byte.  This actually
 *  will clear the placing of the full fit match a version from back, and try to actually
 *  share this section.
 *
 *  The algorithm will keep removing fully placed section until a fit is found, or the
 *  algorithm determines that with the extra sharing the matches still will not fit.
 */
bool TableFormat::attempt_allocate_shares() {
    // Try with all full fits
    if (allocate_shares())
        return true;
    // Eliminate a full fit section from the back one at a time, clear it out, and repeat
    // allocation
    for (int width_sect = layout_option.way.width - 1; width_sect >= 0; width_sect--) {
        std::fill(shared_groups_per_RAM.begin(), shared_groups_per_RAM.end(), 0);
        int overhead_groups_seen = 0;
        if (full_match_groups_per_RAM[width_sect] == 0)
            continue;
        for (int j = 0; j < width_sect; j++)
             overhead_groups_seen += overhead_groups_per_RAM[j];
        int group = overhead_groups_seen + full_match_groups_per_RAM[width_sect] - 1;
        total_use -= use->match_groups[group].mask[MATCH];
        total_use -= use->match_groups[group].mask[VERS];
        match_byte_use -= use->match_groups[group].match_byte_mask;
        use->match_groups[group].clear_match();
        full_match_groups_per_RAM[width_sect]--;

        if (allocate_shares())
            return true;
    }
    return false;
}

/** Gateway tables and exact match tables share search buses to perform lookups.  Thus
 *  in order to potentially share a search bus, the allocation algorithm is run up to
 *  two times.  The first run, the lower 4 bytes of the gateway are packed last.  However,
 *  occasionally this is suboptimal, as the combination of overhead with match bytes might
 *  provide extra room.  Thus if the first iteration doesn't fit, the bytes closest to the
 *  overhead are attempted first
 */
bool TableFormat::allocate_match() {
    pre_match_total_use = total_use;
    bool success = false;

    for (int i = 0; i < PACKING_ALGORITHMS; i++) {
        total_use = pre_match_total_use;
        for (int group = 0; group < layout_option.way.match_groups; group++) {
            use->match_groups[group].clear_match();
        }
        match_bytes.clear();
        ghost_bytes.clear();
        std::fill(full_match_groups_per_RAM.begin(), full_match_groups_per_RAM.end(), 0);
        version_allocated.clear();

        use->ghost_bits.clear();
        match_byte_use.clear();

        pa = static_cast<packing_algorithm_t>(i);
        success = allocate_match_with_algorithm();

        if (success)
            break;
    }
    return success;
}

/** This section allocates all of the match data.  Given that we have assigned search buses to
 *  each individual RAM as well as overhead, this algorithm fills in the gap with all of the
 *  match data.
 *
 *  The general constraints for match data are described in many sections, but mostly in the
 *  from 6.4.1 Exact Match Table Entry Description - 6.4.3 Match Merge.  Section 6.4.2
 *  Match Generation indicates that at most 5 entries can be contained per RAM line.  The total
 *  data used for all match can be specified at bit granularity, while each of the 5 entries
 *  can specify which bytes to match on of these bits.  Thus every byte must coordinate to at
 *  most one match, but any bits of those bytes can be ignored as well.
 *
 *  The other major constraint that the algorithm takes advantage of is specified in section
 *  6.4.3.1 Exact Match Physical Row Generation.  This is the hardware that allows matches
 *  to chain, for example wide matches.  However, the maximum number of hits allowed to chain
 *  is at most two.
 *
 *  (The previous paragraph does have the following exception, the upper 4 nibbles are not
 *   on a byte by byte granularity, but on a nibble by nibble granularity, to pack version
 *   nibbles)
 *
 *  The algorithm is the following:
 *    1. Choose ghost bits: bits that won't appear in the match format
 *    2. Allocate full fits: i.e. match groups that fit on the entirety of the individual RAM
 *    3. Allocate shares: share match groups RAMs
 */
bool TableFormat::allocate_match_with_algorithm() {
    classify_match_bits();
    for (int width_sect = 0; width_sect < layout_option.way.width; width_sect++) {
        allocate_full_fits(width_sect);
    }

    // Determine if everything is fully allocated
    safe_vector<int> search_bus_alloc(match_ixbar.search_buses_single(), 0);
    for (int width_sect = 0; width_sect < layout_option.way.width; width_sect++) {
        int search_bus = search_bus_per_width[width_sect];
        if (search_bus < 0)
            continue;
        search_bus_alloc[search_bus] += full_match_groups_per_RAM[width_sect];
    }

    bool split_match = false;

    for (size_t sb = 0; sb < search_bus_alloc.size(); sb++) {
        BUG_CHECK(search_bus_alloc[sb] <= layout_option.way.match_groups, "Allocating of more "
                  "match groups than actually required");
        if (fully_ghosted_search_buses.count(sb) > 0)
            continue;
        split_match |= search_bus_alloc[sb] < layout_option.way.match_groups;
    }


    if (requires_versioning())
        split_match |= version_allocated.popcount() != layout_option.way.match_groups;

    if (split_match) {
        // Will not split up wide matches
        if (pa != PACK_TIGHT)
            return false;
        if (is_match_entry_wide()) {
            return false;
        } else {
            return attempt_allocate_shares();
        }
    }
    return true;
}

/** As specified in the uArch document in section 6.3.6 TCAM Search Data Format, a TCAM search
 *  data/match data can be encoded in 4 ways:
 *
 *  0 - tcam_normal
 *  1 - dirtcam_2b
 *  2 - dirtcam_4b_lo
 *  3 - dirtcam_4b_hi
 *
 *  TCAM values have two search words and two match words.  These two words give the ability to
 *  do all 0, 1, and don't care matches.
 *
 *  The encoding for TCAM normal is described in section 6.3.1 TCAM Data Representation
 *
 *  2b/4b encoding is a translation of all possible matches through a Karnaugh map.  The
 *  following table is a map of 2b encoding
 *
 *  __Desired_Match__|____Encoding____
 *         00        |  word0[0] = 1
 *         01        |  word0[1] = 1
 *         10        |  word1[0] = 1
 *         11        |  word1[1] = 1
 *
 *  Thus one can calculate all 0 1 and * patterns, i.e if the match was *0, word0 would be 01
 *  and word1 would be 01
 *
 *  4b encoding has a similar table:
 *
 *  __Desired_Match__|____Encoding____
 *       0000        |  word0[0] = 1
 *       ....        |  ............
 *       0111        |  word0[7] = 1
 *       1000        |  word1[0] = 1
 *       ....        |  ............
 *       1111        |  word1[7] = 1
 *
 *  One can surmise that ranges are now possible, as each individual number translates to a
 *  particular byte in either word0 or word1.  Notice also that it takes a full byte to match
 *  on the range of a nibble.  Thus the reason for 4b_lo and 4b_hi, as the encoding will match
 *  on the lower or higher nibble respectively.
 *
 *  The encodings for Barefoot are the following:
 *     - TCAM normal for version/valid matching
 *     - 2b encoding for standard match data, as this apparently saves power when compared to
 *       TCAM normal encoding
 *     - Each full byte of range match will need a 4b_lo and a 4b_hi
 */
void TableFormat::initialize_dirtcam_value(bitvec &dirtcam, const IXBar::Use::Byte &byte) {
    if (byte.is_spec(IXBar::RANGE_LO)) {
        dirtcam.setbit(byte.loc.byte * 2 + 1);  // 4b_lo encoding
    } else if (byte.is_spec(IXBar::RANGE_HI)) {
        dirtcam.setrange(byte.loc.byte * 2, 2);  // 4b_hi_encoding
    } else {
        dirtcam.setbit(byte.loc.byte * 2);  // 2b_encoding
    }
}

void TableFormat::Use::TCAM_use::set_group(int _group, bitvec _dirtcam) {
    group = _group;
    dirtcam = _dirtcam;
}

void TableFormat::Use::TCAM_use::set_midbyte(int _byte_group, int _byte_config) {
    byte_group = _byte_group;
    byte_config = _byte_config;

    if (byte_config == MID_BYTE_LO || byte_config == MID_BYTE_HI)
        dirtcam.setbit(IXBar::TERNARY_BYTES_PER_GROUP * 2);
}

void TableFormat::ternary_midbyte(int midbyte, size_t &index, bool lo_midbyte) {
    Use::TCAM_use *tcam_p;
    Use::TCAM_use tcam;
    if (index < use->tcam_use.size())
        tcam_p = &(use->tcam_use[index]);
    else
        tcam_p = &tcam;

    int midbyte_type = lo_midbyte ? MID_BYTE_LO : MID_BYTE_HI;

    if (lo_midbyte)
        tcam_p->set_midbyte(midbyte, midbyte_type);
    else
        tcam_p->set_midbyte(midbyte, midbyte_type);

    if (tcam_p == &tcam)
        use->tcam_use.push_back(tcam);
    index++;
}

void TableFormat::ternary_version(size_t &index) {
    Use::TCAM_use *tcam_version_p;
    Use::TCAM_use tcam_version;
    if (index < use->tcam_use.size()) {
        tcam_version_p = &(use->tcam_use[index]);
    } else {
        tcam_version_p = &tcam_version;
    }
    tcam_version_p->set_midbyte(-1, MID_BYTE_VERS);
    if (tcam_version_p == &tcam_version)
        use->tcam_use.push_back(tcam_version);
    index++;
}

/**
 * Reservation of ternary match tables.  Allocate the group and midbyte config.
 *
 * There is some specific constraints on tables with multiple ranges, due to the multirange
 * distribution described in section 6.3.9.2 Multirange distributor:
 *     1. If a range key is allocated in multiple TCAMs, then no other range fields can
 *        appear in that TCAM
 *     2. If multiple TCAMs contain a single range match, then TCAMs between these
 *        two TCAM in hardware cannot contain any range matches.
 *
 * The reason for this is that the multirange distribution has to happen on an individual
 * key by key basis.  By breaking these constraints, you are breaking these restrictions on
 * multirange distribution.
 *
 * The compiler currently implements a tighter set of constraints:
 *     1. Each TCAM can at most have only one range field
 *     2. TCAMs with split range fields are contiguous.
 */
bool TableFormat::allocate_all_ternary_match() {
    bitvec used_groups;
    std::map<int, bitvec> dirtcam;
    bitvec used_midbytes;
    std::map<int, std::pair<bool, bool>> midbyte_lo_hi;
    std::map<int, int> range_indexes;

    for (auto &byte : match_ixbar.use) {
        if (byte.loc.byte == IXBar::TERNARY_BYTES_PER_GROUP) {
            // Reserves groups and the mid bytes
            used_midbytes.setbit(byte.loc.group / 2);
            std::pair<bool, bool> lo_hi = { false, false };
            if (byte.bit_use.min().index() <= 3) {
                lo_hi.first = true;
            }
            if (byte.bit_use.max().index() >= 4) {
                lo_hi.second = true;
            }
            midbyte_lo_hi[byte.loc.group / 2] = lo_hi;
        } else {
            used_groups.setbit(byte.loc.group);
            initialize_dirtcam_value(dirtcam[byte.loc.group], byte);
            if (byte.is_range()) {
                range_indexes[byte.loc.group] = byte.range_index;
            }
        }
    }

    // Sets up the the TCAM_use with the four fields output to the assembler
    for (auto group : used_groups) {
        Use::TCAM_use tcam;
        tcam.set_group(group, dirtcam.at(group));
        if (range_indexes.count(group)) {
            tcam.range_index = range_indexes.at(group);
        }
        use->tcam_use.push_back(tcam);
    }

    // In order to maintain that split ranges are continuous
    std::sort(use->tcam_use.begin(), use->tcam_use.end(),
              [](const Use::TCAM_use &a, const Use::TCAM_use &b) {
        int t;
        if ((t = a.range_index - b.range_index) != 0)
            return t > 0;
        return a.group < b.group;
    });

    size_t index = 0;
    bitvec done_midbytes;
    // Because midbyte is shared between two TCAMs, make sure that contiguous TCAMs keep their
    // bytes together
    for (auto midbyte : used_midbytes) {
        if (!(midbyte_lo_hi[midbyte].first && midbyte_lo_hi[midbyte].second))
            continue;
        for (int i = 0; i < 2; i++) {
            ternary_midbyte(midbyte, index, (i % 2) == 0);
        }
        done_midbytes.setbit(midbyte);
    }

    // Allocate all groups that have either a lo or hi section of midbyte but not both.
    // Potentially one can use this for version as well
    bool version_placed = requires_versioning() ? false : true;
    for (auto midbyte : used_midbytes) {
        if (done_midbytes.getbit(midbyte)) continue;
        bool lo = midbyte_lo_hi[midbyte].first;
        bool hi = midbyte_lo_hi[midbyte].second;
        BUG_CHECK((lo || hi) && !(lo && hi), "Midbytes with both a lo and hi range should have "
                  "been handled");
        ternary_midbyte(midbyte, index, lo);
        if (!version_placed) {
            version_placed = true;
            ternary_version(index);
        } else {
            index++;
        }
    }
    if (!version_placed)
        ternary_version(index);

    // For corner cases, i.e. sharing midbytes, where extra gaps in the TCAMs have to be
    // added
    for (size_t i = 0; i < use->tcam_use.size(); i += 2) {
        if (use->tcam_use.size() - 1 == i)
            break;
        if (use->tcam_use[i].byte_group >= 0 && use->tcam_use[i+1].byte_group >= 0
            && use->tcam_use[i].byte_group != use->tcam_use[i+1].byte_group) {
            auto tcam = use->tcam_use[i];
            use->tcam_use.insert(use->tcam_use.begin() + i, tcam);
        }
    }

    if ((use->tcam_use.size() % 2) == 1) {
        use->split_midbyte = use->tcam_use.back().byte_group;
    }
    return true;
}

/**
 * As described by section 6.4.3.1 Exact Match Physical Row Result Generation, the 5 possible
 * entries per RAM line are ranked through a priority.  For exact match, the priority does not
 * matter, but for ATCAM, the lower the priority number, the higher the prioirty ranking.
 *
 * Only 2 entries can be in a different RAM than their match overhead, and those two entries
 * are the two highest priority entries.  The order in which the entries are in the match_groups
 * vector determine the ranking of these entries in the assembler.  Thus after the match bits
 * have been determined for each entry, the compiler reorders them so that the split entries
 * are the first entries in the vector.
 *
 * @seealso comments on no_overhead_atcam_result_bus_words
 */
void TableFormat::redistribute_entry_priority() {
    safe_vector<size_t> multi_ram_entries;
    safe_vector<size_t> single_ram_entries;

    for (size_t idx = 0; idx < use->match_groups.size(); idx++) {
        bitvec entry_use = use->match_groups[idx].entry_info_bit_mask();
        if ((entry_use.min().index() / SINGLE_RAM_BITS) ==
            (entry_use.max().index() / SINGLE_RAM_BITS))
            single_ram_entries.push_back(idx);
        else
            multi_ram_entries.push_back(idx);
    }

    safe_vector<Use::match_group_use> reordered_match_groups;
    for (size_t entry : multi_ram_entries) {
        reordered_match_groups.push_back(use->match_groups[entry]);
    }

    for (size_t entry : single_ram_entries) {
        reordered_match_groups.push_back(use->match_groups[entry]);
    }
    use->match_groups = reordered_match_groups;
}

/**
 * This is implementing a constraint detailed in section 6.4.1.3.2 Next Table Bits / 6.4.3.1
 * Exact Match Physical Row Result Generation.  As described in that section, the next table
 * bits per each entry must be organized so that lower entries have lower lsbs in their next
 * table bits.
 *
 * On top of this constraint, any entry that is spread across multiple RAMs must be considered
 * entry 0 or entry 1.  When the next table is allocated, the algorithm has not yet determined
 * which entries are split across multiple RAMs.  Thus, this is to redistribute the next
 * table mapping after this information is known so that multi-ram entries have less significant
 * bit next tables.
 */
void TableFormat::redistribute_next_table() {
    int next_index;
    if (!tbl->action_chain())
        return;
    else if (hit_actions() <= NEXT_MAP_TABLE_ENTRIES)
        next_index = ACTION;
    else
        next_index = NEXT;

    safe_vector<safe_vector<size_t>> multi_ram_entries(layout_option.way.width);
    safe_vector<safe_vector<size_t>> single_ram_entries(layout_option.way.width);

    for (size_t idx = 0; idx < use->match_groups.size(); idx++) {
        auto &match_group = use->match_groups[idx];
        int overhead_position = match_group.overhead_mask().min().index() / SINGLE_RAM_BITS;
        bitvec entry_use = use->match_groups[idx].entry_info_bit_mask();
        if ((entry_use.min().index() / SINGLE_RAM_BITS) ==
            (entry_use.max().index() / SINGLE_RAM_BITS)) {
            single_ram_entries[overhead_position].push_back(idx);
        } else {
            multi_ram_entries[overhead_position].push_back(idx);
        }
    }


    for (int idx = 0; idx < layout_option.way.width; idx++) {
        safe_vector<bitvec> next_masks;

        for (auto entry : multi_ram_entries[idx]) {
            next_masks.push_back(use->match_groups[entry].mask[next_index]);
        }

        for (auto entry : single_ram_entries[idx]) {
            next_masks.push_back(use->match_groups[entry].mask[next_index]);
        }

        std::sort(next_masks.begin(), next_masks.end(), [](const bitvec &a, const bitvec &b) {
            return a.min().index() < b.min().index();
        });

        size_t next_mask_entry = 0;
        for (auto entry : multi_ram_entries[idx]) {
            use->match_groups[entry].mask[next_index] = next_masks[next_mask_entry];
            next_mask_entry++;
        }

        for (auto entry : single_ram_entries[idx]) {
            use->match_groups[entry].mask[next_index] = next_masks[next_mask_entry];
            next_mask_entry++;
        }
    }
}

/* This is a verification pass that guarantees that we don't have overlap.  More constraints can
   be checked as well.  */
void TableFormat::verify() {
    bitvec verify_mask;
    bitvec on_search_bus_mask;

    for (int i = 0; i < layout_option.way.match_groups; i++) {
        for (int j = NEXT; j <= INDIRECT_ACTION; j++) {
            if (!use->match_groups[i].mask[j].empty()) {
                if ((verify_mask & use->match_groups[i].mask[j]).popcount() != 0) {
                    BUG("Overlap of multiple things in the format");
                    verify_mask |= use->match_groups[i].mask[j];
                }
                if (j == VERS)
                    on_search_bus_mask |= use->match_groups[i].mask[j];
            } else if (j == VERS && requires_versioning()) {
                BUG("A group has been allocated without version bits");
            }
        }
    }

    for (int i = 0; i < layout_option.way.match_groups; i++) {
        for (auto byte_info : use->match_groups[i].match) {
            bitvec &byte_mask = byte_info.second;
            if ((verify_mask & byte_mask).popcount() != 0)
                BUG("Overlap of a match byte in the format");
            verify_mask |= byte_mask;
            on_search_bus_mask |= byte_mask;
        }
    }

    for (int i = 0; i < layout_option.way.width; i++) {
        for (int j = 0; j < GATEWAY_BYTES * 2; j++) {
            if (on_search_bus_mask.getrange(i * SINGLE_RAM_BITS + j * 8, 8))
                continue;
            use->avail_sb_bytes.setbit(i * SINGLE_RAM_BYTES + j);
        }
    }
}
