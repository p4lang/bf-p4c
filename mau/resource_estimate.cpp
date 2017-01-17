#include "resource_estimate.h"
#include "lib/bitops.h"

int CounterPerWord(const IR::Counter *ctr) {
    switch (ctr->type) {
    case IR::CounterType::PACKETS:
        if (ctr->min_width <= 21) return 6;
        // fall through
    case IR::CounterType::BYTES:
        if (ctr->min_width <= 32) return 4;
        if (ctr->min_width > 64)
            error("%s: Maximum width for counter %s is 64 bits", ctr->srcInfo, ctr->name);
        return 2;
    case IR::CounterType::BOTH:
        if (ctr->min_width <= 42) return 3;
        if (ctr->min_width <= 64) return 2;
        if (ctr->min_width > 128)
            error("%s: Maximum width for counter %s is 128 bits", ctr->srcInfo, ctr->name);
        return 1;
    default:
        error("%s: No counter type for %s", ctr->srcInfo, ctr->name);
        return 1; }
}

int RegisterPerWord(const IR::Register *reg) {
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

void StageUseEstimate::calculate_way_sizes(IR::MAU::Table::LayoutOption *lo,
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
    //Cannot share a single hash group
    } else {
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

void StageUseEstimate::options_to_ways(const IR::MAU::Table *tbl, int &entries) {
    layout_options.clear();
    layout_options = tbl->layout_options;
    for (auto &lo : layout_options) {
        int per_row = lo.way->match_groups;
        int total_depth = (entries + per_row * 1024 - 1) / (per_row * 1024); 
        int calculated_depth = total_depth;
        calculate_way_sizes(&lo, calculated_depth);
        lo.entries = calculated_depth * lo.way->match_groups * 1024;
        lo.srams = calculated_depth * lo.way->width;
        lo.maprams = 0;
    }
}

void StageUseEstimate::options_to_ternary_entries(const IR::MAU::Table *tbl, int &entries) {
    layout_options.clear();
    layout_options = tbl->layout_options;
    for (auto &lo : layout_options) {
        int depth = (entries + 511u)/512u;
        int width = (tbl->layout.match_width_bits + 47)/44;  // +4 bits for v/v, round up
        lo.tcams = depth * width;
        lo.srams = 0;
        lo.entries = depth * 512;
    }
}

void StageUseEstimate::calculate_attached_rams(const IR::MAU::Table *tbl,
                                               IR::MAU::Table::LayoutOption *lo,
                                               bool table_placement) {
    for (auto at : tbl->attached) {
        int per_word = 0;
        int width = 1;
        int attached_entries = lo->entries;
        bool need_maprams = false;
        if (auto *ctr = dynamic_cast<const IR::Counter *>(at)) {
            per_word = CounterPerWord(ctr);
            if (!ctr->direct) attached_entries = ctr->instance_count;
            need_maprams = true;
        } else if (auto *mtr = dynamic_cast<const IR::Meter *>(at)) {
            per_word = 1;
            if (!mtr->direct) attached_entries = mtr->instance_count;
            need_maprams = true;
        } else if (auto *reg = dynamic_cast<const IR::Register *>(at)) {
            per_word = RegisterPerWord(reg);
            if (!reg->direct) attached_entries = reg->instance_count;
            need_maprams = true;
        } else if (auto *ap = dynamic_cast<const IR::ActionProfile *>(at)) {
            per_word = ActionDataPerWord(lo->layout, &width);
            attached_entries = ap->size;
        } else if (/*auto *ad = */dynamic_cast<const IR::MAU::ActionData *>(at)) {
            // FIXME: in theory, the table should not have an action data table,
            // as that is decided after the table layout is picked
            if (!table_placement)
                BUG("Action Data table exists before table placement occurs");
            width = 1;
            per_word = ActionDataPerWord(lo->layout, &width);
        } else if (/*auto *as = */dynamic_cast<const IR::ActionSelector *>(at)) {
            // TODO(cdodd)
        } else if (/*auto *ti = */dynamic_cast<const IR::MAU::TernaryIndirect *>(at)) {
            if (!table_placement)
                BUG("Ternary Indirect Data table exists before table placement occurs");
            per_word = TernaryIndirectPerWord(lo->layout, tbl);
        } else {
            BUG("unknown attached table type %s", at->kind()); }
        if (per_word > 0) {
            if (attached_entries <= 0)
                BUG("%s: no size in indirect %s %s", at->srcInfo, at->kind(), at->name);
            int entries_per_sram = 1024 * per_word;
            int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
            lo->srams += units * width;
            if (need_maprams) lo->maprams += units; 
        }
    }
    if (lo->action_data_required) {
        int width = 1;
        int per_word = ActionDataPerWord(lo->layout, &width);
        int attached_entries = lo->entries;
        int entries_per_sram = 1024 * per_word;
        int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
        lo->srams += units * width;
    }
    if (lo->ternary_indirect_required) {
        int per_word = TernaryIndirectPerWord(lo->layout, tbl);
        int attached_entries = lo->entries;
        int entries_per_sram = 1024 * per_word;
        int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
        lo->srams += units;
    }
}

void StageUseEstimate::options_to_rams(const IR::MAU::Table *tbl, bool table_placement) {
    for (auto &lo : layout_options) {
        calculate_attached_rams(tbl, &lo, table_placement);
    }
}


// sorting algorithm
// first check is to determine if the tbl 
// number of total rams
// closeness to the number of entries needed
void StageUseEstimate::select_best_option(const IR::MAU::Table *tbl) {
    bool small_table_allocation = true;
    for (auto lo : layout_options) {
        if (lo.entries < tbl->match_table->size) {
            small_table_allocation = false;
            break;
        }
    }

    if (small_table_allocation) {
        std::sort(layout_options.begin(), layout_options.end(),
            [=](const IR::MAU::Table::LayoutOption &a, const IR::MAU::Table::LayoutOption &b) {
            int t;
            // The next two lines are to prevent sharing a group across multiple widths,
            // as the asm doesn't yet handle this
            if ((t = a.way->match_groups % a.way->width) != 0) return false;
            if ((t = b.way->match_groups % b.way->width) != 0) return true;
            if ((t = a.srams - b.srams) != 0) return t < 0;
            if ((t = a.way->width - b.way->width) != 0) return t < 0;
            if ((t = a.way->match_groups - b.way->match_groups) != 0) return t < 0;
            if (a.action_data_required) return true;
            if (b.action_data_required) return false;
            return true;
        });
    } else {
        std::sort(layout_options.begin(), layout_options.end(),
            [=](const IR::MAU::Table::LayoutOption a, const IR::MAU::Table::LayoutOption b) {
            int t;
            if ((t = a.way->match_groups % a.way->width) != 0) return false;
            if ((t = b.way->match_groups % b.way->width) != 0) return true;
            if ((t = a.srams - b.srams) != 0) return t < 0;
            if ((t = a.way->width - b.way->width) != 0) return t < 0;
            if ((t = a.way->match_groups - b.way->match_groups) != 0) return t > 0;
            if (a.action_data_required) return true;
            if (b.action_data_required) return false;
            return true;
        });
    }
    LOG1("table " << tbl->name << " requiring " << tbl->match_table->size << " entries.");
    if (small_table_allocation)
        LOG1("small table allocation");
    else
        LOG1("large table allocation");
    for (auto &lo : layout_options) {
        LOG1("layout option width " << lo.way->width << " match groups " << lo.way->match_groups
              << " entries " << lo.entries << " srams " << lo.srams
              << " action data " << lo.action_data_required); 
        LOG1("Layout option way sizes " << lo.way_sizes);
    }

    preferred_index = 0;
}

void StageUseEstimate::select_best_option_ternary() {
    std::sort(layout_options.begin(), layout_options.end(),
        [=](const IR::MAU::Table::LayoutOption &a, const IR::MAU::Table::LayoutOption &b) {
        int t;
        if ((t = a.srams - b.srams) != 0) return t < 0;
        if (!a.ternary_indirect_required) return true;
        if (!b.ternary_indirect_required) return false;
        if (!a.action_data_required) return true;
        if (!b.action_data_required) return false;
        return false;
    });

    for (auto &lo : layout_options) {
        LOG1("entries " << lo.entries << " srams " << lo.srams << " tcams " << lo.tcams 
              << " action data " << lo.action_data_required
              << " ternary indirect " << lo.ternary_indirect_required); 
    }

    preferred_index = 0;
}

void StageUseEstimate::fill_estimate_from_option(int &entries) {
    tcams = preferred()->tcams;
    srams = preferred()->srams;
    maprams = preferred()->maprams;
    entries = preferred()->entries;
}

StageUseEstimate::StageUseEstimate(const IR::MAU::Table *tbl, int &entries, bool table_placement,
                                   bool redo) {
    // FIXME: This is wrong
    if (redo) previous_index = provided_index;
    memset(this, 0, sizeof(*this));
    logical_ids = 1;
    exact_ixbar_bytes = tbl->layout.ixbar_bytes;
    if (tbl->layout.ternary) {
        options_to_ternary_entries(tbl, entries);
        options_to_rams(tbl, table_placement);
        select_best_option_ternary();
        fill_estimate_from_option(entries);
        /*
        if (match_ixbar)
            width = match_ixbar->groups();
        */
    } else if (tbl->match_table) {
        /* assuming all ways have the same format and width (only differ in depth) */
        options_to_ways(tbl, entries);
        options_to_rams(tbl, table_placement);
        select_best_option(tbl);
        fill_estimate_from_option(entries);
    } else {
        entries = 0;
    } 
}

void StageUseEstimate::set_provided(const IR::MAU::Table::LayoutOption *a) {
    int index = 0;
    for (auto lo : layout_options) {
        if (lo.way->match_groups == a->way->match_groups &&
            lo.way->width == a->way->width &&
            lo.action_data_required == a->action_data_required &&
            lo.ternary_indirect_required == a->ternary_indirect_required) {
            provided_index = index;
            return;
        }
        index++;
    }
    BUG("Non-matching resource estimate.  Should never happen within same table");
    provided_index = -1;
}

void StageUseEstimate::known_srams_needed(const IR::MAU::Table *tbl,
                                          IR::MAU::Table::LayoutOption *lo) {
    for (auto at : tbl->attached) {
         int attached_entries = 0;
         int per_word = 0;
         int width = 1;
         bool need_maprams = false;
         if (auto *ctr = dynamic_cast<const IR::Counter *>(at)) {
            if (ctr->direct) continue;
            attached_entries  = ctr->instance_count;
            per_word = CounterPerWord(ctr);
            need_maprams = true;
        } else if (auto *mtr = dynamic_cast<const IR::Meter *>(at)) {
            if (mtr->direct) continue;
            per_word = 1;
            attached_entries = mtr->instance_count;
            need_maprams = true;
        } else if (auto *reg = dynamic_cast<const IR::Register *>(at)) {
            if (reg->direct) continue; 
            per_word = RegisterPerWord(reg);
            attached_entries = reg->instance_count;
            need_maprams = true;
        } else if (auto *ap = dynamic_cast<const IR::ActionProfile *>(at)) {
            per_word = ActionDataPerWord(lo->layout, &width);
            attached_entries = ap->size;
        } else if (/*auto *ad = */dynamic_cast<const IR::MAU::ActionData *>(at)) {
           continue;
        } else if (/*auto *as = */dynamic_cast<const IR::ActionSelector *>(at)) {
            // TODO(cdodd)
        } else if (dynamic_cast<const IR::MAU::TernaryIndirect *>(at)) {
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

void StageUseEstimate::calculate_per_row_vector(vector<RAM_counter> &per_word_and_width,
                                                const IR::MAU::Table *tbl,
                                                IR::MAU::Table::LayoutOption *lo) {
    for (auto at : tbl->attached) {
         int per_word = 0;
         int width = 1;
         bool need_maprams = false;
         if (auto *ctr = at->to<IR::Counter>()) {
             if (!ctr->direct) continue;
             per_word = CounterPerWord(ctr);
             need_maprams = true;;
         } else if (auto *mtr = at->to<IR::Meter>()) {
             if (!mtr->direct) continue;
             per_word = 1;
             need_maprams = true;
         } else if (auto *reg = at->to<IR::Register>()) {
             if (!reg->direct) continue;
             per_word = RegisterPerWord(reg);
             need_maprams = true;
         } else if (at->is<IR::ActionProfile>() || at->is<IR::ActionSelector>()) {
             continue;
         } else {
             BUG("Unrecognized table type");
         }
         per_word_and_width.emplace_back(per_word, width, need_maprams);
    }
    if (lo->action_data_required) {
        int width = 1;
        int per_word = ActionDataPerWord(lo->layout, &width);
        per_word_and_width.emplace_back(per_word, width, false);
    }
    if (lo->ternary_indirect_required) {
        int width = 1;
        int per_word = TernaryIndirectPerWord(lo->layout, tbl);
        per_word_and_width.emplace_back(per_word, width, false);
    }

}

void StageUseEstimate::unknown_srams_needed(const IR::MAU::Table *tbl,
                                            IR::MAU::Table::LayoutOption *lo,
                                            int srams_left) {
    vector<RAM_counter> per_word_and_width;
    calculate_per_row_vector(per_word_and_width, tbl, lo);

    int available_srams = srams_left - lo->srams;
    int used_srams = 0; int used_maprams = 0;
    int adding_entries = 0;
    int depth = 1;

    while (true) {
        int sram_count = 0;
        int mapram_count = 0;
        int attempted_entries = lo->way->match_groups * 1024 * depth;
        LOG1("Match groups and depth " << lo->way->match_groups << " " << depth);
        sram_count += attempted_entries / (lo->way->match_groups * 1024) * lo->way->width;
        for (auto rc : per_word_and_width) {
            int entries_per_sram = 1024 * rc.per_word;
            int units = (attempted_entries + entries_per_sram - 1) / entries_per_sram;
            sram_count += units * rc.width;
            if (rc.need_maprams)
                mapram_count += units;
        }

        if (sram_count > available_srams) break;
        depth++;
        adding_entries = attempted_entries;
        used_srams = sram_count;
        used_maprams = mapram_count;
    }

    calculate_way_sizes(lo, depth);
    lo->srams += used_srams;
    lo->maprams += used_maprams;
    lo->entries = adding_entries;
    LOG1("Entries is " << adding_entries << " for layout option " << lo->way->match_groups
          << " " << lo->way->width << " with depth " << depth);
}

void StageUseEstimate::srams_left_best_option() {
    std::sort(layout_options.begin(), layout_options.end(),
        [=](const IR::MAU::Table::LayoutOption &a, const IR::MAU::Table::LayoutOption &b) {
        int t;
        if ((t = a.way->match_groups % a.way->width) != 0) return false;
        if ((t = b.way->match_groups % b.way->width) != 0) return true;
        if ((t = a.entries - b.entries) != 0) return t > 0;
        if ((t = a.way->width - b.way->width) != 0) return t < 0;
        if (!a.action_data_required) return true;
        if (!b.action_data_required) return false;
        return true;
    });
    for (auto &lo : layout_options) {
        LOG1("layout option width " << lo.way->width << " match groups " << lo.way->match_groups
              << " entries " << lo.entries << " srams " << lo.srams
              << " action data " << lo.action_data_required); 
        LOG1("Layout option way sizes " << lo.way_sizes);
    }
    preferred_index = 0;
}

void StageUseEstimate::unknown_tcams_needed(const IR::MAU::Table *tbl,
                                            IR::MAU::Table::LayoutOption *lo,
                                            int tcams_left, int srams_left) { 
    vector<RAM_counter> per_word_and_width;
    calculate_per_row_vector(per_word_and_width, tbl, lo);

    int available_srams = srams_left - lo->srams;
    int available_tcams = tcams_left;
    int adding_entries = 0;
    int used_srams = 0; int used_maprams = 0; int used_tcams = 0;
    int depth = 1;

    while (true) {
        int sram_count = 0; int mapram_count = 0; int tcam_count = 0;
        int attempted_entries = depth * 512;
        tcam_count += depth;
        for (auto rc : per_word_and_width) { 
            int entries_per_sram = 1024 * rc.per_word;
            int units = (attempted_entries + entries_per_sram - 1) / entries_per_sram;
            sram_count += units * rc.width;
            if (rc.need_maprams)
                mapram_count += units;
        }

        if (sram_count > available_srams || tcam_count > available_tcams) break;
        depth++;
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

void StageUseEstimate::tcams_left_best_option() {
    std::sort(layout_options.begin(), layout_options.end(),
        [=](const IR::MAU::Table::LayoutOption &a, const IR::MAU::Table::LayoutOption &b) {
        int t;
        if ((t = a.entries - b.entries) != 0) return t > 0;
        if ((t = a.srams - b.srams) != 0) return t < 0;
        if (!a.ternary_indirect_required) return true;
        if (!b.ternary_indirect_required) return false;
        if (!a.action_data_required) return true;
        if (!b.action_data_required) return false;
        return true;
    });
    preferred_index = 0;
}

void StageUseEstimate::calculate_for_leftover_srams(const IR::MAU::Table *tbl, int srams_left,
                                                    int &entries) {
    LOG1("srams left " << srams_left);
    layout_options.clear();
    layout_options = tbl->layout_options;
    for (auto &lo : layout_options) {
        lo.clear_mems();
        known_srams_needed(tbl, &lo);
        unknown_srams_needed(tbl, &lo, srams_left);
    }
    srams_left_best_option();
    fill_estimate_from_option(entries);
}

void StageUseEstimate::calculate_for_leftover_tcams(const IR::MAU::Table *tbl, int tcams_left,
                                                    int srams_left, int &entries) {
    layout_options.clear();
    layout_options = tbl->layout_options;
    for (auto &lo : layout_options) {
        lo.clear_mems();
        known_srams_needed(tbl, &lo);
        unknown_tcams_needed(tbl, &lo, tcams_left, srams_left);
    }
    tcams_left_best_option();
    fill_estimate_from_option(entries);
}
