#include "resource_estimate.h"
#include "memories.h"
#include "lib/bitops.h"

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
        if (ctr->min_width <= 64) return 2;
        if (ctr->min_width > 128)
            error("%s: Maximum width for counter %s is 128 bits", ctr->srcInfo, ctr->name);
        return 1;
    default:
        error("%s: No counter type for %s", ctr->srcInfo, ctr->name);
        return 1; }
}

int RegisterPerWord(const IR::MAU::StatefulAlu *reg) {
    if (reg->width <= 0)
        warning("%s: No width in register %s, using 8", reg->srcInfo, reg->name);
    if (reg->width == 1) return 128;
    if (reg->width <= 8) return 16;
    if (reg->width <= 16) return 8;
    if (reg->width <= 32) return 4;
    if (reg->width > 64)
        error("%s: Maximum width for register %s is 64 bits", reg->srcInfo, reg->name);
    return 2;
}

int ActionDataPerWord(const IR::MAU::Table::Layout *layout, int *width) {
    int size = 0;
    if (layout->action_data_bytes_in_table > 0)
        size = ceil_log2(layout->action_data_bytes_in_table);
    if (size > 4) {
        *width = 1 << (size-4);
        return 1; }
    return 16 >> size;
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

bool StageUseEstimate::ways_provided(const IR::MAU::Table *tbl, LayoutOption *lo,
                                     int &calculated_depth) {
    int way_total = -1;
    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("ways")) {
        ERROR_CHECK(s->expr.size() >= 1, "%s: The ways pragma on table %s does not have a "
                    "value", tbl->srcInfo, tbl->name);
        auto pragma_val =  s->expr.at(0)->to<IR::Constant>();
        if (pragma_val == nullptr) {
            ::error("%s: The ways pragma value on table %s is not a constant", tbl->srcInfo,
                  tbl->name);
            return false;
        }
        way_total = pragma_val->asInt();
        if (way_total < MIN_WAYS || way_total > MAX_WAYS) {
            ::warning("%s: The ways pragma value on table %s is not between %d and %d, and "
                      "will be ignored", tbl->srcInfo, tbl->name, MIN_WAYS, MAX_WAYS);
            way_total = -1;
        }
    }
    if (way_total == -1)
        return false;

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

    if (lo->layout.match_width_bits <= ceil_log2(Memories::SRAM_DEPTH)) {
        if (calculated_depth == 1) {
            lo->way_sizes = {1};
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
void StageUseEstimate::options_to_ways(const IR::MAU::Table *tbl, int &entries) {
    for (auto &lo : layout_options) {
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
void StageUseEstimate::options_to_ternary_entries(const IR::MAU::Table *tbl, int &entries) {
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
void StageUseEstimate::options_to_atcam_entries(const IR::MAU::Table *tbl, int &entries) {
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
                     * Memories::SRAM_DEPTH;
    }
}

/* Calculate the number of rams required for attached tables, given the number of entries
   provided from the table placment */
void StageUseEstimate::calculate_attached_rams(const IR::MAU::Table *tbl,
                                               LayoutOption *lo,
                                               bool table_placement) {
    for (auto at : tbl->attached) {
        int per_word = 0;
        int width = 1;
        int attached_entries = lo->entries;
        bool need_srams = true;
        bool need_maprams = false;
        if (auto *ctr = at->to<IR::MAU::Counter>()) {
            per_word = CounterPerWord(ctr);
            if (!ctr->direct) attached_entries = ctr->size;
            need_maprams = true;
        } else if (auto *mtr = at->to<IR::MAU::Meter>()) {
            per_word = 1;
            if (!mtr->direct) attached_entries = mtr->size;
            need_maprams = true;
        } else if (auto *reg = at->to<IR::MAU::StatefulAlu>()) {
            per_word = RegisterPerWord(reg);
            if (!reg->direct) attached_entries = reg->size;
            need_maprams = true;
        } else if (auto *ad = at->to<IR::MAU::ActionData>()) {
            // FIXME: in theory, the table should not have an action data table,
            // as that is decided after the table layout is picked
            if (!table_placement && ad->direct)
                BUG("Direct Action Data table exists before table placement occurs");
            if (shared_action_data.find(ad) != shared_action_data.end())
                continue;
            width = 1;
            per_word = ActionDataPerWord(&lo->layout, &width);
            if (!ad->direct)
                attached_entries = ad->size;
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
void StageUseEstimate::options_to_rams(const IR::MAU::Table *tbl, bool table_placement) {
    for (auto &lo : layout_options) {
        calculate_attached_rams(tbl, &lo, table_placement);
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

    if (small_table_allocation) {
        std::sort(layout_options.begin(), layout_options.end(),
            [=](const LayoutOption &a, const LayoutOption &b) {
            int t;
            // The first two lines are to prevent sharing a group across multiple widths,
            // as the asm doesn't yet handle this
            if ((t = a.way.match_groups % a.way.width) != 0) return false;
            if ((t = b.way.match_groups % b.way.width) != 0) return true;
            if ((t = a.srams - b.srams) != 0) return t < 0;
            if ((t = a.way.width - b.way.width) != 0) return t < 0;
            if ((t = a.way.match_groups - b.way.match_groups) != 0) return t < 0;
            if (!a.layout.direct_ad_required()) return true;
            if (!b.layout.direct_ad_required()) return false;
            return a.srams < b.srams;
        });
    } else {
        std::sort(layout_options.begin(), layout_options.end(),
            [=](const LayoutOption &a, const LayoutOption &b) {
            int t;
            // The first two lines are to prevent sharing a group across multiple widths,
            // as the asm doesn't yet handle this
            if ((t = a.way.match_groups % a.way.width) != 0) return false;
            if ((t = b.way.match_groups % b.way.width) != 0) return true;
            if ((t = a.srams - b.srams) != 0) return t < 0;
            if ((t = a.way.width - b.way.width) != 0) return t < 0;
            if ((t = a.way.match_groups - b.way.match_groups) != 0) return t > 0;
            if (!a.layout.direct_ad_required()) return true;
            if (!b.layout.direct_ad_required()) return false;
            return a.srams < b.srams;
        });
    }
    LOG3("table " << tbl->name << " requiring " << table_size << " entries.");
    if (small_table_allocation)
        LOG3("small table allocation");
    else
        LOG3("large table allocation");
    for (auto &lo : layout_options) {
        LOG3("layout option width " << lo.way.width << " match groups " << lo.way.match_groups
              << " entries " << lo.entries << " srams " << lo.srams
              << " action data " << lo.layout.direct_ad_required());
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
              << " action data " << lo.layout.direct_ad_required()
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

/* Constructor to estimate the number of srams, tcams, and maprams a table will require*/
StageUseEstimate::StageUseEstimate(const IR::MAU::Table *tbl, int &entries,
                                   const LayoutChoices *lc,
                                   ordered_set<const IR::MAU::ActionData *> sad /* Defaulted */,
                                   bool table_placement)
    : shared_action_data(sad) {
    // Because the table is const, the layout options must be copied into the Object
    logical_ids = 1;
    layout_options.clear();
    layout_options = lc->get_layout_options(tbl);
    action_formats = lc->get_action_formats(tbl);
    exact_ixbar_bytes = tbl->layout.ixbar_bytes;
    // FIXME: This is a quick hack to handle tables with only a default action
    if (layout_options.size() == 1 && layout_options[0].layout.no_match_data()) {
        entries = 512;
        preferred_index = 0;
    } else if (tbl->layout.atcam) {
        options_to_atcam_entries(tbl, entries);
        options_to_rams(tbl, table_placement);
        select_best_option(tbl);
        fill_estimate_from_option(entries);
    } else if (tbl->layout.ternary) {  // ternary
        options_to_ternary_entries(tbl, entries);
        options_to_rams(tbl, table_placement);
        select_best_option_ternary();
        fill_estimate_from_option(entries);
    } else if (!tbl->gateway_only()) {  // exact_match
        /* assuming all ways have the same format and width (only differ in depth) */
        options_to_ways(tbl, entries);
        options_to_rams(tbl, table_placement);
        select_best_option(tbl);
        fill_estimate_from_option(entries);
    } else {  // gw
        entries = 0;
    }
}

int StageUseEstimate::stages_required() const {
    return std::max({(srams + StageUse::MAX_SRAMS - 1) / StageUse::MAX_SRAMS,
                    (tcams + StageUse::MAX_TCAMS - 1) / StageUse::MAX_TCAMS,
                    (maprams + StageUse::MAX_MAPRAMS - 1) / StageUse::MAX_MAPRAMS});
}

/* Given a number of available srams within a stage, calculate the maximum size
   different layout options can be while still using up to the number of srams */
void StageUseEstimate::calculate_for_leftover_srams(const IR::MAU::Table *tbl, int srams_left,
                                                    int &entries) {
    for (auto &lo : layout_options) {
        lo.clear_mems();
        known_srams_needed(tbl, &lo);
        unknown_srams_needed(tbl, &lo, srams_left);
    }
    srams_left_best_option(srams_left);
    fill_estimate_from_option(entries);
}

/* Given a number of available tcams/srams within a stage, calculate the maximum size of different
   layout options that can with the available resources */
void StageUseEstimate::calculate_for_leftover_tcams(const IR::MAU::Table *tbl, int tcams_left,
                                                    int srams_left, int &entries) {
    for (auto &lo : layout_options) {
        lo.clear_mems();
        known_srams_needed(tbl, &lo);
        unknown_tcams_needed(tbl, &lo, tcams_left, srams_left);
    }
    tcams_left_best_option();
    fill_estimate_from_option(entries);
}

void StageUseEstimate::calculate_for_leftover_atcams(const IR::MAU::Table *tbl, int srams_left,
                                                     int &entries) {
    for (auto &lo : layout_options) {
        lo.clear_mems();
        known_srams_needed(tbl, &lo);
        unknown_atcams_needed(tbl, &lo, srams_left);
    }
    srams_left_best_option(srams_left);
    fill_estimate_from_option(entries);
}

/* Calculates the number of resources needed by the attached tables that are independent
   of the size of table, such as indirect counters, action profiles, etc.*/
void StageUseEstimate::known_srams_needed(const IR::MAU::Table *tbl,
                                          LayoutOption *lo) {
    for (auto at : tbl->attached) {
         int attached_entries = 0;
         int per_word = 0;
         int width = 1;
         bool need_maprams = false;
         if (auto *ctr = at->to<IR::MAU::Counter>()) {
            if (ctr->direct) continue;
            attached_entries  = ctr->size;
            per_word = CounterPerWord(ctr);
            need_maprams = true;
        } else if (auto *mtr = at->to<IR::MAU::Meter>()) {
            if (mtr->direct) continue;
            per_word = 1;
            attached_entries = mtr->size;
            need_maprams = true;
        } else if (auto *reg = at->to<IR::MAU::StatefulAlu>()) {
            if (reg->direct) continue;
            per_word = RegisterPerWord(reg);
            attached_entries = reg->size;
            need_maprams = true;
        } else if (auto *ad = at->to<IR::MAU::ActionData>()) {
            // Because this is called before and after table placement
            if (ad->direct) continue;
            if (shared_action_data.find(ad) != shared_action_data.end()) continue;
            per_word = ActionDataPerWord(&lo->layout, &width);
            attached_entries = ad->size;
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
    for (auto at : tbl->attached) {
         int per_word = 0;
         int width = 1;
         bool need_srams = true;
         bool need_maprams = false;
         if (auto *ctr = at->to<IR::MAU::Counter>()) {
             if (!ctr->direct) continue;
             per_word = CounterPerWord(ctr);
             need_maprams = true;;
         } else if (auto *mtr = at->to<IR::MAU::Meter>()) {
             if (!mtr->direct) continue;
             per_word = 1;
             need_maprams = true;
         } else if (auto *reg = at->to<IR::MAU::StatefulAlu>()) {
             if (!reg->direct) continue;
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
        if (a.srams > srams_left) return false;
        if (b.srams > srams_left) return true;
        if ((t = a.way.match_groups % a.way.width) != 0) return false;
        if ((t = b.way.match_groups % b.way.width) != 0) return true;
        if ((t = a.entries - b.entries) != 0) return t > 0;
        if ((t = a.way.width - b.way.width) != 0) return t < 0;
        if (!a.layout.direct_ad_required()) return true;
        if (!b.layout.direct_ad_required()) return false;
        return a.entries < b.entries;
    });
    for (auto &lo : layout_options) {
        LOG3("layout option width " << lo.way.width << " match groups " << lo.way.match_groups
              << " entries " << lo.entries << " srams " << lo.srams
              << " action data " << lo.layout.direct_ad_required());
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
              << " action data " << lo.layout.direct_ad_required()
              << " ternary indirect " << lo.layout.ternary_indirect_required());
    }
}

