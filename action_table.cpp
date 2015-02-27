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
            /* done above to be done before action_bus */
        } else if (kv.key.type == tCMD && kv.key[0] == "format") {
            /* done above to be done before action_bus */
        } else if (kv.key == "actions") {
            if (CHECKTYPE(kv.value, tMAP))
                actions = new Actions(this, kv.value.map);
        } else if (kv.key == "action_bus") {
            if (CHECKTYPE(kv.value, tMAP))
                action_bus = new ActionBus(this, kv.value.map);
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
                if (fld.second.bit != f->bit || fld.second.size != f->size) {
                    error(fmt.second->lineno, "Action %s format for field %s incompatible "
                          "with default format", fmt.first.c_str(), fld.first.c_str());
                    continue; } }
            for (auto &fmt2 : action_formats) {
                if (fmt.second == fmt2.second) break;
                if (auto *f = fmt2.second->field(fld.first)) {
                    if (fld.second.bit != f->bit || fld.second.size != f->size) {
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

void Table::ActionBus::pass1(Table *tbl) {
    for (auto &ent : by_byte) {
        int slot = Stage::action_bus_slot_map[ent.first];
        Format::Field *field = ent.second.second;
        bool err = false;
        for (int space = field->size; space > 0; space -= Stage::action_bus_slot_size[slot++]) {
            if (slot >= ACTION_DATA_BUS_SLOTS) {
                error(lineno, "%s extends past the end of the actions bus",
                      ent.second.first.c_str());
                err = true;
                break; }
            if (tbl->stage->action_bus_use[slot]) {
                error(lineno, "Action bus byte %d set in table %s and table %s", ent.first,
                      tbl->name(), tbl->stage->action_bus_use[slot]->name());
                err = true;
                break; }
            tbl->stage->action_bus_use[slot] = tbl;
        }
        if (err) continue;
    }
}
void Table::ActionBus::pass2(Table *tbl) {
    /* FIXME -- allocate action bus slots for things that need to be on the action bus
     * FIXME -- and aren't */
}

void Table::ActionBus::set_action_offsets(Table *tbl) {
    for (auto &f : by_byte) {
        Format::Field *field = f.second.second;
        assert(field->action_xbar == (int)f.first);
        int slot = Stage::action_bus_slot_map[f.first];
        field->action_xbar_bit = field->bit % Stage::action_bus_slot_size[slot]; }
}

void Table::ActionBus::write_action_regs(Table *tbl, unsigned home_row, unsigned action_slice) {
    /* FIXME -- home_row is the wrong row to use for action_slice != 0 */
    auto &action_hv_xbar = tbl->stage->regs.rams.array.row[home_row/2].action_hv_xbar;
    unsigned side = home_row%2;  /* 0 == left,  1 == right */
    for (auto &el : by_byte) {
        unsigned byte = el.first;
        Format::Field *f = el.second.second;
        if ((f->bit >> 7) != action_slice)
            continue;
        unsigned bit = f->bit & 0x7f;
        if (bit + f->size > 128) {
            error(lineno, "Action bus setup can't deal with field split across "
                  "SRAM rows");
            continue; }
        unsigned slot = Stage::action_bus_slot_map[byte];
        switch (Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned sbyte = bit/8; sbyte <= (bit+f->size-1)/8; sbyte++, byte++, slot++) {
                unsigned code, mask;
                switch (sbyte >> 2) {
                case 0: code = sbyte>>1; mask = 1; break;
                case 1: code = 2; mask = 3; break;
                case 2: case 3: code = 3; mask = 7; break;
                default: assert(0); }
                if ((sbyte^byte) & mask) {
                    error(lineno, "Can't put field %s into byte %d on action xbar",
                          el.second.first.c_str(), byte);
                    break; }
                action_hv_xbar.action_hv_xbar_ctl_byte[side].set_subfield(code, slot*2, 2);
                action_hv_xbar.action_hv_xbar_ctl_byte_enable[side] |= 1 << slot; }
            break;
        case 16:
            slot -= ACTION_DATA_8B_SLOTS;
            for (unsigned word = bit/16; word <= (bit+f->size-1)/16; word++, byte+=2, slot++) {
                unsigned code, mask;
                switch (word >> 1) {
                case 0: code = 1; mask = 3; break;
                case 1: code = 2; mask = 3; break;
                case 2: case 3: code = 3; mask = 7; break;
                default: assert(0); }
                if (((word << 1)^byte) & mask) {
                    error(lineno, "Can't put field %s into byte %d on action xbar",
                          el.second.first.c_str(), byte);
                    break; }
                action_hv_xbar.action_hv_xbar_ctl_half[side][slot/4]
                        .set_subfield(code, (slot%4)*2, 2); }
            break;
        case 32: {
            slot -= ACTION_DATA_8B_SLOTS + ACTION_DATA_16B_SLOTS;
            unsigned word = bit/32;
            unsigned code = 1 + word/2;
            if (((word << 2)^byte) & 7)
                error(lineno, "Can't put field %s into byte %d on action xbar",
                      el.second.first.c_str(), byte);
            else
                action_hv_xbar.action_hv_xbar_ctl_word[side][slot/2]
                        .set_subfield(code, (slot%2)*2, 2);
            break; }
        default:
            assert(0); }
    }
}

void ActionTable::write_regs() {
    Layout &home = layout[0];
    unsigned home_top = home.row >= 8;
    for (unsigned slice = 0; slice <= (format->size-1)/128; slice++)
        action_bus->write_action_regs(this, home.row, slice);
    int vpn = 0;
    bool home_row = true;
    auto &icxbar = stage->regs.rams.match.adrdist.adr_dist_action_data_adr_icxbar_ctl[logical_id];
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        unsigned top = logical_row.row >= 8; /* 0 == bottom  1 == top */
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
            unitram_config.unitram_vpn = vpn;
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
                ram_mux.ram_oflo_adr_mux_select_oflo = 1; }
            vpn++; }
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

