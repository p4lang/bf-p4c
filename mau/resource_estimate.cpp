#include "resource_estimate.h"
#include "lib/bitops.h"

int CounterPerWord(const IR::Counter *ctr) {
    switch (ctr->type) {
    case IR::Counter::PACKETS:
        if (ctr->min_width <= 21) return 6;
        // fall through
    case IR::Counter::BYTES:
        if (ctr->min_width <= 32) return 4;
        if (ctr->min_width > 64)
            error("%s: Maximum width for counter %s is 64 bits", ctr->srcInfo, ctr->name);
        return 2;
    case IR::Counter::BOTH:
        if (ctr->min_width <= 17) return 3;
        if (ctr->min_width <= 28) return 2;
        if (ctr->min_width > 64)
            error("%s: Maximum width for counter %s is 64 bits", ctr->srcInfo, ctr->name);
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
    int size = ceil_log2(layout->action_data_bytes);
    if (size > 4) {
        *width = 1 << (size-4);
        return 1; }
    return 16 >> size;
}

StageUseEstimate::StageUseEstimate(const IR::MAU::Table *tbl, int &entries) {
    memset(this, 0, sizeof(*this));
    logical_ids = 1;
    exact_ixbar_bytes = tbl->layout.ixbar_bytes;
    if (tbl->layout.ternary) {
        int depth = (entries + 511U)/512U;
        int width = (tbl->layout.match_width_bits + 47)/44;  // +4 bits for v/v, round up
        ternary_ixbar_groups = width;
        tcams = depth * width;
        entries = depth * 512;
    } else if (tbl->match_table) {
        int width = tbl->layout.match_width_bits + tbl->layout.overhead_bits + 4;  // valid/version
        int groups = 128/width;
        if (groups) {
            width = 1;
        } else {
            groups = 1;
            width = (width+127)/128; }
        int depth = ((entries + groups - 1U)/groups + 1023)/1024U;
        srams = depth * width;
        entries = depth * groups * 1024U;
    } else {
        entries = 0; }
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
            per_word = ActionDataPerWord(&tbl->layout, &width);
        } else if (/*auto *as = */dynamic_cast<const IR::ActionSelector *>(at)) {
            // TODO(cdodd)
        } else if (/*auto *ti = */dynamic_cast<const IR::MAU::TernaryIndirect *>(at)) {
            int indir_size = ceil_log2(tbl->layout.overhead_bits);
            if (indir_size > 8)
                throw Util::CompilerBug("Can't have more than 64 bits of overhead in "
                                        "ternary table %s", tbl->name);
            if (indir_size < 3) indir_size = 3;
            per_word = 128 >> indir_size;
        } else {
            throw Util::CompilerBug("Unknown attached table type %s", at->kind()); }
        if (per_word > 0) {
            if (attached_entries <= 0)
                error("%s: No size in indirect %s %s", at->srcInfo, at->kind(), at->name);
            int entries_per_sram = 1024 * per_word;
            int units = (attached_entries + entries_per_sram - 1) / entries_per_sram;
            srams += units * width;
            if (need_maprams) maprams += units; } }
}
