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
    for (auto *match_table : match_tables) {
        assert((Table *)match_table != (Table *)this);
        if (auto *rv = match_table->lookup_field(name))
            return rv; }
    return 0;
}
void ActionTable::apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn) {
    for (auto &fmt : action_formats)
        fmt.second->apply_to_field(n, fn);
    if (format)
        format->apply_to_field(n, fn);
}
int ActionTable::find_on_actionbus(Table::Format::Field *f, int off) {
    int rv;
    if (action_bus && (rv = action_bus->find(f, off)) >= 0)
        return rv;
    for (auto *match_table : match_tables) {
        assert((Table *)match_table != (Table *)this);
        if ((rv = match_table->find_on_actionbus(f, off)) >= 0)
            return rv; }
    return -1;
}

void ActionTable::setup(VECTOR(pair_t) &data) {
    action_id = -1;
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(row, get(data, "column"), 0);
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "format") {
            if (CHECKTYPE(kv.value, tMAP))
                format = new Format(kv.value.map, true);
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
        } else if (kv.key == "action_id") {
            if (CHECKTYPE(kv.value, tINT))
                action_id = kv.value.i;
        } else if (kv.key == "vpns") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_vpns(&kv.value.vec);
        } else if (kv.key == "p4_table") {
            if (CHECKTYPE(kv.value, tSTR))
                p4_table = kv.value.s;
        } else if (kv.key == "p4_table_size") {
            if (CHECKTYPE(kv.value, tINT))
                p4_table_size = kv.value.i;
        } else if (kv.key == "handle") {
            if (CHECKTYPE(kv.value, tINT))
                handle = kv.value.i;
        } else if (kv.key == "row" || kv.key == "logical_row" || kv.key == "column") {
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
    LOG1("### Action table " << name() << " pass1");
    alloc_vpns();
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
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
    unsigned width = (format->size-1)/128 + 1;
    unsigned depth = layout_size()/width;
    unsigned idx = 0; // ram index within depth
    int prev_row = -1;
    for (auto &row : layout) {
        if (idx != 0)
            need_bus(lineno, stage->overflow_bus_use, row.row, "Overflow");
        if (idx == 0 || idx + row.cols.size() > depth)
            need_bus(lineno, stage->action_data_use, row.row, "Action data");
        for (int r = (row.row + 1) | 1; r < prev_row; r += 2)
            need_bus(lineno, stage->overflow_bus_use, r, "Overflow");
        if ((idx += row.cols.size()) >= depth) idx -= depth;
        prev_row = row.row; }
    action_bus->pass1(this);
    if (actions) actions->pass1(this);
}
void ActionTable::pass2() {
    LOG1("### Action table " << name() << " pass2");
    if (match_tables.empty())
        error(lineno, "No match table for action table %s", name());
    action_bus->pass2(this);
    if (actions) actions->pass2(this);
}

static void flow_selector_addr(Stage *stage, int from, int to) {
    assert(from > to);
    if (from/2 == to/2) {
        /* L to R */
        stage->regs.rams.map_alu.selector_adr_switchbox.row[from/2].ctl
            .l_oflo_adr_o_mux_select.l_oflo_adr_o_sel_selector_adr_r_i = 1;
        return; }
    if (from & 1)
        /* R down */
        stage->regs.rams.map_alu.selector_adr_switchbox.row[from/2].ctl
            .b_oflo_adr_o_mux_select.b_oflo_adr_o_sel_selector_adr_r_i = 1;
    else
        /* L down */
        stage->regs.rams.map_alu.selector_adr_switchbox.row[from/2].ctl
            .b_oflo_adr_o_mux_select.b_oflo_adr_o_sel_selector_adr_l_i = 1;
    for (int row = from/2 - 1; row > to/2; row--)
        /* top to bottom */
        stage->regs.rams.map_alu.selector_adr_switchbox.row[row].ctl
            .b_oflo_adr_o_mux_select.b_oflo_adr_o_sel_oflo_adr_t_i = 1;
    if (to & 1)
        /* flow down? to R */
        stage->regs.rams.map_alu.selector_adr_switchbox.row[to/2].ctl.r_oflo_adr_o_mux_select = 1;
    else
        /* flow down to L */
        stage->regs.rams.map_alu.selector_adr_switchbox.row[to/2].ctl
            .l_oflo_adr_o_mux_select.l_oflo_adr_o_sel_oflo_adr_t_i = 1;
}

void ActionTable::write_regs() {
    LOG1("### Action table " << name() << " write_regs");
    int width = (format->size+127)/128;
    int depth = layout_size()/width;
    int idx = 0;
    int word = 0;
    Layout *home = &layout[0];
    int prev_logical_row = -1;
    decltype(stage->regs.rams.array.switchbox.row[0].ctl) *home_switch_ctl = 0,
                                                          *prev_switch_ctl = 0;
    auto &icxbar = stage->regs.rams.match.adrdist.adr_dist_action_data_adr_icxbar_ctl;
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        unsigned top = logical_row.row >= 8; /* 0 == bottom  1 == top */
        auto vpn = logical_row.vpns.begin();
        auto &switch_ctl = stage->regs.rams.array.switchbox.row[row].ctl;
        auto &map_alu_row =  stage->regs.rams.map_alu.row[row];
        if (idx != 0) {
            if (&switch_ctl == home_switch_ctl) {
                /* overflow from L to R action */
                switch_ctl.r_action_o_mux_select.r_action_o_sel_oflo_rd_l_i = 1;
            } else {
                if (side) {
                    /* overflow R up */
                    switch_ctl.t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_r_i = 1;
                } else {
                    /* overflow L up */
                    switch_ctl.t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_l_i = 1; }
                if (prev_switch_ctl != &switch_ctl) {
                    if (prev_switch_ctl != home_switch_ctl)
                        prev_switch_ctl->t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_b_i = 1;
                    else if (home->row & 1)
                        home_switch_ctl->r_action_o_mux_select.r_action_o_sel_oflo_rd_b_i = 1;
                    else
                        home_switch_ctl->r_l_action_o_mux_select.r_l_action_o_sel_oflo_rd_b_i = 1;
                }
            }
            /* if we're skipping over full rows and overflowing over those rows, need to
             * propagate overflow from bottom to top.  This effectively uses only the
             * odd (right side) overflow busses.  L ovfl can still go to R action */
            for (int r = prev_logical_row/2 - 1; r > (int)row; r--) {
                prev_switch_ctl = &stage->regs.rams.array.switchbox.row[r].ctl;
                prev_switch_ctl->t_oflo_rd_o_mux_select.t_oflo_rd_o_sel_oflo_rd_b_i = 1; }

            auto &oflo_adr_xbar = map_alu_row.vh_xbars.adr_dist_oflo_adr_xbar_ctl[side];
            if ((home->row >= 8) == top) {
                oflo_adr_xbar.adr_dist_oflo_adr_xbar_source_index = home->row % 8;
                oflo_adr_xbar.adr_dist_oflo_adr_xbar_source_sel = 0;
            } else {
                assert(home->row >= 8);
                oflo_adr_xbar.adr_dist_oflo_adr_xbar_source_index = 0;
                oflo_adr_xbar.adr_dist_oflo_adr_xbar_source_sel = 3;
                for (auto mtab : match_tables)
                    if (!icxbar[mtab->logical_id].address_distr_to_overflow)
                        icxbar[mtab->logical_id].address_distr_to_overflow = 1; }
            oflo_adr_xbar.adr_dist_oflo_adr_xbar_enable = 1; }
        if (SelectionTable *sel = get_selector()) {
            if (logical_row.row != sel->layout[0].row) {
                if (logical_row.row > sel->layout[0].row)
                    error(lineno, "Selector data from %s on row %d cannot flow up to %s on row %d",
                          sel->name(), sel->layout[0].row, name(), logical_row.row);
                else
                    flow_selector_addr(stage, sel->layout[0].row, logical_row.row); } }
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            auto &ram = stage->regs.rams.array.row[row].ram[col];
            auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
            if (idx == 0) {
                home = &logical_row;
                home_switch_ctl = &switch_ctl;
                action_bus->write_action_regs(this, logical_row.row, word);
                if (side)
                    switch_ctl.r_action_o_mux_select.r_action_o_sel_action_rd_r_i = 1;
                else
                    switch_ctl.r_l_action_o_mux_select.r_l_action_o_sel_action_rd_l_i = 1;
                unitram_config.unitram_action_subword_out_en = 1;
                for (auto mtab : match_tables)
                    icxbar[mtab->logical_id].address_distr_to_logical_rows |=
                        1U << logical_row.row; }
            ram.unit_ram_ctl.match_ram_write_data_mux_select = UnitRam::DataMux::NONE;
            ram.unit_ram_ctl.match_ram_read_data_mux_select = home == &logical_row ? 4 : 2;
            unitram_config.unitram_type = UnitRam::ACTION;
            unitram_config.unitram_vpn = *vpn++;
            unitram_config.unitram_logical_table = action_id >= 0 ? action_id : logical_id;
            if (gress == INGRESS)
                unitram_config.unitram_ingress = 1;
            else
                unitram_config.unitram_egress = 1;
            unitram_config.unitram_enable = 1;
            auto &ram_mux = map_alu_row.adrmux.ram_address_mux_ctl[side][logical_col];
            if (SelectionTable *sel = get_selector()) {
                int slot = side * 9;
                if (row == sel->layout[0].row/2U) {
                    /* we're on the home row of the selector, so use it directly */
                    ram_mux.ram_unitram_adr_mux_select = UnitRam::AdrMux::SELECTOR_ALU;
                    slot += 6;
                } else {
                    /* not on the home row -- use overflows */
                    ram_mux.ram_unitram_adr_mux_select = UnitRam::AdrMux::SELECTOR_OVERFLOW; }
                stage->regs.rams.map_alu.mau_selector_action_adr_shift[row]
                    .set_subfield(format->log2size - 2, slot, 3);
            } else {
                if (home == &logical_row)
                    ram_mux.ram_unitram_adr_mux_select = UnitRam::AdrMux::ACTION;
                else {
                    ram_mux.ram_unitram_adr_mux_select = UnitRam::AdrMux::OVERFLOW;
                    ram_mux.ram_oflo_adr_mux_select_oflo = 1; } }
            if (++idx == depth) { idx = 0; ++word; } }
        prev_switch_ctl = &switch_ctl;
        prev_logical_row = logical_row.row; }
    if (actions) actions->write_regs(this);
}

void ActionTable::gen_tbl_cfg(json::vector &out) {
    unsigned fmt_width = (format->size + 127)/128;
    unsigned number_entries = (layout_size() * 128 * 1024) / (1 << format->log2size);
    json::map &tbl = *base_tbl_cfg(out, "action_data", number_entries);
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "action_data", number_entries);
    add_pack_format(stage_tbl, 128, fmt_width,
                    128 >> format->log2size ? 128 >> format->log2size : 1);
    stage_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg();
    stage_tbl["how_referenced"] = action_call().args.size() > 1 ? "indirect" : "direct";
    tbl["action_data_entry_width"] = 1 << format->log2size;
    /* FIXME -- don't include ref to select table as compiler doesn't */
    tbl.erase("p4_selection_tables");
}

