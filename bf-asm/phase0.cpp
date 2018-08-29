#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(Phase0MatchTable)

void Phase0MatchTable::setup(VECTOR(pair_t) &data) {
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data, P4Table::MatchEntry)) {
        } else if (auto *fmt = get(data, "format")) {
            if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map"))
                format = new Format(this, fmt->map);
        } else if (kv.key == "size") {
            if (CHECKTYPE(kv.value, tINT))
                size = kv.value.i;
        } else if (kv.key == "constant_value") {
            if (CHECKTYPE(kv.value, tINT))
                constant_value = kv.value.i;
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    if (gress != INGRESS || stage->stageno != 0)
        error(lineno, "Phase 0 match table can only be in stage 0 ingress");
}

void Phase0MatchTable::pass1() {
    LOG1("### Phase 0 match table " << name() << " pass1");
    MatchTable::pass1(0);
    if (actions)
        actions->pass1(this);
}

void Phase0MatchTable::pass2() {
    LOG1("### Phase 0 match table " << name() << " pass2");
}

void Phase0MatchTable::pass3() {
    LOG1("### Phase 0 match table " << name() << " pass3");
}

template<class REGS>
void Phase0MatchTable::write_regs(REGS &) {
    LOG1("### Phase 0 match table " << name() << " write_regs");
}

void Phase0MatchTable::gen_tbl_cfg(json::vector &out) const {
    json::map &tbl = *base_tbl_cfg(out, "match_entry", p4_table ? p4_table->size : size);
    common_tbl_cfg(tbl);
    tbl["statistics_table_refs"] = json::vector();
    tbl["meter_table_refs"] = json::vector();
    tbl["selection_table_refs"] = json::vector();
    tbl["stateful_table_refs"] = json::vector();
    tbl["action_data_table_refs"] = json::vector();
    json::map &match_attributes = tbl["match_attributes"] = json::map();
    json::map &stage_tbl = *add_stage_tbl_cfg(match_attributes, "phase_0_match", size);
    match_attributes["match_type"] = "phase_0_match";
    stage_tbl["stage_number"] = -1;
    stage_tbl.erase("logical_table_id");
    stage_tbl.erase("default_next_table");
    stage_tbl.erase("has_attached_gateway");
    auto &mra = stage_tbl["memory_resource_allocation"] = json::map();
    mra["spare_bank_memory_unit"] = 0;
    mra["memory_type"] = "ingress_buffer";
    json::map tmp;
    (tmp["vpns"] = json::vector()).push_back(0L);
    (tmp["memory_units"] = json::vector()).push_back(0L);
    (mra["memory_units_and_vpns"] = json::vector()).push_back(std::move(tmp));
    add_pack_format(stage_tbl, format, false, true); // is this used by driver?
    if (actions)
        actions->gen_tbl_cfg(tbl["actions"]);
    if (context_json)
        stage_tbl.merge(*context_json);
}
