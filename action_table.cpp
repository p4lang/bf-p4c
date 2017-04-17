#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(ActionTable)

std::string ActionTable::find_field(Table::Format::Field *field) {
    for (auto &af : action_formats) {
        auto name = af.second->find_field(field);
        if (!name.empty() && name[0] != '<')
            return af.first + ":" + name; }
    return Table::find_field(field);
}

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
        if (auto *fmt = get(action_formats, action)) {
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
void ActionTable::pad_format_fields() {
    for (auto &fmt : action_formats) {
        for (auto &fmt2 : action_formats)
            if (fmt.second->log2size < fmt2.second->log2size)
                fmt.second->log2size = fmt2.second->log2size;
        if (format->log2size < fmt.second->log2size)
            format->log2size = fmt.second->log2size;
        if (format->size < fmt.second->size)
            format->size = fmt.second->size; }
}
void ActionTable::apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn) {
    for (auto &fmt : action_formats)
        fmt.second->apply_to_field(n, fn);
    if (format)
        format->apply_to_field(n, fn);
}
int ActionTable::find_on_actionbus(Table::Format::Field *f, int off, int size) {
    int rv;
    if (action_bus && (rv = action_bus->find(f, off, size)) >= 0)
        return rv;
    for (auto *match_table : match_tables) {
        assert((Table *)match_table != (Table *)this);
        if ((rv = match_table->find_on_actionbus(f, off, size)) >= 0)
            return rv; }
    return -1;
}
int ActionTable::find_on_actionbus(const char *name, int off, int size, int *len) {
    int rv;
    if (action_bus && (rv = action_bus->find(name, off, size, len)) >= 0)
        return rv;
    for (auto *match_table : match_tables) {
        assert((Table *)match_table != (Table *)this);
        if ((rv = match_table->find_on_actionbus(name, off, size, len)) >= 0)
            return rv; }
    return -1;
}

void ActionTable::vpn_params(int &width, int &depth, int &period, const char *&period_name) {
    width = 1;
    depth = layout_size();
    period = format ? 1 << std::max((int)format->log2size - 7, 0) : 0;
    for (auto fmt : Values(action_formats))
        period = std::max(period, 1 << std::max((int)fmt->log2size - 7, 0));
    period_name = "action data width";
}

void ActionTable::setup(VECTOR(pair_t) &data) {
    action_id = -1;
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(layout, row, get(data, "column"), 0);
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "format") {
            const char *action = nullptr;
            if (kv.key.type == tCMD) {
                if (!PCHECKTYPE(kv.key.vec.size > 1, kv.key[1], tSTR)) continue;
                if (action_formats.count((action = kv.key[1].s))) {
                    error(kv.key.lineno, "Multiple formats for action %s", kv.key[1].s);
                    continue; } }
            if (CHECKTYPEPM(kv.value, tMAP, kv.value.map.size > 0, "non-empty map")) {
                auto *fmt = new Format(kv.value.map, action == nullptr);
                if (fmt->size < 8) {  // pad out to minimum size
                    fmt->size = 8;
                    fmt->log2size = 3; }
                if (action)
                    action_formats[action] = fmt;
                else
                    format = fmt; } } }
    if (!format && action_formats.empty())
        error(lineno, "No format in action table %s", name());
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
            if (kv.value == "null")
                no_vpns = true;
            else if (CHECKTYPE(kv.value, tVEC))
                setup_vpns(layout, &kv.value.vec);
        } else if (kv.key == "home_row") {
            home_lineno = kv.value.lineno;
            if (CHECKTYPE2(kv.value, tINT, tVEC)) {
                if (kv.value.type == tINT)
                    home_rows.push_back(kv.value.i);
                else for (auto &v : kv.value.vec)
                    if (CHECKTYPE(v, tINT))
                        home_rows.push_back(v.i); }
        } else if (kv.key == "p4") {
            if (CHECKTYPE(kv.value, tMAP))
                p4_table = P4Table::get(P4Table::ActionData, kv.value.map);
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
    if (!p4_table) p4_table = P4Table::alloc(P4Table::ActionData, this);
    else p4_table->check(this);
    alloc_vpns();
    std::sort(layout.begin(), layout.end(),
              [](const Layout &a, const Layout &b)->bool { return a.row > b.row; });
    std::sort(home_rows.begin(), home_rows.end(),
              [](const int &a, const int &b)->bool { return a > b; });
    unsigned width = format ? (format->size-1)/128 + 1 : 1;
    for (auto &fmt : action_formats) {
        if (!actions->exists(fmt.first)) {
            error(fmt.second->lineno, "Format for non-existant action %s", fmt.first.c_str());
            continue; }
#if 0
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
                        break; } } } }
#endif
        width = std::max(width, (fmt.second->size-1)/128 + 1); }
    unsigned depth = layout_size()/width;
    unsigned idx = 0; // ram index within depth
    int prev_row = -1;
    int *home = home_rows.empty() ? nullptr : &home_rows[0];
    int *home_end = home ? home + home_rows.size() : nullptr;
    for (auto &row : layout) {
        if (idx == 0 || idx + row.cols.size() > depth) {
            if (!home)
                home_rows.push_back(row.row);
            else if (home == home_end || *home++ != row.row)
                error(home_lineno, "invalid home rows for table %s", name());
            need_bus(lineno, stage->action_data_use, row.row, "Action data"); }
        if (idx != 0) {
            if (home < home_end && *home == row.row) {
                home++;
                need_bus(lineno, stage->action_data_use, row.row, "Action data");
            } else if (!home && home_rows.back() - row.row > 10) {
                /* can't go over >10 rows for timing */
                home_rows.push_back(row.row);
                need_bus(lineno, stage->action_data_use, row.row, "Action data");
            } else if (home && home[-1] - row.row > 10) {
                error(home_lineno, "Can't propagate over more than 10 rows to home row");
            } else {
                need_bus(lineno, stage->overflow_bus_use, row.row, "Overflow");
                for (int r = (row.row + 1) | 1; r < prev_row; r += 2)
                    need_bus(lineno, stage->overflow_bus_use, r, "Overflow"); } }
        if ((idx += row.cols.size()) >= depth) idx -= depth;
        prev_row = row.row; }
    action_bus->pass1(this);
    if (actions) actions->pass1(this);
}
void ActionTable::pass2() {
    LOG1("### Action table " << name() << " pass2");
    if (match_tables.empty())
        error(lineno, "No match table for action table %s", name());
    if (!format)
        format = new Format();
    if (direct) {
        /* need all formats to be the same size, so pad them out */
        pad_format_fields(); }
    if (actions) actions->pass2(this);
    action_bus->pass2(this);
}

template<class REGS>
static void flow_selector_addr(REGS &regs, int from, int to) {
    assert(from > to);
    assert((from & 3) == 3);
    if (from/2 == to/2) {
        /* R to L */
        regs.rams.map_alu.selector_adr_switchbox.row[from/4].ctl
            .l_oflo_adr_o_mux_select.l_oflo_adr_o_sel_selector_adr_r_i = 1;
        return; }
    if (from & 1)
        /* R down */
        regs.rams.map_alu.selector_adr_switchbox.row[from/4].ctl
            .b_oflo_adr_o_mux_select.b_oflo_adr_o_sel_selector_adr_r_i = 1;
    //else
    //    /* L down */
    //    regs.rams.map_alu.selector_adr_switchbox.row[from/4].ctl
    //        .b_oflo_adr_o_mux_select.b_oflo_adr_o_sel_selector_adr_l_i = 1;
    for (int row = from/4 - 1; row > to/4; row--)
        /* top to bottom */
        regs.rams.map_alu.selector_adr_switchbox.row[row].ctl
            .b_oflo_adr_o_mux_select.b_oflo_adr_o_sel_oflo_adr_t_i = 1;
    switch (to & 3) {
    case 3:
        /* flow down to R */
        regs.rams.map_alu.selector_adr_switchbox.row[to/4].ctl.r_oflo_adr_o_mux_select = 1;
        break;
    case 2:
        /* flow down to L */
        regs.rams.map_alu.selector_adr_switchbox.row[to/4].ctl
            .l_oflo_adr_o_mux_select.l_oflo_adr_o_sel_oflo_adr_t_i = 1;
        break;
    default:
        /* even physical rows are hardwired to flow down to both L and R */
        break; }
}

template<class REGS>
void ActionTable::write_regs(REGS &regs) {
    LOG1("### Action table " << name() << " write_regs");
    unsigned fmt_log2size = format->log2size;
    for (auto fmt : Values(action_formats))
        fmt_log2size = std::max(fmt_log2size, fmt->log2size);
    int width = 1 << std::max(fmt_log2size - 7, 0U);
    int depth = layout_size()/width;
    int idx = 0;
    int word = 0;
    Layout *home = nullptr;
    auto home_row = home_rows.begin();
    int prev_logical_row = -1;
    decltype(regs.rams.array.switchbox.row[0].ctl) *home_switch_ctl = 0,
                                                          *prev_switch_ctl = 0;
    auto &icxbar = regs.rams.match.adrdist.adr_dist_action_data_adr_icxbar_ctl;
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        unsigned top = logical_row.row >= 8; /* 0 == bottom  1 == top */
        auto vpn = logical_row.vpns.begin();
        auto &switch_ctl = regs.rams.array.switchbox.row[row].ctl;
        auto &map_alu_row =  regs.rams.map_alu.row[row];
        if (home_row != home_rows.end() && *home_row == logical_row.row) {
            /* FIXME -- won't work if new home row starts in the middle of this row */
            home = nullptr;
            ++home_row; }
        if (home) {
            // FIXME use DataSwitchboxSetup for this somehow?
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
                prev_switch_ctl = &regs.rams.array.switchbox.row[r].ctl;
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
            if (logical_row.row != sel->home_row()) {
                if (logical_row.row > sel->home_row())
                    error(lineno, "Selector data from %s on row %d cannot flow up to %s on row %d",
                          sel->name(), sel->home_row(), name(), logical_row.row);
                else
                    flow_selector_addr(regs, sel->home_row(), logical_row.row); } }
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            auto &ram = regs.rams.array.row[row].ram[col];
            auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
            if (!home) {
                /* FIXME -- this probably won't work if this isn't the first RAM used by this
                 * table on this logical row (boundary between groups falls within a logical row)
                 * as we'll then be trying to use the same physical bus for both groups
                 * Should have issued an error earlier in this case?  */
                home = &logical_row;
                home_switch_ctl = &switch_ctl;
                action_bus->write_action_regs(regs, this, logical_row.row, word);
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
            if (!no_vpns)
                unitram_config.unitram_vpn = *vpn++;
            unitram_config.unitram_logical_table = action_id >= 0 ? action_id : logical_id;
            if (gress == INGRESS)
                unitram_config.unitram_ingress = 1;
            else
                unitram_config.unitram_egress = 1;
            unitram_config.unitram_enable = 1;
            auto &ram_mux = map_alu_row.adrmux.ram_address_mux_ctl[side][logical_col];
            auto &adr_mux_sel = ram_mux.ram_unitram_adr_mux_select;
            if (SelectionTable *sel = get_selector()) {
                int shift = fmt_log2size - 2;
                auto &shift_ctl = regs.rams.map_alu.mau_selector_action_adr_shift[row];
                if (logical_row.row == sel->layout[0].row) {
                    /* we're on the home row of the selector, so use it directly */
                    if (home == &logical_row)
                        adr_mux_sel = UnitRam::AdrMux::SELECTOR_ALU;
                    else
                        adr_mux_sel = UnitRam::AdrMux::SELECTOR_ACTION_OVERFLOW;
                    if (side)
                        shift_ctl.mau_selector_action_adr_shift_right = shift;
                    else
                        shift_ctl.mau_selector_action_adr_shift_left = shift;
                } else {
                    /* not on the home row -- use overflows */
                    if (home == &logical_row)
                        adr_mux_sel = UnitRam::AdrMux::SELECTOR_OVERFLOW;
                    else
                        adr_mux_sel = UnitRam::AdrMux::SELECTOR_ACTION_OVERFLOW;
                    if (side)
                        shift_ctl.mau_selector_action_adr_shift_right_oflo = shift;
                    else
                        shift_ctl.mau_selector_action_adr_shift_left_oflo = shift;
                }
            } else {
                if (home == &logical_row)
                    adr_mux_sel = UnitRam::AdrMux::ACTION;
                else {
                    adr_mux_sel = UnitRam::AdrMux::OVERFLOW;
                    ram_mux.ram_oflo_adr_mux_select_oflo = 1; } }
            if (gress)
                regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row);
            regs.rams.array.row[row].actiondata_error_uram_ctl[gress] |= 1 << (col-2);
            if (++idx == depth) { idx = 0; home = nullptr; ++word; } }
        prev_switch_ctl = &switch_ctl;
        prev_logical_row = logical_row.row; }
    // FIXME -- should we do this?
    // if (push_on_overflow)
    //    adrdist.oflo_adr_user[0] = adrdist.oflo_adr_user[1] = AdrDist::ACTION;
    if (actions) actions->write_regs(regs, this);
}

void ActionTable::gen_tbl_cfg(json::vector &out) {
    // FIXME -- this is wrong if actions have different format sizes
    unsigned number_entries = (layout_size() * 128 * 1024) / (1 << format->log2size);
    json::map &tbl = *base_tbl_cfg(out, "action_data", number_entries);
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "action_data", number_entries);
    stage_tbl["stage_table_handle"] = action_id;
    for (auto &act : *actions) {
        auto *fmt = ::get(action_formats, act.name);
        add_pack_format(stage_tbl, fmt ? fmt : format); }
    stage_tbl["memory_resource_allocation"] =
            gen_memory_resource_allocation_tbl_cfg("sram", layout);
    if (actions)
        actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
    stage_tbl["how_referenced"] = indirect ? "indirect" : "direct";
    // FIXME -- this is wrong if actions have different format sizes
    tbl["action_data_entry_width"] = 1 << format->log2size;
    /* FIXME -- don't include ref to select table as compiler doesn't */
    tbl.erase("p4_selection_tables");
    if (options.match_compiler)
        tbl["indirect"] = indirect;
}

