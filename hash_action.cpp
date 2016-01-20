#include "action_bus.h"
#include "input_xbar.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(HashActionTable)

void HashActionTable::setup(VECTOR(pair_t) &data) {
    if (auto *fmt = get(data, "format"))
        if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map"))
            format = new Format(fmt->map);
    if (auto *fmt = get(data, "hash_dist"))
	HashDistribution::parse(hash_dist, *fmt, HashDistribution::ACTION_DATA_ADDRESS);
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data)) {
        } else if (kv.key == "format") {
            /* done above to be done before action_bus and vpns */
        } else if (kv.key == "input_xbar") {
            if (CHECKTYPE(kv.value, tMAP))
                input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "row") {
            if (CHECKTYPE(kv.value, tINT))
                if ((row = kv.value.i) >= 8)
                    error(kv.value.lineno, "Invalid row %d", row);
        } else if (kv.key == "bus") {
            if (CHECKTYPE(kv.value, tINT))
                if ((bus = kv.value.i) >= 4)
                    error(kv.value.lineno, "Invalid bus %d", row);
        } else if (kv.key == "hash_dist") {
	    /* done above to be dnoe before parsing table calls */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    if (action.set() && actions)
        error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
        error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action.args.size() > 2)
        error(lineno, "Unexpected number of action table arguments %zu", action.args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}


void HashActionTable::pass1() {
    LOG1("### Hash Action " << name() << " pass1");
    MatchTable::pass1(0);
    check_next();
    if (action.check() && action->set_match_table(this, action.args.size() > 1) != ACTION)
        error(action.lineno, "%s is not an action table", action->name());
    attached.pass1(this);
    if (action_bus) action_bus->pass1(this);
    if (actions) {
        assert(action.args.size() == 0);
        if (auto *sel = lookup_field("action"))
            action.args.push_back(sel);
        else if (actions->count() > 1)
            error(lineno, "No field 'action' to select between mulitple actions in "
                  "table %s format", name());
        actions->pass1(this); }
    if (action_enable >= 0)
        if (action.args.size() < 1 || action.args[0].size() <= (unsigned)action_enable)
            error(lineno, "Action enable bit %d out of range for action selector", action_enable);
    if (input_xbar)
        input_xbar->pass1(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
    for (auto &hd : hash_dist)
        hd.pass1(this);
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
    if (idletime) {
        idletime->logical_id = logical_id;
        idletime->pass1(); }
}

void HashActionTable::pass2() {
    LOG1("### Hash Action " << name() << " pass2");
    if (row < 0 || bus < 0)
        error(lineno, "Need explicit row/bus in hash_action table"); // FIXME
    //if (hash_dist.empty())
    //    error(lineno, "Need explicit hash_dist in hash_action table"); // FIXME
    //if (bus >= 2) stage->table_use[gress] |= Stage::USE_TCAM;
    if (input_xbar)
        input_xbar->pass2(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
    if (actions) actions->pass2(this);
    if (action_bus) action_bus->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
}

void HashActionTable::write_merge_regs(int type, int bus) {
    attached.write_merge_regs(this, type, bus);
    /* FIXME -- factor with ExactMatch::write_merge_regs? */
    auto &merge = stage->regs.rams.match.merge;
    //merge.exact_match_phys_result_en[bus/8U] |= 1U << (bus%8U);
    merge.exact_match_phys_result_thread[bus/8U] |= gress << (bus%8U);
    //if (stage->tcam_delay(gress))
    //    merge.exact_match_phys_result_delay[bus/8U] |= 1U << (bus%8U);
    if (options.match_compiler && action_enable >= 0 && enable_action_instruction_enable)
        /* this seems wrong */
        merge.mau_action_instruction_adr_mask[type][bus] |= 1U << action_enable;

    //merge.mau_bus_hash_group_ctl[type][bus/4].set_subfield(
    //    1 << BusHashGroup::ACTION_DATA_ADDRESS, 5 * (bus%4), 5);
    //merge.mau_bus_hash_group_sel[type][bus/8].set_subfield(hash_dist[0].id | 8, 4*(bus%8), 4);
}

void HashActionTable::write_regs() {
    LOG1("### Hash Action " << name() << " write_regs");
    /* FIXME -- setup layout with no rams so other functions can write registers properly */
    layout.resize(1);
    layout[0].row = row;
    layout[0].bus = bus & 1;
    MatchTable::write_regs((bus&2) >> 1, this);
    auto &merge = stage->regs.rams.match.merge;
    //merge.exact_match_logical_result_en |= 1 << logical_id;
    if (stage->tcam_delay(gress))
        merge.exact_match_logical_result_delay |= 1 << logical_id;
    if (actions) actions->write_regs(this);
    if (idletime) idletime->write_regs();
    if (gateway) gateway->write_regs();
    for (auto &hd : hash_dist)
        hd.write_regs(this, 1, false);
    if (options.match_compiler && !enable_action_data_enable) {
        /* this seems unneeded? (won't actually be used...) */
        merge.next_table_format_data[logical_id].match_next_table_adr_default =
            merge.next_table_format_data[logical_id].match_next_table_adr_miss_value.value;
    }
}

void HashActionTable::gen_tbl_cfg(json::vector &out) {
    int size = hash_dist.empty() ? 1 : 1 + hash_dist[0].mask;
    json::map &tbl = *base_tbl_cfg(out, "match_entry", size);
    if (!tbl.count("preferred_match_type"))
        tbl["preferred_match_type"] = "exact";
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, hash_dist.empty() ? "match_with_no_key"
                                                                     : "hash_action", size);
    add_pack_format(stage_tbl, 0, 0, hash_dist.empty() ? 1 : 0);
    if (options.match_compiler)
        stage_tbl["memory_resource_allocation"] = "null";
    if (idletime)
        idletime->gen_stage_tbl_cfg(stage_tbl);
    else if (options.match_compiler)
        stage_tbl["stage_idletime_table"] = "null";
    tbl["performs_hash_action"] = !hash_dist.empty();
    tbl["uses_versioning"] = true;  // FIXME
    tbl["tcam_error_detect"] = false;
}
