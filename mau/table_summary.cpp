#include "table_summary.h"
#include "lib/hex.h"
#include "lib/map.h"

std::ostream &operator<<(std::ostream &out, const TableSummary &ts) {
    for (auto *t : Values(ts.order)) {
	out << hex(t->logical_id, 3) << ' ' << (t->gress ? 'E' : 'I') << ' '
	    << t->name << std::endl;
    }
    return out;
}
