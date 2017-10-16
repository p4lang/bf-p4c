#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "lib/hex.h"
#include "lib/map.h"
#include "lib/safe_vector.h"

std::ostream &operator<<(std::ostream &out, const TableSummary &ts) {
    out << " id G                     name       xb  hb g sr tc mr ab" << std::endl;
    for (auto *t : Values(ts.order)) {
        safe_vector<LayoutOption> lo;
        ordered_set<const IR::MAU::ActionData *> sad;
        if (t->layout.ternary || t->layout.no_match_data())
            lo.emplace_back(t->layout);
        else
            lo.emplace_back(t->layout, t->ways[0]);
        int entries = t->layout.entries;
        StageUseEstimate use(t, entries, false, false, lo, sad, true);
        out << hex(t->logical_id, 3) << ' ' << (t->gress ? 'E' : 'I')
            << ' ' << std::setw(30) << t->name
            << ' ' << std::setw(2) << t->layout.ixbar_bytes
            << ' ' << std::setw(3) << t->layout.match_width_bits
            << ' ' << (t->uses_gateway() ? '1' : '0')
            << ' ' << std::setw(2) << use.srams
            << ' ' << std::setw(2) << use.tcams
            << ' ' << std::setw(2) << use.maprams
            << ' ' << std::setw(2) << t->layout.action_data_bytes
            << std::endl;
    }
    for (auto &i : ts.ixbar)
        out << "Stage " << i.first << std::endl << i.second << ts.memory.at(i.first);
    return out;
}
