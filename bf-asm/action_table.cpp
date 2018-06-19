#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "stage.h"
#include "tables.h"

/// See 6.2.8.4.3 of the MAU Micro-Architecture document.
const unsigned MAX_AD_SHIFT = 5U;

DEFINE_TABLE_TYPE(ActionTable)

std::string ActionTable::find_field(Table::Format::Field *field) {
    for (auto &af : action_formats) {
        auto name = af.second->find_field(field);
        if (!name.empty() && name[0] != '<')
            return af.first + ":" + name; }
    return Table::find_field(field);
}

int ActionTable::find_field_lineno(Table::Format::Field *field) {
    int rv = -1;
    for (auto &af : action_formats)
        if ((rv = af.second->find_field_lineno(field)) >= 0)
            return rv;
    return Table::find_field_lineno(field);
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
    format->size = get_size();
    format->log2size = get_log2size();
    for (auto &fmt : action_formats) {
        if (fmt.second->size < format->size) {
            fmt.second->size = format->size;
            fmt.second->log2size = format->log2size; } }
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
int ActionTable::find_on_actionbus(HashDistribution *hd, int off, int size) {
    int rv;
    if (action_bus && (rv = action_bus->find(hd, off, size)) >= 0)
        return rv;
    for (auto *match_table : match_tables) {
        if (match_table->find_hash_dist(hd->id) == hd) {
            if ((rv = match_table->find_on_actionbus(hd, off, size)) >= 0)
                return rv; } }
    return -1;
}
int ActionTable::find_on_actionbus(RandomNumberGen rng, int off, int size) {
    int rv;
    if (action_bus && (rv = action_bus->find(rng, off, size)) >= 0)
        return rv;
    for (auto *match_table : match_tables) {
        if ((rv = match_table->find_on_actionbus(rng, off, size)) >= 0)
            return rv; }
    return -1;
}

void ActionTable::need_on_actionbus(Format::Field *f, int off, int size) {
    if (f->fmt == format) {
        Table::need_on_actionbus(f, off, size);
        return; }
    for (auto af : Values(action_formats)) {
        if (f->fmt == af) {
            Table::need_on_actionbus(f, off, size);
            return; } }
    for (auto *match_table : match_tables) {
        assert((Table *)match_table != (Table *)this);
        if (f->fmt == match_table->format) {
            match_table->need_on_actionbus(f, off, size);
            return; } }
    assert(!"Can't find table associated with field");
}

void ActionTable::need_on_actionbus(Table *attached, int off, int size) {
    int attached_count = 0;
    for (auto *match_table : match_tables) {
        if (match_table->is_attached(attached)) {
            match_table->need_on_actionbus(attached, off, size);
            ++attached_count; } }
    // FIXME -- if its attached to more than one match table (mutex match tables that
    // share attached action table and attached other table), then it needs to be allocated
    // to the same slot of the action bus in all of the match tables.  Not sure if we do that
    // properly
    assert(attached_count == 1);
}

void ActionTable::need_on_actionbus(HashDistribution *hd, int off, int size) {
    for (auto &hash_dist : this->hash_dist) {
        if (&hash_dist == hd) {
            Table::need_on_actionbus(hd, off, size);
            return; } }
    for (auto *match_table : match_tables) {
        if (match_table->find_hash_dist(hd->id) == hd) {
            match_table->need_on_actionbus(hd, off, size);
            return; } }
    assert(!"Can't find table associated with hash_dist");
}

void ActionTable::need_on_actionbus(RandomNumberGen rng, int off, int size) {
    int attached_count = 0;
    for (auto *match_table : match_tables) {
        match_table->need_on_actionbus(rng, off, size);
        ++attached_count; }
    // FIXME -- if its attached to more than one match table (mutex match tables that
    // share actions in an attached action data table, then it needs to be allocated
    // to the same slot of the action bus in all of the match tables.  Not sure if we do that
    // properly
    assert(attached_count == 1);
}

int ActionTable::get_start_vpn() {
    // Based on the format width, the starting vpn is determined as follows (See
    // Section 6.2.8.4.3 in MAU MicroArchitecture Doc)
    //    WIDTH     LOG2SIZE START_VPN 
    // <= 128 bits  -  7       - 0 
    //  = 256 bits  -  8       - 0
    //  = 512 bits  -  9       - 1
    //  = 1024 bits - 10       - 3
    int size = get_log2size();
    if (size <= 8) return 0;
    if (size == 9) return 1;
    if (size == 10) return 3;
    return 0;
}

void ActionTable::vpn_params(int &width, int &depth, int &period, const char *&period_name) {
    width = 1;
    depth = layout_size();
    period = format ? 1 << std::max((int)format->log2size - 7, 0) : 0;
    // Based on the format width, the vpn are numbered as follows (See Section
    // 6.2.8.4.3 in MAU MicroArchitecture Doc)
    //    WIDTH     PERIOD  VPN'S
    // <= 128 bits  - +1 - 0, 1, 2, 3, ...
    //  = 256 bits  - +2 - 2, 4, 6, 8, ...
    //  = 512 bits  - +4 - 1, 5, 9, 13, ...
    //  = 1024 bits - +8 - 3, 11, 19, 27, ...
    for (auto fmt : Values(action_formats))
        period = std::max(period, 1 << std::max((int)fmt->log2size - 7, 0));
    period_name = "action data width";
}

void ActionTable::setup(VECTOR(pair_t) &data) {
    action_id = -1;
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(layout, row, get(data, "column"), 0, get(data, "word"));
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "format") {
            const char *action = nullptr;
            if (kv.key.type == tCMD) {
                if (!PCHECKTYPE(kv.key.vec.size > 1, kv.key[1], tSTR)) continue;
                if (action_formats.count((action = kv.key[1].s))) {
                    error(kv.key.lineno, "Multiple formats for action %s", kv.key[1].s);
                    continue; } }
            if (CHECKTYPEPM(kv.value, tMAP, kv.value.map.size > 0, "non-empty map")) {
                auto *fmt = new Format(this, kv.value.map, action == nullptr);
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
                if (kv.value.type == tINT) {
                    if (kv.value.i >= 0 || kv.value.i < LOGICAL_SRAM_ROWS)
                        home_rows |= 1 << kv.value.i;
                    else
                        error(kv.value.lineno, "Invalid home row %ld", kv.value.i);
                } else for (auto &v : kv.value.vec) {
                    if (CHECKTYPE(v, tINT)) {
                        if (v.i >= 0 || v.i < LOGICAL_SRAM_ROWS)
                            home_rows |= 1 << v.i;
                        else
                            error(v.lineno, "Invalid home row %ld", v.i); } } }
        } else if (kv.key == "p4") {
            if (CHECKTYPE(kv.value, tMAP))
                p4_table = P4Table::get(P4Table::ActionData, kv.value.map);
        } else if (kv.key == "row" || kv.key == "logical_row" || kv.key == "column"
                   || kv.key == "word") {
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
    if (default_action.empty()) default_action = get_default_action();
    if (!p4_table) p4_table = P4Table::alloc(P4Table::ActionData, this);
    else p4_table->check(this);
    alloc_vpns();
    std::sort(layout.begin(), layout.end(), [](const Layout &a, const Layout &b)->bool {
              if (a.word != b.word) return a.word < b.word;
              return a.row > b.row; });
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
    std::vector<int> slice_size(width, 0);
    unsigned idx = 0; // ram index within depth
    unsigned word = 0;  // word within wide table;
    int home_row = -1;
    unsigned final_home_rows = 0;
    Layout *prev = nullptr;
    for (auto row = layout.begin(); row != layout.end(); ++row) {
        if (row->word > 0) word = row->word;
        if (!prev || prev->word != word || ((home_rows >> row->row) & 1) != 0
            || home_row - row->row > 10 /* can't go over >10 rows for timing */
#ifdef HAVE_JBAY
            || (options.target == JBAY && home_row >= 8 && row->row < 8)
            /* can't flow between logical row 7 and 8 in JBay*/
#endif /* HAVE_JBAY */
        ) {
            if (prev && prev->row == row->row) prev->home_row = false;
            home_row = row->row;
            row->home_row = true;
            final_home_rows |= 1 << row->row; }
        if (row->word >= 0) {
            if (row->word > width) {
                error(row->lineno, "Invalid word %u for row %d", row->word, row->row);
                continue; }
            slice_size[row->word] += row->cols.size();
        } else {
            if (slice_size[word] + row->cols.size() > depth) {
                int split = depth - slice_size[word];
                row = layout.insert(row, Layout(*row));
                row->cols.erase(row->cols.begin() + split, row->cols.end());
                row->vpns.erase(row->vpns.begin() + split, row->vpns.end());
                auto next = row + 1;
                next->cols.erase(next->cols.begin(), next->cols.begin() + split);
                next->vpns.erase(next->vpns.begin(), next->vpns.begin() + split); }
            row->word = word;
            if ((slice_size[word] += row->cols.size()) == depth)
                ++word; }
        prev = &*row; }
    if (home_rows & ~final_home_rows)
        for (unsigned row : bitvec(home_rows & ~final_home_rows)) {
            error(home_lineno, "home row %u not present in table %s", row, name());
            break; }
    home_rows = final_home_rows;
    for (word = 0; word < width; ++word)
        if (slice_size[word] != depth) {
            error(layout.front().lineno, "Incorrect size for word %u in layout of table %s",
                  word, name());
            break; }
    for (auto &r : layout)
        LOG4("  " << r);
    action_bus->pass1(this);
    if (actions) actions->pass1(this);
    AttachedTable::pass1();
}

void ActionTable::pass2() {
    LOG1("### Action table " << name() << " pass2");
    if (match_tables.empty())
        error(lineno, "No match table for action table %s", name());
    if (!format)
        format = new Format(this);
    /* Driver does not support formats with different widths. Need all formats
     * to be the same size, so pad them out */
    pad_format_fields();
    if (actions) actions->pass2(this);
}

void ActionTable::pass3() {
    LOG1("### Action table " << name() << " pass3");
    action_bus->pass3(this);
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
    unsigned width = (fmt_log2size > 7) ? 1 << (fmt_log2size - 7) : 1;
    unsigned depth = layout_size()/width;
    int idx = 0;
    int word = 0;
    Layout *home = nullptr;
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
        if (logical_row.home_row) {
            home = &logical_row;
            home_switch_ctl = &switch_ctl;
            action_bus->write_action_regs(regs, this, logical_row.row, word);
            if (side)
                switch_ctl.r_action_o_mux_select.r_action_o_sel_action_rd_r_i = 1;
            else
                switch_ctl.r_l_action_o_mux_select.r_l_action_o_sel_action_rd_l_i = 1;
            for (auto mtab : match_tables)
                icxbar[mtab->logical_id].address_distr_to_logical_rows |=
                    1U << logical_row.row;
        } else {
            assert(home);
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
            if (logical_row.home_row)
                unitram_config.unitram_action_subword_out_en = 1;
            ram.unit_ram_ctl.match_ram_write_data_mux_select = UnitRam::DataMux::NONE;
            ram.unit_ram_ctl.match_ram_read_data_mux_select =
                home == &logical_row ? UnitRam::DataMux::ACTION : UnitRam::DataMux::OVERFLOW;
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
                int shift = std::min(fmt_log2size - 2, MAX_AD_SHIFT);
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

//Action data address huffman encoding
//    { 0,      {"xxx", "xxxxx"} },
//    { 8,      {"xxx", "xxxx0"} },
//    { 16,     {"xxx", "xxx01"} },
//    { 32,     {"xxx", "xx011"} },
//    { 64,     {"xxx", "x0111"} },
//    { 128,    {"xxx", "01111"} },
//    { 256,    {"xx0", "11111"} },
//    { 512,    {"x01", "11111"} },
//    { 1024,   {"011", "11111"} };

void ActionTable::gen_tbl_cfg(json::vector &out) {
    // FIXME -- this is wrong if actions have different format sizes
    unsigned number_entries = (layout_size() * 128 * 1024) / (1 << format->log2size);
    json::map &tbl = *base_tbl_cfg(out, "action_data", number_entries);
    json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "action_data", number_entries);
    for (auto &act : *actions) {
        auto *fmt = ::get(action_formats, act.name);
        add_pack_format(stage_tbl, fmt ? fmt : format, true, true, &act); }
    stage_tbl["memory_resource_allocation"] =
        gen_memory_resource_allocation_tbl_cfg("sram", layout);
    if (actions)
        actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
    tbl["how_referenced"] = indirect ? "indirect" : "direct";
    if (context_json)
        stage_tbl.merge(*context_json);
}
