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

void StageUseEstimate::options_to_ways(const IR::MAU::Table *tbl, int &entries) {
    layout_options.clear();
    layout_options = tbl->layout_options;
    for (auto &lo : layout_options) {
        int per_row = lo.way->match_groups;
        int total_depth = (entries + per_row * 1024 - 1) / (per_row * 1024); 
        int calculated_depth = total_depth;
        //Need to have a larger depth in ways than it's total 
        if (total_depth < 8) {
            switch (total_depth) {
                case 1:
                    lo.way_sizes = {1, 1, 1};
                    calculated_depth = 3;
                    break;
                case 2:
                    lo.way_sizes = {1, 1, 1, 1};
                    calculated_depth = 4;
                    break;
                case 3:
                    lo.way_sizes = {1, 1, 1, 1};
                    calculated_depth = 4;
                    break;
                case 4:
                    lo.way_sizes = {1, 1, 1, 1};
                    break;
                case 5:
                    lo.way_sizes = {2, 1, 1, 1};
                    break;
                case 6:
                    lo.way_sizes = {2, 2, 1, 1};
                    break;
                case 7:
                    lo.way_sizes = {2, 2, 2, 1};
                    break;
            }
        //Cannot share a single hash group
        } else {
            int max_group_size = (1 << ceil_log2(total_depth)) / 4;
            int depth = total_depth;
            while (depth > 0) {
                if (max_group_size <= depth) {
                    lo.way_sizes.push_back(max_group_size);
                    depth -= max_group_size; 
                } else {
                    max_group_size /= 2;
                }
            }
        }
        lo.entries = calculated_depth * lo.way->match_groups * 1024;
        lo.srams = calculated_depth * lo.way->width;
        lo.maprams = 0;
    }
}


void StageUseEstimate::calculate_attached_rams(const IR::MAU::Table *tbl, int entries,
                                               int &srams, int &maprams) {
    for (auto at : tbl->attached) {
        int per_word = 0;
        int width = 1;
        int attached_entries = entries;
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
            per_word = ActionDataPerWord(&tbl->layout, &width);
            attached_entries = ap->size;
        } else if (/*auto *ad = */dynamic_cast<const IR::MAU::ActionData *>(at)) {
            // fixme: in theory, the table should not have an action data table,
            // as that is decided after the table layout is picked
            continue;
            //per_word = actiondataperword(&tbl->layout, &width);
        } else if (/*auto *as = */dynamic_cast<const IR::ActionSelector *>(at)) {
            // todo(cdodd)
        } else if (/*auto *ti = */dynamic_cast<const IR::MAU::TernaryIndirect *>(at)) {
            int indir_size = ceil_log2(tbl->layout.overhead_bits);
            if (indir_size > 8)
                BUG("can't have more than 64 bits of overhead in "
                                        "ternary table %s", tbl->name);
            if (indir_size < 3) indir_size = 3;
            per_word = 128 >> indir_size;
        } else {
            BUG("unknown attached table type %s", at->kind()); }
        if (per_word > 0) {
            if (attached_entries <= 0)
                BUG("%s: no size in indirect %s %s", at->srcInfo, at->kind(), at->name);
            int entries_per_sram = 1024 * per_word;
            int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
            srams += units * width;
            if (need_maprams) maprams += units; 
        }
    }
}

void StageUseEstimate::options_to_rams(const IR::MAU::Table *tbl) {
    for (auto &lo : layout_options) {
        for (auto at : tbl->attached) {
            int per_word = 0;
            int width = 1;
            int attached_entries = lo.entries;
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
                per_word = ActionDataPerWord(&tbl->layout, &width);
                attached_entries = ap->size;
            } else if (/*auto *ad = */dynamic_cast<const IR::MAU::ActionData *>(at)) {
                // fixme: in theory, the table should not have an action data table,
                // as that is decided after the table layout is picked
                continue;
                //per_word = actiondataperword(&tbl->layout, &width);
            } else if (/*auto *as = */dynamic_cast<const IR::ActionSelector *>(at)) {
                // todo(cdodd)
            } else if (/*auto *ti = */dynamic_cast<const IR::MAU::TernaryIndirect *>(at)) {
                int indir_size = ceil_log2(tbl->layout.overhead_bits);
                if (indir_size > 8)
                    BUG("can't have more than 64 bits of overhead in "
                                            "ternary table %s", tbl->name);
                if (indir_size < 3) indir_size = 3;
                per_word = 128 >> indir_size;
            } else {
                BUG("unknown attached table type %s", at->kind()); }
            if (per_word > 0) {
                if (attached_entries <= 0)
                    BUG("%s: no size in indirect %s %s", at->srcInfo, at->kind(), at->name);
                int entries_per_sram = 1024 * per_word;
                int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
                lo.srams += units * width;
                if (need_maprams) lo.maprams += units; 
            }
        }
        if (lo.action_data_required) {
            int width = 1;
            int per_word = ActionDataPerWord(&tbl->layout, &width);
            int attached_entries = lo.entries;
            int entries_per_sram = 1024 * per_word;
            int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
            lo.srams += units * width;
        }
    }
}


// sorting algorithm
// first check is to determine if the tbl 
// number of total rams
// closeness to the number of entries needed
void StageUseEstimate::select_best_option(const IR::MAU::Table *tbl) {
    LOG1("select best option");
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
            if ((t = a.srams - b.srams) != 0) return t < 0;
            if ((t = a.way->width - b.way->width) != 0) return t < 0;
            if ((t = a.way->match_groups - b.way->match_groups) != 0) return t > 0;
            if (a.action_data_required) return true;
            if (b.action_data_required) return false;
            return true;
        });
    }
    LOG1("table " << tbl->name << " requiring " << tbl->layout.entries << " entries.");
    if (small_table_allocation)
        LOG1("small table allocation");
    else
        LOG1("large table allocation");
    for (auto &lo : layout_options) {
        LOG1("layout option width " << lo.way->width << " match groups " << lo.way->match_groups
              << " entries " << lo.entries << " srams " << lo.srams
              << " action data " << lo.action_data_required); 
    }
}

StageUseEstimate::StageUseEstimate(const IR::MAU::Table *tbl, int &entries,
                                   const IXBar::Use *match_ixbar) {
    memset(this, 0, sizeof(*this));
    logical_ids = 1;
    exact_ixbar_bytes = tbl->layout.ixbar_bytes;
    if (tbl->layout.ternary) {
        int depth = (entries + 511u)/512u;
        int width = (tbl->layout.match_width_bits + 47)/44;  // +4 bits for v/v, round up
        if (match_ixbar)
            width = match_ixbar->groups();
        ternary_ixbar_groups = width;
        tcams = depth * width;
        entries = depth * 512;
    } else if (!tbl->ways.empty()) {
        /* assuming all ways have the same format and width (only differ in depth) */
        options_to_ways(tbl, entries);
        options_to_rams(tbl);
        select_best_option(tbl);
        int width = tbl->ways[0].width;
        int groups = tbl->ways[0].match_groups;
        int depth = ((entries + groups - 1u)/groups + 1023)/1024u;
        if (depth < static_cast<int>(tbl->ways.size()))
            depth = tbl->ways.size();
        srams = depth * width;
        entries = depth * groups * 1024u;
    } else {
        entries = 0; }
    calculate_attached_rams(tbl, entries, srams, maprams);
}
