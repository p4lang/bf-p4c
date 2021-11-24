#include "algorithm.h"
#include "data_switchbox.h"
#include "input_xbar.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

void Synth2Port::common_init_setup(const VECTOR(pair_t) &data, bool, P4Table::type p4type) {
    setup_layout(layout, data);
    if (auto *fmt = get(data, "format")) {
        if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map"))
            format = new Format(this, fmt->map); }
}

bool Synth2Port::common_setup(pair_t &kv, const VECTOR(pair_t) &data, P4Table::type p4type) {
    if (kv.key == "vpns") {
        if (kv.value == "null") {
            no_vpns = true;
        } else if (CHECKTYPE(kv.value, tVEC)) {
            setup_vpns(layout, &kv.value.vec, true);
        }
    } else if (kv.key == "maprams") {
        setup_maprams(kv.value);
    } else if (kv.key == "global_binding") {
        global_binding = get_bool(kv.value);
    } else if (kv.key == "per_flow_enable") {
        if (CHECKTYPE(kv.value, tSTR)) {
            per_flow_enable = 1;
            per_flow_enable_param = kv.value.s; }
    } else if (kv.key == "p4") {
        if (CHECKTYPE(kv.value, tMAP))
            p4_table = P4Table::get(p4type, kv.value.map);
    } else if (kv.key == "context_json") {
        setup_context_json(kv.value);
    } else if (kv.key == "format" || kv.key == "row" || kv.key == "logical_row" ||
               kv.key == "column" || kv.key == "bus") {
        /* already done in setup_layout */
    } else if (kv.key == "logical_bus") {
        if (CHECKTYPE2(kv.value, tSTR, tVEC)) {
            if (kv.value.type == tSTR) {
                if (*kv.value.s != 'A' && *kv.value.s != 'O' && *kv.value.s != 'S')
                    error(kv.value.lineno, "Invalid logical bus %s", kv.value.s);
            } else {
                for (auto &v : kv.value.vec) {
                    if (CHECKTYPE(v, tSTR)) {
                        if (*v.s != 'A' && *v.s != 'O' && *v.s != 'S')
                            error(v.lineno, "Invalid logical bus %s", v.s); } } } }
    } else if (kv.key == "home_row") {
        home_lineno = kv.value.lineno;
        if (CHECKTYPE2(kv.value, tINT, tVEC)) {
            if (kv.value.type == tINT) {
                if (kv.value.i >= 0 || kv.value.i < LOGICAL_SRAM_ROWS)
                    home_rows.insert(kv.value.i);
                else
                    error(kv.value.lineno, "Invalid home row %" PRId64 "", kv.value.i);
            } else {
                for (auto &v : kv.value.vec) {
                    if (CHECKTYPE(v, tINT)) {
                        if (v.i >= 0 || v.i < LOGICAL_SRAM_ROWS)
                            home_rows.insert(v.i);
                        else
                            error(v.lineno, "Invalid home row %" PRId64 "", v.i); } } } }
    } else {
        return false;
    }
    return true;
}

void Synth2Port::pass1() {
    LOG1("### Synth2Port table " << name() << " pass1 " << loc());
    AttachedTable::pass1();
}

void Synth2Port::pass2() {
    LOG1("### Synth2Port table " << name() << " pass2 " << loc());
}

void Synth2Port::pass3() {
    LOG1("### Synth2Port table " << name() << " pass3 " << loc());
}

template<class REGS>
void Synth2Port::write_regs_vt(REGS &) {
}

json::map *Synth2Port::add_stage_tbl_cfg(json::map &tbl, const char *type, int size) const {
    json::map &stage_tbl = *AttachedTable::add_stage_tbl_cfg(tbl, type, size);
    std::string hr = how_referenced();
    if (hr.empty())
        hr = direct ? "direct" : "indirect";
    tbl["how_referenced"] = hr;
    int entries = 1;
    if (format) {
        BUG_CHECK(format->log2size <= 7);
        if (format->groups() > 1) {
            BUG_CHECK(format->log2size == 7);
            entries = format->groups();
        } else {
            entries = 128U >> format->log2size; } }
    add_pack_format(stage_tbl, 128, 1, entries);
    stage_tbl["memory_resource_allocation"] =
        gen_memory_resource_allocation_tbl_cfg("sram", layout, true);
    return &stage_tbl;
}

void Synth2Port::add_alu_indexes(json::map &stage_tbl, std::string alu_indexes) const {
    json::vector home_alu;

    for (auto row : home_rows)
        home_alu.push_back(row/4U);

    stage_tbl[alu_indexes] = home_alu.clone();
}

int Synth2Port::get_home_row_for_row(int row) const {
    for (int home_row : home_rows) {
        // Tofino1 have an overflow bus in the middle of the SRAM array
        if (options.target == TOFINO)
            return home_row;
        else if (row / 8 == home_row / 8)
            return home_row;
    }
    BUG();
    return -1;
}

