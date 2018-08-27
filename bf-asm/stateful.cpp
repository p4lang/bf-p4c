#include "algorithm.h"
#include "data_switchbox.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(StatefulTable)

void StatefulTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::Stateful);
    if (!format)
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data, true)) {
        if (common_setup(kv, data, P4Table::Stateful)) {
        } else if (kv.key == "initial_value") {
            if (CHECKTYPE(kv.value, tMAP)) {
                for (auto &v : kv.value.map) {
                    if (v.key == "lo") {
                        if (CHECKTYPE(v.value, tINT))
                                initial_value_lo = v.value.i; }
                    if (v.key == "hi") {
                        if (CHECKTYPE(v.value, tINT))
                                initial_value_lo = v.value.i; } } }
        } else if (kv.key == "input_xbar") {
            if (CHECKTYPE(kv.value, tMAP))
                input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "hash_dist") {
            /* parsed in common_init_setup */
        } else if (kv.key == "actions") {
            if (CHECKTYPE(kv.value, tMAP))
                actions = new Actions(this, kv.value.map);
        } else if (kv.key == "selection_table") {
            bound_selector = kv.value;
        } else if (kv.key == "const_table") {
            if (!CHECKTYPE2(kv.value, tVEC, tMAP)) continue;
            if (kv.value.type == tVEC) {
                parse_vector(const_vals, kv.value);
            } else {
                for (auto &v : kv.value.map)
                    if (CHECKTYPE(v.key, tINT) && CHECKTYPE(v.value, tINT)) {
                        if (v.key.i < 0 || v.key.i >= 4)
                            error(v.key.lineno, "invalid index for const_table");
                        if (const_vals.size() <= size_t(v.key.i))
                            const_vals.resize(v.key.i + 1);
                        const_vals[v.key.i] = v.value.i; } }
        } else if (kv.key == "math_table") {
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            math_table.lineno = kv.value.lineno;
            for (auto &v : kv.value.map) {
                if (v.key == "data") {
                    if (!CHECKTYPE2(v.value, tVEC, tMAP)) continue;
                    if (v.value.type == tVEC) {
                        parse_vector(math_table.data, v.value);
                    } else {
                        math_table.data.resize(16);
                        for (auto &d : v.value.map)
                            if (CHECKTYPE(d.key, tINT) && CHECKTYPE(d.value, tINT)) {
                                if (d.key.i < 0 || d.key.i >= 16)
                                    error(v.key.lineno, "invalid index for math_table");
                                else
                                    math_table.data[v.key.i] = v.value.i; } }
                } else if (v.key == "invert") {
                    math_table.invert = get_bool(v.value);
                } else if (v.key == "shift") {
                    if (CHECKTYPE(v.value, tINT))
                        math_table.shift = v.value.i;
                } else if (v.key == "scale") {
                    if (CHECKTYPE(v.value, tINT))
                        math_table.scale = v.value.i;
                } else if (v.key.type == tINT && v.key.i >= 0 && v.key.i < 16) {
                    if (CHECKTYPE(v.value, tINT))
                        math_table.data[v.key.i] = v.value.i;
                } else error(v.key.lineno, "Unknow item %s in math_table", value_desc(kv.key)); }
#ifdef HAVE_JBAY
        } else if (options.target == JBAY && setup_jbay(kv)) {
            /* jbay specific extensions done in setup_jbay */
#endif
        } else if (kv.key == "log_vpn") {
            logvpn_lineno = kv.value.lineno;
            if (CHECKTYPE2(kv.value, tINT, tRANGE)) {
                if (kv.value.type == tINT)
                    logvpn_min = logvpn_max = kv.value.i;
                else {
                    logvpn_min = kv.value.lo;
                    logvpn_max = kv.value.hi; } }
        } else if (kv.key == "pred_shift") {
            if (CHECKTYPE(kv.value, tINT))
                if ((pred_shift = kv.value.i) < 0 || pred_shift >= 32 || (pred_shift & 3) != 0)
                    error(kv.value.lineno, "Invalid pred_shift value %d: %s", pred_shift,
                          pred_shift < 0 ? "negative" : pred_shift >= 32 ? "too large" :
                          "must be a mulitple of 4");
        } else if (kv.key == "pred_comb_shift") {
            if (CHECKTYPE(kv.value, tINT))
                if ((pred_comb_shift = kv.value.i) < 0 || pred_comb_shift >= 32)
                    error(kv.value.lineno, "Invalid pred_comb_shift value %d: %s", pred_comb_shift,
                          pred_comb_shift < 0 ? "negative" : "too large");
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
}

bool match_table_layouts(Table *t1, Table *t2) {
    if (t1->layout.size() != t2->layout.size()) return false;
    auto it = t2->layout.begin();
    for (auto &row : t1->layout) {
        if (row.row != it->row) return false;
        if (row.cols != it->cols) return false;
        if (row.maprams.empty())
            row.maprams = it->maprams;
        if (row.maprams != it->maprams) return false;
        ++it; }
    return true;
}

void StatefulTable::MathTable::check() {
    if (data.size() > 16)
        error(lineno, "math table only has 16 data entries");
    data.resize(16);
    for (auto &v : data)
        if (v < 0 || v >= 256)
            error(lineno, "%d out of range for math_table data", v);
    if (shift < -1 || shift > 1)
        error(lineno, "%d out of range for math_table shift", shift);
    if (scale < -32 || scale >= 32)
        error(lineno, "%d out of range for math_table scale", scale);
}

void StatefulTable::pass1() {
    LOG1("### Stateful table " << name() << " pass1");
    if (!p4_table) p4_table = P4Table::alloc(P4Table::Stateful, this);
    else p4_table->check(this);
    alloc_vpns();
    if (bound_selector.check()) {
        if (layout.empty())
            layout = bound_selector->layout;
        else if (!match_table_layouts(this, bound_selector))
            error(layout[0].lineno, "Layout in %s does not match selector %s", name(),
                  bound_selector->name());
        //Add a back reference to this table
        if (!bound_selector->get_stateful())
            bound_selector->set_stateful(this);
    } else {
        alloc_maprams();
        alloc_rams(true, stage->sram_use); }
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    stage->table_use[timing_thread(gress)] |= Stage::USE_STATEFUL;
    for (auto &hd : hash_dist)
        hd.pass1(this);
    if (input_xbar) input_xbar->pass1();
    int prev_row = -1;
    for (auto &row : layout) {
        if (prev_row >= 0)
            need_bus(lineno, stage->overflow_bus_use, row.row, "Overflow");
        else
            need_bus(lineno, stage->meter_bus_use, row.row, "Meter data");
        for (int r = (row.row + 1) | 1; r < prev_row; r += 2)
            need_bus(lineno, stage->overflow_bus_use, r, "Overflow");
        prev_row = row.row; }
    unsigned idx = 0, size = 0;
    for (auto &fld : *format) {
        switch (idx++) {
        case 0:
            if ((size = fld.second.size) != 1 && size != 8 && size != 16 && size != 32 &&
                ((size != 64 && size != 128) || options.target == TOFINO))
                error(format->lineno, "invalid size %d for stateful format field %s",
                      size, fld.first.c_str()); break;
            break;
        case 1:
            if (size != fld.second.size)
                error(format->lineno, "stateful fields must be the same size");
            else if (size == 1)
                error(format->lineno, "one bit stateful tables can only have a single field");
            break;
        default:
            error(format->lineno, "only two fields allowed in a stateful table"); } }
    if ((idx == 2) && (format->size == 2*size))
        dual_mode = true;
    if (actions) {
        actions->pass1(this);
        bool stop = false;
        for (auto &act : *actions) {
            for (auto inst : act.instr) {
                if (inst->salu_output()) {
                    need_bus(layout.at(0).lineno, stage->action_data_use,
                             home_row(), "action data");
                    stop = true;
                    break; } }
            if (stop) break; }
    } else
        error(lineno, "No actions in stateful table %s", name());
    if (math_table)
        math_table.check();
    for (auto &r : sbus_learn)
        if (r.check() && (r->table_type() != STATEFUL || r->stage != stage))
            error(r.lineno, "%s is not a stateful table in the same stage as %s",
                  r->name(), name());
    for (auto &r : sbus_match)
        if (r.check() && (r->table_type() != STATEFUL || r->stage != stage))
            error(r.lineno, "%s is not a stateful table in the same stage as %s",
                  r->name(), name());
    Synth2Port::pass1();
    if (underflow_action.set() && (!actions || !actions->exists(underflow_action.name)))
        error(underflow_action.lineno, "No action %s in table %s",
              underflow_action.name.c_str(), name());
    if (overflow_action.set() && (!actions || !actions->exists(overflow_action.name)))
        error(overflow_action.lineno, "No action %s in table %s",
              overflow_action.name.c_str(), name());
}

int StatefulTable::get_const(long v) {
    size_t rv = std::find(const_vals.begin(), const_vals.end(), v) - const_vals.begin();
    if (rv == const_vals.size())
        const_vals.push_back(v);
    return rv;
}

void StatefulTable::pass2() {
    LOG1("### Stateful table " << name() << " pass2");
    if (input_xbar) input_xbar->pass2();
    if (actions)
        actions->stateful_pass2(this);
    if (stateful_counter_mode) {
        if (logvpn_min < 0)
            layout_vpn_bounds(logvpn_min, logvpn_max, true);
        else if (!offset_vpn) {
            int min, max;
            layout_vpn_bounds(min, max, true);
            if (logvpn_min < min || logvpn_max > max)
                error(logvpn_lineno, "log_vpn out of range (%d..%d)", min, max); } }
}

void StatefulTable::pass3() {
    LOG1("### Stateful table " << name() << " pass3");
}

int StatefulTable::direct_shiftcount() const {
    return 64 + METER_ADDRESS_ZERO_PAD - address_shift();
}

int StatefulTable::indirect_shiftcount() const {
    return METER_ADDRESS_ZERO_PAD - address_shift();
}

int StatefulTable::address_shift() const {
    return ceil_log2(format->size) - meter_adr_shift;
}

unsigned StatefulTable::per_flow_enable_bit(MatchTable *match) const {
    if (!per_flow_enable)
        return METER_ADDRESS_BITS - METER_TYPE_BITS - 1;
    else
        return AttachedTable::per_flow_enable_bit(match);
}

unsigned StatefulTable::determine_shiftcount(Table::Call &call, int group, int word,
        int tcam_shift) const {
    return determine_meter_shiftcount(call, group, word, tcam_shift);
}

#include "tofino/stateful.cpp"
#if HAVE_JBAY
#include "jbay/stateful.cpp"
#endif /* HAVE_JBAY */

template<class REGS> void StatefulTable::write_action_regs(REGS &regs, const Actions::Action *act) {
    int meter_alu = layout[0].row/4U;
    auto &stateful_regs = regs.rams.map_alu.meter_group[meter_alu].stateful;
    auto &salu_instr_common = stateful_regs.salu_instr_common[act->code];
    if (is_dual_mode()) {
        salu_instr_common.salu_datasize = format->log2size - 1;
        salu_instr_common.salu_op_dual = 1; }
    else {
        salu_instr_common.salu_datasize = format->log2size; }
}

template<class REGS> void StatefulTable::write_merge_regs(REGS &regs, MatchTable *match,
            int type, int bus, const std::vector<Call::Arg> &args) {
    auto &merge = regs.rams.match.merge;
    unsigned adr_mask = 0U;
    unsigned per_entry_en_mux_ctl = 0U;
    unsigned adr_default = 0U;
    unsigned meter_type_position = 0U;
    METER_ACCESS_TYPE default_type = match->default_meter_access_type(true);
    AttachedTable::determine_meter_merge_regs(match, type, bus, args, default_type,
            adr_mask, per_entry_en_mux_ctl, adr_default, meter_type_position);
    merge.mau_meter_adr_default[type][bus] = adr_default;
    merge.mau_meter_adr_mask[type][bus] = adr_mask;
    merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = per_entry_en_mux_ctl;
    merge.mau_meter_adr_type_position[type][bus] = meter_type_position;
}

template<class REGS> void StatefulTable::write_regs(REGS &regs) {
    LOG1("### Stateful table " << name() << " write_regs");
    // FIXME -- factor common AttachedTable::write_regs
    // FIXME -- factor common Synth2Port::write_regs
    // FIXME -- factor common CounterTable::write_regs
    // FIXME -- factor common MeterTable::write_regs
    if (input_xbar) input_xbar->write_regs(regs);
    Layout *home = &layout[0];
    bool push_on_overflow = false;
    auto &map_alu =  regs.rams.map_alu;
    auto &merge =  regs.rams.match.merge;
    auto &adrdist = regs.rams.match.adrdist;
    DataSwitchboxSetup<REGS> swbox(regs, this);
    int minvpn, maxvpn;
    layout_vpn_bounds(minvpn, maxvpn, true);
    if (!bound_selector) {
        for (Layout &logical_row : layout) {
            unsigned row = logical_row.row/2U;
            unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
            assert(side == 1);      /* no map rams or alus on left side anymore */
            auto vpn = logical_row.vpns.begin();
            auto mapram = logical_row.maprams.begin();
            auto &map_alu_row =  map_alu.row[row];
            LOG2("# DataSwitchbox.setup(" << row << ") home=" << home->row/2U);
            swbox.setup_row(row);
            for (int logical_col : logical_row.cols) {
                unsigned col = logical_col + 6*side;
                swbox.setup_row_col(row, col, *vpn);
                write_mapram_regs(regs, row, *mapram, *vpn, MapRam::STATEFUL);
                if (gress)
                    regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row);
                ++mapram, ++vpn; }
            /* FIXME -- factor with selector/meter? */
            if (&logical_row == home) {
                auto &vh_adr_xbar = regs.rams.array.row[row].vh_adr_xbar;
                auto &data_ctl = regs.rams.array.row[row].vh_xbar[side].stateful_meter_alu_data_ctl;
                if (input_xbar) {
                    auto hashdata_bytemask = bitmask2bytemask(input_xbar->hash_group_bituse());
                    if (hashdata_bytemask != 0U) {
                        vh_adr_xbar.alu_hashdata_bytemask.alu_hashdata_bytemask_right =
                        hashdata_bytemask;
                        setup_muxctl(vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[2 + side],
                                     input_xbar->hash_group());
                    } else {
                        data_ctl.stateful_meter_alu_data_bytemask = phv_byte_mask;
                        data_ctl.stateful_meter_alu_data_xbar_ctl = 8 | input_xbar->match_group();
                    }
                }
                map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_base = minvpn;
                map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_limit = maxvpn;
                int meter_group_index = row/2U;
                auto &delay_ctl = map_alu.meter_alu_group_data_delay_ctl[meter_group_index];
                delay_ctl.meter_alu_right_group_delay = Target::METER_ALU_GROUP_DATA_DELAY() + row/4 + stage->tcam_delay(gress);
                auto &error_ctl = map_alu.meter_alu_group_error_ctl[meter_group_index];
                error_ctl.meter_alu_group_ecc_error_enable = 1;
                if (output_used) {
                    auto &action_ctl = map_alu.meter_alu_group_action_ctl[meter_group_index];
                    action_ctl.right_alu_action_enable = 1;
                    action_ctl.right_alu_action_delay =
                        stage->group_table_use[gress] & Stage::USE_SELECTOR ? 4 : 0;
                    auto &switch_ctl = regs.rams.array.switchbox.row[row].ctl;
                    switch_ctl.r_action_o_mux_select.r_action_o_sel_action_rd_r_i = 1;
                    // disable action data address huffman decoding, on the assumtion we're not
                    // trying to combine this with an action data table on the same home row.
                    // Otherwise, the huffman decoding will think this is an 8-bit value and
                    // replicate it.
                    regs.rams.array.row[row].action_hv_xbar.action_hv_xbar_disable_ram_adr
                        .action_hv_xbar_disable_ram_adr_right = 1; }
            } else {
                auto &adr_ctl = map_alu_row.vh_xbars.adr_dist_oflo_adr_xbar_ctl[side];
                if (home->row >= 8 && logical_row.row < 8) {
                    adr_ctl.adr_dist_oflo_adr_xbar_source_index = 0;
                    adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::OVERFLOW;
                    push_on_overflow = true;
                } else {
                    adr_ctl.adr_dist_oflo_adr_xbar_source_index = home->row % 8;
                    adr_ctl.adr_dist_oflo_adr_xbar_source_sel = AdrDist::METER; }
                adr_ctl.adr_dist_oflo_adr_xbar_enable = 1; } } }
    if (actions)
        actions->write_regs(regs, this);
    unsigned meter_group = home->row/4U;
    for (MatchTable *m : match_tables)
        adrdist.mau_ad_meter_virt_lt[meter_group] |= 1U << m->logical_id;
    if (!bound_selector) {
        bool first_match = true;
        for (MatchTable *m : match_tables) {
            adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id] = 1 << meter_group;
            adrdist.movereg_ad_meter_alu_to_logical_xbar_ctl[m->logical_id/8U].set_subfield(
                4 | meter_group, 3*(m->logical_id % 8U), 3);
            if (first_match)
                adrdist.movereg_meter_ctl[meter_group].movereg_meter_ctl_lt = m->logical_id;
            if (direct) {
                if (first_match)
                    adrdist.movereg_meter_ctl[meter_group].movereg_meter_ctl_direct = 1;
                adrdist.movereg_ad_direct[MoveReg::METER] |= 1U << m->logical_id; }
            first_match = false; }
        adrdist.movereg_meter_ctl[meter_group].movereg_ad_meter_shift = format->log2size;
        if (push_on_overflow)
            adrdist.oflo_adr_user[0] = adrdist.oflo_adr_user[1] = AdrDist::METER;
        adrdist.packet_action_at_headertime[1][meter_group] = 1; }
    write_logging_regs(regs);
    //for (auto &hd : hash_dist)
    //    hd.write_regs(regs, this, 0, non_linear_hash);
    if (gress == INGRESS || gress == GHOST) {
        merge.meter_alu_thread[0].meter_alu_thread_ingress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_ingress |= 1U << meter_group;
    } else if (gress == EGRESS) {
        merge.meter_alu_thread[0].meter_alu_thread_egress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_egress |= 1U << meter_group; }
    auto &salu = regs.rams.map_alu.meter_group[meter_group].stateful;
    salu.stateful_ctl.salu_enable = 1;
    salu.stateful_ctl.salu_output_pred_shift = pred_shift / 4;
    salu.stateful_ctl.salu_output_pred_comb_shift = pred_comb_shift;
    if (gress == EGRESS) {
        regs.rams.map_alu.meter_group[meter_group].meter.meter_ctl.meter_alu_egress = 1;
    }
    if (math_table) {
        for (size_t i = 0; i < math_table.data.size(); ++i)
            salu.salu_mathtable[i/4U].set_subfield(math_table.data[i], 8*(i%4U), 8);
        salu.salu_mathunit_ctl.salu_mathunit_output_scale = math_table.scale & 0x2fU;
        salu.salu_mathunit_ctl.salu_mathunit_exponent_invert = math_table.invert;
        salu.salu_mathunit_ctl.salu_mathunit_exponent_shift = math_table.shift & 0x2U; }
}

void StatefulTable::gen_tbl_cfg(json::vector &out) {
    // FIXME -- factor common Synth2Port stuff
    int size = (layout_size() - 1) * 1024 * (128U/format->size);
    json::map &tbl = *base_tbl_cfg(out, "stateful", size);
    unsigned alu_width = format->size/(dual_mode ? 2 : 1);
    tbl["alu_width"] = alu_width;
    tbl["dual_width_mode"] = dual_mode;
    json::vector &act_to_sful_instr_slot = tbl["action_to_stateful_instruction_slot"];
    if (actions) {
        for (auto &a : *actions) {
            for (auto &i : a.instr) {
                if (i->name() == "set_bit_at")
                    tbl["set_instr_at"] = a.code;
                if (i->name() == "set_bit")
                    tbl["set_instr"] = a.code;
                if (i->name() == "clr_bit_at")
                    tbl["clr_instr_at"] = a.code;
                if (i->name() == "clr_bit")
                    tbl["clr_instr"] = a.code; } } }
    // Add action handle and instr slot for action which references stateful
    for (auto *m : get_match_tables()) {
        if (auto *acts = m->get_actions()) {
            for (auto &a : *acts) {
                // Check for action args to determine which stateful action is
                // called. If no args are present skip as the action does not
                // invoke stateful
                bool action_invokes_stateful = false;
                Actions::Action * stful_action = nullptr;
                if (indirect) {
                    for (auto att : a.attached) {
                        if (att->table_type() != Table::STATEFUL)
                            continue;
                        if (att.args.size() == 0)
                            continue;
                        auto meter_type_arg = att.args[0];
                        if (meter_type_arg.type == Call::Arg::Name) {
                            // Check if stateful has this called action
                            stful_action = actions->action(meter_type_arg.name());
                            if (stful_action) {
                                action_invokes_stateful = true;
                                break;
                            }
                        } else if (meter_type_arg.type == Call::Arg::Const) {
                            int index = -1;
                            switch(meter_type_arg.value()) {
                                case STATEFUL_INSTRUCTION_0:
                                    index = 0; break;
                                case STATEFUL_INSTRUCTION_1:
                                    index = 1; break;
                                case STATEFUL_INSTRUCTION_2:
                                    index = 2; break;
                                case STATEFUL_INSTRUCTION_3:
                                    index = 3; break;
                            }
                            if (index == -1)
                                continue;
                            if (actions->size() < index)
                                continue;
                            auto it = actions->begin();
                            std::advance(it, index);
                            stful_action = &(*it);
                            action_invokes_stateful = true;
                            break;
                        }
                    }
                } else {
                    // If stateful is direct, all user defined actions will
                    // invoke stateful except for the miss action. This is
                    // defined as 'default_only' in p4, if not the compiler
                    // generates a default_only action and adds it
                    // FIXME: Brig should add these generated actions as
                    // default_only in assembly
                    if (!((a.name == m->default_action) && m->default_only_action)) {
                        // Direct has only one action
                        if (actions)
                            stful_action = &*actions->begin();
                        action_invokes_stateful = true; } }
                if (!action_invokes_stateful) continue;
                bool act_present = false;
                // Do not add handle if already present, if stateful spans
                // multiple stages this can happen as action handles are unique
                // and this code will get called again
                for (auto &s: act_to_sful_instr_slot) {
                    auto s_handle = s->to<json::map>()["action_handle"];
                    if (*s_handle->as_number() == a.handle) {
                        act_present = true; break; } }
                if (act_present) continue;
		        json::map instr_slot;
		        instr_slot["action_handle"] = a.handle;
		        instr_slot["instruction_slot"] = stful_action ? stful_action->code : -1;
		        act_to_sful_instr_slot.push_back(std::move(instr_slot)); } } }
    if (bound_selector)
        tbl["bound_to_selection_table_handle"] = bound_selector->handle();
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "stateful", size);
    add_alu_index(stage_tbl, "meter_alu_index");
    if (initial_value_lo > 0)
        tbl["initial_value_lo"] = initial_value_lo;
    if (initial_value_hi > 0)
        tbl["initial_value_hi"] = initial_value_hi;
    SWITCH_FOREACH_TARGET(options.target, gen_tbl_cfg(TARGET(), tbl, stage_tbl); )
    if (context_json)
        stage_tbl.merge(*context_json);
}
