#include "algorithm.h"
#include "data_switchbox.h"
#include "input_xbar.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

void Synth2Port::common_init_setup(const VECTOR(pair_t) &data, bool, P4Table::type p4type) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(layout, row, get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
        if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map"))
            format = new Format(this, fmt->map); }
}

bool Synth2Port::common_setup(pair_t &kv, const VECTOR(pair_t) &data, P4Table::type p4type) {
    if (kv.key == "vpns") {
        if (kv.value == "null")
            no_vpns = true;
    else if (CHECKTYPE(kv.value, tVEC))
        setup_vpns(layout, &kv.value.vec, true);
    } else if (kv.key == "maprams") {
        if (CHECKTYPE(kv.value, tVEC))
            setup_maprams(&kv.value.vec);
    } else if (kv.key == "global_binding") {
        global_binding = get_bool(kv.value);
    } else if (kv.key == "per_flow_enable") {
        if (CHECKTYPE(kv.value, tSTR)) {
            per_flow_enable = 1;
            per_flow_enable_param = kv.value.s; }
    } else if (kv.key == "p4") {
        if (CHECKTYPE(kv.value, tMAP))
            p4_table = P4Table::get(p4type, kv.value.map);
    } else if (kv.key == "format" || kv.key == "row" || kv.key == "logical_row" ||
               kv.key == "column" || kv.key == "bus") {
        /* already done in setup_layout */
    } else
        return false;
    return true;
}

void Synth2Port::pass1() {
    LOG1("### Synth2Port table " << name() << " pass1");
}

void Synth2Port::pass2() {
    LOG1("### Synth2Port table " << name() << " pass2");
}

template<class REGS>
void Synth2Port::write_regs(REGS &) {
}

json::map *Synth2Port::base_tbl_cfg(json::vector &out, const char *type, int size) {
    json::map &tbl = *AttachedTable::base_tbl_cfg(out, type, size);
    tbl.erase("p4_selection_tables");
    tbl.erase("p4_action_data_tables");
    tbl["enable_per_flow_enable"] = per_flow_enable;
    tbl["per_flow_enable_bit_position"] = per_flow_enable_bit;
    return &tbl;
}

json::map *Synth2Port::add_stage_tbl_cfg(json::map &tbl, const char *type, int size) {
    json::map &stage_tbl = *AttachedTable::add_stage_tbl_cfg(tbl, type, size);
    tbl["how_referenced"] = indirect ? "indirect" : "direct";
    int entries = 1;
    if (format) {
        assert(format->log2size <= 7);
        if (format->groups() > 1) {
            assert(format->log2size == 7);
            entries = format->groups();
        } else {
            entries = 128U >> format->log2size; } }
    add_pack_format(stage_tbl, 128, 1, entries);
    stage_tbl["memory_resource_allocation"] =
        gen_memory_resource_allocation_tbl_cfg("sram", layout, true);
    return &stage_tbl;
}
