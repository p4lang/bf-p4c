#include "resource_estimate.h"
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
    if (layout->action_data_bytes > 0)
        size = ceil_log2(layout->action_data_bytes);
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

/* Calculates the individual way sizes, given a total depth, i.e. 24 will become
   4 4 4 4 4 4 */
void StageUseEstimate::calculate_way_sizes(LayoutOption *lo,
                                           int &calculated_depth) {
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
void StageUseEstimate::options_to_ways(int &entries) {
    for (auto &lo : layout_options) {
        int per_row = lo.way.match_groups;
        int total_depth = (entries + per_row * 1024 - 1) / (per_row * 1024);
        int calculated_depth = total_depth;
        calculate_way_sizes(&lo, calculated_depth);
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
            if (prev_placed && has_action_data != a.layout.direct_ad_required()) return false;
            if (prev_placed && has_action_data != b.layout.direct_ad_required()) return true;
            if ((t = a.way.match_groups % a.way.width) != 0) return false;
            if ((t = b.way.match_groups % b.way.width) != 0) return true;
            if ((t = a.srams - b.srams) != 0) return t < 0;
            if ((t = a.way.width - b.way.width) != 0) return t < 0;
            if ((t = a.way.match_groups - b.way.match_groups) != 0) return t < 0;
            if (!a.layout.direct_ad_required()) return true;
            if (!b.layout.direct_ad_required()) return false;
            return true;
        });
    } else {
        std::sort(layout_options.begin(), layout_options.end(),
            [=](const LayoutOption a, const LayoutOption b) {
            int t;
            // The first two lines are to prevent sharing a group across multiple widths,
            // as the asm doesn't yet handle this
            if (prev_placed && has_action_data != a.layout.direct_ad_required()) return false;
            if (prev_placed && has_action_data != b.layout.direct_ad_required()) return true;
            if ((t = a.way.match_groups % a.way.width) != 0) return false;
            if ((t = b.way.match_groups % b.way.width) != 0) return true;
            if ((t = a.srams - b.srams) != 0) return t < 0;
            if ((t = a.way.width - b.way.width) != 0) return t < 0;
            if ((t = a.way.match_groups - b.way.match_groups) != 0) return t > 0;
            if (!a.layout.direct_ad_required()) return true;
            if (!b.layout.direct_ad_required()) return false;
            return true;
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
        if (prev_placed && has_action_data != a.layout.direct_ad_required()) return false;
        if (prev_placed && has_action_data != b.layout.direct_ad_required()) return true;
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
StageUseEstimate::StageUseEstimate(const IR::MAU::Table *tbl, int &entries, bool pp, bool had,
                                   const safe_vector<LayoutOption> &lo, bool table_placement) {
    // Because the table is const, the layout options must be copied into the Object
    memset(this, 0, sizeof(*this));
    prev_placed = pp;
    has_action_data = had;
    logical_ids = 1;
    layout_options.clear();
    layout_options = lo;
    exact_ixbar_bytes = tbl->layout.ixbar_bytes;
    // FIXME: This is a quick hack to handle tables with only a default action
    if (layout_options.size() == 1 && layout_options[0].layout.no_match_data()) {
        entries = 512;
        preferred_index = 0;
    } else if (tbl->layout.ternary) {  // ternary
        options_to_ternary_entries(tbl, entries);
        options_to_rams(tbl, table_placement);
        select_best_option_ternary();
        fill_estimate_from_option(entries);
    } else if (!tbl->gateway_only()) {  // exact_match
        /* assuming all ways have the same format and width (only differ in depth) */
        options_to_ways(entries);
        options_to_rams(tbl, table_placement);
        select_best_option(tbl);
        fill_estimate_from_option(entries);
    } else {  // gw
        entries = 0;
    }
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
    srams_left_best_option();
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
        calculate_way_sizes(lo, depth_test);

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

/* Sorting the layout options in terms of best fit for the given number of resources left
*/
void StageUseEstimate::srams_left_best_option() {
    std::sort(layout_options.begin(), layout_options.end(),
        [=](const LayoutOption &a, const LayoutOption &b) {
        int t;
        if (prev_placed && has_action_data != a.layout.direct_ad_required()) return false;
        if (prev_placed && has_action_data != b.layout.direct_ad_required()) return true;
        if ((t = a.way.match_groups % a.way.width) != 0) return false;
        if ((t = b.way.match_groups % b.way.width) != 0) return true;
        if ((t = a.entries - b.entries) != 0) return t > 0;
        if ((t = a.way.width - b.way.width) != 0) return t < 0;
        if (!a.layout.direct_ad_required()) return true;
        if (!b.layout.direct_ad_required()) return false;
        return true;
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
        if (prev_placed && has_action_data != a.layout.direct_ad_required()) return false;
        if (prev_placed && has_action_data != b.layout.direct_ad_required()) return true;
        if ((t = a.entries - b.entries) != 0) return t > 0;
        if ((t = a.srams - b.srams) != 0) return t < 0;
        if (!a.layout.ternary_indirect_required()) return true;
        if (!b.layout.ternary_indirect_required()) return false;
        if (!a.layout.direct_ad_required()) return true;
        if (!b.layout.direct_ad_required()) return false;
        return true;
    });
    preferred_index = 0;

    for (auto &lo : layout_options) {
        LOG3("entries " << lo.entries << " srams " << lo.srams << " tcams " << lo.tcams
              << " action data " << lo.layout.direct_ad_required()
              << " ternary indirect " << lo.layout.ternary_indirect_required());
    }
}

