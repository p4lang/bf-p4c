#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(ActionTable)

Table::Format::Field *ActionTable::lookup_field(const std::string &name, const std::string &action)
{
    if (action == "*" || action == "") {
        if (auto *rv = format ? format->field(name) : 0)
            return rv;
        if (action == "*")
            for (auto &fmt : action_formats)
                if (auto *rv = fmt.second->field(name))
                    return rv;
    } else { 
        if (auto *fmt = get(action_formats, name)) {
            if (auto *rv = fmt->field(name))
                return rv;
        } else if (auto *rv = format ? format->field(name) : 0)
            return rv; }
    if (match_table) {
        assert((Table *)match_table != (Table *)this);
        return match_table->lookup_field(name); }
    return 0;
}
void ActionTable::apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn) {
    for (auto &fmt : action_formats)
        fmt.second->apply_to_field(n, fn);
    if (format)
        format->apply_to_field(n, fn);
}

void ActionTable::setup(VECTOR(pair_t) &data) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(row, get(data, "column"), get(data, "bus"));
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "format") {
            if (CHECKTYPE(kv.value, tMAP))
                format = new Format(kv.value.map);
        } else if (kv.key.type == tCMD && kv.key[0] == "format") {
            if (!PCHECKTYPE(kv.key.vec.size > 1, kv.key[1], tSTR)) continue;
            if (action_formats.count(kv.key[1].s)) {
                error(kv.key.lineno, "Multiple formats for action %s", kv.key[1].s);
                return; }
            if (CHECKTYPE(kv.value, tMAP))
                action_formats[kv.key[1].s] = new Format(kv.value.map); } }
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "format") {
            /* done above to be done before action_bus and vpns */
        } else if (kv.key.type == tCMD && kv.key[0] == "format") {
            /* done above to be done before action_bus */
        } else if (kv.key == "actions") {
            if (CHECKTYPE(kv.value, tMAP))
                actions = new Actions(this, kv.value.map);
        } else if (kv.key == "action_bus") {
            if (CHECKTYPE(kv.value, tMAP))
                action_bus = new ActionBus(this, kv.value.map);
        } else if (kv.key == "vpns") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_vpns(&kv.value.vec);
        } else if (kv.key == "row" || kv.key == "logical_row" ||
                   kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(true, stage->sram_use, 0);
    if (!actions)
        error(lineno, "No actions in action table %s", name());
    if (actions && !action_bus) action_bus = new ActionBus();
}
void ActionTable::pass1() {
    alloc_vpns();
    for (Layout &row : layout) {
        if (row.row > layout[0].row)
            error(row.lineno, "Action table %s home row must be first", name());
    }
    for (auto &fmt : action_formats) {
        if (!actions->exists(fmt.first)) {
            error(fmt.second->lineno, "Format for non-existant action %s", fmt.first.c_str());
            continue; }
        for (auto &fld : *fmt.second) {
            if (auto *f = format ? format->field(fld.first) : 0) {
                if (fld.second.bits != f->bits || fld.second.size != f->size) {
                    error(fmt.second->lineno, "Action %s format for field %s incompatible "
                          "with default format", fmt.first.c_str(), fld.first.c_str());
                    continue; } }
            for (auto &fmt2 : action_formats) {
                if (fmt.second == fmt2.second) break;
                if (auto *f = fmt2.second->field(fld.first)) {
                    if (fld.second.bits != f->bits || fld.second.size != f->size) {
                        error(fmt.second->lineno, "Action %s format for field %s incompatible "
                              "with action %s format", fmt.first.c_str(), fld.first.c_str(),
                              fmt2.first.c_str());
                        break; } } } } }
    action_bus->pass1(this);
    if (actions) actions->pass1(this);
}
void ActionTable::pass2() {
    if (!match_table)
        error(lineno, "No match table for action table %s", name());
    action_bus->pass2(this);
    action_bus->set_action_offsets(this);
    if (actions) actions->pass2(this);
}

void ActionTable::write_regs() {
    LOG1("### Action table " << name());
    Layout &home = layout[0];
    unsigned home_top = home.row >= 8;
    for (unsigned slice = 0; slice <= (format->size-1)/128; slice++)
        action_bus->write_action_regs(this, home.row, slice);
    bool home_row = true;
    auto &icxbar = stage->regs.rams.match.adrdist.adr_dist_action_data_adr_icxbar_ctl[logical_id];
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        unsigned top = logical_row.row >= 8; /* 0 == bottom  1 == top */
        auto vpn = logical_row.vpns.begin();
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            auto &ram = stage->regs.rams.array.row[row].ram[col];
            ram.unit_ram_ctl.match_ram_write_data_mux_select = 7; /*disable*/
            ram.unit_ram_ctl.match_ram_read_data_mux_select = home_row ? 4 : 2;
            auto &map_alu_row =  stage->regs.rams.map_alu.row[row];
            auto &oflo_adr_xbar = map_alu_row.vh_xbars.adr_dist_oflo_adr_xbar_ctl[side];
            if (!home_row) {
                if (home_top == top) {
                    oflo_adr_xbar.adr_dist_oflo_adr_xbar_source_index = logical_row.row % 8;
                    oflo_adr_xbar.adr_dist_oflo_adr_xbar_source_sel = 0;
                } else {
                    assert(home_top);
                    oflo_adr_xbar.adr_dist_oflo_adr_xbar_source_index = 0;
                    oflo_adr_xbar.adr_dist_oflo_adr_xbar_source_sel = 2;
                    if (!icxbar.address_distr_to_overflow)
                        icxbar.address_distr_to_overflow = 1; }
                oflo_adr_xbar.adr_dist_oflo_adr_xbar_enable = 1; }
            auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
            unitram_config.unitram_type = 2;
            unitram_config.unitram_vpn = *vpn++;
            unitram_config.unitram_logical_table = logical_id;
            if (gress == INGRESS)
                unitram_config.unitram_ingress = 1;
            else
                unitram_config.unitram_egress = 1;
            if (home_row)
                unitram_config.unitram_action_subword_out_en = 1;
            unitram_config.unitram_enable = 1;
            auto &ram_mux = map_alu_row.adrmux.ram_address_mux_ctl[side][logical_col];
            if (home_row)
                ram_mux.ram_unitram_adr_mux_select = 1;
            else {
                ram_mux.ram_unitram_adr_mux_select = 4;
                ram_mux.ram_oflo_adr_mux_select_oflo = 1; } }
        icxbar.address_distr_to_logical_rows |= 1U << logical_row.row;
        auto &switch_ctl = stage->regs.rams.array.switchbox.row[row].ctl;
        /* FIXME -- figure out oflo stuff */
        if(side)
            switch_ctl.r_action_o_mux_select.r_action_o_sel_action_rd_r_i = 1;
        else
            switch_ctl.r_l_action_o_mux_select.r_l_action_o_sel_action_rd_l_i = 1;
        home_row = false; }

    if (actions) actions->write_regs(this);
}

void ActionTable::gen_tbl_cfg(json::vector &out) {
}

