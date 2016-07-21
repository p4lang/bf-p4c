#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(GatewayTable)

static struct {
    unsigned         units, bits, half_shift, mask, half_mask;
} range_match_info[] = { { 0, 0, 0, 0 }, { 6, 4, 2, 0xf, 0x3 }, { 3, 8, 8, 0xffff, 0xff } };

GatewayTable::Match::Match(value_t *v, value_t &data, range_match_t range_match) {
    if (range_match)
        for (unsigned i = 0; i < range_match_info[range_match].units; i++)
            range[i] = range_match_info[range_match].mask;
    if (v) {
        lineno = v->lineno;
        if (v->type == tVEC) {
            int last = v->vec.size - 1;
            if (last > (int)range_match_info[range_match].units)
                error(lineno, "Too many set values for range match");
            for (int i = 0; i < last; i++)
                if (CHECKTYPE((*v)[last-i-1], tINT)) {
                    if ((unsigned)(*v)[last-i-1].i > range_match_info[range_match].mask)
                        error(lineno, "range match set too large");
                    range[i] = (*v)[last-i-1].i; }
            v = &(*v)[last]; }
        if (v->type == tINT) {
            val.word0 = ~(val.word1 = (unsigned long)v->i);
        } else if (v->type == tBIGINT) {
            if (v->bigi.size > 1)
                error(lineno, "Gateway key too large");
            val.word0 = ~(val.word1 = (unsigned long)v->bigi.data[0]);
        } else if (v->type == tMATCH) {
            val = v->m; } }
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
    setup_logical_id();
    if (auto *v = get(data, "range")) {
        if (CHECKTYPE(*v, tINT)) {
            if (v->i == 2) range_match = DC_2BIT;
            if (v->i == 4) range_match = DC_4BIT;
            else error(v->lineno, "Unknown range match size %d bits", v->i); } }
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "row") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 7)
                error(kv.value.lineno, "row %d out of range", kv.value.i);
            if (layout.empty()) layout.resize(1);
            layout[0].row = kv.value.i;
            layout[0].lineno = kv.value.lineno;
        } else if (kv.key == "bus") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "bus %d out of range", kv.value.i);
            if (layout.empty()) layout.resize(1);
            layout[0].bus = kv.value.i;
            if (layout[0].lineno < 0)
                layout[0].lineno = kv.value.lineno;
        } else if (kv.key == "payload_row") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 7)
                error(kv.value.lineno, "row %d out of range", kv.value.i);
            if (layout.size() < 2) layout.resize(2);
            layout[1].row = kv.value.i;
            layout[1].lineno = kv.value.lineno;
        } else if (kv.key == "payload_bus") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "bus %d out of range", kv.value.i);
            if (layout.size() < 2) layout.resize(2);
            layout[1].bus = kv.value.i;
            if (layout[1].lineno < 0)
                layout[1].lineno = kv.value.lineno;
        } else if (kv.key == "gateway_unit") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "gateway unit %d out of range", kv.value.i);
            gw_unit = kv.value.i;
        } else if (kv.key == "input_xbar") {
            if (CHECKTYPE(kv.value, tMAP))
                input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "miss") {
            miss = Match(0, kv.value, range_match);
        } else if (kv.key == "payload") {
            if (kv.value.type == tBIGINT && kv.value.bigi.size == 1)
                payload = kv.value.bigi.data[0];
            else if (sizeof(uintptr_t) == sizeof(uint32_t) && kv.value.type == tBIGINT &&
                     kv.value.bigi.size == 2)
                payload = kv.value.bigi.data[0] + ((uint64_t)kv.value.bigi.data[1] << 32);
            else if (CHECKTYPE(kv.value, tINT))
                payload = kv.value.i;
            have_payload = kv.key.lineno;
        } else if (kv.key == "match_address") {
            if (CHECKTYPE(kv.value, tINT))
                match_address = kv.value.i;
        } else if (kv.key == "match") {
            if (kv.value.type == tVEC) {
                for (auto &v : kv.value.vec)
                    match.emplace_back(gress, v);
            } else if (kv.value.type == tMAP) {
                for (auto &v : kv.value.map)
                    if (CHECKTYPE(v.key, tINT))
                        match.emplace_back(v.key.i, gress, v.value);
            } else
                match.emplace_back(gress, kv.value);
        } else if (kv.key == "range") {
            /* done above, to be before match parsing */
        } else if (kv.key == "xor") {
            if (kv.value.type == tVEC) {
                for (auto &v : kv.value.vec)
                    xor_match.emplace_back(gress, v);
            } else if (kv.value.type == tMAP) {
                for (auto &v : kv.value.map)
                    if (CHECKTYPE(v.key, tINT))
                        xor_match.emplace_back(v.key.i, gress, v.value);
            } else
                xor_match.emplace_back(gress, kv.value);
        } else if (kv.key.type == tINT || kv.key.type == tBIGINT || kv.key.type == tMATCH ||
                   (kv.key.type == tVEC && range_match != NONE))
        {
            table.emplace_back(&kv.key, kv.value, range_match);
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
}

void check_match_key(std::vector<GatewayTable::MatchKey> &vec, const char *name, unsigned max) {
    for (unsigned i = 0; i < vec.size(); i++) {
        if (!vec[i].val.check(true))
            break;
        if (vec[i].offset >= 0) {
            for (unsigned j = 0; j < i; ++j) {
                if (vec[i].offset < vec[j].offset + (int)vec[j].val->size() &&
                    vec[j].offset < vec[i].offset + (int)vec[i].val->size())
                    error(vec[i].val.lineno, "Gateway %s key at offset %d overlaps previous "
                          "value at offset %d", name, vec[i].offset, vec[j].offset); }
        } else
            vec[i].offset = i ? vec[i-1].offset + vec[i-1].val->size() : 0;
        if (vec[i].offset < 32 && (vec[i].offset & 7) != (vec[i].val->lo & 7))
            error(vec[i].val.lineno, "Gateway %s key %s misaligned within byte", name,
                  vec[i].val.name());
        if (vec[i].offset + vec[i].val->size() > max) {
            error(vec[i].val.lineno, "Gateway %s key too big", name);
            break; } }
}

void GatewayTable::pass1() {
    LOG1("### Gateway table " << name() << " pass1");
    alloc_id("logical", logical_id, stage->pass1_logical_id,
             LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    if (layout.empty() || layout[0].row < 0)
        error(lineno, "No row specified in gateway");
    if (layout.size() > 1) {
        if (layout[1].row < 0)
            error(layout[1].lineno, "payload_bus with no payload_row in gateway");
        else if (match_table)
            error(layout[1].lineno, "payload_row/bus on gateway attached to table");
    } else if (have_payload && !match_table)
        error(have_payload, "payload on standalone gateway requires explicit payload_row");
    if (gw_unit < 0) gw_unit = layout[0].bus;
    if (input_xbar)
        input_xbar->pass1(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
    else
        error(lineno, "input_xbar required for gateway");
    check_match_key(match, "match", 44);
    check_match_key(xor_match, "xor", 32);
    std::sort(match.begin(), match.end());
    std::sort(xor_match.begin(), xor_match.end());
    if (table.size() > 4)
        error(lineno, "Gateway can only have 4 match entries max");
    for (auto &line : table)
        if (line.next != "END")
            line.next.check();
    if (miss.next != "END")
        miss.next.check();
    if (error_count > 0) return;
    unsigned long ignore = ~0UL;
    int shift = -1;
    for (auto &r : match) {
        if (range_match && r.offset >= 32) {
            if ((r.offset-32) & ((1U<<range_match) - 1))
                error(r.val.lineno, "Upper word match of %s for range gateway not a multiple"
                      " of %d bits", r.val.name(), 1U<<range_match);
            continue; }
        ignore ^= ((1UL << r.val->size()) - 1) << r.offset;
        if (shift < 0 || shift > r.offset) shift = r.offset; }
    if (shift < 0) shift = 0;
    for (auto &line : table) {
#if 0
        if ((line.val.word0 & (ignore >> shift)) != (ignore >> shift))
            error(line.lineno, "Not ignoring bits not in match of gateway");
        if ((line.val.word1 & (ignore >> shift)) != (ignore >> shift))
            warning(line.lineno, "Not wildcarding bits not in match of gateway");
#endif
        line.val.word0 = (line.val.word0 << shift) | ignore;
        line.val.word1 = (line.val.word1 << shift) | ignore; }
}
void GatewayTable::pass2() {
    LOG1("### Gateway table " << name() << " pass2");
    if (logical_id < 0)  {
        if (match_table) logical_id = match_table->logical_id;
        else choose_logical_id(); }
    if (input_xbar) input_xbar->pass2(stage->exact_ixbar, EXACT_XBAR_GROUP_SIZE);
}

/* FIXME -- how to deal with (or even specify) matches in the upper 24 bits coming from
 * the hash bus?   Currently we assume that the input_xbar is declared to set up the
 * hash signals correctly so that we can just match them.  Should at least check it
 * somewhere, somehow. */
static bool setup_vh_xbar(Table *table, Table::Layout &row, int base,
                          std::vector<GatewayTable::MatchKey> &match, int group)
{
    auto &rams_row = table->stage->regs.rams.array.row[row.row];
    auto &byteswizzle_ctl = rams_row.exactmatch_row_vh_xbar_byteswizzle_ctl[row.bus];
    for (auto &r : match) {
        if (r.offset >= 32) break; /* skip hash matches */
        unsigned byte = base + r.offset / 8;
        int ibyte = table->find_on_ixbar(*r.val, group);
        for (unsigned b = 0; b < (r.val->size()+7)/8; b++, byte++, ibyte++)
            for (unsigned bit = 0; bit < 8; bit++)
                byteswizzle_ctl[byte][bit] = 0x10 + ibyte; }
    return true;
}

void GatewayTable::payload_write_regs(int row, int type, int bus) {
    auto &merge = stage->regs.rams.match.merge;
    auto &xbar_ctl = merge.gateway_to_pbus_xbar_ctl[row*2 + bus];
    if (type) {
        xbar_ctl.tind_logical_select = logical_id;
        xbar_ctl.tind_inhibit_enable = 1;
    } else {
        xbar_ctl.exact_logical_select = logical_id;
        xbar_ctl.exact_inhibit_enable = 1; }
    if (have_payload) {
        if (type)
            merge.gateway_payload_tind_pbus[row] |= 1 << bus;
        else
            merge.gateway_payload_exact_pbus[row] |= 1 << bus;
        if (options.match_compiler) {
            /* working around a problem in the harlyn model */
            merge.gateway_payload_data[row][bus][0][type^1] = payload & 0xffffffff;
            merge.gateway_payload_data[row][bus][1][type^1] = payload >> 32; }
        merge.gateway_payload_data[row][bus][0][type] = payload & 0xffffffff;
        merge.gateway_payload_data[row][bus][1][type] = payload >> 32; }
    if (match_address >= 0)
        merge.gateway_payload_match_adr[row][bus][type] = match_address;
}

void GatewayTable::write_regs() {
    LOG1("### Gateway table " << name() << " write_regs");
    auto &row = layout[0];
    if (input_xbar) {
        input_xbar->write_regs();
        if (!setup_vh_xbar(this, row, 0, match, input_xbar->match_group()) ||
            !setup_vh_xbar(this, row, 4, xor_match, input_xbar->match_group()))
            return; }
    auto &row_reg = stage->regs.rams.array.row[row.row];
    auto &gw_reg = row_reg.gateway_table[gw_unit];
    auto &merge = stage->regs.rams.match.merge;
    if (row.bus == 0) {
        gw_reg.gateway_table_ctl.gateway_table_input_data0_select = 1;
        gw_reg.gateway_table_ctl.gateway_table_input_hash0_select = 1;
    } else {
        assert(row.bus == 1);
        gw_reg.gateway_table_ctl.gateway_table_input_data1_select = 1;
        gw_reg.gateway_table_ctl.gateway_table_input_hash1_select = 1; }
    if (input_xbar && input_xbar->hash_group() >= 0)
        setup_muxctl(row_reg.vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus],
                     input_xbar->hash_group());
    if (input_xbar && input_xbar->match_group() >= 0) {
        auto &vh_xbar_ctl = row_reg.vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl;
        setup_muxctl(vh_xbar_ctl, input_xbar->match_group());
        /* vh_xbar_ctl.exactmatch_row_vh_xbar_thread = gress; */ }
    gw_reg.gateway_table_ctl.gateway_table_logical_table = logical_id;
    gw_reg.gateway_table_ctl.gateway_table_thread = gress;
    for (auto &r : xor_match)
        gw_reg.gateway_table_matchdata_xor_en |= ((1U << r.val->size()) - 1) << r.offset;
    int lineno = 3;
    gw_reg.gateway_table_ctl.gateway_table_mode = range_match;
    for (auto &line : table) {
        assert(lineno >= 0);
        /* FIXME -- hardcoding version/valid to always */
        gw_reg.gateway_table_vv_entry[lineno].gateway_table_entry_versionvalid0 = 0x3;
        gw_reg.gateway_table_vv_entry[lineno].gateway_table_entry_versionvalid1 = 0x3;
        gw_reg.gateway_table_entry_matchdata[lineno][0] = line.val.word0 & 0xffffffff;
        gw_reg.gateway_table_entry_matchdata[lineno][1] = line.val.word1 & 0xffffffff;
        if (range_match) {
            auto &info = range_match_info[range_match];
            for (unsigned i = 0; i < range_match_info[range_match].units; i++) {
                gw_reg.gateway_table_data_entry[lineno][0] |=
                    (line.range[i] & info.half_mask) << (i * info.bits);
                gw_reg.gateway_table_data_entry[lineno][1] |=
                    ((line.range[i] >> info.half_shift) & info.half_mask) << (i * info.bits); }
        } else {
            gw_reg.gateway_table_data_entry[lineno][0] = (line.val.word0 >> 32) & 0xffffff;
            gw_reg.gateway_table_data_entry[lineno][1] = (line.val.word1 >> 32) & 0xffffff; }
        if (!line.run_table) {
            merge.gateway_next_table_lut[logical_id][lineno] =
                line.next ? line.next->table_id() : 0xff;
            merge.gateway_inhibit_lut[logical_id] |= 1 << lineno; }
        lineno--; }
    if (!miss.run_table) {
        merge.gateway_next_table_lut[logical_id][4] = miss.next ? miss.next->table_id() : 0xff;
        merge.gateway_inhibit_lut[logical_id] |= 1 << 4; }
    merge.gateway_en |= 1 << logical_id;
    setup_muxctl(merge.gateway_to_logicaltable_xbar_ctl[logical_id], row.row*2 + gw_unit);
    if (Table *tbl = match_table) {
        bool tind_bus = false;
        auto *tmatch = dynamic_cast<TernaryMatchTable *>(tbl);
        if (tmatch) {
            tind_bus = true;
            tbl = tmatch->indirect;
        } else if (auto *hashaction = dynamic_cast<HashActionTable *>(tbl))
            tind_bus = hashaction->bus >= 2;
        if (tbl)
            for (auto &row : tbl->layout)
                payload_write_regs(row.row, tind_bus, row.bus);
        else {
            assert(tmatch);
            auto &xbar_ctl = merge.gateway_to_pbus_xbar_ctl[tmatch->indirect_bus];
            xbar_ctl.tind_logical_select = logical_id;
            xbar_ctl.tind_inhibit_enable = 1; }
    } else {
        merge.predication_ctl[gress].table_thread |= 1 << logical_id;
        if (gress) {
            stage->regs.dp.imem_table_addr_egress |= 1 << logical_id;
            merge.logical_table_thread[0].logical_table_thread_egress |= 1 << logical_id;
            merge.logical_table_thread[1].logical_table_thread_egress |= 1 << logical_id;
            merge.logical_table_thread[2].logical_table_thread_egress |= 1 << logical_id;
        } else {
            merge.logical_table_thread[0].logical_table_thread_ingress |= 1 << logical_id;
            merge.logical_table_thread[1].logical_table_thread_ingress |= 1 << logical_id;
            merge.logical_table_thread[2].logical_table_thread_ingress |= 1 << logical_id; }
        auto &adrdist = stage->regs.rams.match.adrdist;
        adrdist.adr_dist_table_thread[gress][0] |= 1 << logical_id;
        adrdist.adr_dist_table_thread[gress][1] |= 1 << logical_id;
        if (layout.size() > 1)
            payload_write_regs(layout[1].row, layout[1].bus >> 1, layout[1].bus & 1);
        // FIXME -- allow table_counter on standalone gateay?  What can it count?
        if (options.match_compiler)
            merge.mau_table_counter_ctl[logical_id/8U].set_subfield(4, 3 * (logical_id%8U), 3); }
}

void GatewayTable::gen_tbl_cfg(json::vector &out) {
}
