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
    StageUseEstimate(const IR::MAU::Table *, int &, const IXBar::Use *);
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
    void options_to_ways(const IR::MAU::Table *tbl, int &entries);
    void options_to_rams(const IR::MAU::Table *tbl);
    void select_best_option(const IR::MAU::Table *tbl);
    void calculate_attached_rams(const IR::MAU::Table *tbl, int entries,
                                 int &srams, int &maprams);
    const IR::MAU::Table::LayoutOption *preferred_option() const {
    if (layout_options.empty())
        return nullptr;
    else
        return &layout_options[preferred_index]; }
};


int CounterPerWord(const IR::Counter *ctr);
int RegisterPerWord(const IR::Register *reg);
int ActionDataPerWord(const IR::MAU::Table::Layout *layout, int *width);

#endif /* _TOFINO_MAU_RESOURCE_ESTIMATE_H_ */
