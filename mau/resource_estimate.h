#ifndef _resource_estimate_h_
#define _resource_estimate_h_

#include "ir/ir.h"

struct StageUse {
    enum {
	MAX_STAGES = 12,
	MAX_LOGICAL_IDS = 16,
	MAX_SRAMS = 80,
	MAX_TCAMS = 24,
	MAX_MAPRAMS = 48,
	MAX_IXBAR_BYTES = 128,
	MAX_TERNARY_GROUPS = 16,
    };
    //short	stage;
    short	logical_ids;
    short	srams, tcams, maprams;
    short	exact_ixbar_bytes;
    short	ternary_ixbar_groups;
    StageUse() { memset(this, 0, sizeof(*this)); }
    StageUse &operator+=(const StageUse &a) {
	logical_ids += a.logical_ids;
	srams += a.srams;
	tcams += a.tcams;
	maprams += a.maprams;
	exact_ixbar_bytes += a.exact_ixbar_bytes;
	ternary_ixbar_groups += a.ternary_ixbar_groups;
	return *this; }
    StageUse(const IR::MAU::Table *, int &);
    StageUse operator+(const StageUse &a) const { StageUse rv = *this; rv += a; return rv; }
    static StageUse max() {
	StageUse rv;
	rv.logical_ids = MAX_LOGICAL_IDS;
	rv.srams = MAX_SRAMS;
	rv.tcams = MAX_TCAMS;
	rv.maprams = MAX_MAPRAMS;
	rv.exact_ixbar_bytes = MAX_IXBAR_BYTES;
	rv.ternary_ixbar_groups = MAX_TERNARY_GROUPS;
	return rv; }
    bool operator<=(const StageUse &a) {
	return logical_ids <= a.logical_ids && srams <= a.srams && tcams <= a.tcams &&
	       maprams <= a.maprams && exact_ixbar_bytes <= a.exact_ixbar_bytes &&
	       ternary_ixbar_groups <= a.ternary_ixbar_groups; }
};

#endif /* _resource_estimate_h_ */
