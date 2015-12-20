#ifndef _resource_estimate_h_
#define _resource_estimate_h_

#include "resource.h"


struct StageUseEstimate {
    short       logical_ids;
    short       srams, tcams, maprams;
    short       exact_ixbar_bytes;
    short       ternary_ixbar_groups;
    StageUseEstimate() { memset(this, 0, sizeof(*this)); }
    StageUseEstimate &operator+=(const StageUseEstimate &a) {
        logical_ids += a.logical_ids;
        srams += a.srams;
        tcams += a.tcams;
        maprams += a.maprams;
        exact_ixbar_bytes += a.exact_ixbar_bytes;
        ternary_ixbar_groups += a.ternary_ixbar_groups;
        return *this; }
    StageUseEstimate(const IR::MAU::Table *, int &);
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
};

int CounterPerWord(const IR::Counter *ctr);
int RegisterPerWord(const IR::Register *reg);
int ActionDataPerWord(const IR::MAU::Table::Layout *layout, int *width);

#endif /* _resource_estimate_h_ */
