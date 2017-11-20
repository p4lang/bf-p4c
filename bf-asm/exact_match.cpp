#include "action_bus.h"
#include "algorithm.h"
#include "hex.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(ExactMatchTable)

void ExactMatchTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::MatchEntry);
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data, P4Table::MatchEntry)) {
        } else if (kv.key == "ways") {
            if (!CHECKTYPE(kv.value, tVEC)) continue;
            for (auto &w : kv.value.vec) {
                if (!CHECKTYPE(w, tVEC)) continue;
                if (w.vec.size < 3 || w[0].type != tINT || w[1].type != tINT || w[2].type != tINT) {
                    error(w.lineno, "invalid way descriptor");
                    continue; }
                ways.emplace_back(Way{w.lineno, w[0].i, w[1].i, w[2].i});
                if (w.vec.size > 3) {
                    for (int i = 3; i < w.vec.size; i++) {
                        if (!CHECKTYPE(w[i], tVEC)) continue;
                        if (w[i].vec.size != 2 || w[i][0].type != tINT || w[i][1].type != tINT ||
                            w[i][0].i < 0 || w[i][0].i >= SRAM_ROWS ||
                            w[i][1].i < 0 || w[i][1].i >= SRAM_UNITS_PER_ROW)
                            error(w[i].lineno, "invalid ram in way");
                        else
                            ways.back().rams.emplace_back(w[i][0].i, w[i][1].i); } } }
        } else if (kv.key == "match") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    match.emplace_back(gress, v);
            else
                match.emplace_back(gress, kv.value);
        } else if (kv.key == "match_group_map") {
            mgm_lineno = kv.value.lineno;
            if (CHECKTYPE(kv.value, tVEC)) {
                word_info.resize(kv.value.vec.size);
                for (int i = 0; i < kv.value.vec.size; i++)
                    if (CHECKTYPE(kv.value[i], tVEC)) {
                        if (kv.value[i].vec.size > 5)
                            error(kv.value[i].lineno, "Too many groups for word %d", i);
                        for (auto &v : kv.value[i].vec)
                            if (CHECKTYPE(v, tINT))
                                word_info[i].push_back(v.i); } }
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(false, stage->sram_use, &stage->sram_match_bus_use);
    if (layout_size() > 0 && !format)
        error(lineno, "No format specified in table %s", name());
    if (action.set() && actions)
        error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
        error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action.args.size() > 2)
        error(lineno, "Unexpected number of action table arguments %zu", action.args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
    if (!input_xbar)
        input_xbar = new InputXbar(this);
}

void ExactMatchTable::pass1() {
    LOG1("### Exact match table " << name() << " pass1");
    MatchTable::pass1(0);
    if (!p4_table) p4_table = P4Table::alloc(P4Table::MatchEntry, this);
    else p4_table->check(this);
    alloc_id("logical", logical_id, stage->pass1_logical_id,
             LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    check_next();
    if (action.check() && action->set_match_table(this, action.args.size() > 1) != ACTION)
        error(action.lineno, "%s is not an action table", action->name());
    attached.pass1(this);
    if (action_bus) action_bus->pass1(this);
    if (actions) {
        assert(action.args.size() == 0);
        if (auto *sel = lookup_field("action"))
            action.args.push_back(sel);
        else if ((actions->count() > 1 && format && default_action.empty())
               || (actions->count() > 2 && format && !default_action.empty()))
            error(lineno, "No field 'action' to select between multiple actions in "
                  "table %s format", name());
        actions->pass1(this);
    } else if (action.args.size() == 0) {
        if (auto *sel = lookup_field("action"))
            action.args.push_back(sel); }
    if (action_enable >= 0)
        if (action.args.size() < 1 || action.args[0].size() <= (unsigned)action_enable)
            error(lineno, "Action enable bit %d out of range for action selector", action_enable);
    input_xbar->pass1();
    if (format) {
        verify_format();
        setup_ways(); }
    alloc_vpns();
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1();
        if (!gateway->layout.empty()) {
            for (auto &row : layout) {
                if (row.row == gateway->layout[0].row && row.bus == gateway->layout[0].bus &&
                    !row.cols.empty()) {
                    unsigned gw_use = gateway->input_use() & 0xff;
                    auto &way = way_map[std::make_pair(row.row, row.cols[0])];
                    for (auto &grp : group_info) {
                        if (gw_use & grp.tofino_mask[way.word]) {
                            error(gateway->lineno, "match bus conflict between match and gateway"
                                  " on table %s", name());
                            break; } }
                    break; } } } }
    if (idletime) {
        idletime->logical_id = logical_id;
        idletime->pass1(); }
}

void ExactMatchTable::setup_ways() {
    unsigned fmt_width = (format->size + 127)/128;
    if (ways.empty())
        error(lineno, "No ways defined in table %s", name());
    else if (ways[0].rams.empty()) {
        for (auto &w : ways)
            if (!w.rams.empty()) {
                error(w.lineno, "Must specify rams for all ways in tabls %s, or none",
                      name());
                return; }
        if (layout.size() % fmt_width != 0) {
            error(lineno, "Rows is not a multiple of width in table %s", name());
            return; }
        for (unsigned i = 0; i < layout.size(); ++i) {
            unsigned first = (i / fmt_width) * fmt_width;
            if (layout[i].cols.size() != layout[first].cols.size())
                error(layout[i].lineno, "Row size mismatch within wide table %s", name()); }
        if (error_count > 0) return;
        unsigned ridx = 0, cidx = 0;
        for (auto &way : ways) {
            if (ridx >= layout.size()) {
                error(way.lineno, "Not enough rams for ways in table %s", name());
                break; }
            unsigned size = 1U << bitcount(way.mask);
            for (unsigned i = 0; i < size; i++) {
                for (unsigned word = 0; word < fmt_width; ++word) {
                    assert(ridx + word < layout.size());
                    auto &row = layout[ridx + word];
                    assert(cidx < row.cols.size());
                    way.rams.emplace_back(row.row, row.cols[cidx]); }
                if (++cidx == layout[ridx].cols.size()) {
                    ridx += fmt_width;
                    cidx = 0; } } }
        if (ridx < layout.size())
            error(ways[0].lineno, "Too many rams for ways in table %s", name());
    } else {
        bitvec rams;
        for (auto &row : layout)
            for (auto col : row.cols)
                rams[row.row*16 + col] = 1;
        int way = -1;
        for (auto &w : ways) {
            ++way;
            int index = -1;
            if (w.rams.size() != (1U << bitcount(w.mask)) * fmt_width)
                error(w.lineno, "Depth of way doesn't match number of rams in table %s", name());
            for (auto &ram : w.rams) {
                ++index;
                if (way_map.count(ram)) {
                    if (way == way_map[ram].way)
                        error(w.lineno, "Ram %d,%d used twice in way %d of table %s",
                              ram.first, ram.second, way, name());
                    else
                        error(w.lineno, "Ram %d,%d used ways %d and %d of table %s",
                              ram.first, ram.second, way, way_map[ram].way, name());
                    continue; }
                way_map[ram].way = way;
                if (!rams[ram.first*16 + ram.second].set(false))
                    error(w.lineno, "Ram %d,%d in way %d not part of table %s",
                          ram.first, ram.second, way, name()); } }
        for (auto bit : rams)
            error(lineno, "Ram %d,%d not in any way of table %s", bit/16, bit%16, name()); }
    if (error_count > 0) return;
    int way = 0;
    for (auto &w : ways) {
        MaskCounter bank(w.mask);
        unsigned index = 0, word = 0;
        int col = -1;
        for (auto &ram : w.rams) {
            auto &wm = way_map[ram];
            wm.way = way;
            wm.index = index;
            wm.word = fmt_width - word - 1;
            wm.bank = bank;
            if (word && col != ram.second)
                error(w.lineno, "Wide exact match split across columns %d and %d",
                      col, ram.second);
            col = ram.second;
            ++index;
            if (++word == fmt_width) { word = 0; bank++; } }
        ++way; }
    // FIXME -- check to ensure that ways that share a bus use the same hash group?
    //Setup unique hash_function_id for each way group
    unsigned hash_fn_id = 0;
    for (auto &w : ways) {
        if (hash_fn_ids.count(w.group) == 0)
            hash_fn_ids[w.group] = hash_fn_id++; }
}

void ExactMatchTable::alloc_vpns() {
    if (error_count > 0 || no_vpns || layout_size() == 0 || layout[0].vpns.size() > 0) return;
    int period, width, depth;
    const char *period_name;
    vpn_params(width, depth, period, period_name);
    std::map<std::pair<int, int>, int *> vpn_for;
    for (auto &row : layout) {
        row.vpns.resize(row.cols.size());
        int i = 0;
        for (auto col : row.cols)
            vpn_for[std::make_pair(row.row, col)] = &row.vpns[i++]; }
    int vpn = 0, word = 0;
    for (auto &way : ways) {
        for (auto unit : way.rams) {
            *vpn_for[unit] = vpn;
            if (++word == width) {
                word = 0;
                vpn += period; } } }
}

void ExactMatchTable::pass2() {
    LOG1("### Exact match table " << name() << " pass2");
    if (logical_id < 0) choose_logical_id();
    input_xbar->pass2();
    setup_word_ixbar_group();
    if (actions) actions->pass2(this);
    if (action_bus) action_bus->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
    if (format) format->pass2(this);
}

/* FIXME -- should have ExactMatchTable::write_merge_regs write some of the merge stuff
 * from write_regs? */

template<class REGS> void ExactMatchTable::write_regs(REGS &regs) {
    LOG1("### Exact match table " << name() << " write_regs");
    MatchTable::write_regs(regs, 0, this);
    auto &merge = regs.rams.match.merge;
    unsigned fmt_width = format ? (format->size + 127)/128 : 0;
    bitvec match_mask, version_nibble_mask;
    match_mask.setrange(0, 128*fmt_width);
    version_nibble_mask.setrange(0, 32*fmt_width);
    for (unsigned i = 0; format && i < format->groups(); i++) {
        if (Format::Field *match = format->field("match", i)) {
            for (auto &piece : match->bits)
                match_mask.clrrange(piece.lo, piece.hi+1-piece.lo); }
        if (Format::Field *version = format->field("version", i)) {
            match_mask.clrrange(version->bits[0].lo, version->size);
            version_nibble_mask.clrrange(version->bits[0].lo/4, 1); } }
    Format::Field *next = format ? format->field("next") : nullptr;
    if (format && !next && hit_next.size() > 1)
        next = format->field("action");

    /* iterating through rows in the sram array;  while in this loop, 'row' is the
     * row we're on, 'word' is which word in a wide full-way the row is for, and 'way'
     * is which full-way of the match table the row is for.  For compatibility with the
     * compiler, we iterate over rows and ways in order, and words from msb to lsb (reversed) */
    int index = -1;
    for (auto &row : layout) {
        index++;  /* index of the row in the layout */
        /* setup match logic in rams */
        auto &rams_row = regs.rams.array.row[row.row];
        auto &vh_adr_xbar = rams_row.vh_adr_xbar;
        bool first = true;
        int hash_group = -1;
        unsigned  word = ~0;
        auto vpn_iter = row.vpns.begin();
        for (auto col : row.cols) {
            auto &way = way_map[std::make_pair(row.row, col)];
            if (first) {
                hash_group = ways[way.way].group;
                word = way.word;
                setup_muxctl(vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus], hash_group);
                first = false;
            } else if (hash_group != ways[way.way].group || (int)word != way.word) {
                auto first_way = way_map[std::make_pair(row.row, row.cols[0])];
                error(ways[way.way].lineno, "table %s ways #%d and #%d use the same row bus "
                      "(%d.%d) but different %s", name(), first_way.way, way.way, row.row,
                      row.bus, (int)word == way.word ? "hash groups" : "word order");
                hash_group = ways[way.way].group;
                word = way.word; }
            setup_muxctl(vh_adr_xbar.exactmatch_mem_hashadr_xbar_ctl[col],
                         ways[way.way].subgroup + row.bus*5);
            if (ways[way.way].mask) {
                auto &bank_enable = vh_adr_xbar.exactmatch_bank_enable[col];
                bank_enable.exactmatch_bank_enable_bank_mask = ways[way.way].mask;
                bank_enable.exactmatch_bank_enable_bank_id = way.bank;
                bank_enable.exactmatch_bank_enable_inp_sel |= 1 << row.bus; }
            auto &ram = rams_row.ram[col];
            for (unsigned i = 0; i < 4; i++)
                ram.match_mask[i] = match_mask.getrange(way.word*128U+i*32, 32);

            if (next) {
                for (int group : word_info[way.word]) {
                    if (group_info[group].overhead_word != way.word) continue;
                    int pos = (next->by_group[group]->bits[0].lo % 128) - 1;
                    auto &n = ram.match_next_table_bitpos;
                    switch(group_info[group].word_group) {
                    case 0: break;
                    case 1: n.match_next_table1_bitpos = pos; break;
                    case 2: n.match_next_table2_bitpos = pos; break;
                    case 3: n.match_next_table3_bitpos = pos; break;
                    case 4: n.match_next_table4_bitpos = pos; break;
                    default: assert(0); } } }

            ram.unit_ram_ctl.match_ram_logical_table = logical_id;
            ram.unit_ram_ctl.match_ram_write_data_mux_select = 7; /* unused */
            ram.unit_ram_ctl.match_ram_read_data_mux_select = 7; /* unused */
            ram.unit_ram_ctl.match_ram_matchdata_bus1_sel = row.bus;
            ram.unit_ram_ctl.match_result_bus_select = 1 << row.bus;
            if (auto cnt = word_info[way.word].size())
                ram.unit_ram_ctl.match_entry_enable = ~(~0U << cnt);
            auto &unitram_config = regs.rams.map_alu.row[row.row].adrmux
                    .unitram_config[col/6][col%6];
            unitram_config.unitram_type = 1;
            unitram_config.unitram_logical_table = logical_id;
            switch (gress) {
            case INGRESS: unitram_config.unitram_ingress = 1; break;
            case EGRESS: unitram_config.unitram_egress = 1; break;
            default: assert(0); }
            unitram_config.unitram_enable = 1;

            int vpn = *vpn_iter++;
            int vpn_base = (vpn + *min_element(word_info[way.word])) & ~3;
            ram.match_ram_vpn.match_ram_vpn0 = vpn_base >> 2;
            int vpn_use = 0;
            for (unsigned group = 0; group < word_info[way.word].size(); group++) {
                int vpn_off = vpn + word_info[way.word][group] - vpn_base;
                vpn_use |= vpn_off;
                ram.match_ram_vpn.match_ram_vpn_lsbs .set_subfield(vpn_off, group*3, 3); }
            if (vpn_use & 4)
                ram.match_ram_vpn.match_ram_vpn1 = (vpn_base >> 2) + 1;

            /* TODO -- Algorithmic TCAM support will require something else here */
            ram.match_nibble_s0q1_enable = version_nibble_mask.getrange(way.word*32U, 32);
            ram.match_nibble_s1q0_enable = 0xffffffffUL;

            int word_group = 0;
            for (int group : word_info[way.word]) {
                unsigned mask = group_info[group].tofino_mask[way.word];
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = ~mask & 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = ~(mask >> 14) & 0xf;
                word_group++; }
            for (; word_group < 5; word_group++) {
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = 0xf; }
            if (gress)
                regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row.row);
            rams_row.emm_ecc_error_uram_ctl[gress] |= 1U << (col - 2); }
        /* setup input xbars to get data to the right places on the bus(es) */
        bool using_match = false;
        auto &byteswizzle_ctl = rams_row.exactmatch_row_vh_xbar_byteswizzle_ctl[row.bus];
        for (unsigned i = 0; format && i < format->groups(); i++) {
            if (Format::Field *match = format->field("match", i)) {
                unsigned bit = 0;
                for (auto &piece : match->bits) {
                    if (piece.lo/128U != word) {
                        bit += piece.size();
                        continue; }
                    using_match = true;
                    for (unsigned fmt_bit = piece.lo; fmt_bit <= piece.hi;) {
                        unsigned byte = (fmt_bit%128)/8;
                        unsigned bits_in_byte = (byte+1)*8 - (fmt_bit%128);
                        if (fmt_bit + bits_in_byte > piece.hi + 1)
                            bits_in_byte = piece.hi + 1 - fmt_bit;
                        auto it = --match_by_bit.upper_bound(bit);
                        Phv::Slice sl(*it->second, bit-it->first, bit-it->first+bits_in_byte-1);
                        int bus_loc = find_on_ixbar(sl, word_ixbar_group[word]);
                        assert(bus_loc >= 0 && bus_loc < 16);
                        for (unsigned b = 0; b < bits_in_byte; b++, fmt_bit++)
                            byteswizzle_ctl[byte][fmt_bit%8U] = 0x10 + bus_loc;
                        bit += bits_in_byte; } }
                assert(bit == match->size); }
            if (Format::Field *version = format->field("version", i)) {
                if (version->bits[0].lo/128U != word) continue;
                // don't need to enable vh_xbar just for version/valid, but do need to enable
                // at least one word of vh_xbar always, so use this one if there's no match
                if (!format->field("match", i))
                    using_match = true;
                for (unsigned bit = version->bits[0].lo; bit <= version->bits[0].hi; bit++) {
                    unsigned byte = (bit%128)/8;
                    byteswizzle_ctl[byte][bit%8U] = 8; } } }
        if (using_match) {
            auto &vh_xbar_ctl = rams_row.vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl;
            setup_muxctl(vh_xbar_ctl,  word_ixbar_group[word]);
            vh_xbar_ctl.exactmatch_row_vh_xbar_thread = gress; }
        /* setup match central config to extract results of the match */
        unsigned bus = row.row*2 + row.bus;
        /* FIXME -- factor this where possible with ternary match code */
        if (action) {
            unsigned action_log2size = 0;
            if (auto adt = action->to<ActionTable>())
                action_log2size = adt->get_log2size();
            int lo_huffman_bits = std::min(action_log2size - 2, 5U);
            if (action.args.size() <= 1) {
                merge.mau_actiondata_adr_mask[0][bus] = 0x3fffff & (~0U << lo_huffman_bits);
                merge.mau_actiondata_adr_vpn_shiftcount[0][bus] =
                    std::max(0, (int)action_log2size - 7);
            } else {
                /* FIXME -- support for multiple sizes of action data? */
                merge.mau_actiondata_adr_mask[0][bus] =
                    ((1U << action.args[1].size()) - 1) << lo_huffman_bits; } }
        if (attached.selector) {
            if (attached.selector.args.size() == 1)
                merge.mau_selectorlength_default[0][bus] = 1;
            else {
                int width = attached.selector.args[1].size();
                if (attached.selector.args.size() == 3)
                    width += attached.selector.args[2].size();
                merge.mau_selectorlength_mask[0][bus] = (1 << width) - 1; } }
        for (unsigned word_group = 0; format && word_group < word_info[word].size(); word_group++) {
            int group = word_info[word][word_group];
            if (group_info[group].overhead_word == (int)word) {
                if (format->immed) {
                    assert(format->immed->by_group[group]->bits[0].lo/128U == word);
                    merge.mau_immediate_data_exact_shiftcount[bus][word_group] =
                        format->immed->by_group[group]->bits[0].lo % 128; }
                if (!action.args.empty() && action.args[0]) {
                    assert(action.args[0].field()->by_group[group]->bits[0].lo/128U == word);
                    merge.mau_action_instruction_adr_exact_shiftcount[bus][word_group] =
                        action.args[0].field()->by_group[group]->bits[0].lo % 128; } }
            /* FIXME -- factor this where possible with ternary match code */
            if (action) {
                unsigned action_log2size = 0;
                if (auto adt = action->to<ActionTable>())
                    action_log2size = adt->get_log2size();
                int lo_huffman_bits = std::min(action_log2size - 2, 5U);
                if (action.args.size() <= 1) {
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        69 - lo_huffman_bits;
                } else if (group_info[group].overhead_word == (int)word) {
                    assert(action.args[1].field()->by_group[group]->bits[0].lo/128U == word);
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        action.args[1].field()->by_group[group]->bits[0].lo%128 + 5 - lo_huffman_bits; } }
            if (attached.selector) {
                if (group_info[group].overhead_word == (int)word) {
                    merge.mau_meter_adr_exact_shiftcount[bus][word_group] =
                        attached.selector.args[0].field()->by_group[group]->bits[0].lo%128 + 23 -
                            get_selector()->address_shift(); } }
            if (idletime)
                merge.mau_idletime_adr_exact_shiftcount[bus][word_group] =
                    68 - idletime->precision_shift();
            write_attached_merge_regs(regs, bus, word, word_group); }
        for (auto col : row.cols) {
            int word_group = 0;
            for (int group : word_info[word]) {
                int overhead_word = group_info[group].overhead_word;
                if (overhead_word < 0)
                    overhead_word = group_info[group].match_group.rbegin()->first;
                if (int(word) == overhead_word)
                    merge.col[col].row_action_nxtable_bus_drive[row.row] |= 1 << row.bus;
                auto &way = way_map[std::make_pair(row.row, col)];
                int idx = way.index + word - overhead_word;
                int overhead_row = ways[way.way].rams[idx].first;
                auto &hitmap_ixbar = merge.col[col].hitmap_output_map[2*row.row + word_group];
                setup_muxctl(hitmap_ixbar, overhead_row*2 + group_info[group].word_group);
                if (++word_group > 1) break; }
            /*setup_muxctl(merge.col[col].hitmap_output_map[bus],
                           layout[index+word].row*2 + layout[index+word].bus); */ }
        //if (gress == EGRESS)
        //    merge.exact_match_delay_config.exact_match_bus_thread |= 1 << bus;
        merge.exact_match_phys_result_en[bus/8U] |= 1U << (bus%8U);
        merge.exact_match_phys_result_thread[bus/8U] |= gress << (bus%8U);
        if (stage->tcam_delay(gress))
            merge.exact_match_phys_result_delay[bus/8U] |= 1U << (bus%8U);
    }

    merge.exact_match_logical_result_en |= 1 << logical_id;
    if (stage->tcam_delay(gress) > 0)
        merge.exact_match_logical_result_delay |= 1 << logical_id;
    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this, 1, false);
}

std::unique_ptr<json::map> ExactMatchTable::gen_memory_resource_allocation_tbl_cfg(Way &way) {
    json::map mra;
    unsigned vpn_ctr = 0;
    unsigned fmt_width = format ? (format->size + 127)/128 : 0;
    if (hash_fn_ids.count(way.group) > 0)
        mra["hash_function_id"] = hash_fn_ids[way.group];
    mra["hash_entry_bit_lo"] = way.subgroup*10;
    mra["hash_entry_bit_hi"] = way.subgroup*10 + 9;
    mra["number_entry_bits"] = 10;
    if (way.mask) {
        int lo = ffs(way.mask) - 1, hi = floor_log2(way.mask);
        mra["hash_select_bit_lo"] = 40 + lo;
        mra["hash_select_bit_hi"] = 40 + hi;
        if (way.mask != (1 << (hi+1)) - (1 << lo)) {
            warning(way.lineno, "driver does not support discontinuous bits in a way mask");
            mra["hash_select_bit_mask"] = way.mask >> lo; }
    } else
        mra["hash_select_bit_lo"] = mra["hash_select_bit_hi"] = 40;
    mra["number_select_bits"] = bitcount(way.mask);
    json::vector mem_units;
    json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"] = json::vector();
    for (auto &ram : way.rams) {
        if (mem_units.empty())
            vpn_ctr = layout_get_vpn(ram.first, ram.second);
        else
            assert(vpn_ctr == layout_get_vpn(ram.first, ram.second));
        mem_units.push_back(memunit(ram.first, ram.second));
        if (mem_units.size() == fmt_width) {
            json::map tmp;
            tmp["memory_units"] = std::move(mem_units);
            mem_units = json::vector();
            json::vector vpns;
            for (unsigned i = 0; i < format->groups(); i++)
                vpns.push_back(vpn_ctr++);
            tmp["vpns"] = std::move(vpns);
            mem_units_and_vpns.push_back(std::move(tmp)); } }
    assert(mem_units.empty());
    return json::mkuniq<json::map>(std::move(mra));
}

void ExactMatchTable::add_field_to_pack_format(json::vector &field_list, int basebit,
                                               std::string name,
                                               const Table::Format::Field &field,
                                               const Table::Actions::Action *act) {
    if (name != "match") {
        Table::add_field_to_pack_format(field_list, basebit, name, field, act);
        return; }
    unsigned bit = 0;
    for (auto &piece : field.bits) {
        auto mw = --match_by_bit.upper_bound(bit);
        int lo = bit - mw->first;
        int lsb_mem_word_idx = piece.lo / MEM_WORD_WIDTH;
        int msb_mem_word_idx = piece.hi / MEM_WORD_WIDTH;
        int offset = piece.lo % MEM_WORD_WIDTH;
        while(mw != match_by_bit.end() &&  mw->first < bit + piece.size()) {
            std::string source = "";
            std::string immediate_name = "";
            std::string mw_name = mw->second.name();
            int start_bit = 0;
            get_cjson_source(mw_name, act, source, immediate_name, start_bit);
            if (source == "")
                error(lineno, "Cannot determine proper source for field %s", name.c_str());
            int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
            int width = hi - lo + 1;
            field_list.push_back( json::map {
                    { "field_name", json::string(mw->second.name()) },
                    { "source", json::string(source) },
                    { "lsb_mem_word_offset", json::number(offset) },
                    { "start_bit", json::number(start_bit + lo + mw->second.lobit()) },
                    { "immediate_name", json::string(immediate_name) },
                    { "lsb_mem_word_idx", json::number(lsb_mem_word_idx) },
                    { "msb_mem_word_idx", json::number(msb_mem_word_idx) },
                    { "match_mode", json::string("unused") }, //FIXME-JSON
                    { "enable_pfe", json::False() }, //FIXME-JSON
                    { "field_width", json::number(width) }});
            offset += width;
            lo = 0;
            ++mw; }
        bit += piece.size(); }
}

void ExactMatchTable::gen_tbl_cfg(json::vector &out) {
    unsigned fmt_width = format ? (format->size + 127)/128 : 0;
    unsigned number_entries = format ? layout_size()/fmt_width * format->groups() * 1024 : 0;
    json::map &tbl = *base_tbl_cfg(out, "match", number_entries);
    common_tbl_cfg(tbl);
    json::map &match_attributes = tbl["match_attributes"];
    json::vector &stage_tables = match_attributes["stage_tables"];
    json::map &stage_tbl = *add_stage_tbl_cfg(match_attributes, "hash_match", number_entries);
    stage_tbl["memory_resource_allocation"] = nullptr;
    match_attributes["match_type"] = "exact";
    match_attributes["uses_dynamic_key_masks"] = false; //FIXME-JSON
    if (number_entries == 0) {
        stage_tbl["stage_table_type"] = "match_with_no_key";
        match_attributes["match_type"] = "match_with_no_key";
        stage_tbl["size"] = 1024; }
    gen_hash_functions(stage_tbl);
    if (actions) {
        actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
        actions->add_action_format(this, stage_tbl);
    } else if (action && action->actions) {
        action->actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
        action->actions->add_action_format(this, stage_tbl); }
    add_pack_format(stage_tbl, format, true, false);
    add_result_physical_buses(stage_tbl);
    if (ways.size() > 0) {
        json::vector &way_stage_tables = stage_tbl["ways"] = json::vector();
        unsigned way_number = 0;
        for (auto &way : ways) {
            json::map way_tbl;
            way_tbl["stage_number"] = stage->stageno;
            way_tbl["way_number"] = way_number++;
            way_tbl["stage_table_type"] = "hash_way";
            way_tbl["size"] = way.rams.size()/fmt_width * format->groups() * 1024;
            add_pack_format(way_tbl, format, false);
            way_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg(way);
            way_stage_tables.push_back(std::move(way_tbl)); } }
    MatchTable::gen_idletime_tbl_cfg(stage_tbl);
    if (context_json)
        stage_tbl.merge(*context_json);
    tbl["stateful_table_refs"] = json::vector();
    json::vector &action_data_table_refs = tbl["action_data_table_refs"] = json::vector();
    add_reference_table(action_data_table_refs, action);
    if (auto a = get_attached()) {
        json::vector &selection_table_refs = tbl["selection_table_refs"] = json::vector();
        tbl["default_selector_mask"] = 0; //FIXME-JSON
        tbl["default_selector_value"] = 0; //FIXME-JSON
        add_reference_table(selection_table_refs, a->selector);
        json::vector &meter_table_refs = tbl["meter_table_refs"] = json::vector();
        for (auto &m : a->meters) { add_reference_table(meter_table_refs, m); }
        json::vector &statistics_table_refs = tbl["statistics_table_refs"] = json::vector();
        for (auto &s : a->stats) { add_reference_table(statistics_table_refs, s); } }
}

// Generate hash_functions node in cjson.
// Loop through each way and get the associated hash group. Output hash bits for
// each table accessed by the hash group with seed and bits_to_xor info.
// 'bits_to_xor' has a field_bit and field_name which correspond to the xor'd
// fields bit position and field's (p4) name. Check that the name appears in the
// match key fields (p4_params_list) as this is verified by the driver.  Do not
// repeat a hash group if already visited.
void ExactMatchTable::gen_hash_functions(json::map &stage_tbl) {
    bitvec visited_groups(EXACT_HASH_GROUPS,0);
    auto ht = input_xbar->get_hash_tables();
    // Output cjson node only if hash tables present
    if (ht.size() > 0) {
        json::vector &hash_functions = stage_tbl["hash_functions"] = json::vector();
        for (auto &way : ways) {
            int hash_group_no = way.group;
            // Do not output json for already processed hash groups
            if (visited_groups[hash_group_no]) continue;
            // Setup cjson hash_function
            json::map hash_function;
            json::vector &hash_bits = hash_function["hash_bits"] = json::vector();
            // Get the hash group data
            auto *hash_group = input_xbar->get_hash_group(hash_group_no);
            if (hash_group) {
                // Process only hash tables used per hash group
                for (unsigned hash_table_id: bitvec(hash_group->tables)) {
                    auto hash_table = input_xbar->get_hash_table(hash_table_id);
                    MatchTable::gen_hash_bits(hash_table, hash_table_id, hash_bits); }
            hash_functions.push_back(std::move(hash_function));
            // Mark hash group as visited
            visited_groups[hash_group_no] = 1; } } }
}

