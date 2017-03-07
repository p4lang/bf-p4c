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
    } else {
        alloc_maprams();
        alloc_rams(true, stage->sram_use); }
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    stage->table_use[gress] |= Stage::USE_STATEFUL;
    for (auto &hd : hash_dist)
        hd.pass1(this);
    if (input_xbar) input_xbar->pass1(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
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
    if (actions) actions->pass1(this);
    if (math_table)
        math_table.check();
}

int Stateful::get_const(long v) {
    size_t rv = std::find(const_vals.begin(), const_vals.end(), v) - const_vals.begin();
    if (rv == const_vals.size())
        const_vals.push_back(v);
    return rv;
}

void Stateful::pass2() {
    LOG1("### Stateful table " << name() << " pass2");
    if (input_xbar) input_xbar->pass2(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
    if (actions)
        actions->stateful_pass2(this);
}

int Stateful::direct_shiftcount() {
    return 64;
}

void Stateful::write_merge_regs(MatchTable *match, int type, int bus, const std::vector<Call::Arg> &args) {
    auto &merge =  stage->regs.rams.match.merge;
    if (per_flow_enable)
        merge.mau_stats_adr_per_entry_en_mux_ctl[type][bus] = 16; // FIXME
}

void Stateful::write_regs() {
    LOG1("### Stateful table " << name() << " write_regs");
    // FIXME -- factor common AttachedTable::write_regs
    // FIXME -- factor common Synth2Port::write_regs
    // FIXME -- factor common CounterTable::write_regs
    // FIXME -- factor common MeterTable::write_regs
    if (input_xbar) input_xbar->write_regs();
    Layout *home = &layout[0];
    bool push_on_overflow = false;
    auto &map_alu =  stage->regs.rams.map_alu;
    auto &merge =  stage->regs.rams.match.merge;
    auto &adrdist = stage->regs.rams.match.adrdist;
    DataSwitchboxSetup swbox(this);
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
                write_mapram_regs(row, *mapram, *vpn, MapRam::STATEFUL);
                if (gress)
                    stage->regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row);
                ++mapram, ++vpn; }
            /* FIXME -- factor with selector/meter? */
            if (&logical_row == home) {
                auto &vh_adr_xbar = stage->regs.rams.array.row[row].vh_adr_xbar;
                //setup_muxctl(vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[2 + logical_row.bus],
                //             selection_hash);
                if (input_xbar)
                    vh_adr_xbar.alu_hashdata_bytemask.alu_hashdata_bytemask_right =
                        bitmask2bytemask(input_xbar->hash_group_bituse());
                map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_base = minvpn;
                map_alu_row.i2portctl.synth2port_vpn_ctl.synth2port_vpn_limit = maxvpn;
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
        actions->write_regs(this);
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
    //    hd.write_regs(this, 0, non_linear_hash);
    if (gress == INGRESS) {
        merge.meter_alu_thread[0].meter_alu_thread_ingress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_ingress |= 1U << meter_group;
    } else {
        merge.meter_alu_thread[0].meter_alu_thread_egress |= 1U << meter_group;
        merge.meter_alu_thread[1].meter_alu_thread_egress |= 1U << meter_group; }
    auto &salu = stage->regs.rams.map_alu.meter_group[meter_group].stateful;
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
    if (actions)
        actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
}
