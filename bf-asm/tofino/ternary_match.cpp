#include "ternary_match.h"
#include "stage.h"

void Target::Tofino::TernaryMatchTable::pass1() {
    ::TernaryMatchTable::pass1();
    // Dont allocate id (mark them as used) for empty ternary tables (keyless
    // tables). Keyless tables are marked ternary with a tind. They are setup by
    // the driver to always miss (since there is no match) and run the miss
    // action. The miss action is associated with the logical table space and
    // does not need a tcam id association. This saves tcams ids to be assigned
    // to actual ternary tables. This way we can have 8 real ternary match
    // tables within a stage and not count the keyless among them.
    // NOTE: The tcam_id is never assigned for these tables and will be set to
    // default (-1). We also disable registers associated with tcam_id for this
    // table.
    if (layout_size() != 0) {
        alloc_id("tcam", tcam_id, stage->pass1_tcam_id,
             TCAM_TABLES_PER_STAGE, false, stage->tcam_id_use);
        physical_ids[tcam_id] = 1; }
    // alloc_busses(stage->tcam_match_bus_use); -- now hardwired
}

void Target::Tofino::TernaryIndirectTable::pass1() {
    ::TernaryIndirectTable::pass1();
    alloc_busses(stage->tcam_indirect_bus_use, Layout::TIND_BUS);
}
