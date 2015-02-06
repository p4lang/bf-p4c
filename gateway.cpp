#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(GatewayTable)

GatewayTable::Match::Match(match_t &v, value_t &data) : val(v), run_table(false) {
    if (data == "run_table")
        run_table = true;
    else if (data.type == tSTR) {
        next = data;
    } else if (data.type == tMAP) {
        for (auto &kv: data.map) {
            if (kv.key == "next") {
                if (CHECKTYPE(kv.value, tSTR))
                    next = kv.value;
            } else if (kv.key == "run_table") {
                if (kv.value == "true")
                    run_table = true;
                else if (kv.value == "false")
                    run_table = false;
                else
                    error(kv.value.lineno, "Syntax error, expecting boolean");
            } else
                error(kv.key.lineno, "Syntax error, expecting gateway action description"); }
    } else
        error(data.lineno, "Syntax error, expecting gateway action description");
}

void GatewayTable::setup(VECTOR(pair_t) &data) {
    int bus = -1;
    payload = 0;
    gw_unit = -1;
    setup_logical_id();
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "row") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 7)
                error(kv.value.lineno, "row %d out of range", kv.value.i);
            layout.push_back(Layout{kv.value.lineno, kv.value.i, bus});
        } else if (kv.key == "bus") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "bus %d out of range", kv.value.i);
            bus = kv.value.i;
            if (!layout.empty()) layout[0].bus = bus;
        } else if (kv.key == "gateway_unit") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "gateway unit %d out of range", kv.value.i);
            gw_unit = kv.value.i;
        } else if (kv.key == "input_xbar") {
	    if (CHECKTYPE(kv.value, tMAP))
		input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "miss") {
            match_t v = { 0, 0 };
            miss = Match(v, kv.value);
        } else if (kv.key == "payload") {
        } else if (kv.key == "match") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    match.emplace_back(gress, v);
            else
                match.emplace_back(gress, kv.value);
        } else if (kv.key == "xor") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    xor_match.emplace_back(gress, v);
            else
                xor_match.emplace_back(gress, kv.value);
        } else if (kv.key.type == tINT) {
            match_t v = { ~(unsigned long)kv.key.i, (unsigned long)kv.key.i };
            table.emplace_back(v, kv.value);
        } else if (kv.key.type == tMATCH) {
            table.emplace_back(kv.key.m, kv.value);
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
}

unsigned width(const Phv::Ref &r) { return r->hi - r->lo + 1; }
unsigned width(const std::vector<Phv::Ref> &vec) {
    unsigned rv = 0;
    for (auto &f : vec)
        rv += width(f);
    return rv;
}

void GatewayTable::pass1() {
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    if (gw_unit < 0) gw_unit = layout[0].bus;
    if (input_xbar) input_xbar->pass1(stage->exact_ixbar, 128);
    for (auto &r : match) r.check();
    for (auto &r : xor_match) r.check();
    if (error_count > 0) return;
    if (width(xor_match) > 32)
        error(lineno, "Gateway can only xor 32 bits max");
    if (table.size() > 4)
        error(lineno, "Gateway can only have 4 match entries max");
    for (auto &line : table)
        if (line.next != "END")
            line.next.check();
    if (miss.next != "END")
        miss.next.check();
    for (auto &line : table) {
        unsigned long ignore = ~(line.val.word0 | line.val.word1);
        line.val.word0 |= ignore;
        line.val.word1 |= ignore; }
}
void GatewayTable::pass2() {
    if (input_xbar) input_xbar->pass2(stage->exact_ixbar, 128);
}
void GatewayTable::write_regs() {
    if (input_xbar) input_xbar->write_regs();
    auto &row = layout[0];
    auto &gw_reg = stage->regs.rams.array.row[row.row].gateway_table[gw_unit];
    auto &merge = stage->regs.rams.match.merge;
    if (row.bus == 0) {
        gw_reg.gateway_table_ctl.gateway_table_input_data0_select = 1;
        gw_reg.gateway_table_ctl.gateway_table_input_hash0_select = 1;
    } else {
        assert(row.bus == 1);
        gw_reg.gateway_table_ctl.gateway_table_input_data1_select = 1;
        gw_reg.gateway_table_ctl.gateway_table_input_hash1_select = 1; }
    gw_reg.gateway_table_ctl.gateway_table_logical_table = logical_id;
    gw_reg.gateway_table_ctl.gateway_table_thread = gress;
    gw_reg.gateway_table_matchdata_xor_en = ~(~0U << width(xor_match));
    unsigned lineno = 0;
    for (auto &line : table) {
        /* FIXME -- hardcoding version/valid to always */
        gw_reg.gateway_table_vv_entry[lineno].gateway_table_entry_versionvalid0 = 0x3;
        gw_reg.gateway_table_vv_entry[lineno].gateway_table_entry_versionvalid1 = 0x3;
        gw_reg.gateway_table_entry_matchdata[lineno][0] = line.val.word0 & 0xffffffff;
        gw_reg.gateway_table_entry_matchdata[lineno][1] = line.val.word1 & 0xffffffff;
        gw_reg.gateway_table_data_entry[lineno][0] = (line.val.word0 >> 32) & 0xffffff;
        gw_reg.gateway_table_data_entry[lineno][1] = (line.val.word1 >> 32) & 0xffffff;
        if (!line.run_table) {
            merge.gateway_next_table_lut[logical_id][lineno] =
                line.next ? line.next->table_id() : 0xff;
            merge.gateway_inhibit_lut[logical_id] |= 1 << lineno; }
        lineno++; }
    if (!miss.run_table) {
        merge.gateway_next_table_lut[logical_id][4] = miss.next ? miss.next->table_id() : 0xff;
        merge.gateway_inhibit_lut[logical_id] |= 1 << 4; }
    //bool ternary_match = false;
    if (auto *tm = dynamic_cast<TernaryMatchTable *>(match_table)) {
        //ternary_match = true;
        merge.gateway_inhibit_logical_to_tcam_xbar_ctl[tm->tcam_id]
            .enabled_4bit_muxctl_select = logical_id;
        merge.gateway_inhibit_logical_to_tcam_xbar_ctl[tm->tcam_id]
            .enabled_4bit_muxctl_enable = 1; }
    for (int v : VersionIter(options.version))
        merge.gateway_en[v] |= 1 << logical_id;
    merge.gateway_to_logicaltable_xbar_ctl[logical_id].enabled_4bit_muxctl_select =
        row.row*2 + gw_unit;
    merge.gateway_to_logicaltable_xbar_ctl[logical_id].enabled_4bit_muxctl_enable = 1;
    if (match_table) {
        for (auto &row : match_table->layout) {
            merge.gateway_to_pbus_xbar_ctl[row.row*2 + row.bus]
                .enabled_4bit_muxctl_select = logical_id;
            merge.gateway_to_pbus_xbar_ctl[row.row*2 + row.bus]
                .enabled_4bit_muxctl_enable = 1;
#if 0
            merge.gateway_payload_pbus[row.row][row.bus] |= 1 << (row.bus + ternary_match ? 2 : 0);
            merge.gateway_payload_data[row.row][row.bus][0] = ???;
            merge.gateway_payload_data[row.row][row.bus][1] = ???;
            merge.gateway_payload_match_adr[row.row][row.bus] = ???;
#endif
        }
    }
}

void GatewayTable::gen_tbl_cfg(json::vector &out) {
}
