#include "action_bus.h"
#include "input_xbar.h"
#include "stage.h"
#include "tables.h"
#include "misc.h"

DEFINE_TABLE_TYPE(HashActionTable)

void HashActionTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::MatchEntry);
    for (auto &kv : MapIterChecked(data)) {
        if (!common_setup(kv, data, P4Table::MatchEntry)) {
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); } }
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
    if (!p4_table) p4_table = P4Table::alloc(P4Table::MatchEntry, this);
    else p4_table->check(this);
    check_next();
    attached.pass1(this);
    if (action_bus) action_bus->pass1(this);
    if (actions) {
        if (instruction)
            validate_instruction(instruction);
        else
            error(lineno, "No instruction call provided, but actions provided");
        actions->pass1(this);
    }
    if (action) {
        action->validate_call(action, this, 2, HashDistribution::ACTION_DATA_ADDRESS, action);     
    }

    if (input_xbar)
        input_xbar->pass1();
    for (auto &hd : hash_dist) {
        if (hd.xbar_use == 0)
            hd.xbar_use |= HashDistribution::ACTION_DATA_ADDRESS;
        hd.pass1(this); }
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1();
    } else if (!hash_dist.empty())
        warning(hash_dist[0].lineno, "No gateway in hash_action means hash_dist can't be used");
    if (idletime) {
        idletime->logical_id = logical_id;
        idletime->pass1(); }
}

void HashActionTable::pass2() {
    LOG1("### Hash Action " << name() << " pass2");
    if (logical_id < 0) choose_logical_id();
    if (layout.size() != 1 || layout[0].bus < 0)
        error(lineno, "Need explicit row/bus in hash_action table"); // FIXME
    //if (hash_dist.empty())
    //    error(lineno, "Need explicit hash_dist in hash_action table"); // FIXME
    //if (bus >= 2) stage->table_use[timing_thread(gress)] |= Stage::USE_TCAM;
    if (input_xbar)
        input_xbar->pass2();
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
}

void HashActionTable::pass3() {
    LOG1("### Hash Action " << name() << " pass3");
    if (action_bus) action_bus->pass3(this);
}

template<class REGS>
void HashActionTable::write_merge_regs(REGS &regs, int type, int bus) {
    attached.write_merge_regs(regs, this, type, bus);
    /* FIXME -- factor with ExactMatch::write_merge_regs? */
    auto &merge = regs.rams.match.merge;
    merge.exact_match_phys_result_en[bus/8U] |= 1U << (bus%8U);
    merge.exact_match_phys_result_thread[bus/8U] |= gress << (bus%8U);
    if (stage->tcam_delay(gress))
        merge.exact_match_phys_result_delay[bus/8U] |= 1U << (bus%8U);
    if (options.match_compiler && action_enable >= 0 && enable_action_instruction_enable)
        /* this seems wrong */
        merge.mau_action_instruction_adr_mask[type][bus] |= 1U << action_enable;

    //merge.mau_bus_hash_group_ctl[type][bus/4].set_subfield(
    //    1 << BusHashGroup::ACTION_DATA_ADDRESS, 5 * (bus%4), 5);
    //merge.mau_bus_hash_group_sel[type][bus/8].set_subfield(hash_dist[0].id | 8, 4*(bus%8), 4);
    if (type) {
        merge.tind_bus_prop[bus].tcam_piped = 1;
        merge.tind_bus_prop[bus].thread = gress;
        merge.tind_bus_prop[bus].enabled = 1; }
}

template<class REGS>
void HashActionTable::write_regs(REGS &regs) {
    LOG1("### Hash Action " << name() << " write_regs");
    /* FIXME -- setup layout with no rams so other functions can write registers properly */
    int bus_type = layout[0].bus >> 1;
    MatchTable::write_regs(regs, bus_type, this);
    auto &merge = regs.rams.match.merge;
    merge.exact_match_logical_result_en |= 1 << logical_id;
    if (stage->tcam_delay(gress))
        merge.exact_match_logical_result_delay |= 1 << logical_id;
    if (actions) actions->write_regs(regs, this);
    if (idletime) idletime->write_regs(regs);
    if (gateway) gateway->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this, 1, false);
    if (options.match_compiler && !enable_action_data_enable &&
        (!gateway || gateway->empty_match())) {
        /* this seems unneeded? (won't actually be used...) */
        merge.next_table_format_data[logical_id].match_next_table_adr_default =
            merge.next_table_format_data[logical_id].match_next_table_adr_miss_value.value;
    }
}

void HashActionTable::gen_tbl_cfg(json::vector &out) const {
    //FIXME: Support multiple hash_dist's
    int size = hash_dist.empty() ? 1 : 1 + hash_dist[0].mask;
    json::map &tbl = *base_tbl_cfg(out, "match_entry", size);
    const char *stage_tbl_type = "match_with_no_key";
    size = 1;
    if (auto act = this->get_action()) {
        for (auto &arg : act.args) {
            if (arg.hash_dist()){
                stage_tbl_type = "hash_action";
                size = 1 + hash_dist[0].mask; } } }
    json::map &match_attributes = tbl["match_attributes"];
    json::vector &stage_tables = match_attributes["stage_tables"];
    json::map &stage_tbl = *add_stage_tbl_cfg(match_attributes, stage_tbl_type, size);
    stage_tbl["memory_resource_allocation"] = nullptr;
    match_attributes["match_type"] = stage_tbl_type;
    // FIXME-JSON: If the next table is modifiable then we set it to what it's mapped
    // to. Otherwise, set it to the default next table for this stage.
    stage_tbl["default_next_table"] = Stage::end_of_pipe();
    add_pack_format(stage_tbl, 0, 0, hash_dist.empty() ? 1 : 0);
    add_result_physical_buses(stage_tbl);
    if (actions) {
        actions->gen_tbl_cfg(tbl["actions"]);
        actions->add_action_format(this, stage_tbl);
    } else if (action && action->actions) {
        action->actions->gen_tbl_cfg(tbl["actions"]);
        action->actions->add_action_format(this, stage_tbl); }
    common_tbl_cfg(tbl);
    if (idletime)
        idletime->gen_stage_tbl_cfg(stage_tbl);
    else if (options.match_compiler)
        stage_tbl["stage_idletime_table"] = nullptr;
    add_all_reference_tables(tbl);
    //json::vector &meter_table_refs = tbl["meter_table_refs"] = json::vector();
    //json::vector &selection_table_refs = tbl["selection_table_refs"] = json::vector();
    //json::vector &stateful_table_refs = tbl["stateful_table_refs"] = json::vector();
    //json::vector &action_data_table_refs = tbl["action_data_table_refs"] = json::vector();
    //if (auto a = get_attached()) {
    //    for (auto m : a->meters)
    //        add_reference_table(meter_table_refs, m);
    //    add_reference_table(selection_table_refs, a->selector); }
    //add_reference_table(action_data_table_refs, action);
    gen_idletime_tbl_cfg(stage_tbl);
    if (context_json)
        stage_tbl.merge(*context_json);
}
