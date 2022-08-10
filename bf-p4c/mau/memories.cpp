#include "bf-p4c/device.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/payload_gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "lib/bitops.h"
#include "lib/range.h"
#include "bf-p4c/mau/tofino/memories.h"
#include "bf-p4c/mau/flatrock/memories.h"

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

std::ostream &operator<<(std::ostream &out, const Memories::Use::Way &w) {
    out << "size : " << w.size << ", select_mask: " << w.select_mask << std::endl;
    out << "\trams - ";
    for (auto r : w.rams) {
        out << "[ " << r.first << ", " << r.second << " ] ";
    }
    return out << std::endl;
}

Memories *Memories::create() {
#ifdef HAVE_FLATROCK
    if (Device::currentDevice() == Device::FLATROCK)
        return new Flatrock::Memories;
#endif
    return new Tofino::Memories;
}
