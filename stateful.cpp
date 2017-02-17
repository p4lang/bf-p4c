#include "algorithm.h"
#include "data_switchbox.h"
#include "input_xbar.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(Stateful)

void Stateful::setup(VECTOR(pair_t) &data) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(layout, row, get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
        if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map"))
            format = new Format(fmt->map);
    } // else
        // error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data, true)) {
        if (common_setup(kv, data, P4Table::Stateful)) {
        } else if (kv.key == "format") {
            /* done above to be done before vpns */
        } else if (kv.key == "hash_dist") {
            HashDistribution::parse(hash_dist, kv.value);
            for (auto &hd : hash_dist) hd.meter_pre_color = true;
            if (hash_dist.size() > 1)
                error(kv.key.lineno, "More than one hast_dist in a stateful table not supported");
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
    int prev_row = -1;
    for (auto &row : layout) {
        if (prev_row >= 0)
            need_bus(lineno, stage->overflow_bus_use, row.row, "Overflow");
        else
            need_bus(lineno, stage->stats_bus_use, row.row, "Statistics data");
        for (int r = (row.row + 1) | 1; r < prev_row; r += 2)
            need_bus(lineno, stage->overflow_bus_use, r, "Overflow");
        prev_row = row.row; }
}

void Stateful::pass2() {
    LOG1("### Stateful table " << name() << " pass2");
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
    Synth2Port::write_regs();
}

void Stateful::gen_tbl_cfg(json::vector &out) {
    // FIXME -- factor common Synth2Port stuff
    int size = (layout_size() - 1)*1024* (format ? format->groups() : 1);
    json::map &tbl = *base_tbl_cfg(out, "stateful", size);
    /*json::map &stage_tbl = */add_stage_tbl_cfg(tbl, "stateful", size);
}
