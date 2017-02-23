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
            HashDistribution::parse(hash_dist, kv.value);
            for (auto &hd : hash_dist) hd.meter_pre_color = true;
            if (hash_dist.size() > 1)
                error(kv.key.lineno, "More than one hast_dist in a stateful table not supported");
        } else if (kv.key == "actions") {
            if (CHECKTYPE(kv.value, tMAP))
                actions = new Actions(this, kv.value.map);
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(true, stage->sram_use);
}

void Stateful::pass1() {
    LOG1("### Stateful table " << name() << " pass1");
    if (!p4_table) p4_table = P4Table::alloc(P4Table::Stateful, this);
    else p4_table->check(this);
    alloc_vpns();
    alloc_maprams();
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
}

int Stateful::get_const(long v) {
    int rv = std::find(const_vals.begin(), const_vals.end(), v) - const_vals.begin();
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
    //bool push_on_overflow = false;
    //auto &map_alu =  stage->regs.rams.map_alu;
    //auto &adrdist = stage->regs.rams.match.adrdist;
    DataSwitchboxSetup swbox(this);
    int minvpn, maxvpn;
    layout_vpn_bounds(minvpn, maxvpn, true);
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2U;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        assert(side == 1);      /* no map rams or alus on left side anymore */
        auto vpn = logical_row.vpns.begin();
        auto mapram = logical_row.maprams.begin();
        //auto &map_alu_row =  map_alu.row[row];
        LOG2("# DataSwitchbox.setup(" << row << ") home=" << home->row/2U);
        swbox.setup_row(row);
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            swbox.setup_row_col(row, col, *vpn);
            write_mapram_regs(row, *mapram, *vpn, MapRam::STATEFUL);
            if (gress)
                stage->regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row);
            ++mapram, ++vpn; } }
    if (actions)
        actions->write_regs(this);
}

void Stateful::gen_tbl_cfg(json::vector &out) {
    // FIXME -- factor common Synth2Port stuff
    int size = (layout_size() - 1)*1024* (format ? format->groups() : 1);
    json::map &tbl = *base_tbl_cfg(out, "stateful", size);
    /*json::map &stage_tbl = */add_stage_tbl_cfg(tbl, "stateful", size);
    if (actions)
        actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
}
