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

Table::Format::Field *TernaryMatchTable::lookup_field(const std::string &n,
         const std::string &act) const {
    assert(!format);
    auto *rv = gateway ? gateway->lookup_field(n, act) : nullptr;
    if (!rv && indirect) rv = indirect->lookup_field(n, act);
    return rv;
}

Table::Format::Field *TernaryIndirectTable::lookup_field(const std::string &n,
         const std::string &act) const {
    auto *rv = format ? format->field(n) : nullptr;
    if (!rv && !act.empty()) {
        if (auto call = get_action())
            rv = call->lookup_field(n, act); }
    return rv;
}

void TernaryMatchTable::vpn_params(int &width, int &depth, int &period, const char *&period_name) const {
    if ((width = match.size()) == 0)
        width = input_xbar->tcam_width();
    depth = width ? layout_size() / width : 0;
    period = 1;
    period_name = 0;
}

void TernaryMatchTable::alloc_vpns() {
    if (no_vpns || layout.size() == 0 || layout[0].vpns.size() > 0) return;
    int period, width, depth;
    const char *period_name;
    vpn_params(width, depth, period, period_name);
    if (width == 0) return;
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

TernaryMatchTable::Match::Match(const value_t &v) : lineno(v.lineno) {
    if (v.type == tVEC) {
        if (v.vec.size < 2 || v.vec.size > 3) {
            error(v.lineno, "Syntax error");
            return; }
        if (!CHECKTYPE(v[0], tINT) || !CHECKTYPE(v[v.vec.size-1], tINT)) return;
        if ((word_group = v[0].i) < 0 || v[0].i >= TCAM_XBAR_GROUPS)
            error(v[0].lineno, "Invalid input xbar group %ld", v[0].i);
        if (v.vec.size == 3 && CHECKTYPE(v[1], tINT)) {
            if ((byte_group = v[1].i) < 0 || v[1].i >= TCAM_XBAR_GROUPS/2)
                error(v[1].lineno, "Invalid input xbar group %ld", v[1].i);
        } else
            byte_group = -1;
        if ((byte_config = v[v.vec.size-1].i) < 0 || byte_config >= 4)
            error(v[v.vec.size-1].lineno, "Invalid input xbar byte control %d", byte_config);
    } else if (CHECKTYPE(v, tMAP)) {
        for (auto &kv : MapIterChecked(v.map)) {
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
            } else {
                error(kv.key.lineno, "Unknown key '%s' in ternary match spec",
                      value_desc(kv.key)); } } }
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
    common_init_setup(data, true, P4Table::MatchEntry);
    if (!input_xbar)
        input_xbar = new InputXbar(this);
    if (auto *m = get(data, "match"))
        if (CHECKTYPE2(*m, tVEC, tMAP)) {
            if (m->type == tVEC)
                for (auto &v : m->vec)
                    match.emplace_back(v);
            else
                match.emplace_back(*m); }
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data, P4Table::MatchEntry)) {
        } else if (kv.key == "match") {
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
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(false, stage->tcam_use, &stage->tcam_match_bus_use);
    check_tcam_match_bus(layout);
    if (indirect_bus >= 0) {
        stage->tcam_indirect_bus_use[indirect_bus/2][indirect_bus&1] = this; }
    if (indirect.set()) {
        if (indirect_bus >= 0)
            error(lineno, "Table %s has both ternary indirect table and explicit indirect bus",
                  name());
        if (!attached.stats.empty() || !attached.meters.empty() || !attached.statefuls.empty())
            error(lineno, "Table %s has ternary indirect table and directly attached stats/meters"
                  " -- move them to indirect table", name());
    }
    else if (!action.set() && !actions)
        error(lineno, "Table %s has no indirect, action table or immediate actions", name());
    if (action && !action_bus) action_bus = new ActionBus();
}

void TernaryMatchTable::pass0() {
    MatchTable::pass0();
    if (indirect.check() && indirect->set_match_table(this, false) != TERNARY_INDIRECT)
        error(indirect.lineno, "%s is not a ternary indirect table", indirect->name());
}

void TernaryMatchTable::pass1() {
    LOG1("### Ternary match table " << name() << " pass1");
    MatchTable::pass1();
    stage->table_use[timing_thread(gress)] |= Stage::USE_TCAM;
    /* FIXME -- unconditionally setting piped mode -- only need it for wide
     * match across a 4-row boundary */
    stage->table_use[timing_thread(gress)] |= Stage::USE_TCAM_PIPED;
    // Dont allocate id (mark them as used) for empty ternary tables (keyless
    // tables). Keyless tables are marked ternary with a tind. They are setup by
    // the driver to always miss (since there is no match) and run the miss
    // action. The miss action is associated with the logical table space and
    // does not need a tcam id association. This saves tcams ids to be assigned
    // to actual ternary tables. This way we can have 8 real ternary match
    // tables within a stage and not count the keyless among them.
    // NOTE: The tcam_id is never assigned for these tables and will be set to
    // default (-1). We also disable registers associated with tcam_id for this
    // table.
    if (layout_size() != 0) {
        alloc_id("tcam", tcam_id, stage->pass1_tcam_id,
             TCAM_TABLES_PER_STAGE, false, stage->tcam_id_use);
    }
    // alloc_busses(stage->tcam_match_bus_use); -- now hardwired
    if (match.empty() && input_xbar->tcam_width()) {
        match.resize(input_xbar->tcam_width());
        for (unsigned i = 0; i < match.size(); i++) {
            match[i].word_group = input_xbar->tcam_word_group(i);
            match[i].byte_group = input_xbar->tcam_byte_group(i/2);
            match[i].byte_config = i&1; }
        match.back().byte_config = 3; }
    if (layout_size() == 0) layout.clear();
    if (match.size() == 0) {
        if (layout.size() != 0)
            error(layout[0].lineno, "No match or input_xbar in non-empty ternary table %s", name());
    } else if (layout.size() % match.size() != 0) {
        error(layout[0].lineno, "Rows not a multiple of the match width in tables %s", name());
    } else if (layout.size() == 0) {
        error(lineno, "Empty ternary table with non-empty match");
    } else {
        auto mg = match.begin();
        for (auto &row : layout) {
            if (row.bus < 0) row.bus = row.cols.at(0);
            if (mg->byte_group >= 0) {
                auto &bg_use = stage->tcam_byte_group_use[row.row/2][row.bus];
                if (bg_use.first) {
                    if (bg_use.second != mg->byte_group) {
                        error(mg->lineno, "Conflicting tcam byte group between rows %d and %d "
                              "in col %d for table %s", row.row, row.row^1, row.bus, name());
                        if (bg_use.first != this)
                            error(bg_use.first->lineno, "...also used in table %s",
                                  bg_use.first->name()); }
                } else {
                    bg_use.first = this;
                    bg_use.second = mg->byte_group; } }
            if (++mg == match.end()) mg = match.begin(); } }
    if (error_count > 0) return;
    for (auto &chain_rows_col : chain_rows)
        chain_rows_col = 0;
    unsigned row_use = 0;
    for (auto &row : layout) row_use |= 1U << row.row;
    unsigned word = 0, wide_row_use = 0;
    int prev_row = -1;
    std::vector<int> *cols = nullptr;
    for (auto &row : layout) {
        if (row.cols.empty()) {
            error(row.lineno, "Empty row in ternary table %s", name());
            continue; }
        if (cols) {
            if (row.cols != *cols)
                error(row.lineno, "Column mismatch across rows in wide tcam match");
        } else {
            cols = &row.cols; }
        wide_row_use |= 1U << row.row;
        if (++word == match.size()) {
            int top_row = floor_log2(wide_row_use);
            int bottom_row = top_row + 1 - match.size();
            if (wide_row_use + (1U << bottom_row) != 1U << (top_row+1)) {
                error(row.lineno, "Ternary match rows must be contiguous "
                      "within each group of rows in a wide match");
            } else {
                // rows chain towards row 6
                if (top_row < 6)
                    wide_row_use -= 1U << top_row;
                else if (bottom_row > 6)
                    wide_row_use -= 1U << bottom_row;
                else
                    wide_row_use -= 1U << 6;
                for (int col : *cols) {
                    if (col < 0 || col >= TCAM_UNITS_PER_ROW)
                        error(row.lineno, "Invalid column %d in table %s", col, name());
                    else
                        chain_rows[col] |= wide_row_use; } }
            word = 0;
            cols = nullptr;
            wide_row_use = 0; } }
    if (indirect) {
        if (hit_next.size() > 0 && indirect->hit_next.size() > 0)
            error(hit_next[0].lineno, "Ternary Match table with both direct and indirect "
                  "next tables");
        if (!indirect->p4_table) indirect->p4_table = p4_table;
        if (hit_next.size() > 1 || indirect->hit_next.size() > 1) {
            if (auto *next = indirect->format->field("next")) {
                if (next->bit(0) != 0)
                    error(indirect->format->lineno, "ternary indirect 'next' field must be"
                          " at bit 0");
            } else if (auto *action = indirect->format->field("action")) {
                if (action->bit(0) != 0)
                    error(indirect->format->lineno, "ternary indirect 'action' field must be"
                          " at bit 0 to be used as next table selector");
            } else
                error(indirect->format->lineno, "No 'next' or 'action' field in format"); } }
    attached.pass1(this);
    if (hit_next.size() > 2 && !indirect)
        error(hit_next[0].lineno, "Ternary Match tables cannot directly specify more"
              "than 2 hit next tables");
}


void TernaryMatchTable::pass2() {
    LOG1("### Ternary match table " << name() << " pass2");
    if (logical_id < 0) choose_logical_id();
    if (input_xbar) input_xbar->pass2();
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
    // If ternary is a pre-classifier to an ALPM table, check that it has only 1
    // action. This action sets the partition index and must be specified
    // separately in the ALPM context json
    if (is_alpm()) {
        if (auto *acts = get_actions()) {
            if (acts->count() == 1) {
                auto act = acts->begin();
                set_partition_action_handle(act->handle);
                if (act->p4_params_list.size() == 1)
                    set_partition_field_name(act->p4_params_list[0].name);
            } else {
                error(lineno, "For ALPM pre_classifier '%s-%s' only 1 action expected to set parition index but found %d", p4_name(), name(), acts->count()); } } }
}

void TernaryMatchTable::pass3() {
    LOG1("### Ternary match table " << name() << " pass3");
    if (action_bus) action_bus->pass3(this);
}

extern int get_address_mau_actiondata_adr_default(unsigned log2size, bool per_flow_enable);

template<class REGS> inline static void tcam_ghost_enable(REGS &regs, int row, int col) {
    regs.tcams.col[col].tcam_ghost_thread_en[row] = 1; }
template<> void tcam_ghost_enable(Target::Tofino::mau_regs &regs, int row, int col) {}

template<class REGS>
void TernaryMatchTable::write_regs(REGS &regs) {
    LOG1("### Ternary match table " << name() << " write_regs");
    MatchTable::write_regs(regs, 1, indirect);
    unsigned word = 0;
    auto &merge = regs.rams.match.merge;
    for (Layout &row : layout) {
        auto vpn = row.vpns.begin();
        for (auto col : row.cols) {
            auto &tcam_mode = regs.tcams.col[col].tcam_mode[row.row];
            //tcam_mode.tcam_data1_select = row.bus; -- no longer used
            if (options.match_compiler)
                tcam_mode.tcam_data1_select = col;
            tcam_mode.tcam_chain_out_enable = (chain_rows[col] >> row.row) & 1;
            if (gress == INGRESS)
                tcam_mode.tcam_ingress = 1;
            else if (gress == EGRESS)
                tcam_mode.tcam_egress = 1;
            else if (gress == GHOST)
                tcam_ghost_enable(regs, row.row, col);
            tcam_mode.tcam_match_output_enable =
                ((~chain_rows[col] | ALWAYS_ENABLE_ROW) >> row.row) & 1;
            tcam_mode.tcam_vpn = *vpn++;
            tcam_mode.tcam_logical_table = logical_id;
            tcam_mode.tcam_data_dirtcam_mode = match[word].dirtcam & 0x3ff;
            tcam_mode.tcam_vbit_dirtcam_mode = match[word].dirtcam >> 10;
            /* TODO -- always disable tcam_validbit_xbar? */
            auto &tcam_vh_xbar = regs.tcams.vh_data_xbar;
            if (options.match_compiler) {
                for (int i = 0; i < 8; i++)
                    tcam_vh_xbar.tcam_validbit_xbar_ctl[col][row.row/2][i] |= 15; }
            auto &halfbyte_mux_ctl = tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[col][row.row];
            halfbyte_mux_ctl.tcam_row_halfbyte_mux_ctl_select = match[word].byte_config;
            halfbyte_mux_ctl.tcam_row_halfbyte_mux_ctl_enable = 1;
            halfbyte_mux_ctl.tcam_row_search_thread = gress;
            if (match[word].word_group >= 0)
                setup_muxctl(tcam_vh_xbar.tcam_row_output_ctl[col][row.row],
                             match[word].word_group);
            if (match[word].byte_group >= 0)
                setup_muxctl(tcam_vh_xbar.tcam_extra_byte_ctl[col][row.row/2],
                             match[word].byte_group);
            if (tcam_id >= 0) {
                if (!((chain_rows[col] >> row.row) & 1))
                    regs.tcams.col[col].tcam_table_map[tcam_id] |= 1U << row.row; } }
        if (++word == match.size()) word = 0; }
    if (tcam_id >= 0)
        setup_muxctl(merge.tcam_hit_to_logical_table_ixbar_outputmap[tcam_id], logical_id);
    /* FIXME -- setting piped mode if any table in the stage is piped -- perhaps
     * FIXME -- tables can be different? */
    if (tcam_id >= 0) {
        if (stage->table_use[timing_thread(gress)] & Stage::USE_TCAM_PIPED)
            merge.tcam_table_prop[tcam_id].tcam_piped = 1;
        merge.tcam_table_prop[tcam_id].thread = gress;
        merge.tcam_table_prop[tcam_id].enabled = 1;
        regs.tcams.tcam_output_table_thread[tcam_id] = 1 << gress;
    }
    if (indirect_bus >= 0) {
        /* FIXME -- factor into corresponding code in MatchTable::write_regs */
        setup_muxctl(merge.match_to_logical_table_ixbar_outputmap[1][indirect_bus], logical_id);
        setup_muxctl(merge.match_to_logical_table_ixbar_outputmap[3][indirect_bus], logical_id);
        if (tcam_id >= 0) {
            setup_muxctl(merge.tcam_match_adr_to_physical_oxbar_outputmap[indirect_bus], tcam_id);
        }
        merge.mau_action_instruction_adr_default[1][indirect_bus] = ACTION_INSTRUCTION_ADR_ENABLE;
        auto &shift_en = merge.mau_payload_shifter_enable[1][indirect_bus];
        if (1 || options.match_compiler) {
            // FIXME -- only need this if there is an instruction address?
            shift_en.action_instruction_adr_payload_shifter_en = 1; }
        if (action)
            shift_en.actiondata_adr_payload_shifter_en = 1;
        if (!attached.stats.empty())
            shift_en.stats_adr_payload_shifter_en = 1;
        if (!attached.meters.empty() || !attached.statefuls.empty())
            shift_en.meter_adr_payload_shifter_en = 1;
        merge.tind_bus_prop[indirect_bus].tcam_piped = 1;
        merge.tind_bus_prop[indirect_bus].thread = gress;
        merge.tind_bus_prop[indirect_bus].enabled = 1;
        //if (action_bus)
        //  merge.mau_immediate_data_mask[1][indirect_bus] =
        //     (UINT64_C(1) << action_bus->size()) - 1;
        attached.write_merge_regs(regs, this, 1, indirect_bus);
        if (idletime)
            idletime->write_merge_regs(regs, 1, indirect_bus);
        if (action) {
            /* FIXME -- factor with TernaryIndirect code below */
            if (auto adt = action->to<ActionTable>()) {
                merge.mau_actiondata_adr_default[1][indirect_bus] = adt->determine_default(action);
                merge.mau_actiondata_adr_mask[1][indirect_bus] = adt->determine_mask(action);
                merge.mau_actiondata_adr_vpn_shiftcount[1][indirect_bus]
                    = adt->determine_vpn_shiftcount(action);
                merge.mau_actiondata_adr_tcam_shiftcount[indirect_bus]
                    = adt->determine_shiftcount(action, 0, 0, 0);
            }
        }
        attached.write_tcam_merge_regs(regs, this, indirect_bus, 0);
    }
    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this, 1, false);
    merge.exact_match_logical_result_delay |= 1 << logical_id;
    regs.cfg_regs.mau_cfg_movereg_tcam_only |= 1U << logical_id;

    // FIXME -- this is wrong; when should we use the actionbit?  glass never does any more?
    // if (hit_next.size() > 1 && !indirect)
    //     merge.next_table_tcam_actionbit_map_en |= 1 << logical_id;
    // if (!indirect)
    //     merge.mau_action_instruction_adr_tcam_actionbit_map_en |= 1 << logical_id;
}

std::unique_ptr<json::map> TernaryMatchTable::gen_memory_resource_allocation_tbl_cfg (
        const char *type, const std::vector<Layout> & layout, bool skip_spare_bank) const {
    if (layout.size() == 0) return nullptr;
    BUG_CHECK(!skip_spare_bank); // never spares in tcam
    json::map mra { { "memory_type", json::string(type) } };
    json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"];
    json::vector mem_units;
    unsigned word = 0;
    bool done = false;
    unsigned lrow = 0;
    for (auto colnum = 0U; !done; colnum++) {
        done = true;
        for (auto &row : layout) {
            if (colnum >= row.cols.size())
                continue;
            auto col = row.cols[colnum];
            auto vpn = row.vpns[colnum];
            mem_units.push_back(memunit(row.row, col));
            lrow = memunit(row.row, col);
            if (++word == match.size()) {
                mem_units_and_vpns.push_back( json::map {
                        { "memory_units",  std::move(mem_units) },
                            { "vpns", json::vector { json::number(vpn) }}});
                mem_units = json::vector();
                word = 0; }
            done = false; } }
    // For keyless table, add empty vectors
    if (mem_units_and_vpns.size() == 0)
        mem_units_and_vpns.push_back(json::map {
                { "memory_units", json::vector() },
                { "vpns", json::vector() } } );
    mra["spare_bank_memory_unit"] = lrow;
    return json::mkuniq<json::map>(std::move(mra));
}

void TernaryMatchTable::gen_entry_cfg(json::vector &out, std::string name, \
        unsigned lsb_offset, unsigned lsb_idx, unsigned msb_idx, \
        std::string source, unsigned start_bit, unsigned field_width, \
        unsigned index, bitvec &tcam_bits) const {
    remove_aug_names(name);
    std::string fix_name(name);

    // If the name has a slice in it, remove it and add the lo bit of
    // the slice to field_bit.  This takes the place of
    // canon_field_list(), rather than extracting the slice component
    // of the field name, if present, and appending it to the key name.
    int slice_offset = remove_name_tail_range(fix_name);

    // Get the key name, if any.
    if (auto *param = find_p4_param(fix_name)) {
        if (!param->key_name.empty()) {
            fix_name = param->key_name;
            remove_aug_names(fix_name); } }

    // For range match we need bytes to decide which nibble is being used, hence
    // split the field in bytes. For normal match entire slice can be used
    // directly.
    auto *p = find_p4_param(name, "range");
    unsigned field_bytes = p ? (field_width + 7)/8 : 1;
    for (unsigned i = 0; i < field_bytes; i++) {
        json::map entry;
        unsigned entry_lo = lsb_offset;
        unsigned entry_size = field_width;
        entry["field_name"] = fix_name;
        entry["lsb_mem_word_offset"] = entry_lo;
        entry["lsb_mem_word_idx"] = lsb_idx;
        entry["msb_mem_word_idx"] = msb_idx;
        entry["source"] = source;
        entry["start_bit"] = start_bit + slice_offset;
        entry["field_width"] = entry_size;
        auto dirtcam_mode = (name != "--unused--") ?
            get_dirtcam_mode(index, (lsb_offset + i*8)/8) : TCAM_NORMAL;
        // If field is a range match output the 'range' node only for 4bit hi/lo
        // encodings (dirtcam = 2 (4bit lo), dirtcam = 3 (4bit hi)
        if (p && ((dirtcam_mode == DIRTCAM_4B_LO) ||
                    (dirtcam_mode == DIRTCAM_4B_HI))) {
            entry_size = 4;
            entry["source"] = "range";
            // Shift start bit based on which nibble is used in range
            entry["start_bit"] =
                i * 8 + start_bit + (dirtcam_mode == DIRTCAM_4B_HI) * 4 + slice_offset;
            entry["field_width"] = entry_size;
            entry_lo = lsb_offset + i*8 + 4*(dirtcam_mode == DIRTCAM_4B_HI);
            entry["lsb_mem_word_offset"] = entry_lo;
            json::map &entry_range = entry["range"];
            entry_range["type"] = 4;
            entry_range["is_duplicate"] = false;

            // Add the duplicate entry as well. It is unclear why this entry is
            // needed by the driver, as most of the information is duplicated
            // and driver should only need to know where to place the actual
            // nibble. But currently we see driver crash in the absence of this
            // field in some situations, hence we add it here.
            json::map entry_dup;
            unsigned entry_lo_dup = lsb_offset + i*8 + 4*(dirtcam_mode == DIRTCAM_4B_LO);
            entry_dup["field_name"] = fix_name;
            entry_dup["lsb_mem_word_offset"] = entry_lo_dup;
            entry_dup["lsb_mem_word_idx"] = lsb_idx;
            entry_dup["msb_mem_word_idx"] = msb_idx;
            entry_dup["source"] = "range";
            entry_dup["start_bit"] = i * 8 + start_bit + (dirtcam_mode == DIRTCAM_4B_HI) * 4 + slice_offset;
            entry_dup["field_width"] = entry_size;
            json::map &entry_dup_range = entry_dup["range"];
            entry_dup_range["type"] = 4;
            entry_dup_range["is_duplicate"] = true;
            tcam_bits.setrange(entry_lo_dup, entry_size);
            out.push_back(std::move(entry_dup));
        }
        tcam_bits.setrange(entry_lo, entry_size);
        out.push_back(std::move(entry)); }

}

void TernaryMatchTable::gen_match_fields_pvp(json::vector &match_field_list, unsigned word,
        bool uses_versioning, unsigned version_word_group, bitvec &tcam_bits) const {
    // Tcam bits are arranged as follows in each tcam word
    // LSB -------------------------------------MSB
    // PAYLOAD BIT - TCAM BITS - [VERSION] - PARITY
    auto start_bit = 0; // always 0 for fields not on input xbar
    auto dirtcam_index = 0; // not relevant for fields not on input xbar
    auto payload_name = "--tcam_payload_" + std::to_string(word) + "--";
    auto parity_name = "--tcam_parity_" + std::to_string(word) + "--";
    auto version_name = "--version--";
    gen_entry_cfg(match_field_list, payload_name, TCAM_PAYLOAD_BITS_START, 
        word, word, "payload", start_bit, TCAM_PAYLOAD_BITS, dirtcam_index, tcam_bits);
    if (uses_versioning && (version_word_group == word)) {
        gen_entry_cfg(match_field_list, version_name, TCAM_VERSION_BITS_START,
             word, word, "version", start_bit, TCAM_VERSION_BITS, dirtcam_index, tcam_bits); }
    gen_entry_cfg(match_field_list, parity_name, TCAM_PARITY_BITS_START, 
        word, word, "parity", start_bit, TCAM_PARITY_BITS, dirtcam_index, tcam_bits);
}

void TernaryMatchTable::gen_tbl_cfg(json::vector &out) const {
    unsigned number_entries = match.size() ? layout_size()/match.size() * 512 : 0;
    json::map *tbl_ptr;
    // For ALPM tables, this sets up the top level ALPM table and this ternary
    // table as its preclassifier. As the pre_classifier is always in the
    // previous stage as the atcams, this function will be called before the
    // atcam cfg generation. The atcam will check for presence of this table and
    // add the atcam cfg gen
    if (is_alpm()) {
        json::map *alpm_ptr = base_tbl_cfg(out, "match_entry", number_entries);
        json::map &alpm = *alpm_ptr;
        json::map &match_attributes = alpm["match_attributes"];
        match_attributes["match_type"] = "algorithmic_lpm";
        json::map &alpm_pre_classifier = match_attributes["pre_classifier"];
        base_alpm_pre_classifier_tbl_cfg(alpm_pre_classifier, "match_entry", number_entries);
        tbl_ptr = &alpm_pre_classifier;
    } else {
        tbl_ptr = base_tbl_cfg(out, "match_entry", number_entries); }
    json::map &tbl = *tbl_ptr;
    bool uses_versioning = false;
    unsigned version_word_group = -1;
    unsigned match_index = match.size() - 1;
    unsigned index = 0;
    json::vector match_field_list, match_entry_list;
    for (auto &m : match) {
        if (m.byte_config == 3) {
            uses_versioning = true;
            version_word_group = match_index - index;
            break; }
        index++; }
    // Determine the zero padding necessary by creating a bitvector (for each
    // word). While creating entries for pack format set bits used. The unused
    // bits must be padded with zero field entries. 
    std::vector<bitvec> tcam_bits;
    tcam_bits.resize(match.size());
    // Set pvp bits for each tcam word
    for (unsigned i = 0; i < match.size(); i++) {
        gen_match_fields_pvp(match_field_list, i, uses_versioning, version_word_group, tcam_bits[i]);
    }
    json::map &match_attributes = tbl["match_attributes"];
    json::vector &stage_tables = match_attributes["stage_tables"];
    json::map &stage_tbl = *add_stage_tbl_cfg(match_attributes, "ternary_match", number_entries);
    stage_tbl["default_next_table"] = default_next_table_id;
    json::map &pack_fmt = add_pack_format(stage_tbl, 47, match.size(), 1);
    stage_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg("tcam", layout);
    // FIXME-JSON: If the next table is modifiable then we set it to what it's mapped
    // to. Otherwise, set it to the default next table for this stage.
    //stage_tbl["default_next_table"] = Target::END_OF_PIPE();
    // FIXME: How to deal with multiple next hit tables?
    stage_tbl["default_next_table"] = hit_next.size() > 0 && hit_next[0].name != "END"
                                    ? hit_next[0]->logical_id : Target::END_OF_PIPE();
    add_result_physical_buses(stage_tbl);
    for (auto field : *input_xbar) {
        switch(field.first.type) {
        case InputXbar::Group::EXACT:
            continue;
        case InputXbar::Group::TERNARY: {
            int word = match_index - match_word(field.first.index);
            if (word < 0) continue;
            std::string source = "spec";
            std::string field_name = field.second.what.name();
            remove_aug_names(field_name);
            unsigned lsb_mem_word_offset = 0;
            if (field.second.hi > 40) {
                // FIXME -- no longer needed if we always convert these to Group::BYTE?
                // a field in the (mid) byte group, which is shared with the adjacent word group
                // each word gets only 4 bits of the byte group and is placed at msb
                // Check mid-byte field does not cross byte boundary (40-47)
                BUG_CHECK(field.second.hi < 48);
                // Check mid-byte field is associated with even group
                // | == 5 == | == 1 == | == 5 == | == 5 == | == 1 == | == 5 == |
                // | Grp 0   | Midbyte0| Grp 1   | Grp 2   | Midbyte1| Grp 3   |
                BUG_CHECK((field.first.index & 1) == 0);
                // Find groups to place this byte nibble. Check group which has this
                // group as the byte_group
                for (auto &m : match) {
                    if (m.byte_group * 2 == field.first.index) {
                        // Check byte_config to determine where to place the nibble
                        lsb_mem_word_offset = 1 + field.second.lo;
                        int nibble_offset = 0;
                        int hwidth = 44 - field.second.lo;
                        int start_bit = 0;
                        if (m.byte_config == MIDBYTE_NIBBLE_HI) {
                            nibble_offset += 4;
                            start_bit = hwidth;
                            hwidth = field.second.hi - 43;
                        }
                        int midbyte_word_group = match_index - match_word(m.word_group);
                        gen_entry_cfg(match_field_list, field_name,
                                lsb_mem_word_offset, midbyte_word_group,
                                midbyte_word_group, source,
                                field.second.what.lobit() + start_bit, hwidth,
                                field.first.index,
                                tcam_bits[midbyte_word_group]);
                    }
                }
            } else {
                lsb_mem_word_offset = 1 + field.second.lo;
                gen_entry_cfg(match_field_list, field_name,
                              lsb_mem_word_offset, word, word, source,
                              field.second.what.lobit(), field.second.hi -
                              field.second.lo + 1, field.first.index,
                              tcam_bits[word]); }
            break; }
        case InputXbar::Group::BYTE:
            for (size_t word = 0; word < match.size(); word++) {
                if (match[word].byte_group != field.first.index) continue;
                std::string source = "spec";
                std::string field_name = field.second.what.name();
                remove_aug_names(field_name);
                int byte_lo = field.second.lo;
                int field_lo = field.second.what.lobit();
                int width = field.second.what.size();
                if (match[word].byte_config == MIDBYTE_NIBBLE_HI) {
                    if (byte_lo >= 4) {
                        byte_lo -= 4;
                    } else {
                        field_lo += 4 - byte_lo;
                        width -= 4 - byte_lo;
                        byte_lo = 0; } }
                if (width > 4) width = 4;
                gen_entry_cfg(match_field_list, field_name, 41 + byte_lo, match_index - word,
                    match_index - word, source, field_lo, width, match[word].byte_group,
                    tcam_bits[match_index - word]); }
            break; } }
    // For keyless table, just add parity & payload bits
    if (p4_params_list.empty()) {
        tcam_bits.resize(1);
        gen_match_fields_pvp(match_field_list, 0, false, -1, tcam_bits[0]);
    }

    // tcam_bits is a vector indexed by tcam word and has all used bits set. We
    // loop through this bitvec for each word and add a zero padding entry for
    // the unused bits.
    // For ternary all unused bits must be marked as source
    // 'zero' for correctness during entry encoding.
    for (unsigned word = 0; word < match.size(); word++) {
        bitvec &pb = tcam_bits[word];
        unsigned start_bit = 0; // always 0 for padded fields
        int dirtcam_index = -1; // irrelevant in this context
        if (pb != bitvec(0)) {
            int idx_lo = 0;
            std::string pad_name = "--unused--";
            for (auto p : pb) {
                if (p > idx_lo) {
                    gen_entry_cfg(match_field_list, pad_name, \
                        idx_lo, word, word, "zero", start_bit,
                        p - idx_lo, dirtcam_index, tcam_bits[word]); }
                idx_lo = p + 1; }
            auto fw = TCAM_VERSION_BITS;
            if (idx_lo < fw) {
                gen_entry_cfg(match_field_list, pad_name, \
                    idx_lo, word, word, "zero", start_bit,
                    fw - idx_lo, dirtcam_index, tcam_bits[word]); }
        }
    }

    pack_fmt["entries"] = json::vector {
        json::map {
            { "entry_number",  json::number(0) },
            { "fields",  std::move(match_field_list) }}};
    add_all_reference_tables(tbl);
    json::map &tind = stage_tbl["ternary_indirection_stage_table"] = json::map();
    if (indirect) {
        unsigned fmt_width = 1U << indirect->format->log2size;
        //json::map tind;
        tind["stage_number"] = stage->stageno;
        tind["stage_table_type"] = "ternary_indirection";
        tind["size"] = indirect->layout_size()*128/fmt_width * 1024;
        indirect->add_pack_format(tind, indirect->format);
        tind["memory_resource_allocation"] =
            indirect->gen_memory_resource_allocation_tbl_cfg("sram", indirect->layout, true);
        // Add action formats for actions present in table or attached action table
        auto *acts = indirect->get_actions();
        if (acts)
            acts->add_action_format(this, tind);
        add_all_reference_tables(tbl, indirect);
        if (indirect->actions) {
            indirect->actions->gen_tbl_cfg(tbl["actions"]);
            indirect->actions->add_next_table_mapping(indirect, stage_tbl);
        } else if (indirect->action && indirect->action->actions) {
            indirect->action->actions->gen_tbl_cfg(tbl["actions"]);
            indirect->action->actions->add_next_table_mapping(indirect, stage_tbl); }
        indirect->common_tbl_cfg(tbl);
    } else {
        // FIXME: Add a fake ternary indirect table (as otherwise driver complains)
        // if tind not present - to be removed with update on driver side
        auto *acts = get_actions();
        if (acts)
            acts->add_action_format(this, tind);
        tind["memory_resource_allocation"] = nullptr;
        json::vector &pack_format = tind["pack_format"] = json::vector();
        json::map pack_format_entry;
        pack_format_entry["memory_word_width"] = 128;
        pack_format_entry["entries_per_table_word"] = 1;
        json::vector &entries = pack_format_entry["entries"] = json::vector();
        entries.push_back( json::map {
                { "entry_number", json::number(0) },
                    { "fields", json::vector() } } );
        pack_format_entry["table_word_width"] = 0;
        pack_format_entry["number_memory_units_per_table_word"] = 0;
        pack_format.push_back(std::move(pack_format_entry));
        tind["logical_table_id"] = 0;
        tind["stage_number"] = 0;
        tind["stage_table_type"] = "ternary_indirection";
        tind["size"] = 0;
        tbl["stateful_table_refs"] = json::vector();
    }
    common_tbl_cfg(tbl);
    if (actions)
        actions->gen_tbl_cfg(tbl["actions"]);
    else if (action && action->actions)
        action->actions->gen_tbl_cfg(tbl["actions"]);
    gen_idletime_tbl_cfg(stage_tbl);
    if (context_json)
        stage_tbl.merge(*context_json);
    match_attributes["match_type"] = "ternary";
}

void TernaryIndirectTable::setup(VECTOR(pair_t) &data) {
    match_table = 0;
    common_init_setup(data, true, P4Table::MatchEntry);
    if (format) {
        if (format->size > 64)
            error(format->lineno, "ternary indirect format larger than 64 bits");
        if (format->size < 4) {
            /* pad out to minumum size */
            format->size = 4;
            format->log2size = 2; }
    } else
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data, P4Table::MatchEntry)) {
        } else if (kv.key == "input_xbar") {
            if (CHECKTYPE(kv.value, tMAP))
                input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "hash_dist") {
            /* parsed in common_init_setup */
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
                    attached.meters.emplace_back(v, this);
            else attached.meters.emplace_back(kv.value, this);
        } else if (kv.key == "stateful") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    attached.statefuls.emplace_back(v, this);
            else attached.statefuls.emplace_back(kv.value, this);
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(false, stage->sram_use, &stage->tcam_indirect_bus_use);
    if (!action.set() && !actions)
        error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (actions && !action_bus) action_bus = new ActionBus();
}

Table::table_type_t TernaryIndirectTable::set_match_table(MatchTable *m, bool indirect) {
    if (match_table)
        error(lineno, "Multiple references to ternary indirect table %s", name());
    else if (!(match_table = dynamic_cast<TernaryMatchTable *>(m)))
        error(lineno, "Trying to link ternary indirect table %s to non-ternary table %s",
              name(), m->name());
    else {
        if (action.check() && action->set_match_table(m, !action.is_direct_call()) != ACTION)
            error(action.lineno, "%s is not an action table", action->name());
        attached.pass0(m);
        logical_id = m->logical_id;
        p4_table = m->p4_table; }
    return TERNARY_INDIRECT;
}

void TernaryIndirectTable::pass1() {
    LOG1("### Ternary indirect table " << name() << " pass1");
    alloc_busses(stage->tcam_indirect_bus_use);
    Table::pass1();
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
    if (format) format->pass2(this);
}

void TernaryIndirectTable::pass3() {
    LOG1("### Ternary indirect table " << name() << " pass3");
    if (action_bus) action_bus->pass3(this);
}

template<class REGS> void TernaryIndirectTable::write_regs(REGS &regs) {
    LOG1("### Ternary indirect table " << name() << " write_regs");
    int tcam_id = match_table->tcam_id;
    int tcam_shift = format->log2size-2;
    if (tcam_id >= 0)
        regs.tcams.tcam_match_adr_shift[tcam_id] = tcam_shift;
    auto &merge = regs.rams.match.merge;
    for (Layout &row : layout) {
        auto vpn = row.vpns.begin();
        auto &ram_row = regs.rams.array.row[row.row];
        for (int col : row.cols) {
            auto &unit_ram_ctl = ram_row.ram[col].unit_ram_ctl;
            unit_ram_ctl.match_ram_write_data_mux_select = 7; /* disable */
            unit_ram_ctl.match_ram_read_data_mux_select = 7; /* disable */
            unit_ram_ctl.tind_result_bus_select = 1U << row.bus;
            auto &mux_ctl = regs.rams.map_alu.row[row.row].adrmux
                    .ram_address_mux_ctl[col/6][col%6];
                mux_ctl.ram_unitram_adr_mux_select = row.bus + 2;
            auto &unitram_config = regs.rams.map_alu.row[row.row].adrmux
                    .unitram_config[col/6][col%6];
            unitram_config.unitram_type = 6;
            unitram_config.unitram_vpn = *vpn++;
            unitram_config.unitram_logical_table = logical_id;
            if (gress == INGRESS)
                unitram_config.unitram_ingress = 1;
            else
                unitram_config.unitram_egress = 1;
            unitram_config.unitram_enable = 1;
            auto &xbar_ctl = regs.rams.map_alu.row[row.row].vh_xbars
                    .adr_dist_tind_adr_xbar_ctl[row.bus];
            if (tcam_id >= 0)
                setup_muxctl(xbar_ctl, tcam_id);
            if (gress)
                regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row.row);
            ram_row.tind_ecc_error_uram_ctl[gress] |= 1 << (col - 2); }
        int bus = row.row*2 + row.bus;
        merge.tind_ram_data_size[bus] = format->log2size - 1;
        if (tcam_id >= 0)
            setup_muxctl(merge.tcam_match_adr_to_physical_oxbar_outputmap[bus], tcam_id);
        merge.tind_bus_prop[bus].tcam_piped = 1;
        merge.tind_bus_prop[bus].thread = gress;
        merge.tind_bus_prop[bus].enabled = 1;
        if (instruction) {
            int shiftcount = 0;
            if (auto field = instruction.args[0].field())
                shiftcount = field->bit(0);
            else if (auto field = instruction.args[1].field())
                shiftcount = field->immed_bit(0);
            merge.mau_action_instruction_adr_tcam_shiftcount[bus] = shiftcount;
        }
        if (format->immed)
            merge.mau_immediate_data_tcam_shiftcount[bus] = format->immed->bit(0);
        if (action) {
            if (auto adt = action->to<ActionTable>()) {
                merge.mau_actiondata_adr_default[1][bus] = adt->determine_default(action);
                merge.mau_actiondata_adr_mask[1][bus] = adt->determine_mask(action);
                merge.mau_actiondata_adr_vpn_shiftcount[1][bus]
                    = adt->determine_vpn_shiftcount(action);
                merge.mau_actiondata_adr_tcam_shiftcount[bus]
                    = adt->determine_shiftcount(action, 0, 0, tcam_shift);
            }
        }
        if (attached.selector) {
            merge.mau_selectorlength_default[1][bus] = 1;
            // if (attached.selector.args.size() == 1)
            /*
            Selector length not yet handled by the compiler
            else {
                int width = attached.selector.args[1].size();
                if (attached.selector.args.size() == 3)
                    width += attached.selector.args[2].size();
                merge.mau_selectorlength_mask[1][bus] = (1 << width) - 1;
            }
            */
            merge.mau_meter_adr_tcam_shiftcount[bus] =
                get_selector()->determine_shiftcount(attached.selector, 0, 0, format->log2size - 2);
        }
        if (match_table->idletime)
            merge.mau_idletime_adr_tcam_shiftcount[bus] =
                    66 + format->log2size - match_table->idletime->precision_shift();
        attached.write_tcam_merge_regs(regs, match_table, bus, tcam_shift);
    }
    if (actions) actions->write_regs(regs, this);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this, 1, false);
}

void TernaryIndirectTable::gen_tbl_cfg(json::vector &out) const {
}

void TernaryMatchTable::add_result_physical_buses(json::map &stage_tbl) const {
    json::vector &result_physical_buses = stage_tbl["result_physical_buses"] = json::vector();
    if (indirect) {
        for (auto l : indirect->layout) {
            result_physical_buses.push_back(l.row * 2 + l.bus); } }
    else
        result_physical_buses.push_back(indirect_bus);
}
