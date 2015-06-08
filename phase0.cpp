#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(Phase0MatchTable)

void Phase0MatchTable::setup(VECTOR(pair_t) &data) {
    VECTOR(pair_t) p4_info = EMPTY_VECTOR_INIT;
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv)) {
        } else if (kv.key == "p4_table") {
            push_back(p4_info, "name", std::move(kv.value));
        } else if (kv.key == "p4_table_size") {
            push_back(p4_info, "size", std::move(kv.value));
        } else if (kv.key == "handle") {
            push_back(p4_info, "handle", std::move(kv.value));
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
    if (p4_info.size) {
        if (p4_table)
            error(p4_info[0].key.lineno, "old and new p4 table info in %s", name());
        else
            p4_table = P4Table::get(P4Table::MatchEntry, p4_info); }
    fini(p4_info);
    if (gress != INGRESS || stage->stageno != 0)
        error(lineno, "Phase 0 match table can only be in stage 0 ingress");
}

void Phase0MatchTable::pass1() {
    LOG1("### Phase 0 match table " << name() << " pass1");
}

void Phase0MatchTable::pass2() {
    LOG1("### Phase 0 match table " << name() << " pass2");
}

void Phase0MatchTable::write_regs() {
    LOG1("### Phase 0 match table " << name() << " write_regs");
}

void Phase0MatchTable::gen_tbl_cfg(json::vector &out) {
    int number_entries = 72;
    json::map &tbl = *base_tbl_cfg(out, "match_entry", number_entries);
    //json::map &stage_tbl = *
    add_stage_tbl_cfg(tbl, "phase_0_match", number_entries);
}
