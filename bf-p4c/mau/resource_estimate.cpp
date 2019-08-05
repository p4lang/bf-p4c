#include "resource_estimate.h"
#include "memories.h"
#include "lib/bitops.h"

constexpr int RangeEntries::MULTIRANGE_DISTRIBUTION_LIMIT;
constexpr int RangeEntries::RANGE_ENTRY_PERCENTAGE;
constexpr int StageUseEstimate::MAX_DLEFT_HASH_SIZE;

constexpr int StageUseEstimate::MAX_MOD;
constexpr int StageUseEstimate::MAX_POOL_RAMLINES;
constexpr int StageUseEstimate::MAX_MOD_SHIFT;

int CounterPerWord(const IR::MAU::Counter *ctr) {
    switch (ctr->type) {
    case IR::MAU::DataAggregation::PACKETS:
        if (ctr->min_width <= 32) return 4;
        if (ctr->min_width > 64)
            error("%s: Maximum width for counter %s is 64 bits", ctr->srcInfo, ctr->name);
        return 2;
    case IR::MAU::DataAggregation::BYTES:
        if (ctr->min_width <= 32) return 4;
        if (ctr->min_width > 64)
            error("%s: Maximum width for counter %s is 64 bits", ctr->srcInfo, ctr->name);
        return 2;
    case IR::MAU::DataAggregation::BOTH:
        // min_width refers to the byte counter at a given index.
        // 1 "packet_and_byte" entry gives 64-bit packet counter and 64-bit byte counter.
        // 2 "packet_and_byte" entries gives 28-bit packet counter and 36-bit byte counter.
        // Hardware also supports 3-entries, but compiler does not (harder to assign VPNs).
        // 3 "packet_and_byte" entries gives 17-bit packet counter and 25-bit byte counter.
        if (ctr->min_width <= 36) return 2;
        if (ctr->min_width > 64)
            error("%s: Maximum width for byte counter %s is 64 bits", ctr->srcInfo, ctr->name);
        return 1;
    default:
        error("%s: No counter type for %s", ctr->srcInfo, ctr->name);
        return 1; }
}

int CounterWidth(const IR::MAU::Counter *cntr) {
    switch (cntr->type) {
    case IR::MAU::DataAggregation::PACKETS:
        if (cntr->min_width <= 32) return 32;
        return 64;
    case IR::MAU::DataAggregation::BYTES:
        if (cntr->min_width <= 32) return 32;
        return 64;
    case IR::MAU::DataAggregation::BOTH:
        // The min_width attribute is with respect to the byte counter.
        if (cntr->min_width <= 36) return 36;
        return 64;
    default:
        error("%s: No counter type for %s", cntr->srcInfo, cntr->name);
        return 1;
    }
}

int RegisterPerWord(const IR::MAU::StatefulAlu *reg) {
    BUG_CHECK(reg->width > 0 && (reg->width & (reg->width-1)) == 0,
              "register width not a power of two");
    return 128/reg->width;
}

int ActionDataPerWord(const IR::MAU::Table::Layout *layout, int *width) {
    int size = 0;
    if (layout->action_data_bytes_in_table > 0)
        size = ceil_log2(layout->action_data_bytes_in_table);
    if (size > 4) {
        *width = (layout->action_data_bytes_in_table / 16);
        return 1;
    }
    return 16 >> size;
}

/** Information necessary for the calculation of VPN addressing on action data tables.  This
 *  comes from section 6.2.8.4.3 Action RAM Addressing.
 *
 *  Essentially action table addresses have different sizes that are programmed through the
 *  Huffman encoding bits.  The address itself has 5 bits pre-pended to the lower portion
 *  of the address to indicate the action data size.  However, for entries of 256, 512, or 1024
 *  bit width, 6, 7, and 8 bits respectively are required to indicate what the encoding is.
 *  These bits are contained in the upper part of the address, and thus need to be part of
 *  the address that comes from match overhead.
 *
 *  Furthermore the encoding scheme affects the VPN allocation of the action data tables, as
 *  the Huffman Encoding appears in the VPN space of the action data table.  The increment is
 *  the difference between VPN per action data RAM.  The offset is the address within the
 *  VPN space for that table type.
 *
 *  ___Action_Data_Bits___|___VPN_Increment___|___VPN_Offset___
 *           256          |         2         |        0
 *           512          |         4         |        1
 *          1024          |         8         |        3
 */
int ActionDataHuffmanVPNBits(const IR::MAU::Table::Layout *layout) {
    int size = 0;
    if (layout->action_data_bytes_in_table > 0)
        size = ceil_log2(layout->action_data_bytes_in_table);
    int huffman_not_req_max_size = 4;
    return std::max(size - huffman_not_req_max_size, 0);
}

int ActionDataVPNStartPosition(const IR::MAU::Table::Layout *layout) {
    int size = 0;
    if (layout->action_data_bytes_in_table > 0)
        size = ceil_log2(layout->action_data_bytes_in_table);
    switch (size) {
        case 6:
           return 1;
        case 7:
           return 3;
        default:
           return 0;
    }
}

int ActionDataVPNIncrement(const IR::MAU::Table::Layout *layout) {
    int width = 1;
    ActionDataPerWord(layout, &width);
    if (width == 1)
        return 1;
    return (1 << ceil_log2(width));
}


int TernaryIndirectPerWord(const IR::MAU::Table::Layout *layout, const IR::MAU::Table *tbl) {
    int indir_size = ceil_log2(layout->overhead_bits);
    if (indir_size > 8)
        BUG("can't have more than 64 bits of overhead in "
                                        "ternary table %s", tbl->name);
    if (indir_size < 3) indir_size = 3;
    return (128 >> indir_size);
}

int IdleTimePerWord(const IR::MAU::IdleTime *idletime) {
    switch (idletime->precision) {
        case 1:  return 8;
        case 2:  return 4;
        case 3:  return 2;
        case 6:  return 1;
        default: BUG("%s: Invalid idletime precision %s", idletime->precision);
    }
}

/**
 * Refer to the comments above the allocate_selector_length function in table_format.cpp
 */
int SelectorRAMLinesPerEntry(const IR::MAU::Selector *sel) {
    return (sel->max_pool_size + StageUseEstimate::SINGLE_RAMLINE_POOL_SIZE - 1)
            / StageUseEstimate::SINGLE_RAMLINE_POOL_SIZE;
}

int SelectorModBits(const IR::MAU::Selector *sel) {
    int RAM_lines_necessary = SelectorRAMLinesPerEntry(sel);
    if (RAM_lines_necessary <= StageUseEstimate::MAX_MOD) {
        return ceil_log2(RAM_lines_necessary);
    }
    return ceil_log2(StageUseEstimate::MAX_MOD);
}

int SelectorShiftBits(const IR::MAU::Selector *sel) {
    int RAM_lines_necessary = SelectorRAMLinesPerEntry(sel);
    if (RAM_lines_necessary > StageUseEstimate::MAX_POOL_RAMLINES) {
        error("%s: The max pools size %d of selector %s requires %d RAM lines, more than maximum "
              "%d RAM lines possibly on Barefoot hardware", sel->srcInfo, sel->max_pool_size,
              sel->name, RAM_lines_necessary, StageUseEstimate::MAX_POOL_RAMLINES);
    }

    int rv = 0;
    if (RAM_lines_necessary <= StageUseEstimate::MAX_MOD)
        return rv;

    rv = ceil_log2(RAM_lines_necessary) - StageUseEstimate::MAX_MOD_SHIFT;

    if (ceil_log2(RAM_lines_necessary) == floor_log2(RAM_lines_necessary))
        rv += 1;

    rv = std::max(StageUseEstimate::MAX_MOD_SHIFT, rv);
    return rv;
}

int SelectorHashModBits(const IR::MAU::Selector *sel) {
    int RAM_lines_necessary = SelectorRAMLinesPerEntry(sel);
    if (RAM_lines_necessary == 1) {
        return 0;
    }
    return SelectorShiftBits(sel) + StageUseEstimate::MOD_INPUT_BITS;
}

int SelectorLengthShiftBits(const IR::MAU::Selector *sel) {
    int sel_shift = SelectorShiftBits(sel);
    return sel_shift == 0 ? 0 : ceil_log2(sel_shift);
}

int SelectorLengthBits(const IR::MAU::Selector *sel) {
    return SelectorModBits(sel) + SelectorLengthShiftBits(sel);
}

static int ways_pragma(const IR::MAU::Table *tbl, int min, int max) {
    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("ways")) {
        ERROR_CHECK(s->expr.size() >= 1, "%s: The ways pragma on table %s does not have a "
                    "value", tbl->srcInfo, tbl->name);
        auto pragma_val =  s->expr.at(0)->to<IR::Constant>();
        if (pragma_val == nullptr) {
            ::error("%s: The ways pragma value on table %s is not a constant", tbl->srcInfo,
                  tbl->name);
            return -1; }
        int rv = pragma_val->asInt();
        if (rv < min || rv > max) {
            ::warning("%s: The ways pragma value on table %s is not between %d and %d, and "
                      "will be ignored", tbl->srcInfo, tbl->name, min, max);
            return -1; }
        return rv; }
    return -1;
}

static int simul_lookups_pragma(const IR::MAU::Table *tbl, int min, int max) {
    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("simul_lookups")) {
        ERROR_CHECK(s->expr.size() >= 1, "%s: The simul_lookups pragma on table %s does not "
                    "have a value", tbl->srcInfo, tbl->name);
        auto pragma_val =  s->expr.at(0)->to<IR::Constant>();
        if (pragma_val == nullptr) {
            ::error("%s: The simul_lookups pragma value on table %s is not a constant",
                    tbl->srcInfo, tbl->name);
            return -1; }
        int rv = pragma_val->asInt();
        if (rv < min || rv > max) {
            ::warning("%s: The simul_lookups pragma value on table %s is not between %d and %d, "
                      "and will be ignored", tbl->srcInfo, tbl->name, min, max);
            return -1; }
        return rv; }
    return -1;
}

/**
 * There are now two support pragmas, ways and simul_lookups.  For an SRAM based table that uses
 * cuckoo hashing, multiple RAMs are looked up simultaneously, each accessed by a different
 * hash function.  The number of ways is the number of simultaneous lookup.  Each way corresponds
 * to a single hash function provided by the 52 bit hash bus.
 *
 * The difference in the meaning is the following:
 *
 *      ways - Each hash function must be entirely independent, i.e. cannot use the same
 *          hash bits
 *      simul_lookups - simultaneous lookups can use the same hash bits, an optimization
 *          supported only in Brig.  Really, one can think of this as making an
 *          individual way deeper
 *
 * simul_lookups is only supported internally at this point, and is necessary to make progress
 * on power.p4
 */
bool StageUseEstimate::ways_provided(const IR::MAU::Table *tbl, LayoutOption *lo,
                                     int &calculated_depth) {
    int ways = ways_pragma(tbl, MIN_WAYS, MAX_WAYS);
    int simul_lookups = simul_lookups_pragma(tbl, MIN_WAYS, MAX_WAYS + 2);

    if (ways == -1 && simul_lookups == -1)
        return false;

    bool independent_hash = ways != -1;
    int way_total = ways != -1 ? ways : simul_lookups;

    int depth_needed = std::min(calculated_depth, int(StageUse::MAX_SRAMS));
    int depth = 0;

    for (int i = 0; i < way_total; i++) {
        if (depth_needed <= 0)
            depth_needed = 1;
        int initial_way_size = (depth_needed + (way_total - i) - 1)  / (way_total - i);
        int log2_way_size = 1 << (ceil_log2(initial_way_size));
        depth_needed -= log2_way_size;
        depth += log2_way_size;
        lo->way_sizes.push_back(log2_way_size);
    }

    if (independent_hash) {
        int select_upper_bits_required = 0;
        int index = 0;
        for (auto way_size : lo->way_sizes) {
            if (index == IXBar::HASH_INDEX_GROUPS) {
                lo->select_bus_split = index;
                break;
            }
            int select_bits = floor_log2(way_size);
            if (select_bits + select_upper_bits_required > IXBar::HASH_SINGLE_BITS) {
                lo->select_bus_split = index;
                break;
            }
            select_upper_bits_required += floor_log2(way_size);
            index++;
        }
    } else {
        int select_upper_bits_required = 0;
        int way_index = 0;
        for (auto way_size : lo->way_sizes) {
            if (way_index == IXBar::HASH_INDEX_GROUPS)
                break;
            select_upper_bits_required += floor_log2(way_size);
            if (select_upper_bits_required > IXBar::HASH_SINGLE_BITS) {
                lo->select_bus_split = way_index;
                break;
            }
            way_index++;
        }
    }

    calculated_depth = depth;
    return true;
}

/** This calculates the number of simultaneous lookups within an exact match table, using the
 *  cuckoo hashing.  The RAM selection is done through using particular bits on the 52 bit
 *  hash bus.  The lower 40 bits are broken into 4 10 bit sections for RAM line selection,
 *  and the upper 12 bits are used to do a RAM select.
 *
 *  In order to fit as at least 90% of entries without having to move other match entries,
 *  generally 4 ways are required for complete independent lookup.  Thus, if the entries
 *  requested for the table is smaller than a particular number, the algorithm will still
 *  bump the number of entries up in order to maintain this number of independent ways.
 *
 *  Let me provide the following example.  Say that the number of entries for a particular
 *  table requires 4 independent ways of size 8.  The hash bus would be allocated as
 *  the following:
 *    - Each of the 4 independent ways would each have a separate 10 bits of RAM row select,
 *      totalling 40 bits
 *    - To select a distinct RAM out of the 8 ways, each way would require 3 bits of RAM
 *      select, totalling 12 bits.
 *  This totals to 52 bits, which fortunately is the size of the number of hash select bits
 *
 *  An optimization that I take advantage of is the fact that I can repeat using of select bits.
 *  For example, say the number of entries required 40 RAMs.  One could in theory break this
 *  up into 5 independent ways of 8 RAMs.  However, this would not fit onto the 52 bits, as
 *  50 bits of RAM row select + 15 bits of RAM select, way larger than the 52 bits on a hash
 *  select bus.
 *
 *  However, the compiler will optimize so that way 1 and way 5 will actually share the 10
 *  bits of RAM row select, and the 3 upper bits of RAM select.  This means that ways 1 and 5
 *  are not independent, instead they are the exact same.  However, this is not an issue for
 *  our constraint, as we still have 4 independent hash lookups.
 *
 *  This cannot be used indefinitely however.  For example, say we needed 64 RAMs, with 4
 *  ways of 16 RAMs.  Even though we can fit all RAM row selection in the lower 40 bits, this
 *  would require 16 bits of RAM select.  In this case, we cannot repeat the use select bits
 *  as this would not provide at least 4 independent hash lookups, which is the standard
 *  required by the driver.
 *
 *  In the case just described, we would actually require 2 separate RAM select buses, and thus
 *  two separate search buses.  The fortunate thing is that the maximum number of RAMs is 80
 *  per MAU stage, so even the input xbar requirements are high, the RAM array requirements
 *  are high as well.
 */
void StageUseEstimate::calculate_way_sizes(const IR::MAU::Table *tbl, LayoutOption *lo,
                                           int &calculated_depth) {
    if (ways_provided(tbl, lo, calculated_depth))
        return;

    // This indicates that we are using identity function.
    if (lo->layout.ixbar_width_bits <= ceil_log2(Memories::SRAM_DEPTH) && !lo->layout.proxy_hash) {
        if (calculated_depth == 1) {
            lo->way_sizes = {1};
            lo->identity = true;
            return;
        }
    }

    if (calculated_depth < 8) {
        switch (calculated_depth) {
            case 1:
                lo->way_sizes = {1, 1, 1};
                calculated_depth = 3;
                break;
            case 2:
                lo->way_sizes = {1, 1, 1, 1};
                calculated_depth = 4;
                break;
            case 3:
                lo->way_sizes = {1, 1, 1, 1};
                calculated_depth = 4;
                break;
            case 4:
                lo->way_sizes = {1, 1, 1, 1};
                break;
            case 5:
                lo->way_sizes = {2, 1, 1, 1};
                break;
            case 6:
                lo->way_sizes = {2, 2, 1, 1};
                break;
            case 7:
                lo->way_sizes = {2, 2, 2, 1};
                break;
        }
    // Anything larger than 8 for depth.
    } else {
        // Limit the size to 80, as anyhing above 80 would not fit within an SRAM
        int test_depth = calculated_depth > 64 ? 64 : calculated_depth;
        int max_group_size = (1 << floor_log2(test_depth)) / 4;
        int depth = calculated_depth > 80 ? 80 : calculated_depth;
        if (depth >= 64)
            lo->select_bus_split = 3;
        while (depth > 0) {
            if (max_group_size <= depth) {
                lo->way_sizes.push_back(max_group_size);
                depth -= max_group_size;
            } else {
                max_group_size /= 2;
            }
        }
    }
}

/* Convert all possible layout options to the correct way sizes */
void StageUseEstimate::options_to_ways(const IR::MAU::Table *tbl, int entries) {
    for (auto &lo : layout_options) {
        if (lo.layout.hash_action) {
            lo.entries = entries;
            lo.srams = 0;
            continue;
        }

        int per_row = lo.way.match_groups;
        int total_depth = (entries + per_row * 1024 - 1) / (per_row * 1024);
        int calculated_depth = total_depth;
        calculate_way_sizes(tbl, &lo, calculated_depth);
        lo.entries = calculated_depth * lo.way.match_groups * 1024;
        lo.srams = calculated_depth * lo.way.width;
        lo.maprams = 0;
    }
}

/* Calculate the correct size of ternary tables.  Obviously with ternary tables, no way
   size calculation is necessary, as ternary has no ways */
void StageUseEstimate::options_to_ternary_entries(const IR::MAU::Table *tbl, int entries) {
    for (auto &lo : layout_options) {
        int depth = (entries + 511u)/512u;
        int width = (tbl->layout.match_width_bits + 47)/44;  // +4 bits for v/v, round up
        lo.tcams = depth * width;
        lo.srams = 0;
        lo.entries = depth * 512;
    }
}

/** Calculates an estimate for the total number of logical tables, given the number of RAMs
 *  dedicated to an ATCAM table.  The goal is, calculate the minimum logical tables that I
 *  need, and then balance the size of those logical tables.
 */
void StageUseEstimate::calculate_partition_sizes(LayoutOption *lo, int ram_depth) {
    int logical_tables_needed = (ram_depth + Memories::MAX_PARTITION_RAMS_PER_ROW - 1)
                                / Memories::MAX_PARTITION_RAMS_PER_ROW;
    for (int i = 0; i < logical_tables_needed; i++) {
        int logical_table_depth = ram_depth / logical_tables_needed;
        if (i < (ram_depth % logical_tables_needed))
            logical_table_depth++;
        lo->partition_sizes.push_back(logical_table_depth);
    }
}

/** Calculating the total number of entries for each layout option for an atcam table.
 *  The number of RAMs for the whole table is the following calculation:
 *      ways_per_partition: ceil_log2(select_bits of the atcam_partition_index)
 *      partition_entries: total (logical) simultaneous lookups in the table
 *      ram_depth: number of RAMs to hold all partitions, if the match was one ram wide
 */
void StageUseEstimate::options_to_atcam_entries(const IR::MAU::Table *tbl, int entries) {
    int partition_entries = (entries + tbl->layout.partition_count - 1)
                           / tbl->layout.partition_count;
    for (auto &lo : layout_options) {
        int per_row = lo.way.match_groups;
        int ram_depth = (partition_entries + per_row - 1) / per_row;
        calculate_partition_sizes(&lo, ram_depth);
        int ways_per_partition = (tbl->layout.partition_count + 1024 - 1) / 1024;
        lo.way_sizes.push_back(ways_per_partition);
        lo.srams = ram_depth * lo.way.width * ways_per_partition;
        lo.entries = ram_depth * ways_per_partition * lo.way.match_groups
                     * std::min(tbl->layout.partition_count, Memories::SRAM_DEPTH);
    }
}

/** Currently a very simple way to split up the dleft hash tables into a reasonable number
 *  of ALUs with a particular size.  Eventually, the hash mod can potentially be used in order
 *  to calculate a RAM size exactly, according to Mike Ferrera, so that the addresses
 *  don't have to be a power of two.
 */
void StageUseEstimate::options_to_dleft_entries(const IR::MAU::Table *tbl,
                                                const attached_entries_t &attached_entries) {
    const IR::MAU::StatefulAlu *salu = nullptr;
    for (auto back_at : tbl->attached) {
        salu = back_at->attached->to<IR::MAU::StatefulAlu>();
        if (salu != nullptr)
            break;
    }
    if (!attached_entries.count(salu))
        return;
    auto entries = attached_entries.at(salu);
    if (entries == 0)
        return;

    /* Figure out how many dleft ways can/should be used for the specified number
     * of entries -- currently ways must be the same size and must be a power of two size.
     * Ways must fit within one half of an MAU stage (max 23 rams/maprams + 1 spare bank) */
    int per_row = RegisterPerWord(salu);
    int total_stateful_rams = (entries + per_row * Memories::SRAM_DEPTH - 1)
                               / (per_row * Memories::SRAM_DEPTH);
    int available_alus = MAX_METER_ALUS - meter_alus;
    int needed_alus = ways_pragma(tbl, 1, MAX_METER_ALUS);
    if (needed_alus < 0)
            needed_alus = std::min(total_stateful_rams, available_alus);
    int per_alu = (total_stateful_rams + needed_alus - 1) / needed_alus;
    int max_rams_per_way = 1 << floor_log2(MAX_DLEFT_HASH_SIZE);
    // if there are more than two ways, then two will have to share one half
    if (needed_alus > 2)
        max_rams_per_way /= 2;

    for (auto &lo : layout_options) {
        // FIXME: The hash distribution units are all identical for each, so the sizes for
        // each of the stateful for the same, as the mask is per hash distribution unit.
        // Just currently a limit of the input xbar algorithm which will have to be opened up
        int dleft_entries = 0;
        for (int i = 0; i < needed_alus; i++) {
            int hash_size = std::min(1 << ceil_log2(per_alu), max_rams_per_way);
            lo.dleft_hash_sizes.push_back(hash_size);
            dleft_entries += hash_size * per_row * Memories::SRAM_DEPTH;
        }
        LOG3("Dleft rams per_alu: " << per_alu << " needed_alus: " << needed_alus <<
             " entries: " << dleft_entries);
    }
}

/* Calculate the number of rams required for attached tables, given the number of entries
   provided from the table placment */
void StageUseEstimate::calculate_attached_rams(const IR::MAU::Table *tbl,
                                               const attached_entries_t &att_entries,
                                               LayoutOption *lo,
                                               bool table_placement) {
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        int per_word = 0;
        int width = 1;
        int attached_entries = lo->entries;
        if (!at->direct) {
            if (!att_entries.count(at) || (attached_entries = att_entries.at(at)) == 0)
                continue; }
        bool need_srams = true;
        bool need_maprams = false;
        if (auto *ctr = at->to<IR::MAU::Counter>()) {
            per_word = CounterPerWord(ctr);
            need_maprams = true;
        } else if (at->is<IR::MAU::Meter>()) {
            per_word = 1;
            need_maprams = true;
        } else if (auto *reg = at->to<IR::MAU::StatefulAlu>()) {
            per_word = RegisterPerWord(reg);
            need_maprams = true;
        } else if (auto *ad = at->to<IR::MAU::ActionData>()) {
            // FIXME: in theory, the table should not have an action data table,
            // as that is decided after the table layout is picked
            if (!table_placement && ad->direct)
                BUG("Direct Action Data table exists before table placement occurs");
            width = 1;
            per_word = ActionDataPerWord(&lo->layout, &width);
        } else if (at->is<IR::MAU::Selector>()) {
            // TODO(cdodd)
        } else if (at->is<IR::MAU::TernaryIndirect>()) {
            if (!table_placement)
                BUG("Ternary Indirect Data table exists before table placement occurs");
            per_word = TernaryIndirectPerWord(&lo->layout, tbl);
        } else if (auto *idle = at->to<IR::MAU::IdleTime>()) {
            need_srams = false;
            need_maprams = true;
            per_word = IdleTimePerWord(idle);
        } else {
            BUG("unknown attached table type %s", at->kind()); }
        if (per_word > 0) {
            if (attached_entries <= 0)
                BUG("%s: no size in indirect %s %s", at->srcInfo, at->kind(), at->name);
            int entries_per_sram = 1024 * per_word;
            int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
            if (need_srams) lo->srams += units * width;
            if (need_maprams) lo->maprams += units;
        }
    }
    // Before table placment, tables do not have attached Ternary Indirect or
    // Action Data Tables
    if (lo->layout.direct_ad_required() && !table_placement) {
        int width = 1;
        int per_word = ActionDataPerWord(&lo->layout, &width);
        int attached_entries = lo->entries;
        int entries_per_sram = 1024 * per_word;
        int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
        lo->srams += units * width;
    }
    if (lo->layout.ternary_indirect_required() && !table_placement) {
        int per_word = TernaryIndirectPerWord(&lo->layout, tbl);
        int attached_entries = lo->entries;
        int entries_per_sram = 1024 * per_word;
        int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
        lo->srams += units;
    }
}

/* Calculate the number of attached rams for every single potential layout option */
void StageUseEstimate::options_to_rams(const IR::MAU::Table *tbl,
            const attached_entries_t &attached_entries, bool table_placement) {
    for (auto &lo : layout_options) {
        calculate_attached_rams(tbl, attached_entries, &lo, table_placement);
    }
}

/* Sorting algorithm to determine the best option given that it is before trying to
   fit the layout options to a certian number of resources, instead just using all entries */
void StageUseEstimate::select_best_option(const IR::MAU::Table *tbl) {
    bool small_table_allocation = true;
    int table_size = 0;
    if (auto k = tbl->match_table->getConstantProperty("size"))
        table_size = k->asInt();
    for (auto lo : layout_options) {
        if (lo.entries < table_size) {
            small_table_allocation = false;
            break;
        }
    }

    std::sort(layout_options.begin(), layout_options.end(),
        [=](const LayoutOption &a, const LayoutOption &b) {
        int t;
        bool wide = a.way.match_groups < a.way.width && b.way.match_groups < b.way.width;
        bool skinny = a.way.match_groups >= a.way.width && b.way.match_groups >= b.way.width;
        skinny &= !a.layout.hash_action && !b.layout.hash_action;
        int a_mod = 0;  int b_mod = 0;

        if (wide) {
           a_mod = a.way.width % a.way.match_groups;
           b_mod = b.way.width % b.way.match_groups;
        } else if (skinny) {
           a_mod = a.way.match_groups % a.way.width;
           b_mod = b.way.match_groups % b.way.width;
        }

        if (a_mod == 0 && b_mod != 0)
            if (b.way.width > 2)
                return true;
        if (b_mod == 0 && a_mod != 0)
            if (a.way.width > 2)
                return false;

        if ((t = a.srams - b.srams) != 0) return t < 0;
        if ((t = a.way.width - b.way.width) != 0) return t < 0;
        if ((t = a.way.match_groups - b.way.match_groups) != 0) return t < 0;
        if (!a.layout.direct_ad_required() && b.layout.direct_ad_required())
            return true;
        if (a.layout.direct_ad_required() && !b.layout.direct_ad_required())
            return false;
        return a.layout.action_data_bytes_in_table < b.layout.action_data_bytes_in_table;
    });

    LOG3("table " << tbl->name << " requiring " << table_size << " entries.");
    if (small_table_allocation)
        LOG3("small table allocation");
    else
        LOG3("large table allocation");
    for (auto &lo : layout_options) {
        LOG3("layout option width " << lo.way.width << " match groups " << lo.way.match_groups
              << " entries " << lo.entries << " srams " << lo.srams
              << " action data " << lo.layout.action_data_bytes_in_table
              << " immediate " << lo.layout.immediate_bits);
        LOG3("Layout option way sizes " << lo.way_sizes);
    }

    preferred_index = 0;
}

/* A sorting algorithm for the best ternary option, without having to fit the table
   to a particular number of resources */
void StageUseEstimate::select_best_option_ternary() {
    std::sort(layout_options.begin(), layout_options.end(),
        [=](const LayoutOption &a, const LayoutOption &b) {
        int t;
        if ((t = a.srams - b.srams) != 0) return t < 0;
        if (!a.layout.ternary_indirect_required()) return true;
        if (!b.layout.ternary_indirect_required()) return false;
        if (!a.layout.direct_ad_required()) return true;
        if (!b.layout.direct_ad_required()) return false;
        return false;
    });

    for (auto &lo : layout_options) {
        LOG3("entries " << lo.entries << " srams " << lo.srams << " tcams " << lo.tcams
              << " action data " << lo.layout.action_data_bytes_in_table
              << " immediate " << lo.layout.immediate_bits
              << " ternary indirect " << lo.layout.ternary_indirect_required());
    }

    preferred_index = 0;
}

/* Set the correct parameters of the preferred index */
void StageUseEstimate::fill_estimate_from_option(int &entries) {
    tcams = preferred()->tcams;
    srams = preferred()->srams;
    maprams = preferred()->maprams;
    entries = preferred()->entries;
}

void StageUseEstimate::determine_initial_layout_option(const IR::MAU::Table *tbl,
        int &entries, attached_entries_t &attached_entries, bool table_placement) {
    if (tbl->for_dleft()) {
        BUG_CHECK(layout_options.size() == 1, "Should only be one layout option for dleft "
                  "hash tables");
        options_to_dleft_entries(tbl, attached_entries); }
    if (layout_options.size() == 1 && layout_options[0].layout.no_match_data()) {
        entries = 512;
        preferred_index = 0;
    } else if (tbl->layout.atcam) {
        options_to_atcam_entries(tbl, entries);
        options_to_rams(tbl, attached_entries, table_placement);
        select_best_option(tbl);
        fill_estimate_from_option(entries);
    } else if (tbl->layout.ternary) {  // ternary
        options_to_ternary_entries(tbl, entries);
        options_to_rams(tbl, attached_entries, table_placement);
        select_best_option_ternary();
        fill_estimate_from_option(entries);
    } else if (!tbl->gateway_only()) {  // exact_match
        /* assuming all ways have the same format and width (only differ in depth) */
        options_to_ways(tbl, entries);
        options_to_rams(tbl, attached_entries, table_placement);
        select_best_option(tbl);
        fill_estimate_from_option(entries);
    } else {  // gw
        entries = 0;
    }
}


/* Constructor to estimate the number of srams, tcams, and maprams a table will require*/
StageUseEstimate::StageUseEstimate(const IR::MAU::Table *tbl, int &entries,
                                   attached_entries_t &attached_entries, const LayoutChoices *lc,
                                   bool prev_placed, bool table_placement) {
    // Because the table is const, the layout options must be copied into the Object
    logical_ids = 1;
    layout_options.clear();
    if (!tbl->created_during_tp) {
        layout_options = lc->get_layout_options(tbl);
        action_formats = lc->get_action_formats(tbl);
        meter_format = lc->get_attached_formats(tbl);
    }
    exact_ixbar_bytes = tbl->layout.ixbar_bytes;
    // A hash action table currently cannot be split across stages, thus if the table has
    // been previously been placed, the current stage table cannot be hash action
    if (prev_placed) {
        auto it = layout_options.begin();
        while (it != layout_options.end()) {
            if (it->layout.hash_action)
                it = layout_options.erase(it);
            else
                it++;
        }
    }

    determine_initial_layout_option(tbl, entries, attached_entries, table_placement);
    // FIXME: This is a quick hack to handle tables with only a default action
}

bool StageUseEstimate::adjust_choices(const IR::MAU::Table *tbl, int &entries,
                                      attached_entries_t &attached_entries) {
    if (tbl->gateway_only() || tbl->layout.no_match_data())
        return false;

    if (tbl->layout.ternary) {
        preferred_index++;
        if (preferred_index == layout_options.size())
            return false;
        return true;
    }

    // A hash action table cannot be split, without adding a PHV.  Thus it is just removed
    if (layout_options[preferred_index].layout.hash_action) {
        layout_options.erase(layout_options.begin() + preferred_index);
        if (layout_options.size() == 0)
            return false;
    } else if (layout_options[preferred_index].previously_widened) {
        return false;
    } else {
        layout_options[preferred_index].way.width++;
        layout_options[preferred_index].previously_widened = true;
    }


    for (auto &lo : layout_options) {
        lo.clear_mems();
    }
    determine_initial_layout_option(tbl, entries, attached_entries, false);
    return true;
}

int StageUseEstimate::stages_required() const {
    return std::max({(srams + StageUse::MAX_SRAMS - 1) / StageUse::MAX_SRAMS,
                    (tcams + StageUse::MAX_TCAMS - 1) / StageUse::MAX_TCAMS,
                    (maprams + StageUse::MAX_MAPRAMS - 1) / StageUse::MAX_MAPRAMS});
}

/* Given a number of available srams within a stage, calculate the maximum size
   different layout options can be while still using up to the number of srams */
bool StageUseEstimate::calculate_for_leftover_srams(const IR::MAU::Table *tbl, int srams_left,
                                        int &entries, attached_entries_t &attached_entries) {
    // Remove the hash action layout option
    auto it = layout_options.begin();
    while (it != layout_options.end()) {
        if (it->layout.hash_action)
            it = layout_options.erase(it);
        else
            it++;
    }

    if (layout_options.size() == 0)
        return false;

    for (auto &lo : layout_options) {
        lo.clear_mems();
        known_srams_needed(tbl, attached_entries, &lo);
        unknown_srams_needed(tbl, &lo, srams_left);
    }
    srams_left_best_option(srams_left);
    fill_estimate_from_option(entries);
    return true;
}

/* Given a number of available tcams/srams within a stage, calculate the maximum size of different
   layout options that can with the available resources */
void StageUseEstimate::calculate_for_leftover_tcams(const IR::MAU::Table *tbl, int tcams_left,
                        int srams_left, int &entries, attached_entries_t &attached_entries) {
    for (auto &lo : layout_options) {
        lo.clear_mems();
        known_srams_needed(tbl, attached_entries, &lo);
        unknown_tcams_needed(tbl, &lo, tcams_left, srams_left);
    }
    tcams_left_best_option();
    fill_estimate_from_option(entries);
}

void StageUseEstimate::calculate_for_leftover_atcams(const IR::MAU::Table *tbl, int srams_left,
                                 int &entries, attached_entries_t &attached_entries) {
    for (auto &lo : layout_options) {
        lo.clear_mems();
        known_srams_needed(tbl, attached_entries, &lo);
        unknown_atcams_needed(tbl, &lo, srams_left);
    }
    srams_left_best_option(srams_left);
    fill_estimate_from_option(entries);
}

/* Calculates the number of resources needed by the attached tables that are independent
   of the size of table, such as indirect counters, action profiles, etc.*/
void StageUseEstimate::known_srams_needed(const IR::MAU::Table *tbl,
                                          const attached_entries_t &att_entries,
                                          LayoutOption *lo) {
    for (auto back_at : tbl->attached) {
         auto at = back_at->attached;
         if (at->direct || !att_entries.count(at)) continue;
         int attached_entries = att_entries.at(at);
         if (attached_entries == 0) continue;
         int per_word = 0;
         int width = 1;
         bool need_maprams = false;
         if (auto *ctr = at->to<IR::MAU::Counter>()) {
            per_word = CounterPerWord(ctr);
            need_maprams = true;
        } else if (at->is<IR::MAU::Meter>()) {
            per_word = 1;
            need_maprams = true;
        } else if (auto *reg = at->to<IR::MAU::StatefulAlu>()) {
            per_word = RegisterPerWord(reg);
            need_maprams = true;
        } else if (at->is<IR::MAU::ActionData>()) {
            // Because this is called before and after table placement
            per_word = ActionDataPerWord(&lo->layout, &width);
        } else if (at->is<IR::MAU::Selector>()) {
            // TODO(cdodd)
        } else if (at->is<IR::MAU::TernaryIndirect>()) {
            // Again, because this is called before and after table placement
            continue;
        } else if (at->is<IR::MAU::IdleTime>()) {
            continue;
        } else {
            BUG("Unrecognized table type");
        }
        if (per_word > 0) {
            if (attached_entries <= 0)
                BUG("%s: no size in indirect %s %s", at->srcInfo, at->kind(), at->name);
            int entries_per_sram = 1024 * per_word;
            int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
            lo->srams += units * width;
            if (need_maprams) lo->maprams += units;
        }
    }
}

/* Calculate the RAM_counter for each attached table.  This contains the entries per_row,
   the width, and the need of maprams */
void StageUseEstimate::calculate_per_row_vector(safe_vector<RAM_counter> &per_word_and_width,
                                                const IR::MAU::Table *tbl,
                                                LayoutOption *lo) {
    for (auto back_at : tbl->attached) {
         auto at = back_at->attached;
         if (!at->direct) continue;
         int per_word = 0;
         int width = 1;
         bool need_srams = true;
         bool need_maprams = false;
         if (auto *ctr = at->to<IR::MAU::Counter>()) {
             per_word = CounterPerWord(ctr);
             need_maprams = true;;
         } else if (at->is<IR::MAU::Meter>()) {
             per_word = 1;
             need_maprams = true;
         } else if (auto *reg = at->to<IR::MAU::StatefulAlu>()) {
             per_word = RegisterPerWord(reg);
             need_maprams = true;
         } else if (auto ad = at->to<IR::MAU::ActionData>()) {
             BUG_CHECK(!ad->direct, "Cannot have an action data table before table placement");
             continue;
         } else if (at->is<IR::MAU::Selector>()) {
             continue;
         } else if (auto *idle = at->to<IR::MAU::IdleTime>()) {
             per_word = IdleTimePerWord(idle);
             need_srams = false;
             need_maprams = true;
         } else {
             BUG("Unrecognized table type");
         }
         per_word_and_width.emplace_back(per_word, width, need_srams, need_maprams);
    }
    if (lo->layout.direct_ad_required()) {
        int width = 1;
        int per_word = ActionDataPerWord(&lo->layout, &width);
        per_word_and_width.emplace_back(per_word, width, true, false);
    }

    if (lo->layout.ternary_indirect_required()) {
        int width = 1;
        int per_word = TernaryIndirectPerWord(&lo->layout, tbl);
        per_word_and_width.emplace_back(per_word, width, true, false);
    }
}

/* Estimate the number of srams on a layout option, gradually growing the srams array
   size and then calculating the corresponding necessary attached rams that are related
   to the number of entries from the srams */
void StageUseEstimate::unknown_srams_needed(const IR::MAU::Table *tbl, LayoutOption *lo,
                                            int srams_left) {
    safe_vector<RAM_counter> per_word_and_width;
    calculate_per_row_vector(per_word_and_width, tbl, lo);

    // Shrink the available srams by the number of known srams needed
    int available_srams = srams_left - lo->srams;
    int used_srams = 0; int used_maprams = 0;
    int adding_entries = 0;
    int depth = 0;

    while (true) {
        int attempted_depth = depth + 1;
        int sram_count = 0;
        int mapram_count = 0;
        int attempted_entries = lo->way.match_groups * 1024 * attempted_depth;
        sram_count += attempted_entries / (lo->way.match_groups * 1024) * lo->way.width;
        for (auto rc : per_word_and_width) {
            int entries_per_sram = 1024 * rc.per_word;
            int units = (attempted_entries + entries_per_sram - 1) / entries_per_sram;
            if (rc.need_srams)
                sram_count += units * rc.width;
            if (rc.need_maprams)
                mapram_count += units;
        }

        if (sram_count > available_srams) break;
        depth = attempted_depth;
        adding_entries = attempted_entries;
        used_srams = sram_count;
        used_maprams = mapram_count;
    }

    int depth_test = depth;

    if (adding_entries > 0)
        calculate_way_sizes(tbl, lo, depth_test);

    if (depth_test != depth) {
        int attempted_entries = lo->way.match_groups * 1024 * depth_test;
        int sram_count = attempted_entries / (lo->way.match_groups * 1024) * lo->way.width;
        int mapram_count = 0;
        for (auto rc : per_word_and_width) {
            int entries_per_sram = 1024 * rc.per_word;
            int units = (attempted_entries + entries_per_sram - 1) / entries_per_sram;
            if (rc.need_srams)
                sram_count += units * rc.width;
            if (rc.need_maprams)
                mapram_count += units;
        }
        used_srams = sram_count;
        adding_entries = attempted_entries;
        used_maprams = mapram_count;
    }
    lo->srams += used_srams;
    lo->maprams += used_maprams;
    lo->entries = adding_entries;
}

/** Given a number of srams, calculate the size of the possible atcam table, given the
 *  layout option.  It is different than normal SRAMs, because the algorithm has to grow all
 *  ways simultaneously.
 */
void StageUseEstimate::unknown_atcams_needed(const IR::MAU::Table *tbl, LayoutOption *lo,
                                             int srams_left) {
    safe_vector<RAM_counter> per_word_and_width;
    calculate_per_row_vector(per_word_and_width, tbl, lo);

    int available_srams = srams_left - lo->srams;
    int used_srams = 0; int used_maprams = 0;
    int adding_entries = 0;
    int depth = 0;
    int ways_per_partition = (tbl->layout.partition_count + 1023) / 1024;

    lo->way_sizes.push_back(ways_per_partition);

    while (true) {
        int attempted_depth = depth + 1;
        int sram_count = 0;
        int mapram_count = 0;
        int atcam_srams = attempted_depth * ways_per_partition;
        int attempted_entries = atcam_srams * lo->way.match_groups * 1024;
        sram_count += atcam_srams * lo->way.width;

        for (auto rc : per_word_and_width) {
            int entries_per_sram = 1024 * rc.per_word;
            int units = (attempted_entries + entries_per_sram - 1) / entries_per_sram;
            if (rc.need_srams)
                sram_count += units * rc.width;
            if (rc.need_maprams)
                mapram_count += units;
        }

        if (sram_count > available_srams) break;
        depth = attempted_depth;
        adding_entries = attempted_entries;
        used_srams = sram_count;
        used_maprams = mapram_count;
    }
    lo->srams += used_srams;
    lo->maprams += used_maprams;
    lo->entries = adding_entries;

    calculate_partition_sizes(lo, depth);
}

/* Sorting the layout options in terms of best fit for the given number of resources left
*/
void StageUseEstimate::srams_left_best_option(int srams_left) {
    std::sort(layout_options.begin(), layout_options.end(),
        [=](const LayoutOption &a, const LayoutOption &b) {
        int t;

        bool wide = a.way.match_groups < a.way.width && b.way.match_groups < b.way.width;
        bool skinny = a.way.match_groups >= a.way.width && b.way.match_groups >= b.way.width;
        skinny &= !a.layout.hash_action && !b.layout.hash_action;
        int a_mod = 0;  int b_mod = 0;

        if (wide) {
           a_mod = a.way.width % a.way.match_groups;
           b_mod = b.way.width % b.way.match_groups;
        } else if (skinny) {
           a_mod = a.way.match_groups % a.way.width;
           b_mod = b.way.match_groups % b.way.width;
        }

        if (a_mod == 0 && b_mod != 0)
            if (b.way.width > 2)
                return true;
        if (b_mod == 0 && a_mod != 0)
            if (a.way.width > 2)
                return false;

        if (a.srams > srams_left && b.srams <= srams_left)
            return false;
        if (b.srams > srams_left && a.srams <= srams_left)
            return true;
        if ((t = a.way.width - b.way.width) != 0) return t < 0;
        if ((t = a.entries - b.entries) != 0) return t > 0;
        if ((t = a.way.match_groups - b.way.match_groups) != 0) return t < 0;
        if (!a.layout.direct_ad_required() && b.layout.direct_ad_required())
            return true;
        if (a.layout.direct_ad_required() && !b.layout.direct_ad_required())
            return false;
        return a.layout.action_data_bytes_in_table < b.layout.action_data_bytes_in_table;
    });
    for (auto &lo : layout_options) {
        LOG3("layout option width " << lo.way.width << " match groups " << lo.way.match_groups
              << " entries " << lo.entries << " srams " << lo.srams
              << " action data " << lo.layout.action_data_bytes_in_table
              << " immediate " << lo.layout.immediate_bits);
        LOG3("Layout option way sizes " << lo.way_sizes);
    }
    preferred_index = 0;
}

/* Calculate the relative size of the different ternary layout options by slowly increasing
   the number of entries until the available tcams or srams are full */
void StageUseEstimate::unknown_tcams_needed(const IR::MAU::Table *tbl, LayoutOption *lo,
                                            int tcams_left, int srams_left) {
    safe_vector<RAM_counter> per_word_and_width;
    calculate_per_row_vector(per_word_and_width, tbl, lo);

    int available_srams = srams_left - lo->srams;
    int available_tcams = tcams_left;
    int adding_entries = 0;
    int used_srams = 0; int used_maprams = 0; int used_tcams = 0;
    int depth = 0;

    while (true) {
        int attempted_depth = depth + 1;
        int sram_count = 0; int mapram_count = 0; int tcam_count = 0;
        int attempted_entries = attempted_depth * 512;
        int width = (tbl->layout.match_width_bits + 47)/44;  // +4 bits for v/v, round up
        tcam_count += attempted_depth * width;

        for (auto rc : per_word_and_width) {
            int entries_per_sram = 1024 * rc.per_word;
            int units = (attempted_entries + entries_per_sram - 1) / entries_per_sram;
            if (rc.need_srams)
                sram_count += units * rc.width;
            if (rc.need_maprams)
                mapram_count += units;
        }

        if (sram_count > available_srams || tcam_count > available_tcams) break;
        depth = attempted_depth;
        adding_entries = attempted_entries;
        used_srams = sram_count;
        used_maprams = mapram_count;
        used_tcams = tcam_count;
    }
    lo->srams += used_srams;
    lo->maprams += used_maprams;
    lo->tcams += used_tcams;
    lo->entries = adding_entries;
}

/* Pick the best ternary option given that the ternary options are selecting from the
   available resources provided */
void StageUseEstimate::tcams_left_best_option() {
    std::sort(layout_options.begin(), layout_options.end(),
        [=](const LayoutOption &a, const LayoutOption &b) {
        int t;
        if ((t = a.entries - b.entries) != 0) return t > 0;
        if ((t = a.srams - b.srams) != 0) return t < 0;
        if (!a.layout.ternary_indirect_required()) return true;
        if (!b.layout.ternary_indirect_required()) return false;
        if (!a.layout.direct_ad_required()) return true;
        if (!b.layout.direct_ad_required()) return false;
        return a.entries < b.entries;
    });
    preferred_index = 0;

    for (auto &lo : layout_options) {
        LOG3("entries " << lo.entries << " srams " << lo.srams << " tcams " << lo.tcams
              << " action data " << lo.layout.action_data_bytes_in_table
              << " immediate " << lo.layout.immediate_bits
              << " ternary indirect " << lo.layout.ternary_indirect_required());
    }
}

/** This pass calculates the number of lines an individual range match will take.  In order
 *  to perform a range match in Tofino, multiple lines of a TCAM may be necessary.  This is
 *  described in section 6.3.12 DirtCAM Example.  Essentially a larger range is broken into
 *  several smaller ranges that the hardware is capable of matching, which occur in factors
 *  of 16, as ranges are matched on a nibble by nibble basis, and 2^4 = 16.
 *
 *  The maximum number of rows that could be required by a range match is 2 * (nibbles involved
 *  in range match) - 1.  Let's look at a 12 bit range example 2 <= x <= 600
 *
 *  _____small_range_____|__nib_11_8__|__nib_7_4__|__nib_3_0__
 *      2 <= x <= 15     |      0     |     0     |  [2:15]
 *     16 <= x <= 255    |      0     |   [1:15]  |    X
 *    256 <= x <= 511    |      1     |     X     |    X
 *    512 <= x <= 591    |      2     |   [1:4]   |    X
 *    592 <= x <= 600    |      2     |     5     |  [1:8]
 *
 *  Calculations for these smaller ranges are done based on the factors within these
 *  individual ranges for nibbles.  The 4b_encoding provides a way to match a nibble to any
 *  combination of numbers between 0-15.  However, note that not all range need all rows.
 *
 *  The hardware to provide matching across TCAM rows is called the Multirange Distributor,
 *  described in section 6.3.9.2 of the uArch.  The distribution can combine the match signals,
 *  of nearby rows, in a 3 step process.  The first step can combine a signal in either the
 *  higher or lower row, the seocnd step can combine a row 2 rows away, and the third can combine
 *  a signal from 4 rows away, for a maximum distribution limit of 8 rows.  Thus the total rows
 *  is the max of the previous formula and 8.
 */
bool RangeEntries::preorder(const IR::MAU::TableKey *ixbar_read) {
    if (ixbar_read->match_type.name != "range")
        return false;

    le_bitrange bits = { 0, 0 };
    auto field = phv.field(ixbar_read->expr, &bits);

    auto tbl = findContext<IR::MAU::Table>();

    int range_nibbles = 0;
    PHV::FieldUse use(PHV::FieldUse::READ);
    field->foreach_byte(bits, tbl, &use, [&](const PHV::Field::alloc_slice &sl) {
        if ((sl.container_bit % 8) < 4)
            range_nibbles++;
        if ((sl.container_hi() % 8) > 3)
            range_nibbles++;
    });

    // FIXME: This is a limitation from Glass where glass requires all range matches to be on an
    // individual TCAM.  After looking at the hardware requirements and talking to the driver
    // team, I'm not sure if this constraint actually exists.  Will have to be verified by
    // packet testing.  Currently the input xbar algorithm ignores this constraint
    ERROR_CHECK(range_nibbles <= IXBar::TERNARY_BYTES_PER_GROUP, "%s: Currently in p4c, the table "
                "%s cannot perform a range match on key %s as the key does not fit in under 5 "
                "PHV nibbles", ixbar_read->srcInfo, tbl->name, field->name);
    int range_lines_needed = 2 * range_nibbles - 1;
    range_lines_needed = std::min(MULTIRANGE_DISTRIBUTION_LIMIT, range_lines_needed);
    max_entry_TCAM_lines = std::max(range_lines_needed, max_entry_TCAM_lines);
    return false;
}

/** Because a range entry requires a lot of extra TCAM rows, and either not every range requires
 *  the maximum number of rows, or no range match at all, the programmer can provide a pragma
 *  to limit the number of rows.
 */
void RangeEntries::postorder(const IR::MAU::Table *tbl) {
    auto annot = tbl->match_table->getAnnotations();
    int range_entries = -1;
    if (auto s = annot->getSingle("entries_with_ranges")) {
        const IR::Constant *pragma_val = nullptr;
        if (s->expr.size() == 0) {
            ::error("%s: entries_with_ranges pragma on table %s has no value", s->srcInfo,
                    tbl->name);
        } else {
            pragma_val = s->expr.at(0)->to<IR::Constant>();
            ERROR_CHECK(pragma_val != nullptr, "%s: the value for the entries_with_ranges "
                        "pragma on table %s is not a constant", s->srcInfo, tbl->name);
        }
        if (pragma_val) {
            int pragma_range_entries = pragma_val->asInt();
            WARN_CHECK(pragma_range_entries > 0, "%s: The value for pragma entries_with_ranges "
                       "on table %s is %d, which is invalid and will be ignored", s->srcInfo,
                        tbl->name, pragma_range_entries);
            WARN_CHECK(pragma_range_entries <= table_entries, "%s: The value for pragma "
                       "entries_with_ranges on table %s is %d, which is greater than the "
                       "entries provided for the table %d, and thus will be shrunk to that size",
                       s->srcInfo, tbl->name, pragma_range_entries, table_entries);
            if (pragma_range_entries > 0)
                range_entries = std::min(pragma_range_entries, table_entries);
        }
    }
    if (range_entries < 0) {
        range_entries = (table_entries * RANGE_ENTRY_PERCENTAGE) / 100;
    }
    total_TCAM_lines = range_entries * max_entry_TCAM_lines + (table_entries - range_entries);
}

std::ostream &operator<<(std::ostream &out, const StageUseEstimate &sue) {
    out << "{ id=" << sue.logical_ids << " ram=" << sue.srams << " tcam=" << sue.tcams
        << " mram=" << sue.maprams << " eixb=" << sue.exact_ixbar_bytes
        << " tixb=" << sue.ternary_ixbar_groups << " malu=" << sue.meter_alus
        << " salu=" << sue.stats_alus << " }";
    return out;
}
