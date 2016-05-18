#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "range.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(TernaryMatchTable)
DEFINE_TABLE_TYPE(TernaryIndirectTable)

void TernaryMatchTable::vpn_params(int &width, int &depth, int &period, const char *&period_name) {
    if ((width = match.size()) == 0)
        width = input_xbar ? input_xbar->tcam_width() : 1;
    depth = layout_size() / width;
    period = 1;
    period_name = 0;
}

void TernaryMatchTable::alloc_vpns() {
    if (no_vpns || layout.size() == 0 || layout[0].vpns.size() > 0) return;
    int period, width, depth;
    const char *period_name;
    vpn_params(width, depth, period, period_name);
    std::vector<Layout *> rows;
    for (auto &r : layout) {
        rows.push_back(&r);
        r.vpns.resize(r.cols.size()); }
    std::sort(rows.begin(), rows.end(), [](Layout *const&a, Layout *const&b)->bool {
                return a->row < b->row; });
    int vpn = 0;
    for (int col = 0; col <= 1; ++col) {
        for (auto *r : rows) {
            unsigned idx = find(r->cols, col) - r->cols.begin();
            if (idx < r->vpns.size())
                r->vpns[idx] = vpn++/width; }
        if (vpn%width != 0)
            error(layout[0].lineno, "%d-wide ternary match must use a multiple of %d tcams "
                  "in each column", width, width); }
}

TernaryMatchTable::Match::Match(const value_t &v) {
    if (v.type == tVEC) {
        if (v.vec.size < 2 || v.vec.size > 3) {
            error(v.lineno, "Syntax error");
            return; }
        if (!CHECKTYPE(v[0], tINT) || !CHECKTYPE(v[v.vec.size-1], tINT)) return;
        if ((word_group = v[0].i) < 0 || v[0].i >= TCAM_XBAR_GROUPS)
            error(v[0].lineno, "Invalid input xbar group %d", v[0].i);
        if (v.vec.size == 3 && CHECKTYPE(v[1], tINT)) {
            if ((byte_group = v[1].i) < 0 || v[1].i >= TCAM_XBAR_GROUPS/2)
                error(v[1].lineno, "Invalid input xbar group %d", v[1].i);
        } else
            byte_group = -1;
        if ((byte_config = v[v.vec.size-1].i) < 0 || byte_config >= 4)
            error(v[v.vec.size-1].lineno, "Invalid input xbar byte control %d", byte_config);
    } else if (CHECKTYPE(v, tMAP))
        for (auto &kv : MapIterChecked(v.map))
            if (kv.key == "group") {
                if (kv.value.type != tINT || kv.value.i < 0 || kv.value.i >= TCAM_XBAR_GROUPS)
                    error(kv.value.lineno, "Invalid input xbar group %s", value_desc(kv.value));
                else word_group = kv.value.i;
            } else if (kv.key == "byte_group") {
                if (kv.value.type != tINT || kv.value.i < 0 || kv.value.i >= TCAM_XBAR_GROUPS/2)
                    error(kv.value.lineno, "Invalid input xbar group %s", value_desc(kv.value));
                else byte_group = kv.value.i;
            } else if (kv.key == "byte_config") {
                if (kv.value.type != tINT || kv.value.i < 0 || kv.value.i >= 4)
                    error(kv.value.lineno, "Invalid byte group config %s", value_desc(kv.value));
                else byte_config = kv.value.i;
            } else if (kv.key == "dirtcam") {
                if (kv.value.type != tINT || kv.value.i < 0 || kv.value.i > 0xfff)
                    error(kv.value.lineno, "Invalid dirtcam mode %s", value_desc(kv.value));
                else dirtcam = kv.value.i;
            } else
                error(kv.key.lineno, "Unknown key '%s' in ternary match spec", value_desc(kv.key));
}

static void check_tcam_match_bus(const std::vector<Table::Layout> &layout) {
    for (auto &row : layout) {
        if (row.bus < 0) continue;
        for (auto col : row.cols)
            if (row.bus != col)
                error(row.lineno, "Tcam match bus hardwired to tcam column");
    }
}

void TernaryMatchTable::setup(VECTOR(pair_t) &data) {
    tcam_id = -1;
    indirect_bus = -1;
    setup_layout(layout, get(data, "row"), get(data, "column"), get(data, "bus"));
    setup_logical_id();
    if (auto *ixbar = get(data, "input_xbar")) {
        if (CHECKTYPE(*ixbar, tMAP))
            input_xbar = new InputXbar(this, true, ixbar->map);
    } else
        warning(lineno, "No input xbar specified in table %s", name());
    VECTOR(pair_t) p4_info = EMPTY_VECTOR_INIT;
    if (auto *m = get(data, "match"))
        if (CHECKTYPE2(*m, tVEC, tMAP)) {
            if (m->type == tVEC)
                for (auto &v : m->vec)
                    match.emplace_back(v);
            else
                match.emplace_back(*m); }
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data)) {
        } else if (kv.key == "input_xbar" || kv.key == "match") {
            /* done above to be done before vpns */
        } else if (kv.key == "indirect") {
            if (CHECKTYPE(kv.value, tSTR))
                indirect = kv.value;
        } else if (kv.key == "indirect_bus") {
            if (CHECKTYPE(kv.value, tINT)) {
                if (kv.value.i < 0 || kv.value.i >= 16)
                    error(kv.value.lineno, "Invalid ternary indirect bus number");
                else {
                    indirect_bus = kv.value.i;
                    if (auto *old = stage->tcam_indirect_bus_use[indirect_bus/2][indirect_bus&1])
                        error(kv.value.lineno, "Indirect bus %d already in use by table %s",
                              indirect_bus, old->name()); } }
        } else if (kv.key == "tcam_id") {
            if (CHECKTYPE(kv.value, tINT)) {
                if ((tcam_id = kv.value.i) < 0 || tcam_id >= TCAM_TABLES_PER_STAGE)
                    error(kv.key.lineno, "Invalid tcam_id %d", tcam_id);
                else if (stage->tcam_id_use[tcam_id])
                    error(kv.key.lineno, "Tcam id %d already in use by table %s",
                          tcam_id, stage->tcam_id_use[tcam_id]->name());
                else
                    stage->tcam_id_use[tcam_id] = this; }
        } else if (kv.key == "p4_table") {
            push_back(p4_info, "name", std::move(kv.value));
        } else if (kv.key == "p4_table_size") {
            push_back(p4_info, "size", std::move(kv.value));
        } else if (kv.key == "handle") {
            push_back(p4_info, "handle", std::move(kv.value));
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    if (p4_info.size) {
        if (p4_table)
            error(p4_info[0].key.lineno, "old and new p4 table info in %s", name());
        else
            p4_table = P4Table::get(P4Table::MatchEntry, p4_info); }
    fini(p4_info);
    alloc_rams(false, stage->tcam_use, &stage->tcam_match_bus_use);
    check_tcam_match_bus(layout);
    if (indirect_bus > 0) {
        stage->tcam_indirect_bus_use[indirect_bus/2][indirect_bus&1] = this; }
    if (indirect.set()) {
        if (action.set() || actions)
            error(lineno, "Table %s has both ternary indirect and direct actions", name());
        if (indirect_bus > 0)
            error(lineno, "Table %s has both ternary indirect table and explicit indirect bus",
                  name());
        if (!attached.stats.empty() || !attached.meter.empty())
            error(lineno, "Table %s has ternary indirect table and directly attached stats/meters"
                  " -- move them to indirect table", name());
    } else if (action.set() && actions)
        error(lineno, "Table %s has both action table and immediate actions", name());
    else if (!action.set() && !actions)
        error(lineno, "Table %s has no indirect, action table or immediate actions", name());
    if (action.args.size() > 0)
        error(lineno, "Unexpected number of action table arguments %zu", action.args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}

void TernaryMatchTable::pass1() {
    LOG1("### Ternary match table " << name() << " pass1");
    MatchTable::pass1(1);
    if (!p4_table) p4_table = P4Table::alloc(P4Table::MatchEntry, this);
    else p4_table->check(this);
    stage->table_use[gress] |= Stage::USE_TCAM;
    /* FIXME -- unconditionally setting piped mode -- only need it for wide
     * match across a 4-row boundary */
    stage->table_use[gress] |= Stage::USE_TCAM_PIPED;
    alloc_id("logical", logical_id, stage->pass1_logical_id,
             LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_id("tcam", tcam_id, stage->pass1_tcam_id,
             TCAM_TABLES_PER_STAGE, false, stage->tcam_id_use);
    // alloc_busses(stage->tcam_match_bus_use); -- now hardwired
    if (input_xbar) {
        input_xbar->pass1(stage->tcam_ixbar, TCAM_XBAR_GROUP_SIZE);
        if (match.empty()) {
            match.resize(input_xbar->tcam_width());
            for (unsigned i = 0; i < match.size(); i++) {
                match[i].word_group = input_xbar->tcam_word_group(i);
                match[i].byte_group = input_xbar->tcam_byte_group(i/2);
                match[i].byte_config = (i&1) + 1; }
            match.back().byte_config = 3; } }
    alloc_vpns();
    check_next();
    indirect.check();
    if (action.check() && action->set_match_table(this, action.args.size() > 1) != ACTION)
        error(action.lineno, "%s is not an action table", action->name());
    chain_rows = 0;
    unsigned row_use = 0;
    for (auto &row : layout) row_use |= 1U << row.row;
    if (layout.size() % match.size() != 0)
        error(layout[0].lineno, "Rows not a multiple of the match width in tables %s", name());
    unsigned word = 0;
    int prev_row = -1;
    for (auto &row : layout) {
        if (word && prev_row+1 != row.row)
            error(row.lineno, "Ternary match rows must be contiguous in ascending order"
                  "within each group of rows in a wide match");
        /* row 6 never chains -- other rows chain towards row 6 */
        if (row.row != 6 && word != (row.row < 6 ? match.size()-1 : 0)) {
            chain_rows |= 1 << row.row;
            int chain_to = row.row + (row.row < 6 ? 1 : -1);
            if (!((row_use >> chain_to) & 1))
                error(row.lineno, "Can't chain properly from row %d in ternary match %s, "
                      "as the table isn't using the next row", row.row, name()); }
        prev_row = row.row;
        if (++word == match.size()) word = 0; }
    if (indirect) {
        if (indirect->set_match_table(this, false) != TERNARY_INDIRECT)
            error(indirect.lineno, "%s is not a ternary indirect table", indirect->name());
        if (hit_next.size() > 0 && indirect->hit_next.size() > 0)
            error(hit_next[0].lineno, "Ternary Match table with both direct and indirect "
                  "next tables");
        if (!indirect->p4_table) indirect->p4_table = p4_table; }
    attached.pass1(this);
    if (hit_next.size() > 2 && !indirect)
        error(hit_next[0].lineno, "Ternary Match tables cannot directly specify more"
              "than 2 hit next tables");
    if (actions) actions->pass1(this);
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
    if (idletime) {
        idletime->logical_id = logical_id;
        idletime->pass1(); }
}
void TernaryMatchTable::pass2() {
    LOG1("### Ternary match table " << name() << " pass2");
    if (logical_id < 0) choose_logical_id();
    if (input_xbar) input_xbar->pass2(stage->tcam_ixbar, TCAM_XBAR_GROUP_SIZE);
    if (!indirect && indirect_bus < 0) {
        for (int i = 0; i < 16; i++)
            if (!stage->tcam_indirect_bus_use[i/2][i&1]) {
                indirect_bus = i;
                stage->tcam_indirect_bus_use[i/2][i&1] = this;
                break; }
        if (indirect_bus < 0)
            error(lineno, "No ternary indirect bus available for table %s", name()); }
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
}
extern int get_address_mau_actiondata_adr_default(unsigned log2size, bool per_flow_enable);
void TernaryMatchTable::write_regs() {
    LOG1("### Ternary match table " << name() << " write_regs");
    MatchTable::write_regs(1, indirect);
    unsigned word = 0;
    auto &merge = stage->regs.rams.match.merge;
    for (Layout &row : layout) {
        auto vpn = row.vpns.begin();
        for (auto col : row.cols) {
            auto &tcam_mode = stage->regs.tcams.col[col].tcam_mode[row.row];
            //tcam_mode.tcam_data1_select = row.bus; -- no longer used
            if (options.match_compiler)
                tcam_mode.tcam_data1_select = col;
            tcam_mode.tcam_chain_out_enable = (chain_rows >> row.row) & 1;
            if (gress == INGRESS)
                tcam_mode.tcam_ingress = 1;
            else
                tcam_mode.tcam_egress = 1;
            tcam_mode.tcam_match_output_enable =
                ((~chain_rows | ALWAYS_ENABLE_ROW) >> row.row) & 1;
            tcam_mode.tcam_vpn = *vpn++;
            tcam_mode.tcam_logical_table = logical_id;
            tcam_mode.tcam_data_dirtcam_mode = match[word].dirtcam & 0x3ff;
            tcam_mode.tcam_vbit_dirtcam_mode = match[word].dirtcam >> 10;
            /* TODO -- always disable tcam_validbit_xbar? */
            auto &tcam_vh_xbar = stage->regs.tcams.vh_data_xbar;
            if (options.match_compiler) {
                for (int i = 0; i < 8; i++)
                    tcam_vh_xbar.tcam_validbit_xbar_ctl[col][row.row/2][i] |= 15; }
            auto &halfbyte_mux_ctl = tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[col][row.row];
            halfbyte_mux_ctl.tcam_row_halfbyte_mux_ctl_select = match[word].byte_config;
            halfbyte_mux_ctl.tcam_row_halfbyte_mux_ctl_enable = 1;
            halfbyte_mux_ctl.tcam_row_search_thread = gress;
            setup_muxctl(tcam_vh_xbar.tcam_row_output_ctl[col][row.row],
                         match[word].word_group);
            if (match[word].byte_group >= 0)
                setup_muxctl(tcam_vh_xbar.tcam_extra_byte_ctl[col][row.row/2],
                             match[word].byte_group);
            if (!((chain_rows >> row.row) & 1))
                stage->regs.tcams.col[col].tcam_table_map[tcam_id] |= 1U << row.row; }
        if (++word == match.size()) word = 0; }
    setup_muxctl(merge.tcam_hit_to_logical_table_ixbar_outputmap[tcam_id], logical_id);
    /* FIXME -- setting piped mode if any table in the stage is piped -- perhaps
     * FIXME -- tables can be different? */
    if (stage->table_use[gress] & Stage::USE_TCAM_PIPED)
        merge.tcam_table_prop[tcam_id].tcam_piped = 1;
    merge.tcam_table_prop[tcam_id].thread = gress;
    merge.tcam_table_prop[tcam_id].enabled = 1;
    stage->regs.tcams.tcam_output_table_thread[tcam_id] = 1 << gress;
    if (indirect_bus >= 0) {
        /* FIXME -- factor into corresponding code in MatchTable::write_regs */
        setup_muxctl(merge.match_to_logical_table_ixbar_outputmap[1][indirect_bus], logical_id);
        setup_muxctl(merge.match_to_logical_table_ixbar_outputmap[3][indirect_bus], logical_id);
        setup_muxctl(merge.tcam_match_adr_to_physical_oxbar_outputmap[indirect_bus], tcam_id);
        merge.mau_action_instruction_adr_default[1][indirect_bus] = 0x40;
        if (options.match_compiler) {
            auto &shift_en = merge.mau_payload_shifter_enable[1][indirect_bus];
            shift_en.action_instruction_adr_payload_shifter_en = 1;
            if (action)
                shift_en.actiondata_adr_payload_shifter_en = 1;
            if (!attached.stats.empty())
                shift_en.stats_adr_payload_shifter_en = 1;
            if (!attached.meter.empty())
                shift_en.meter_adr_payload_shifter_en = 1; }
        merge.tind_bus_prop[indirect_bus].tcam_piped = 1;
        merge.tind_bus_prop[indirect_bus].thread = gress;
        merge.tind_bus_prop[indirect_bus].enabled = 1;
        //if (action_bus)
        //     merge.mau_immediate_data_mask[1][indirect_bus] = (1UL << action_bus->size()) - 1;
        attached.write_merge_regs(this, 1, indirect_bus);
        if (idletime)
            idletime->write_merge_regs(1, indirect_bus);
        if (action) {
            merge.mau_actiondata_adr_default[1][indirect_bus] =
                get_address_mau_actiondata_adr_default(action->format->log2size, false);
            /* FIXME -- factor with TernaryIndirect code below */
            int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
            if (action.args.size() <= 1) {
                merge.mau_actiondata_adr_mask[1][indirect_bus] = 0x3fffff & (~0U<<lo_huffman_bits);
                merge.mau_actiondata_adr_tcam_shiftcount[indirect_bus] = 69 - lo_huffman_bits;
                merge.mau_actiondata_adr_vpn_shiftcount[1][indirect_bus] =
                    std::max(0, (int)action->format->log2size - 7);
            } else {
                /* FIXME -- support for multiple sizes of action data? */
                merge.mau_actiondata_adr_mask[1][indirect_bus] =
                    ((1U << action.args[1].size()) - 1) << lo_huffman_bits;
                merge.mau_actiondata_adr_tcam_shiftcount[indirect_bus] =
                    action.args[1].field()->bits[0].lo + 5 - lo_huffman_bits; } }
        for (auto &st : attached.stats) {
            if (st.args.empty())
                merge.mau_stats_adr_tcam_shiftcount[indirect_bus] = st->direct_shiftcount();
            else
                merge.mau_stats_adr_tcam_shiftcount[indirect_bus] = st.args[0].field()->bits[0].lo + 7;
            break; /* all must be the same, only config once */ }
        for (auto &m : attached.meter) {
            if (m.args.empty()) {
                merge.mau_meter_adr_tcam_shiftcount[indirect_bus] = m->direct_shiftcount() + 16;
                merge.mau_idletime_adr_tcam_shiftcount[indirect_bus] = m->direct_shiftcount();
            } else {
                merge.mau_meter_adr_tcam_shiftcount[indirect_bus] = m.args[0].field()->bits[0].lo + 16;
                merge.mau_idletime_adr_tcam_shiftcount[indirect_bus] = m.args[0].field()->bits[0].lo; }
            break; /* all must be the same, only config once */ }
    }
    if (actions) actions->write_regs(this);
    if (gateway) gateway->write_regs();
    if (idletime) idletime->write_regs();
    merge.exact_match_logical_result_delay |= 1 << logical_id;
    stage->regs.cfg_regs.mau_cfg_movereg_tcam_only |= 1U << logical_id;
}

std::unique_ptr<json::map> TernaryMatchTable::gen_memory_resource_allocation_tbl_cfg(const char *type, bool skip_spare_bank) {
    assert(!skip_spare_bank); // never spares in tcam
    json::map mra { { "memory_type", json::string(type) } };
    json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"];
    json::vector mem_units;
    unsigned word = 0;
    bool done = false;
    for (auto colnum = 0U; !done; colnum++) {
        done = true;
        for (auto &row : layout) {
            if (colnum >= row.cols.size())
                continue;
            auto col = row.cols[colnum];
            auto vpn = row.vpns[colnum];
            mem_units.push_back(memunit(row.row, col));
            if (++word == match.size()) {
                mem_units_and_vpns.push_back( json::map {
                    { "memory_units",  std::move(mem_units) },
                    { "vpns", json::vector { json::number(vpn) }}});
                mem_units = json::vector();
                word = 0; }
            done = false; } }
    return json::make_unique<json::map>(std::move(mra));
}

void TernaryMatchTable::gen_tbl_cfg(json::vector &out) {
    unsigned number_entries = layout_size()/match.size() * 512;
    json::map &tbl = *base_tbl_cfg(out, "match_entry", number_entries);
    if (!tbl.count("preferred_match_type"))
        tbl["preferred_match_type"] = "ternary";
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "ternary_match", number_entries);
    json::map &pack_fmt = add_pack_format(stage_tbl, 47, match.size(), 1);
    stage_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg("tcam");
    json::vector match_field_list, match_entry_list;
    for (auto field : *input_xbar) {
        int word = match_word(field.first);
        if (word < 0) continue;
        if (field.second.hi > 43) {
            // a field in the byte group, which is shared with the adjacent word group
            // each word gets only 4 bits of the byte group
            assert(field.second.hi < 48);
            assert((field.first & 1) == 0);
            int hwidth = 44 - field.second.lo;
            match_field_list.push_back( json::map {
                { "name", json::string(field.second.what.name()) },
                { "start_offset", json::number(47*word + 2) },
                { "start_bit", json::number(field.second.what.lobit()) },
                { "bit_width", json::number(hwidth) }});
            int adjword = match_word(field.first + 1);
            if (adjword < 0) continue;
            match_field_list.push_back( json::map {
                { "name", json::string(field.second.what.name()) },
                { "start_offset", json::number(47*adjword + 49 - field.second.hi) },
                { "start_bit", json::number(field.second.what.lobit() + hwidth) },
                { "bit_width", json::number(field.second.hi - 43) }});
        } else {
            match_field_list.push_back( json::map {
                { "name", json::string(field.second.what.name()) },
                { "start_offset", json::number(47*word + 45 - field.second.hi) },
                { "start_bit", json::number(field.second.what.lobit()) },
                { "bit_width", json::number(field.second.hi - field.second.lo + 1) }}); } }
    canon_field_list(match_field_list);
    pack_fmt["entry_list"] = json::vector {
        json::map {
            { "entry_number",  json::number(0) },
            { "field_list",  std::move(match_field_list) }}};
    if (indirect) {
        unsigned fmt_width = 1U << indirect->format->log2size;
        json::map tind {
            { "stage_number", json::number(stage->stageno) },
            { "number_entries", json::number(indirect->layout_size()*128/fmt_width * 1024) },
            { "stage_table_type", json::string("ternary_indirection") }};
        indirect->add_pack_format(tind, indirect->format);
        tind["memory_resource_allocation"] =
            indirect->gen_memory_resource_allocation_tbl_cfg("sram");
        stage_tbl["ternary_indirection_table"] = std::move(tind);
        if (indirect->actions) {
            indirect->actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
            indirect->actions->add_immediate_mapping(stage_tbl);
        } else if (indirect->action && indirect->action->actions) {
            indirect->action->actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
            indirect->action->actions->add_immediate_mapping(stage_tbl); } }
    if (actions)
        actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
    else if (action && action->actions)
        action->actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
    if (idletime)
        idletime->gen_stage_tbl_cfg(stage_tbl);
    tbl["performs_hash_action"] = false;
    bool uses_versioning = false;
    for (auto &m : match)
        if (m.byte_config == 3) {
            uses_versioning = true;
            break; }
    tbl["uses_versioning"] = uses_versioning;
    tbl["tcam_error_detect"] = false;
}

void TernaryIndirectTable::setup(VECTOR(pair_t) &data) {
    match_table = 0;
    setup_layout(layout, get(data, "row"), get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
        if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map")) {
            format = new Format(fmt->map, true);
            if (format->size > 64)
                error(fmt->lineno, "ternary indirect format larger than 64 bits");
            if (format->size < 4) {
                /* pad out to minumum size */
                format->size = 4;
                format->log2size = 2; } }
    } else
        error(lineno, "No format specified in table %s", name());
    VECTOR(pair_t) p4_info = EMPTY_VECTOR_INIT;
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data)) {
        } else if (kv.key == "format") {
            /* done above to be done before action_bus and vpns */
        } else if (kv.key == "selector") {
            attached.selector.setup(kv.value, this);
        } else if (kv.key == "stats") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    attached.stats.emplace_back(v, this);
            else attached.stats.emplace_back(kv.value, this);
        } else if (kv.key == "meter") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    attached.meter.emplace_back(v, this);
            else attached.meter.emplace_back(kv.value, this);
        } else if (kv.key == "p4_table") {
            push_back(p4_info, "name", std::move(kv.value));
        } else if (kv.key == "p4_table_size") {
            push_back(p4_info, "size", std::move(kv.value));
        } else if (kv.key == "handle") {
            push_back(p4_info, "handle", std::move(kv.value));
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    if (p4_info.size) {
        if (p4_table)
            error(p4_info[0].key.lineno, "old and new p4 table info in %s", name());
        else
            p4_table = P4Table::get(P4Table::MatchEntry, p4_info); }
    fini(p4_info);
    alloc_rams(false, stage->sram_use, &stage->tcam_indirect_bus_use);
    if (action.set() && actions)
        error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
        error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action.args.size() > 2)
        error(lineno, "Unexpected number of action table arguments %zu", action.args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}

Table::table_type_t TernaryIndirectTable::set_match_table(MatchTable *m, bool indirect) {
    if (match_table)
        error(lineno, "Multiple references to ternary indirect table %s", name());
    else if (!(match_table = dynamic_cast<TernaryMatchTable *>(m)))
        error(lineno, "Trying to link ternary indirect table %s to non-ternary table %s",
              name(), m->name());
    else {
        if (action.check() && action->set_match_table(m, action.args.size() > 1) != ACTION)
            error(action.lineno, "%s is not an action table", action->name());
        attached.pass1(m);
        logical_id = m->logical_id; }
    return TERNARY_INDIRECT;
}

void TernaryIndirectTable::pass1() {
    LOG1("### Ternary indirect table " << name() << " pass1");
    alloc_busses(stage->tcam_indirect_bus_use);
    alloc_vpns();
    check_next();
    if (action_bus) action_bus->pass1(this);
    if (actions) {
        assert(action.args.size() == 0);
        if (auto *sel = lookup_field("action"))
            action.args.push_back(sel);
        else if (actions->count() > 1)
            error(lineno, "No field 'action' to select between mulitple actions in "
                  "table %s format", name());
        actions->pass1(this); }
    // attached.pass1(match_table); -- done in set_match_table, called from
    // TernaryMatchTable::pass1()
    if (action_enable >= 0)
        if (action.args.size() < 1 || action.args[0].size() <= (unsigned)action_enable)
            error(lineno, "Action enable bit %d out of range for action selector", action_enable);
    if (format) format->pass1(this);
}

void TernaryIndirectTable::pass2() {
    LOG1("### Ternary indirect table " << name() << " pass2");
    if (logical_id < 0 && match_table) logical_id = match_table->logical_id;
    if (!match_table)
        error(lineno, "No match table for ternary indirect table %s", name());
    if (actions) actions->pass2(this);
    if (action_bus) action_bus->pass2(this);
    if (format) format->pass2(this);
}

void TernaryIndirectTable::write_regs() {
    LOG1("### Ternary indirect table " << name() << " write_regs");
    int tcam_id = match_table->tcam_id;
    stage->regs.tcams.tcam_match_adr_shift[tcam_id] = format->log2size-2;
    auto &merge = stage->regs.rams.match.merge;
    for (Layout &row : layout) {
        auto vpn = row.vpns.begin();
        auto &ram_row = stage->regs.rams.array.row[row.row];
        for (int col : row.cols) {
            auto &unit_ram_ctl = ram_row.ram[col].unit_ram_ctl;
            unit_ram_ctl.match_ram_write_data_mux_select = 7; /* disable */
            unit_ram_ctl.match_ram_read_data_mux_select = 7; /* disable */
            unit_ram_ctl.tind_result_bus_select = 1U << row.bus;
            auto &mux_ctl = stage->regs.rams.map_alu.row[row.row].adrmux
                    .ram_address_mux_ctl[col/6][col%6];
                mux_ctl.ram_unitram_adr_mux_select = row.bus + 2;
            auto &unitram_config = stage->regs.rams.map_alu.row[row.row].adrmux
                    .unitram_config[col/6][col%6];
            unitram_config.unitram_type = 6;
            unitram_config.unitram_vpn = *vpn++;
            unitram_config.unitram_logical_table = logical_id;
            if (gress == INGRESS)
                unitram_config.unitram_ingress = 1;
            else
                unitram_config.unitram_egress = 1;
            unitram_config.unitram_enable = 1;
            auto &xbar_ctl = stage->regs.rams.map_alu.row[row.row].vh_xbars
                    .adr_dist_tind_adr_xbar_ctl[row.bus];
            setup_muxctl(xbar_ctl, tcam_id);
            if (gress)
                stage->regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row.row);
            ram_row.tind_ecc_error_uram_ctl[gress] |= 1 << (col - 2); }
        int bus = row.row*2 + row.bus;
        merge.tind_ram_data_size[bus] = format->log2size - 1;
        setup_muxctl(merge.tcam_match_adr_to_physical_oxbar_outputmap[bus], tcam_id);
        merge.tind_bus_prop[bus].tcam_piped = 1;
        merge.tind_bus_prop[bus].thread = gress;
        merge.tind_bus_prop[bus].enabled = 1;
        if (action.args.size() > 0 && action.args[0])
            merge.mau_action_instruction_adr_tcam_shiftcount[bus] = action.args[0].field()->bits[0].lo;
        if (format->immed)
            merge.mau_immediate_data_tcam_shiftcount[bus] = format->immed->bits[0].lo;
        if (action) {
            int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
            if (action.args.size() <= 1) {
                merge.mau_actiondata_adr_mask[1][bus] = 0x3fffff & (~0U << lo_huffman_bits);
                merge.mau_actiondata_adr_tcam_shiftcount[bus] =
                    69 + (format->log2size-2) - lo_huffman_bits;
                merge.mau_actiondata_adr_vpn_shiftcount[1][bus] =
                    std::max(0, (int)action->format->log2size - 7);
            } else {
                /* FIXME -- support for multiple sizes of action data? */
                merge.mau_actiondata_adr_mask[1][bus] =
                    ((1U << action.args[1].size()) - 1) << lo_huffman_bits;
                merge.mau_actiondata_adr_tcam_shiftcount[bus] =
                    action.args[1].field()->bits[0].lo + 5 - lo_huffman_bits; } }
        if (attached.selector) {
            if (attached.selector.args.size() == 1)
                merge.mau_selectorlength_default[1][bus] = 1;
            else {
                int width = attached.selector.args[1].size();
                if (attached.selector.args.size() == 3)
                    width += attached.selector.args[2].size();
                merge.mau_selectorlength_mask[1][bus] = (1 << width) - 1; }
            merge.mau_meter_adr_tcam_shiftcount[bus] =
                attached.selector.args[0].field()->bits[0].lo%128 + 23 - get_selector()->address_shift(); }
        if (match_table->idletime)
            merge.mau_idletime_adr_tcam_shiftcount[bus] =
                    66 + format->log2size - match_table->idletime->precision_shift();
        for (auto &st : attached.stats) {
            if (st.args.empty())
                merge.mau_stats_adr_tcam_shiftcount[bus] = st->direct_shiftcount();
            else
                merge.mau_stats_adr_tcam_shiftcount[bus] = st.args[0].field()->bits[0].lo + 7;
            break; /* all must be the same, only config once */ }
        for (auto &m : attached.meter) {
            if (m.args.empty()) {
                merge.mau_meter_adr_tcam_shiftcount[bus] = m->direct_shiftcount() + 16;
                merge.mau_idletime_adr_tcam_shiftcount[bus] = m->direct_shiftcount();
            } else {
                merge.mau_meter_adr_tcam_shiftcount[bus] = m.args[0].field()->bits[0].lo + 16;
                merge.mau_idletime_adr_tcam_shiftcount[bus] = m.args[0].field()->bits[0].lo; }
            break; /* all must be the same, only config once */ }
    }
    if (actions) actions->write_regs(this);
}

void TernaryIndirectTable::add_field_to_pack_format(json::vector &field_list, int basebit,
                                std::string name, const Table::Format::Field &field) {
    if (name == "action") name = "--instruction_address--";
    Table::add_field_to_pack_format(field_list, basebit, name, field);
}

void TernaryIndirectTable::gen_tbl_cfg(json::vector &out) {
}
