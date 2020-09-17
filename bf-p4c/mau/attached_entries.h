#ifndef BF_P4C_MAU_ATTACHED_ENTRIES_H_
#define BF_P4C_MAU_ATTACHED_ENTRIES_H_

#include "lib/ordered_map.h"

namespace IR {
namespace MAU {
class AttachedMemory;  // forward declaration
}
}

// Table Placement needs to communicate infomation about attached tables (how many entries
// are being placed in the current stage and whether more will be in a later stage) to Memory
// allocation, IXBar allocation, and table layout.  It does so via an attached_entries_t
// map, which needs to be declared before anything related to any of the above can be
// declared, so there's no good place to do it.  So we declare it here as a stand-alone
// header that can be included before anything else

struct attached_entries_element_t {
    int         entries;
    bool        need_more = false;
    attached_entries_element_t() = delete;
    explicit attached_entries_element_t(int e) : entries(e) {}
};

typedef ordered_map<const IR::MAU::AttachedMemory *, attached_entries_element_t> attached_entries_t;

#endif /* BF_P4C_MAU_ATTACHED_ENTRIES_H_ */
