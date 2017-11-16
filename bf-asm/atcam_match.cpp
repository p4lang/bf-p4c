#include "action_bus.h"
#include "algorithm.h"
#include "hex.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

DEFINE_TABLE_TYPE(AlgTcamMatchTable)

void AlgTcamMatchTable::setup(VECTOR(pair_t) &data) {
    common_init_setup(data, false, P4Table::MatchEntry);
    for (auto &kv : MapIterChecked(data)) {
        if (common_setup(kv, data, P4Table::MatchEntry)) {
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

void AlgTcamMatchTable::pass1() {
    LOG1("### ATCAM match table " << name() << " pass1");
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
        find_tcam_match(); }
    alloc_vpns();
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
    if (idletime) {
        idletime->logical_id = logical_id;
        idletime->pass1(); }
}

namespace {
struct match_element {
    Phv::Ref        *field;
    unsigned        offset, width;
};

static void setup_nibble_mask(Table::Format::Field *match, int group,
                              std::map<int, match_element> &elems, bitvec &mask) {
    for (auto &el : Values(elems)) {
        int bit = match->bit(el.offset);
        if (match->hi(bit) < bit + el.width - 1)
            error(el.field->lineno, "match bits for %s not contiguous in match(%d)",
                  el.field->desc().c_str(), group);
        else if ((bit % 4U) != 0)
            error(el.field->lineno, "match bits for %s not nibble aligned in match(%d)",
                  el.field->desc().c_str(), group);
        else
            mask.setrange(bit/4U, el.width/4U); }
}
} // end anonymous namespace

void AlgTcamMatchTable::find_tcam_match() {
    std::map<Phv::Slice, match_element>                                 exact;
    std::map<Phv::Slice, std::pair<match_element, match_element>>       tcam;
    std::map<int, match_element>        s0q1, s1q0;
    unsigned off = 0;
    /* go through the match fields and find duplicates -- those are the tcam matches */
    for (auto &match_field : match) {
        auto sl = *match_field;
        if (!sl) continue;
        if (exact.count(sl)) {
            if (tcam.count(sl))
                error(match_field.lineno, "%s appears more than twice in atcam match",
                      match_field.desc().c_str());
            if ((sl.size() % 4U) != 0)
                error(match_field.lineno, "tcam match field %s not a multiple of 4 bits",
                      match_field.desc().c_str());
            tcam.emplace(sl, std::make_pair(exact.at(sl),
                            match_element{ &match_field, off, sl->size() }));
            exact.erase(sl);
        } else {
            exact.emplace(sl, match_element{ &match_field, off, sl->size() }); }
        off += sl.size(); }
    for (auto e : exact)
        for (auto t : tcam)
            if (e.first.overlaps(t.first))
                error(e.second.field->lineno, "%s overlaps %s in atcam match", 
                      e.second.field->desc().c_str(), t.second.first.field->desc().c_str());
    if (error_count > 0) return;
    /* for the tcam pairs, treat first as s0q1 and second as s1q0 */
    for (auto &el : Values(tcam)) {
        s0q1[el.first.offset] = el.first;
        s1q0[el.second.offset] = el.second; }
    /* now find the bits in each group that match with the tcam pairs, ensure that they
     * are nibble-aligned, and setup the nibble masks */
    for (unsigned i = 0; i < format->groups(); i++) {
        if (Format::Field *match = format->field("match", i)) {
            setup_nibble_mask(match, i, s0q1, s0q1_nibbles);
            setup_nibble_mask(match, i, s1q0, s1q0_nibbles);
        } else {
            error(format->lineno, "no 'match' field in format group %d", i); } }
}

void AlgTcamMatchTable::alloc_vpns() {
    /* FIXME -- factor with ExactMatchTable::alloc_vpns */
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
}

void AlgTcamMatchTable::pass2() {
    LOG1("### ATCAM match table " << name() << " pass2");
    if (logical_id < 0) choose_logical_id();
    input_xbar->pass2();
    setup_word_ixbar_group();
    ixbar_subgroup.resize(word_ixbar_group.size());
    ixbar_mask.resize(word_ixbar_group.size());
    // FIXME -- need a method of specifying these things in the asm code?
    // FIXME -- should at least check that these are sane
    for (unsigned i = 0; i < word_ixbar_group.size(); ++i) {
        bitvec ixbar_use = input_xbar->hash_group_bituse(word_ixbar_group[i]);
        // Which 10-bit address group to use for this word -- use the lowest one with
        // a bit set in the hash group.  Can it be different for different words?
        ixbar_subgroup[i] = ixbar_use.min().index() / EXACT_HASH_ADR_BITS;
        // Assume that any hash bits usuable for select are used for select
        ixbar_mask[i] = ixbar_use.getrange(EXACT_HASH_FIRST_SELECT_BIT, EXACT_HASH_SELECT_BITS); }
    if (actions) actions->pass2(this);
    if (action_bus) action_bus->pass2(this);
    if (gateway) gateway->pass2();
    if (idletime) idletime->pass2();
    if (format) format->pass2(this);
}

// FIXME -- factor out common stuff with ExactMatchTable::write_regs
template<class REGS> void AlgTcamMatchTable::write_regs(REGS &regs) {
    LOG1("### ATCAM match table " << name() << " write_regs");
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
    std::vector<MaskCounter>    select_id;
    for (auto m : ixbar_mask)
        select_id.emplace_back(m);

    /* iterating through rows in the sram array;  while in this loop, 'row' is the
     * row we're on, and 'word' is which word in a wide full-way the row is for.  For
     * compatibility with the compiler, we iterate over rows in order, and words
     * from msb to lsb (reversed) */
    int index = -1;
    int word = fmt_width;
    for (auto &row : layout) {
        index++;  /* index of the row in the layout */
        if (--word < 0) word = fmt_width - 1;
        /* setup match logic in rams */
        auto &rams_row = regs.rams.array.row[row.row];
        auto &vh_adr_xbar = rams_row.vh_adr_xbar;
        bool first = true;
        int hash_group = word_ixbar_group[word];
        setup_muxctl(vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus], hash_group);
        auto vpn_iter = row.vpns.begin();
        for (auto col : row.cols) {
            setup_muxctl(vh_adr_xbar.exactmatch_mem_hashadr_xbar_ctl[col],
                         ixbar_subgroup[word] + row.bus*5);
            if (ixbar_mask[word]) {
                auto &bank_enable = vh_adr_xbar.exactmatch_bank_enable[col];
                bank_enable.exactmatch_bank_enable_bank_mask = ixbar_mask[word];
                bank_enable.exactmatch_bank_enable_bank_id = select_id[word]++;
                bank_enable.exactmatch_bank_enable_inp_sel |= 1 << row.bus; }
            auto &ram = rams_row.ram[col];
            for (unsigned i = 0; i < 4; i++)
                ram.match_mask[i] = match_mask.getrange(word*128U+i*32, 32);

            if (next) {
                for (int group : word_info[word]) {
                    if (group_info[group].overhead_word != word) continue;
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
            if (auto cnt = word_info[word].size())
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
            int vpn_base = (vpn + *min_element(word_info[word])) & ~3;
            ram.match_ram_vpn.match_ram_vpn0 = vpn_base >> 2;
            int vpn_use = 0;
            for (unsigned group = 0; group < word_info[word].size(); group++) {
                int vpn_off = vpn + word_info[word][group] - vpn_base;
                vpn_use |= vpn_off;
                ram.match_ram_vpn.match_ram_vpn_lsbs .set_subfield(vpn_off, group*3, 3); }
            if (vpn_use & 4)
                ram.match_ram_vpn.match_ram_vpn1 = (vpn_base >> 2) + 1;

            ram.match_nibble_s0q1_enable =
                version_nibble_mask.getrange(word*32U, 32) &~ s1q0_nibbles.getrange(word*32U, 32);
            ram.match_nibble_s1q0_enable = 0xffffffffUL &~ s0q1_nibbles.getrange(word*32U, 32);

            int word_group = 0;
            for (int group : word_info[word]) {
                unsigned mask = group_info[group].tofino_mask[word];
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
            int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
            if (action.args.size() <= 1) {
                merge.mau_actiondata_adr_mask[0][bus] = 0x3fffff & (~0U << lo_huffman_bits);
                merge.mau_actiondata_adr_vpn_shiftcount[0][bus] =
                    std::max(0, (int)action->format->log2size - 7);
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
                int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
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
                // auto &way = way_map[std::make_pair(row.row, col)];
                // int idx = way.index + word - overhead_word;
                // int overhead_row = ways[way.way].rams[idx].first;
                // auto &hitmap_ixbar = merge.col[col].hitmap_output_map[2*row.row + word_group];
                // setup_muxctl(hitmap_ixbar, overhead_row*2 + group_info[group].word_group);
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

// FIXME: Add tbl-cfg support for ATCAM tables
void AlgTcamMatchTable::gen_tbl_cfg(json::vector &out) {
    //json::map &tbl = *base_tbl_cfg(out, "match", number_entries);
    //common_tbl_cfg(tbl);
    //json::map &match_attributes = tbl["match_attributes"];
    //json::vector &stage_tables = match_attributes["stage_tables"];
    //json::map &stage_tbl = *add_stage_tbl_cfg(match_attributes, "atcam" , size);
    //stage_tbl["stage_table_type"] = "algorithmic_tcam_match";
    // FIXME-JSON: If the next table is modifiable then we set it to what it's mapped
    // to. Otherwise, set it to the default next table for this stage.
    //stage_tbl["default_next_table"] = 255;
    //stage_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg("tcam", layout);
    //stage_tbl["logical_table_id"] = logical_id;
    //stage_tbl["hash_functions"] = // TODO
    //add_result_physical_buses(stage_tbl);
    //stage_tbl["action_format"] = // TODO
    //MatchTable::gen_idletime_tbl_cfg(stage_tbl);
    //if (context_json)
    //    stage_tbl.merge(*context_json);
}
