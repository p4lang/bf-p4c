#ifndef _TOFINO_MAU_RESOURCE_ESTIMATE_H_
#define _TOFINO_MAU_RESOURCE_ESTIMATE_H_

#include "resource.h"

struct StageUseEstimate {
    int logical_ids;
    int srams, tcams, maprams;
    int exact_ixbar_bytes;
    int ternary_ixbar_groups;
    vector<IR::MAU::Table::LayoutOption> layout_options;
    int preferred_index;
    StageUseEstimate() { memset(this, 0, sizeof(*this)); }
    StageUseEstimate &operator+=(const StageUseEstimate &a) {
        logical_ids += a.logical_ids;
        srams += a.srams;
        tcams += a.tcams;
        maprams += a.maprams;
        exact_ixbar_bytes += a.exact_ixbar_bytes;
        ternary_ixbar_groups += a.ternary_ixbar_groups;
        return *this; }
    StageUseEstimate(const IR::MAU::Table *, int &, bool table_placement = false);
    StageUseEstimate operator+(const StageUseEstimate &a) const {
        StageUseEstimate rv = *this; rv += a; return rv; }
    static StageUseEstimate max() {
        StageUseEstimate rv;
        rv.logical_ids = StageUse::MAX_LOGICAL_IDS;
        rv.srams = StageUse::MAX_SRAMS;
        rv.tcams = StageUse::MAX_TCAMS;
        rv.maprams = StageUse::MAX_MAPRAMS;
        rv.exact_ixbar_bytes = StageUse::MAX_IXBAR_BYTES;
        rv.ternary_ixbar_groups = StageUse::MAX_TERNARY_GROUPS;
        return rv; }
    bool operator<=(const StageUseEstimate &a) {
        return logical_ids <= a.logical_ids && srams <= a.srams && tcams <= a.tcams &&
               maprams <= a.maprams && exact_ixbar_bytes <= a.exact_ixbar_bytes &&
               ternary_ixbar_groups <= a.ternary_ixbar_groups; }
    void clear() {
        logical_ids = 0; srams = 0; tcams = 0; maprams = 0;
        exact_ixbar_bytes = 0; ternary_ixbar_groups = 0;
    }
    void options_to_ways(const IR::MAU::Table *tbl, int &entries);
    void options_to_rams(const IR::MAU::Table *tbl, bool table_placement);
    void select_best_option(const IR::MAU::Table *tbl);
    void options_to_ternary_entries(const IR::MAU::Table *tbl, int &entries);
    void select_best_option_ternary();
    void calculate_attached_rams(const IR::MAU::Table *tbl,
                                 IR::MAU::Table::LayoutOption *lo, bool table_placement);
    void fill_estimate_from_option(int &entries);
    const IR::MAU::Table::LayoutOption *preferred() const {
    if (layout_options.empty())
        return nullptr;
    else
        return &layout_options[preferred_index]; }

    void calculate_for_leftover_srams(const IR::MAU::Table *tbl, int srams_left, int &entries);
    void calculate_for_leftover_tcams(const IR::MAU::Table *tbl, int srams_left, int tcams_left,
                                      int &entries);
    void known_srams_needed(const IR::MAU::Table *tbl, IR::MAU::Table::LayoutOption *lo);
    void unknown_srams_needed(const IR::MAU::Table *tbl, IR::MAU::Table::LayoutOption *lo,
                              int srams_left);
    void unknown_tcams_needed(const IR::MAU::Table *tbl, IR::MAU::Table::LayoutOption *lo,
                              int tcams_left, int srams_left);
    void calculate_way_sizes(IR::MAU::Table::LayoutOption *lo, int &calculated_depth);
    void srams_left_best_option();
    void tcams_left_best_option();
    struct RAM_counter {
        int per_word;
        int width;
        bool need_maprams;
        RAM_counter() : per_word(0), width(0), need_maprams(false) {}
        RAM_counter(int p, int w, bool nm) : per_word(p), width(w), need_maprams(nm) {}
    };
    void calculate_per_row_vector(vector<RAM_counter> &per_word_and_width,
                                  const IR::MAU::Table *tbl, IR::MAU::Table::LayoutOption *lo);
};


int CounterPerWord(const IR::Counter *ctr);
int RegisterPerWord(const IR::Register *reg);
int ActionDataPerWord(const IR::MAU::Table::Layout *layout, int *width);
int TernaryIndirectPerWord(const IR::MAU::Table::Layout *layout, const IR::MAU::Table *tbl);

#endif /* _TOFINO_MAU_RESOURCE_ESTIMATE_H_ */
