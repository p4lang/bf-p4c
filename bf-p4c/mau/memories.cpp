#include "bf-p4c/device.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/payload_gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "lib/bitops.h"
#include "lib/range.h"
#include "bf-p4c/mau/tofino/memories.h"

constexpr int Memories::SRAM_DEPTH;

int Memories::Use::rams_required() const {
    int rv = 0;
    for (auto r : row) {
        rv += r.col.size();
    }
    return rv;
}

/**
 * A function to determine whether or not the asm_output for a table needs to have a separate
 * search bus and result bus printed, rather than having just a single bus, as the result bus
 * a search bus have different values.
 */
bool Memories::Use::separate_search_and_result_bus() const {
    if (type != EXACT && type != ATCAM)
        return false;
    for (auto r : row) {
        if (!(r.result_bus == -1 || r.result_bus == r.bus))
            return true;
    }
    return false;
}

template<int R, int C>
std::ostream &operator<<(std::ostream& out, const Alloc2D<cstring, R, C>& alloc2d) {
    for (int i = 0; i < R; i++) {
        for (int j = 0; j < C; j++) {
            cstring val = alloc2d[i][j];
            if (!val) val = "-";
            out << std::setw(10) << val << " ";
        }
        out << Log::endl;
    }
    return out;
}

Memories *Memories::create() { return new Tofino::Memories; }
