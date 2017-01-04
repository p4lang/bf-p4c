#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(Phase0MatchTable)

void Phase0MatchTable::setup(VECTOR(pair_t) &data) {
    VECTOR(pair_t) p4_info = EMPTY_VECTOR_INIT;
    for (auto &kv : MapIterChecked(data)) {
        /* if (common_setup(kv, data)) { } else */
        if (kv.key == "p4") {
            if (CHECKTYPE(kv.value, tMAP))
                p4_table = P4Table::get(P4Table::MatchEntry, kv.value.map);
        } else if (kv.key == "p4_table") {
            push_back(p4_info, "name", std::move(kv.value));
        } else if (kv.key == "p4_table_size") {
            push_back(p4_info, "size", std::move(kv.value));
        } else if (kv.key == "handle") {
            push_back(p4_info, "handle", std::move(kv.value));
        } else if (kv.key == "size") {
            if (CHECKTYPE(kv.value, tINT))
                size = kv.value.i;
        } else if (kv.key == "width") {
            if (CHECKTYPE(kv.value, tINT))
                width = kv.value.i;
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
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
    json::map &tbl = *base_tbl_cfg(out, "match_entry", p4_table ? p4_table->size : size);
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "phase_0_match", size);
    auto &mra = stage_tbl["memory_resource_allocation"] = json::map();
    stage_tbl["stage_number"] = -1;
    mra["memory_type"] = "ingress_buffer";
    mra["memory_units_depth"] = 1;
    mra["memory_units_width"] = width;
    json::map tmp;
    auto &mem_units = tmp["memory_units"] = json::vector();
    for (int i = width-1; i >= 0; i--)
        mem_units.push_back(i);
    (tmp["vpns"] = json::vector()).push_back(0L);
    (mra["memory_units_and_vpns"] = json::vector()).push_back(std::move(tmp));
    add_pack_format(stage_tbl, 64, width, 1);
    if (options.match_compiler)
        tbl["p4_statistics_tables"] = json::vector();
    if (!default_action.empty()) {
        tbl["default_action"] = default_action;
        json::vector &params = tbl["default_action_parameters"] = json::vector();
        for (auto val : default_action_args)
            params.push_back(val);
    } else if (options.match_compiler) {
        tbl["default_action"] = nullptr;
        tbl["default_action_parameters"] = nullptr; }
    tbl["performs_hash_action"] = false;
    tbl["uses_versioning"] = true;
    tbl["tcam_error_detect"] = false;
    tbl["match_type"] = p4_table->match_type.empty() ? "exact" : p4_table->match_type;
    if (!p4_table->action_profile.empty())
        tbl["action_profile"] = p4_table->action_profile;
    else
        tbl["action_profile"] = nullptr;
}
