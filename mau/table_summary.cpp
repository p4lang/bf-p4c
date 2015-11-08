#include "table_summary.h"
#include "resource_estimate.h"
#include "lib/hex.h"
#include "lib/map.h"

std::ostream &operator<<(std::ostream &out, const TableSummary &ts) {
    out << " id G                     name       xb  hb g sr tc mr ab" << std::endl;
    for (auto *t : Values(ts.order)) {
	int entries = t->layout.entries;
	StageUse use(t, entries);
	out << hex(t->logical_id, 3) << ' ' << (t->gress ? 'E' : 'I')
	    << ' ' << std::setw(30) << t->name
	    << ' ' << std::setw(2) << t->layout.ixbar_bytes
	    << ' ' << std::setw(3) << t->layout.match_width_bits
	    << ' ' << (t->gateway_expr ? '1' : '0')
	    << ' ' << std::setw(2) << use.srams
	    << ' ' << std::setw(2) << use.tcams
	    << ' ' << std::setw(2) << use.maprams
	    << ' ' << std::setw(2) << t->layout.action_data_bytes
	    << std::endl;
    }
    return out;
}
