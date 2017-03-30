#include "action_bus.h"
#include "input_xbar.h"
#include "stage.h"
#include "tables.h"

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
    //if (bus >= 2) stage->table_use[gress] |= Stage::USE_TCAM;
    if (input_xbar)
        input_xbar->pass2();
    if (actions) actions->pass2(this);
    if (action_bus) action_bus->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
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

void HashActionTable::gen_tbl_cfg(json::vector &out) {
    int size = hash_dist.empty() ? 1 : 1 + hash_dist[0].mask;
    json::map &tbl = *base_tbl_cfg(out, "match_entry", size);
    size = tbl["number_entries"].get()->as_number()->val;
    if (!tbl.count("preferred_match_type"))
        tbl["preferred_match_type"] = "exact";
    const char *stage_tbl_type = "hash_action";
    if (hash_dist.empty()) {
        stage_tbl_type = "match_with_no_key";
        size = 1; }
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, stage_tbl_type, size);
    add_pack_format(stage_tbl, 0, 0, hash_dist.empty() ? 1 : 0);
    if (options.match_compiler)
        stage_tbl["memory_resource_allocation"] = nullptr;
    if (actions)
        actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
    if (!default_action.empty()) {
        tbl["default_action"] = default_action;
        json::vector &params = tbl["default_action_parameters"] = json::vector();
        for (auto val : default_action_args)
            params.push_back(val);
    } else if (options.match_compiler) {
        tbl["default_action"] = nullptr;
        tbl["default_action_parameters"] = nullptr; }
    if (idletime)
        idletime->gen_stage_tbl_cfg(stage_tbl);
    else if (options.match_compiler)
        stage_tbl["stage_idletime_table"] = nullptr;
    tbl["performs_hash_action"] = !hash_dist.empty();
    tbl["uses_versioning"] = true;  // FIXME
    tbl["tcam_error_detect"] = false;
    tbl["match_type"] = p4_table->match_type.empty() ? "exact" : p4_table->match_type;
    if (!p4_table->action_profile.empty())
        tbl["action_profile"] = p4_table->action_profile;
    else
        tbl["action_profile"] = nullptr;
}
