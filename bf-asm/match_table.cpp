#include <config.h>

#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

#include <unordered_map>


void MatchTable::common_init_setup(const VECTOR(pair_t) &data, bool ternary, P4Table::type p4type) {
    Table::common_init_setup(data, ternary, p4type);
    setup_logical_id();
    if (auto *ixbar = get(data, "input_xbar")) {
        if (CHECKTYPE(*ixbar, tMAP))
            input_xbar = new InputXbar(this, ternary, ixbar->map); }
}

bool MatchTable::common_setup(pair_t &kv, const VECTOR(pair_t) &data, P4Table::type p4type) {
    if (Table::common_setup(kv, data, p4type)) {
        return true; }
    if (kv.key == "input_xbar" || kv.key == "hash_dist") {
        /* done in common_init_setup */
        return true; }
    if (kv.key == "gateway") {
        if (CHECKTYPE(kv.value, tMAP)) {
            gateway = GatewayTable::create(kv.key.lineno, name_+" gateway",
                                           gress, stage, -1, kv.value.map);
            gateway->set_match_table(this, false); }
        return true; }
    if (kv.key == "idletime") {
        if (CHECKTYPE(kv.value, tMAP)) {
            idletime = IdletimeTable::create(kv.key.lineno, name_+" idletime",
                                             gress, stage, -1, kv.value.map);
            idletime->set_match_table(this, false); }
        return true; }
    if (kv.key == "selector") {
        attached.selector.setup(kv.value, this);
        return true; }
    if (kv.key == "stats") {
        if (kv.value.type == tVEC)
            for (auto &v : kv.value.vec)
                attached.stats.emplace_back(v, this);
        else attached.stats.emplace_back(kv.value, this);
        return true; }
    if (kv.key == "meter") {
        if (kv.value.type == tVEC)
            for (auto &v : kv.value.vec)
                attached.meters.emplace_back(v, this);
        else attached.meters.emplace_back(kv.value, this);
        return true; }
    if (kv.key == "stateful") {
        if (kv.value.type == tVEC)
            for (auto &v : kv.value.vec)
                attached.statefuls.emplace_back(v, this);
        else attached.statefuls.emplace_back(kv.value, this);
        return true; }
    if (kv.key == "table_counter") {
        if (kv.value == "table_miss") table_counter = TABLE_MISS;
        else if (kv.value == "table_hit") table_counter = TABLE_HIT;
        else if (kv.value == "gateway_miss") table_counter = GATEWAY_MISS;
        else if (kv.value == "gateway_hit") table_counter = GATEWAY_HIT;
        else if (kv.value == "gateway_inhibit") table_counter = GATEWAY_INHIBIT;
        else if (kv.value == "disabled") table_counter = DISABLED;
        else error(kv.value.lineno, "Invalid table counter %s", value_desc(kv.value));
        return true; }
    return false;
}

bool MatchTable::is_attached(const Table *tbl) const {
    return tbl && (tbl == gateway || tbl == idletime || get_attached()->is_attached(tbl));
}

void MatchTable::pass0() {
    LOG1("### match table " << name() << " pass0");
    alloc_id("logical", logical_id, stage->pass1_logical_id,
             LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    if (action.check() && action->set_match_table(this, action.args.size() > 1) != ACTION)
        error(action.lineno, "%s is not an action table", action->name());
    attached.pass0(this);
}

void MatchTable::pass1(int type) {
    /* FIXME -- move common stuff from Exact/Ternary/HashAction here. */
    // Set up default action. This will look up action and/or tind for default
    // action if the match_table doesnt have one specified
    if (default_action.empty()) default_action = get_default_action();
    if (table_counter >= GATEWAY_MISS && !gateway)
        error(lineno, "Can't count gateway events on table %s as it doesn't have a gateway",
              name());
    if (!p4_params_list.empty()) {
        for (auto &p : p4_params_list) {
            // bit_width_full should be generated in assembly as 'full_size' in
            // the 'p4_param_order'. This is the full size of the field as used
            // in p4 program.
            if (!p.bit_width_full)
                p.bit_width_full = p.bit_width;
            stack_asm_name_to_p4(p.name);
            bool found = remove_aug_names(p.name);
            if (found)
                p.is_valid = true; } }
}

void MatchTable::gen_idletime_tbl_cfg(json::map &stage_tbl) {
   if (idletime)
       idletime->gen_stage_tbl_cfg(stage_tbl);
}

#include "tofino/match_table.cpp"
#if HAVE_JBAY
#include "jbay/match_table.cpp"
#endif // HAVE_JBAY

template<class TARGET> void MatchTable::write_common_regs(typename TARGET::mau_regs &regs,
                                                          int type, Table *result) {
    /* this follows the order and behavior in stage_match_entry_table.py
     * it can be reorganized to be clearer */

    /*------------------------
     * data path
     *-----------------------*/
    if (gress == EGRESS)
        regs.dp.imem_table_addr_egress |= 1 << logical_id;

    /*------------------------
     * Match Merge
     *-----------------------*/
    auto &merge = regs.rams.match.merge;
    auto &adrdist = regs.rams.match.adrdist;
    merge.predication_ctl[gress].table_thread |= 1 << logical_id;
    if (gress) {
        merge.logical_table_thread[0].logical_table_thread_egress |= 1 << logical_id;
        merge.logical_table_thread[1].logical_table_thread_egress |= 1 << logical_id;
        merge.logical_table_thread[2].logical_table_thread_egress |= 1 << logical_id;
    } else {
        merge.logical_table_thread[0].logical_table_thread_ingress |= 1 << logical_id;
        merge.logical_table_thread[1].logical_table_thread_ingress |= 1 << logical_id;
        merge.logical_table_thread[2].logical_table_thread_ingress |= 1 << logical_id; }
    adrdist.adr_dist_table_thread[gress][0] |= 1 << logical_id;
    adrdist.adr_dist_table_thread[gress][1] |= 1 << logical_id;

    Actions *actions = action ? action->actions : this->actions;
    if (result) {
        actions = result->action ? result->action->actions : result->actions;
        unsigned action_enable = 0;
        if (result->action_enable >= 0)
            action_enable = 1 << result->action_enable;
        for (auto &row : result->layout) {
            int bus = row.row*2 | (row.bus & 1);
            auto &shift_en = merge.mau_payload_shifter_enable[type][bus];
            setup_muxctl(merge.match_to_logical_table_ixbar_outputmap[type][bus], logical_id);
            setup_muxctl(merge.match_to_logical_table_ixbar_outputmap[type+2][bus], logical_id);

            int default_action = 0;
            if (result->action.args.size() >= 1 && result->action.args[0].field()) {
                merge.mau_action_instruction_adr_mask[type][bus] =
                    ((1U << result->action.args[0].size()) - 1) & ~action_enable;
            } else {
                if (this->to<HashActionTable>() && this->get_gateway())
                    merge.mau_action_instruction_adr_mask[type][bus] = 1;
                else
                    merge.mau_action_instruction_adr_mask[type][bus] = 0;
                if (actions->count() == 1)
                    default_action = actions->begin()->code;
            }
            if (!result->enable_action_instruction_enable)
                default_action |= ACTION_INSTRUCTION_ADR_ENABLE;
            merge.mau_action_instruction_adr_default[type][bus] = default_action;
            // must enable to get the default, even if the shifter itself is unneeded
            shift_en.action_instruction_adr_payload_shifter_en = 1;

            if (action_enable) {
                if (result->enable_action_instruction_enable)
                    merge.mau_action_instruction_adr_per_entry_en_mux_ctl[type][bus] =
                        result->action_enable;
                if (enable_action_data_enable)
                    merge.mau_actiondata_adr_per_entry_en_mux_ctl[type][bus] =
                        result->action_enable + 5;
            }
            if (idletime)
                idletime->write_merge_regs(regs, type, bus);
            if (result->action) {
                if (auto adt = result->action->to<ActionTable>()) {
                    merge.mau_actiondata_adr_default[type][bus] =
                        get_address_mau_actiondata_adr_default(adt->get_log2size(),
                                                               result->enable_action_data_enable); }
                if (enable_action_data_enable || !dynamic_cast<HashActionTable *>(this))
                    /* HACK -- HashAction tables with no action data don't need this? */
                    shift_en.actiondata_adr_payload_shifter_en = 1; }
            if (!get_attached()->stats.empty())
                shift_en.stats_adr_payload_shifter_en = 1;
            if (!get_attached()->meters.empty() || !get_attached()->statefuls.empty())
                shift_en.meter_adr_payload_shifter_en = 1;

            result->write_merge_regs(regs, type, bus); }
    } else {
        /* ternary match with no indirection table */
        assert(type == 1);
        result = this; }

    /*------------------------
     * Action instruction Address
     *-----------------------*/
    int max_code = actions->max_code;
    if (options.match_compiler)
        if (auto *action_format = lookup_field("action"))
            max_code = (1 << (action_format->size - (gateway ? 1 : 0))) - 1;
    if (max_code < ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH) {
        merge.mau_action_instruction_adr_map_en[type] |= (1U << logical_id);
        for (auto &act : *actions)
            if ((act.name != result->default_action) || !result->default_only_action) {
                merge.mau_action_instruction_adr_map_data[type][logical_id][act.code/4]
                    .set_subfield(act.addr + ACTION_INSTRUCTION_ADR_ENABLE,
                                  (act.code%4) * TARGET::ACTION_INSTRUCTION_MAP_WIDTH,
                                  TARGET::ACTION_INSTRUCTION_MAP_WIDTH);
            } }
    if (this->to<HashActionTable>()) {
        merge.mau_action_instruction_adr_miss_value[logical_id] = 0;
    } else if (!default_action.empty()) {
        auto *act = actions->action(default_action);
        merge.mau_action_instruction_adr_miss_value[logical_id] =
            ACTION_INSTRUCTION_ADR_ENABLE + act->addr;
    } else if (!result->default_action.empty()) {
        auto *act = actions->action(result->default_action);
        merge.mau_action_instruction_adr_miss_value[logical_id] =
            ACTION_INSTRUCTION_ADR_ENABLE + act->addr; }

    /*------------------------
     * Next Table
     *-----------------------*/
    // Next Table processing can have 4 different types
    // 1. One Next Table - No action or next bits in format, uses indirection
    // map set, index 0 to next table, mask is 0, default doesnt matter
    // 2. Action bits only - No next bits in format, uses indirection map, set
    // index to action bits and configure 'next_table' in cjson as this index,
    // mask is for action bits, default doesnt matter
    // 3. Next bits < 8 - Uses indirection map, set index to next bits
    // and configure 'next_table' in cjson as this index, mask is for next bits,
    // default doesnt matter
    // 4. Next bits == 8- Does not use indirection map, uses all 8 bits to
    // configure full address in 'next_table', set default address to full
    // address
    Table *next = result->hit_next.size() > 0 ? result : this;
    int next_field_size = next->get_format_field_size("next");
    int action_field_size = next->get_format_field_size("action");
    if (next->hit_next.empty()) {
        /* nothing to do... */
    } else if (next->hit_next.size() == 1) {
        // Only 1 next table, action bits may or may not be present.
        // Scenario 1 : Action bits present < 8 actions
        // Scenario 2 : Action bits present > 8 actions
        // Scenario 3 : Action bits absent = 1 action
        setup_next_table_map(regs, next);
    } else if (((1U << next_field_size) <= NEXT_TABLE_SUCCESSOR_TABLE_DEPTH)
            && (next_field_size > 0)) {
        // Only setup next table map if there are < 8 next tables when 'next'
        // field is present in format.
        setup_next_table_map(regs, next);
    } else if ((1U << action_field_size) <= NEXT_TABLE_SUCCESSOR_TABLE_DEPTH) {
        // Only setup next table map if there are < 8 next tables when 'action'
        // field is present or absent in format. If no 'action' field is present
        // in format index 0 is used to setup the default next table
        setup_next_table_map(regs, next); }

    if (next->miss_next || next->miss_next == "END") {
        merge.next_table_format_data[logical_id].match_next_table_adr_miss_value =
            default_next_table_id = next->miss_next ? next->miss_next->table_id()
                                                    : Stage::end_of_pipe(); }
    // For next table processing the address coming from match overhead goes
    // through either
    // 1. And'ed with an adr_mask and or'ed with an adr_default.
    // 2. And'ed with an adr_mask and lower 3 bits sent to index the next table
    // map.
    // This is different from the shift - mask - or which happens in match
    // merge for other registers. The adr_mask must be set according to how many
    // bits in the match overhead are being used to determine next table address
    // either directly or via indexing into the indirection table.  Sec 6.4.3.3
    // on Next Table Processing in MAU uArch.
    if (next->hit_next.size() > 1) {
        unsigned adr_mask = (1U << ceil_log2(next->hit_next.size())) - 1;
        // Generate mask on no. of bits required to denote the next table bits
        if (next_field_size > 0)
            adr_mask = (1U << next_field_size) - 1;
        default_next_table_mask = adr_mask;
        merge.next_table_format_data[logical_id].match_next_table_adr_mask = adr_mask;
    } else if (next->hit_next.size() == 1) {
        merge.next_table_format_data[logical_id].match_next_table_adr_mask =
            default_next_table_mask = 0;
        merge.next_table_format_data[logical_id].match_next_table_adr_default =
            next->hit_next[0] ? next->hit_next[0]->table_id() : Stage::end_of_pipe();
    } else {
        merge.next_table_format_data[logical_id].match_next_table_adr_mask =
        merge.next_table_format_data[logical_id].match_next_table_adr_default = Stage::end_of_pipe(); }


    /*------------------------
     * Immediate data found in overhead
     *-----------------------*/
    if (result->format) {
        for (auto &row : result->layout) {
            int bus = row.row*2 | (row.bus & 1);
            merge.mau_immediate_data_mask[type][bus] = (1UL << result->format->immed_size)-1;
            if (result->format->immed_size > 0)
                merge.mau_payload_shifter_enable[type][bus]
                    .immediate_data_payload_shifter_en = 1; } }
    if (result->action_bus) {
        result->action_bus->write_immed_regs(regs, result);
        for (auto &mtab : get_attached()->meters) {
            // if the meter table outputs something on the action-bus of the meter
            // home row, need to set up the action hv xbar properly
            result->action_bus->write_action_regs(regs, result, mtab->home_row(), 0); }
        for (auto &stab : get_attached()->statefuls) {
            // if the stateful table outputs something on the action-bus of the meter
            // home row, need to set up the action hv xbar properly
            result->action_bus->write_action_regs(regs, result, stab->home_row(), 0); }
    }

    // FIXME:
    // The action parameters that are stored as immediates in the match
    // overhead need to be properly packed into this register. We had been
    // previously assuming that the compiler would do that for us, specifying
    // the bits needed here as the argument to the action call; eg assembly
    // code like:
    //         default_action: actname(0x100)
    // for the default action being actname with the value 0x100 for its
    // parameters stored as immediates (which might actually be several
    // parameters in the P4 source code.) To get this from the
    // default_action_parameters map, we need to look up those argument names
    // in the match table format and action aliases and figure out which ones
    // correspond to match immediates, and pack the values appropriately.
    // Doable but non-trivial, probably requiring a small helper function. Need
    // to deal with both exact match and ternary indirect.
    //
    // For now, most miss configuration registers are only written by the driver
    // (since the user API says what miss behavior to perform). The compiler
    // (glass) relies on the driver to write them but this could change in
    // future. This particular register would only be set if the compiler chose
    // to allocate action parameters in match overhead.
    //
    //if (default_action_parameters.size() > 0)
    //    merge.mau_immediate_data_miss_value[logical_id] = default_action_parameters[0];
    //else if (result->default_action_parameters.size() > 0)
    //    merge.mau_immediate_data_miss_value[logical_id] = result->default_action_parameters[0];

    if (input_xbar) input_xbar->write_regs(regs);

    if (gress == EGRESS)
        regs.cfg_regs.mau_cfg_lt_thread |= 1U << logical_id;
    if (options.match_compiler && dynamic_cast<HashActionTable *>(this))
        return; // skip the rest

    if (table_counter) {
        merge.mau_table_counter_ctl[logical_id/8U].set_subfield(
            table_counter, 3 * (logical_id%8U), 3);
    } else { // Set to TABLE_HIT by default
        merge.mau_table_counter_ctl[logical_id/8U].set_subfield(
            TABLE_HIT, 3 * (logical_id%8U), 3); }
}

void MatchTable::gen_name_lookup(json::map &out) {
    if (p4_table && p4_table->p4_name())
        out["table_name"] = p4_table->p4_name();
    else
        out["table_name"] = name();
    json::map &actions_map = out["actions"] = json::map();
    if (auto acts = get_actions()) {
        for (auto &a : *acts) {
            json::map &action_map = actions_map[a.name] = json::map();
            action_map["direction"] = logical_id;
            json::vector &prims = action_map["primitives"] = json::vector();
        }
    }
}

int MatchTable::get_address_mau_actiondata_adr_default(unsigned log2size, bool per_flow_enable) {
    int huffman_ones = log2size > 2 ? log2size - 3 : 0;
    assert(huffman_ones < 7);
    int rv = (1 << huffman_ones) - 1;
    rv = ((rv << 10) & 0xf8000) | ( rv & 0x1f);
    if (!per_flow_enable)
        rv |= 1 << 22;
    return rv;
}

// Create json node for all hash bits
void MatchTable::gen_hash_bits(const std::map<int, HashCol> &hash_table,
        unsigned hash_table_id, json::vector &hash_bits) {
    for (auto &col: hash_table) {
        json::map hash_bit;
        bool hash_bit_added = false;
        json::vector *bits_to_xor_prev;
        for (auto &hb : hash_bits) {
            if (hb->to<json::map>()["hash_bit"]->to<json::number>() == json::number(col.first)) {
                bits_to_xor_prev = &(hb->to<json::map>()["bits_to_xor"]->to<json::vector>());
                hash_bit_added = true; } }
        hash_bit["hash_bit"] = col.first;
        hash_bit["seed"] = input_xbar->get_seed_bit(hash_table_id, col.first);
        json::vector &bits_to_xor = hash_bit["bits_to_xor"] = json::vector();
        for (const auto &bit: col.second.data) {
            json::map field;
            if (auto ref = input_xbar->get_hashtable_bit(hash_table_id, bit)) {
                std::string field_name = ref.name();
                // FIXME -- if field_name is a raw register name, should lookup in PHV for alias?
                // Make names compatible with PD Gen API
                remove_aug_names(field_name);
                stack_asm_name_to_p4(field_name);
                field["field_bit"] = remove_name_tail_range(field_name) + ref.lobit();
                // Sanity check to see if field_name is also in p4_param_list.
                if (!find_p4_param(field_name) && !p4_params_list.empty())
                    warning(col.second.lineno, "Cannot find field name %s in p4_param_order "
                            "for table %s", field_name.c_str(), name());
                field["field_name"] = field_name;
                field["hash_match_group"] = input_xbar->hash_group();
                field["hash_match_group_bit"] = 0;  // FIXME: input_xbar->get_group_bit(input_xbar->get_group() col.first);
            }
            if (!hash_bit_added)
                bits_to_xor.push_back(std::move(field));
            else
                bits_to_xor_prev->push_back(std::move(field)); }
        if (!hash_bit_added)
            hash_bits.push_back(std::move(hash_bit)); }
}

void MatchTable::add_hash_functions(json::map &stage_tbl) {
    json::vector &hash_functions = stage_tbl["hash_functions"] = json::vector();
    // XXX(amresh): Hash functions are not generated for ALPM atcams as the
    // partition index bits used in hash which is a compiler generated field and
    // should not be in 'match_key_fields'. The tests in p4factory are written
    // with match_spec to not include the partition index field. Glass also
    // generates an empty 'hash_functions' node
    if (is_alpm()) return;
    // Emit hash info only if p4_param_order (match_key_fields) are present
    // FIXME: This input_xbar is populated if its a part of the hash_action
    // table or the hash_distribution which is incorrect. This should move
    // inside the hash_dist so this condition does not occur in the
    // hash_action table
    if (!p4_params_list.empty() && input_xbar) {
        auto ht = input_xbar->get_hash_tables();
        if (ht.size() > 0) {
            // Merge all bits to xor across multiple hash ways in single
            // json::vector for each hash bit
            json::map hash_function;
            json::vector &hash_bits = hash_function["hash_bits"] = json::vector();
            for (const auto hash_table : ht) {
                hash_function["hash_function_number"] = hash_table.first;
                gen_hash_bits(hash_table.second, hash_table.first, hash_bits);
            hash_functions.push_back(std::move(hash_function)); } } }
}

void MatchTable::add_all_reference_tables(json::map &tbl, Table *match_table) {
    if (!match_table) match_table = this;
    json::vector &action_data_table_refs = tbl["action_data_table_refs"];
    json::vector &selection_table_refs = tbl["selection_table_refs"];
    json::vector &meter_table_refs = tbl["meter_table_refs"];
    json::vector &statistics_table_refs = tbl["statistics_table_refs"];
    json::vector &stateful_table_refs = tbl["stateful_table_refs"];
    add_reference_table(action_data_table_refs, match_table->action);
    if (auto a = match_table->get_attached()) {
        if (a->selector) {
            tbl["default_selector_mask"] = 0; //FIXME-JSON
            tbl["default_selector_value"] = 0; //FIXME-JSON
            add_reference_table(selection_table_refs, a->selector); }
        for (auto &m : a->meters) { add_reference_table(meter_table_refs, m); }
        for (auto &s : a->stats) { add_reference_table(statistics_table_refs, s); }
        for (auto &s : a->statefuls) { add_reference_table(stateful_table_refs, s); } }
}

void MatchTable::add_static_entries(json::map &tbl) {
    if (static_entries_list.size() > 0) {
        json::vector &static_entries = tbl["static_entries"];
        for (auto &s : static_entries_list) {
            json::map static_entry;
            static_entry["priority"] = s.priority;
            static_entry["is_default_entry"] = s.is_default_entry ? true : false;
            if (auto acts = get_actions()) {
                if (auto a = acts->action(s.action)) {
                    static_entry["action_handle"] = a->handle;
                    if (s.action_parameters_values.size() == a->p4_params_list.size()) {
                        json::vector &action_parameters_values = static_entry["action_parameters_values"];
                        int idx = 0;
                        for (auto m : s.action_parameters_values) {
                            json::map action_parameter;
                            action_parameter["parameter_name"] = a->p4_params_list[idx++].name;
                            action_parameter["value"] = m;
                            action_parameters_values.push_back(std::move(action_parameter));
                        }
                    }
                    if (s.match_key_fields_values.size() == p4_params_list.size()) {
                        json::vector &match_key_fields_values = static_entry["match_key_fields_values"];
                        int idx = 0;
                        for (auto m : s.match_key_fields_values) {
                            json::map match_key_field;
                            match_key_field["field_name"] = p4_params_list[idx++].name;
                            match_key_field["value"] = m;
                            match_key_fields_values.push_back(std::move(match_key_field));
                        }
                    }
                }
            }
            static_entries.push_back(std::move(static_entry));
        }
    }
}

