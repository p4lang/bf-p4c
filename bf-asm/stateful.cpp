#include "algorithm.h"
#include "data_switchbox.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(Stateful)

void Stateful::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::Stateful);
    if (!format)
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data, true)) {
        if (common_setup(kv, data, P4Table::Stateful)) {
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
                for (auto &v : kv.value.vec)
                    if (CHECKTYPE(v, tINT))
                        const_vals.push_back(v.i);
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
                        for (auto &d : v.value.vec)
                            if (CHECKTYPE(d, tINT))
                                math_table.data.push_back(d.i);
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

void Stateful::MathTable::check() {
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

void Stateful::pass1() {
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
    stage->table_use[gress] |= Stage::USE_STATEFUL;
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
            if ((size = fld.second.size) != 1 && size != 8 && size != 16 && size != 32)
                error(format->lineno, "invalid size %d for stateful format field %s",
                      size, fld.first.c_str()); break;
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
    if (actions) actions->pass1(this);
    if (math_table)
        math_table.check();
    AttachedTable::pass1();
}

int Stateful::get_const(long v) {
    size_t rv = std::find(const_vals.begin(), const_vals.end(), v) - const_vals.begin();
    if (rv == const_vals.size())
        const_vals.push_back(v);
    return rv;
}

void Stateful::pass2() {
    LOG1("### Stateful table " << name() << " pass2");
    if (input_xbar) input_xbar->pass2();
    if (actions)
        actions->stateful_pass2(this);
}

int Stateful::direct_shiftcount() {
    return 64;
}

int Stateful::indirect_shiftcount() {
    return 7U - (64U/format->size);
}

template<class REGS> void Stateful::write_merge_regs(REGS &regs, MatchTable *match,
            int type, int bus, const std::vector<Call::Arg> &args) {
    auto &merge = regs.rams.match.merge;
    assert(args.size() <= 1);
    //if (args.empty()) { // direct access
    //    merge.mau_meter_adr_mask[type][bus] = 0x7fff80;
    //} else if (args[0].type == Call::Arg::Field) {
    //    // indirect access via overhead field
    //    int bits = args[0].size() - 3;
    //    if (per_flow_enable) --bits;
    //    merge.mau_meter_adr_mask[type][bus] = 0x700000 | (~(~0u << bits) << 7);
    //} else if (args[0].type == Call::Arg::HashDist) {
    //    // indirect access via hash_dist
    //    merge.mau_meter_adr_mask[type][bus] = 0x7fff80; }
    //merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = 16; // FIXME
    //merge.mau_meter_adr_type_position[type][bus] = per_flow_enable ? 16 : 17;
    //if (!per_flow_enable)
    //    merge.mau_meter_adr_default[type][bus] |= 1 << 23;
    //merge.mau_meter_adr_default[type][bus] |= 1 << 24;  // FIXME -- instruction number?

    unsigned ptr_bits = 0;
    unsigned entry_bit_width = format->size/(dual_mode ? 2 : 1);
    unsigned bw_adjust = ceil_log2(entry_bit_width);
    unsigned full_mask = (1U << METER_ADDRESS_BITS) - 1;
    unsigned instr_slots = get_instruction_count();
    if (args.empty()) { // direct access
        if (match->to<ExactMatchTable>()) {
            if (entry_bit_width < 16)
                ptr_bits = EXACT_VPN_BITS + EXACT_WORD_BITS;
            else {
                ptr_bits = METER_ADDRESS_BITS - METER_TYPE_BITS - 1 - bw_adjust; }
        } else
            ptr_bits = TCAM_VPN_BITS + TCAM_WORD_BITS;
    } else if (args[0].type == Call::Arg::HashDist) {
        // indirect access via hash dist
        if (instr_slots > 1)
            ptr_bits = METER_TYPE_BITS - 1;
        if (per_flow_enable)
            ptr_bits += 1;
    } else {
        ptr_bits = METER_ADDRESS_BITS - bw_adjust;
        if (!per_flow_enable)
            ptr_bits -= 1;
        if (instr_slots < 2)
            ptr_bits -= METER_TYPE_BITS;
        else
            ptr_bits -= 1;
    }

    unsigned stateful_adr_default = 0x0;
    if (!per_flow_enable)
        stateful_adr_default |= (1U << METER_PER_FLOW_ENABLE_START_BIT);
    // FIXME: Factor in stateful logging which is not currently supported in
    // assembly?
    //if (instr_slots == 1) -- encode instr number in type?
    stateful_adr_default |= (1U << METER_TYPE_START_BIT);
    // FIXME: Factor in index constants
    // FIXME: Factor in when addr is OR'd from hash computation
    merge.mau_meter_adr_default[type][bus] = stateful_adr_default;

    unsigned stateful_adr_mask = 0x0;
    unsigned base_width = 0;
    unsigned base_mask = 0x0;
    unsigned type_mask = (1U << (METER_TYPE_BITS - 1)) - 1;
    if (instr_slots > 1) {
        base_width = ptr_bits - METER_TYPE_BITS + 1;
        if (per_flow_enable)
            base_width -= 1;
        base_mask = (1U << base_width) - 1;
        stateful_adr_mask = base_mask << bw_adjust;
        stateful_adr_mask |= (type_mask << (METER_TYPE_START_BIT + 1));
    } else {
        base_width = ptr_bits;
        if (per_flow_enable)
            base_width -= 1;
        base_mask = (1U << base_width) - 1;
        stateful_adr_mask = base_mask << bw_adjust;
    }
    stateful_adr_mask &= full_mask;
    if (match->to<HashActionTable>()) {
        merge.mau_stats_adr_mask[type][bus] = 0;
    } else
        merge.mau_meter_adr_mask[type][bus] = stateful_adr_mask;

    if (!per_flow_enable)
        per_flow_enable_bit = METER_ADDRESS_BITS - METER_TYPE_BITS - 1;
    merge.mau_meter_adr_per_entry_en_mux_ctl[type][bus] = per_flow_enable_bit;
}

template<class REGS> void Stateful::write_regs(REGS &regs) {
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
                //setup_muxctl(vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[2 + logical_row.bus],
                //             selection_hash);
                if (input_xbar) {
                    vh_adr_xbar.alu_hashdata_bytemask.alu_hashdata_bytemask_right =
                        bitmask2bytemask(input_xbar->hash_group_bituse());
                    data_ctl.stateful_meter_alu_data_bytemask = phv_byte_mask;
                    data_ctl.stateful_meter_alu_data_xbar_ctl = 8 | input_xbar->match_group(); }
                map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_base = minvpn;
                map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_limit = maxvpn;
                int meter_group_index = row/2U;
                auto &delay_ctl = map_alu.meter_alu_group_data_delay_ctl[meter_group_index];
                delay_ctl.meter_alu_right_group_delay = METER_ALU_GROUP_DATA_DELAY + row/4 + stage->tcam_delay(gress);
                auto &error_ctl = map_alu.meter_alu_group_error_ctl[meter_group_index];
                error_ctl.meter_alu_group_ecc_error_enable = 1;
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
    for (MatchTable *m : match_tables) {
        adrdist.adr_dist_meter_adr_icxbar_ctl[m->logical_id] = 1 << meter_group;
        adrdist.mau_ad_meter_virt_lt[meter_group] |= 1U << m->logical_id;
        adrdist.movereg_ad_meter_alu_to_logical_xbar_ctl[m->logical_id/8U].set_subfield(
            4 | meter_group, 3*(m->logical_id % 8U), 3); }
    if (!bound_selector) {
        adrdist.movereg_meter_ctl[meter_group].movereg_ad_meter_shift = format->log2size;
        if (push_on_overflow)
            adrdist.oflo_adr_user[0] = adrdist.oflo_adr_user[1] = AdrDist::METER;
        adrdist.packet_action_at_headertime[1][meter_group] = 1; }
    //for (auto &hd : hash_dist)
    //    hd.write_regs(regs, this, 0, non_linear_hash);
    if (gress == INGRESS) {
        merge.meter_alu_thread[0].meter_alu_thread_ingress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_ingress |= 1U << meter_group;
    } else {
        merge.meter_alu_thread[0].meter_alu_thread_egress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_egress |= 1U << meter_group; }
    auto &salu = regs.rams.map_alu.meter_group[meter_group].stateful;
    salu.stateful_ctl.salu_enable = 1;
    if (math_table) {
        for (size_t i = 0; i < math_table.data.size(); ++i)
            salu.salu_mathtable[i/4U].set_subfield(math_table.data[i], 8*(i%4U), 8);
        salu.salu_mathunit_ctl.salu_mathunit_output_scale = math_table.scale & 0x2fU;
        salu.salu_mathunit_ctl.salu_mathunit_exponent_invert = math_table.invert;
        salu.salu_mathunit_ctl.salu_mathunit_exponent_shift = math_table.shift & 0x2U; }
    for (size_t i = 0; i < const_vals.size(); ++i)
        salu.salu_const_regfile[i] = const_vals[i] & 0xffffffffU;
}

void Stateful::gen_tbl_cfg(json::vector &out) {
    // FIXME -- factor common Synth2Port stuff
    int size = (layout_size() - 1) * 1024 * (128U/format->size);
    json::map &tbl = *base_tbl_cfg(out, "stateful", size);
    /*json::map &stage_tbl = */add_stage_tbl_cfg(tbl, "stateful", size);
    tbl["alu_width"] = format->size/(dual_mode ? 2 : 1);
    tbl["dual_width_mode"] = dual_mode;
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
                    tbl["clr_instr"] = a.code; } }
        actions->gen_tbl_cfg((tbl["actions"] = json::vector())); }
    if (bound_selector)
        tbl["bound_to_selection_table_handle"] = bound_selector->handle();
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "stateful", size);
    add_meter_alu_index(stage_tbl);
    if (context_json)
        stage_tbl.merge(*context_json);
}
