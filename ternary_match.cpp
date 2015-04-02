#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "range.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(TernaryMatchTable)
DEFINE_TABLE_TYPE(TernaryIndirectTable)

void TernaryMatchTable::vpn_params(int &width, int &depth, int &period, const char *&period_name) {
    width = input_xbar->width();
    depth = layout_size() / width;
    period = 1;
    period_name = 0;
}

void TernaryMatchTable::setup(VECTOR(pair_t) &data) {
    tcam_id = -1;
    indirect_bus = -1;
    setup_layout(get(data, "row"), get(data, "column"), get(data, "bus"));
    setup_logical_id();
    if (auto *ixbar = get(data, "input_xbar")) {
        if (CHECKTYPE(*ixbar, tMAP))
            input_xbar = new InputXbar(this, true, ixbar->map);
    } else
        error(lineno, "No input xbar specified in table %s", name());
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "input_xbar") {
            /* done above to be done before vpns */
        } else if (kv.key == "gateway") {
            if (CHECKTYPE(kv.value, tMAP)) {
                gateway = GatewayTable::create(kv.key.lineno, name_+" gateway",
                        gress, stage, -1, kv.value.map);
                gateway->match_table = this; }
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
        } else if (kv.key == "action") {
            setup_action_table(kv.value);
        } else if (kv.key == "actions") {
            if (CHECKTYPE(kv.value, tMAP))
                actions = new Actions(this, kv.value.map);
        } else if (kv.key == "tcam_id") {
            if (CHECKTYPE(kv.value, tINT)) {
                if ((tcam_id = kv.value.i) < 0 || tcam_id >= TCAM_TABLES_PER_STAGE)
                    error(kv.key.lineno, "Invalid tcam_id %d", tcam_id);
                else if (stage->tcam_id_use[tcam_id])
                    error(kv.key.lineno, "Tcam id %d already in use by table %s",
                          tcam_id, stage->tcam_id_use[tcam_id]->name());
                else
                    stage->tcam_id_use[tcam_id] = this; }
        } else if (kv.key == "hit") {
            if (!hit_next.empty())
                error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
            else if (CHECKTYPE(kv.value, tSTR))
                hit_next.emplace_back(kv.value);
        } else if (kv.key == "miss") {
            if (CHECKTYPE(kv.value, tSTR))
                miss_next = kv.value;
        } else if (kv.key == "next") {
            if (!hit_next.empty())
                error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
            else if (CHECKTYPE(kv.value, tSTR))
                hit_next.emplace_back(kv.value);
                miss_next = kv.value;
        } else if (kv.key == "vpns") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_vpns(&kv.value.vec);
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
    alloc_rams(false, stage->tcam_use, &stage->tcam_match_bus_use);
    if (indirect_bus > 0) {
        stage->tcam_indirect_bus_use[indirect_bus/2][indirect_bus&1] = this; }
    if (indirect.set()) {
        if (action.set() || actions)
            error(lineno, "Table %s has both ternary indirect and direct actions", name());
        if (indirect_bus > 0)
            error(lineno, "Table %s has both ternary indirect table and explicit indirect bus",
                  name());
    } else if (action.set() && actions)
        error(lineno, "Table %s has both action table and immediate actions", name());
    else if (!action.set() && !actions)
        error(lineno, "Table %s has no indirect, action table or immediate actions", name());
    if (action_args.size() > 0)
        error(lineno, "Unexpected number of action table arguments %zu", action_args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}
void TernaryMatchTable::pass1() {
    stage->table_use[gress] |= Stage::USE_TCAM;
    /* FIXME -- unconditionally setting piped mode -- only need it for wide
     * match across a 4-row boundary */
    stage->table_use[gress] |= Stage::USE_TCAM_PIPED;
    alloc_id("logical", logical_id, stage->pass1_logical_id,
             LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_id("tcam", tcam_id, stage->pass1_tcam_id,
             TCAM_TABLES_PER_STAGE, false, stage->tcam_id_use);
    alloc_busses(stage->tcam_match_bus_use);
    alloc_vpns();
    check_next();
    indirect.check();
    link_action(action);
    if (indirect) {
        if (!dynamic_cast<TernaryIndirectTable *>((Table *)indirect))
            error(indirect.lineno, "%s is not a ternary indirect table", indirect->name());
        if (indirect->match_table)
            error(indirect->lineno, "Multiple references to ternary indirect table %s",
                  indirect->name());
        indirect->match_table = this;
        indirect->logical_id = logical_id;
        link_action(indirect->action);
        if (hit_next.size() > 0 && indirect->hit_next.size() > 0)
            error(hit_next[0].lineno, "Ternary Match table with both direct and indirect "
                  "next tables"); }
    if (hit_next.size() > 2)
        error(hit_next[0].lineno, "Ternary Match tables cannot directly specify more"
              "than 2 hit next tables");
    input_xbar->pass1(stage->tcam_ixbar, 44);
    if (actions) actions->pass1(this);
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
}
void TernaryMatchTable::pass2() {
    input_xbar->pass2(stage->tcam_ixbar, 44);
    if (!indirect && indirect_bus < 0) {
        for (int i = 0; i < 16; i++)
            if (!stage->tcam_indirect_bus_use[i/2][i&1]) {
                indirect_bus = i;
                stage->tcam_indirect_bus_use[i/2][i&1] = this;
                break; }
        if (indirect_bus < 0)
            error(lineno, "No ternary indirect bus available for table %s", name()); }
    if (gateway) gateway->pass2();
}
void TernaryMatchTable::write_regs() {
    LOG1("### Ternary match table " << name());
    MatchTable::write_regs(1, indirect);
    unsigned word = 0;
    auto &merge = stage->regs.rams.match.merge;
    for (Layout &row : layout) {
        auto vpn = row.vpns.begin();
        for (auto col : row.cols) {
            auto &tcam_mode = stage->regs.tcams.col[col].tcam_mode[row.row];
            /* TODO -- always setting dirtcam mode to 0 */
            tcam_mode.tcam_data_dirtcam_mode = 0;
            tcam_mode.tcam_data1_select = row.bus;
            tcam_mode.tcam_chain_out_enable = word > 0;
            if (gress == INGRESS)
                tcam_mode.tcam_ingress = 1;
            else
                tcam_mode.tcam_egress = 1;
            tcam_mode.tcam_match_output_enable = (word == 0);
            tcam_mode.tcam_vpn = *vpn++;
            tcam_mode.tcam_logical_table = tcam_id;
            /* TODO -- always disable tcam_validbit_xbar? */
            auto &tcam_vh_xbar = stage->regs.tcams.vh_data_xbar;
            if (options.match_compiler) {
                for (int i = 0; i < 8; i++)
                    tcam_vh_xbar.tcam_validbit_xbar_ctl[row.bus][row.row/2][i] |= 15; }
            auto &halfbyte_mux_ctl = tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row];
            if (word+1 == input_xbar->width()) {
                halfbyte_mux_ctl.tcam_row_halfbyte_mux_ctl_select = 3;
                halfbyte_mux_ctl.tcam_row_halfbyte_mux_ctl_enable = 1;
                halfbyte_mux_ctl.tcam_row_search_thread = gress;
            } else {
                /* FIXME -- program to halfbyte mux */
                if (options.match_compiler) {
                    halfbyte_mux_ctl.tcam_row_halfbyte_mux_ctl_select = (row.row & 1) + 1;
                    halfbyte_mux_ctl.tcam_row_halfbyte_mux_ctl_enable = 1;
                    halfbyte_mux_ctl.tcam_row_search_thread = gress;
                }
            }
            /* FIXME:
            tcam_vh_xbar.tcam_extra_byte_ctl[row.bus][row.row/2]
                .enabled_3bit_muxctl_select = byte_match_group_number;
            tcam_vh_xbar.tcam_extra_byte_ctl[row.bus][row.row/2]
                .enabled_3bit_muxctl_enable = 1; */
            tcam_vh_xbar.tcam_row_output_ctl[row.bus][row.row]
                .enabled_4bit_muxctl_select = input_xbar->group_for_word(word);
            tcam_vh_xbar.tcam_row_output_ctl[row.bus][row.row]
                .enabled_4bit_muxctl_enable = 1;
            if (word == 0)
                stage->regs.tcams.col[col].tcam_table_map[tcam_id] |= 1U << row.row; }
        if (++word == input_xbar->width()) word = 0; }
    merge.tcam_hit_to_logical_table_ixbar_outputmap[tcam_id]
        .enabled_4bit_muxctl_select = logical_id;
    merge.tcam_hit_to_logical_table_ixbar_outputmap[tcam_id]
        .enabled_4bit_muxctl_enable = 1;
    /* FIXME -- setting piped mode if any table in the stage is piped -- perhaps
     * FIXME -- tables can be different? */
    if (stage->table_use[gress] & Stage::USE_TCAM_PIPED)
        merge.tcam_table_prop[tcam_id].tcam_piped = 1;
    merge.tcam_table_prop[tcam_id].thread = gress;
    merge.tcam_table_prop[tcam_id].enabled = 1;
    stage->regs.tcams.tcam_output_table_thread[tcam_id] = 1 << gress;
    if (indirect_bus >= 0) {
        auto &ixbar_outputmap = merge.match_to_logical_table_ixbar_outputmap[1][indirect_bus];
        ixbar_outputmap.enabled_4bit_muxctl_select = logical_id;
        ixbar_outputmap.enabled_4bit_muxctl_enable = 1;
        auto &oxbar_outputmap = merge.tcam_match_adr_to_physical_oxbar_outputmap[indirect_bus];
        oxbar_outputmap.enabled_3bit_muxctl_select = tcam_id;
        oxbar_outputmap.enabled_3bit_muxctl_enable = 1;
        merge.tind_bus_prop[indirect_bus].tcam_piped = 1;
        merge.tind_bus_prop[indirect_bus].thread = gress;
        merge.tind_bus_prop[indirect_bus].enabled = 1; }
    if (gateway) gateway->write_regs();
}

void TernaryMatchTable::gen_tbl_cfg(json::vector &out) {
}

void TernaryIndirectTable::setup(VECTOR(pair_t) &data) {
    match_table = 0;
    setup_layout(get(data, "row"), get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
       if (CHECKTYPE(*fmt, tMAP))
           format = new Format(fmt->map);
        if (format->size > 64)
            error(fmt->lineno, "ternary indirect format larger than 64 bits");
        if (format->size < 4) {
            /* pad out to minumum size */
            format->size = 4;
            format->log2size = 2; }
    } else
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "format") {
            /* done above to be done before action_bus and vpns */
        } else if (kv.key == "action") {
            setup_action_table(kv.value);
        } else if (kv.key == "actions") {
            if (CHECKTYPE(kv.value, tMAP))
                actions = new Actions(this, kv.value.map);
        } else if (kv.key == "action_bus") {
            if (CHECKTYPE(kv.value, tMAP))
                action_bus = new ActionBus(this, kv.value.map);
        } else if (kv.key == "hit") {
            if (!hit_next.empty())
                error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
            else if (kv.value.type == tVEC) {
                for (auto &v : kv.value.vec)
                    if (CHECKTYPE(v, tSTR))
                        hit_next.emplace_back(v);
            } else if (CHECKTYPE(kv.value, tSTR))
                hit_next.emplace_back(kv.value);
        } else if (kv.key == "miss") {
            if (CHECKTYPE(kv.value, tSTR))
                miss_next = kv.value;
        } else if (kv.key == "next") {
            if (!hit_next.empty())
                error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
            else if (CHECKTYPE(kv.value, tSTR))
                hit_next.emplace_back(kv.value);
                miss_next = kv.value;
        } else if (kv.key == "vpns") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_vpns(&kv.value.vec);
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
    alloc_rams(false, stage->sram_use, &stage->tcam_indirect_bus_use);
    if (action.set() && actions)
        error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
        error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action_args.size() > 2)
        error(lineno, "Unexpected number of action table arguments %zu", action_args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}
void TernaryIndirectTable::pass1() {
    alloc_busses(stage->tcam_indirect_bus_use);
    alloc_vpns();
    check_next();
    if (action_bus) action_bus->pass1(this);
    if (actions) {
        assert(action_args.size() == 0);
        if (auto *sel = lookup_field("action"))
            action_args.push_back(sel);
        else if (actions->count() > 1)
            error(lineno, "No field 'action' to select between mulitple actions in "
                  "table %s format", name());
        actions->pass1(this); }
    if (format) format->setup_immed(this);
}
void TernaryIndirectTable::pass2() {
    if (!match_table)
        error(lineno, "No match table for ternary indirect table %s", name());
    if (action_bus) action_bus->pass2(this);
    if (actions) actions->pass2(this);
}
void TernaryIndirectTable::write_regs() {
    LOG1("### Ternary indirect table " << name());
    int tcam_id = dynamic_cast<TernaryMatchTable *>(match_table)->tcam_id;
    stage->regs.tcams.tcam_match_adr_shift[tcam_id] = format->log2size-2;
    auto &merge = stage->regs.rams.match.merge;
    for (Layout &row : layout) {
        auto vpn = row.vpns.begin();
        for (int col : row.cols) {
            auto &unit_ram_ctl = stage->regs.rams.array.row[row.row].ram[col].unit_ram_ctl;
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
            xbar_ctl.enabled_3bit_muxctl_select = tcam_id;
            xbar_ctl.enabled_3bit_muxctl_enable = 1; }
        int bus = row.row*2 + row.bus;
        merge.tind_ram_data_size[bus] = format->log2size - 1;
        merge.tcam_match_adr_to_physical_oxbar_outputmap[bus].enabled_3bit_muxctl_select = tcam_id;
        merge.tcam_match_adr_to_physical_oxbar_outputmap[bus].enabled_3bit_muxctl_enable = 1;
        merge.tind_bus_prop[bus].tcam_piped = 1;
        merge.tind_bus_prop[bus].thread = gress;
        merge.tind_bus_prop[bus].enabled = 1;
        merge.mau_action_instruction_adr_tcam_shiftcount[bus] = action_args[0]->bits[0].lo;
        if (format->immed)
            merge.mau_immediate_data_tcam_shiftcount[bus] = format->immed->bits[0].lo;
        if (action) {
            int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
            if (action_args.size() == 1) {
                merge.mau_actiondata_adr_mask[1][bus] = 0x3fffff & (~0U << lo_huffman_bits);
                merge.mau_actiondata_adr_tcam_shiftcount[bus] =
                    69 + (format->log2size-2) - lo_huffman_bits;
                merge.mau_actiondata_adr_vpn_shiftcount[1][bus] =
                    std::max(0, (int)action->format->log2size - 7);
            } else {
                /* FIXME -- support for multiple sizes of action data? */
                merge.mau_actiondata_adr_mask[1][bus] =
                    ((1U << action_args[1]->size) - 1) << lo_huffman_bits;
                merge.mau_actiondata_adr_tcam_shiftcount[bus] =
                    action_args[1]->bits[0].lo + 5 - lo_huffman_bits; } } }
    if (actions) actions->write_regs(this);
}

void TernaryIndirectTable::gen_tbl_cfg(json::vector &out) {
}
