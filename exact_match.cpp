#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "stage.h"
#include "tables.h"
#include "hex.h"

DEFINE_TABLE_TYPE(ExactMatchTable)

void ExactMatchTable::setup(VECTOR(pair_t) &data) {
    setup_layout(get(data, "row"), get(data, "column"), get(data, "bus"));
    setup_logical_id();
    if (auto *fmt = get(data, "format")) {
       if (CHECKTYPE(*fmt, tMAP))
           format = new Format(fmt->map);
    } else
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "input_xbar") {
	    if (CHECKTYPE(kv.value, tMAP))
		input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "gateway") {
	    if (CHECKTYPE(kv.value, tMAP)) {
                gateway = GatewayTable::create(kv.key.lineno, name_+" gateway",
                        gress, stage, -1, kv.value.map);
                gateway->match_table = this; }
        } else if (kv.key == "format") {
            /* done above to be done before action_bus */
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
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else if (kv.key == "ways") {
            if (!CHECKTYPE(kv.value, tVEC)) continue;
            for (auto &w : kv.value.vec) {
                if (!CHECKTYPE(w, tVEC)) continue;
                if (w.vec.size != 3 || w[0].type != tINT || w[1].type != tINT || w[2].type != tINT)
                    error(w.lineno, "invalid way descriptor");
                else ways.emplace_back(Way{w.lineno, w[0].i, w[1].i, w[2].i}); }
        } else if (kv.key == "match") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    match.emplace_back(gress, v);
            else
                match.emplace_back(gress, kv.value);
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
    alloc_rams(false, stage->sram_use, &stage->sram_match_bus_use);
    if (action.set() && actions)
	error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
	error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action.set() && (action_args.size() < 1 || action_args.size() > 2))
        error(lineno, "Unexpected number of action table arguments %zu", action_args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}

void ExactMatchTable::pass1() {
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    check_next();
    link_action(action);
    if (action_bus)
        action_bus->pass1(this);
    if (actions) {
        assert(action_args.size() == 0);
        if (auto *sel = lookup_field("action"))
            action_args.push_back(sel);
        else
            error(lineno, "No field 'action' in table %s format", name());
        actions->pass1(this); }
    input_xbar->pass1(stage->exact_ixbar, 128);
    format->setup_immed(this);
    group_info.resize(format->groups());
    if (!format->field("match"))
        error(format->lineno, "No 'match' field in format for table %s", name());
    else for (unsigned i = 0; i < format->groups(); i++) {
        Format::Field *match = format->field("match", i);
        for (auto &piece : match->bits) {
            if (piece.lo % 8 != 0 || (piece.hi+1) % 8 != 0)
                error(format->lineno, "'match' field not byte aligned in table %s", name());
            if (piece.lo/128 != piece.hi/128)
                error(format->lineno, "'match' field must be explictly split across 128-bit "
                      "boundary in table %s", name());
            group_info[i].match_group[piece.lo/128] = -1; }
        if (auto *version = format->field("version", i)) {
            if (version->bits.size() != 1)
                error(format->lineno, "'version' field cannot be split");
            if (version->size != 4 || (version->bits[0].lo % 4) != 0)
                error(format->lineno, "'version' field not 4 bits and nibble aligned "
                      "in table %s", name());
            group_info[i].match_group[version->bits[0].lo/128] = -1; }
        for (auto it = format->begin(i); it != format->end(i); it++) {
            if (it->first == "match" || it->first == "version") continue;
            if (it->second.bits.size() != 1) {
                error(format->lineno, "Can't deal with split field %s", it->first.c_str());
                continue; }
            unsigned limit = it->first == "next" ? 40 : 64;
            unsigned word = it->second.bits[0].lo/128;
            if (group_info[i].overhead_word < 0) {
                group_info[i].overhead_word = word;
                if (!group_info[i].match_group.count(word))
                    error(format->lineno, "Overhead for group %d must be in the same word "
                          "as part of its match", i);
            } else if (group_info[i].overhead_word != (int)word)
                error(format->lineno, "Match overhead group %d split across words", i);
            else if (word != it->second.bits[0].hi/128 || it->second.bits[0].hi%128 >= limit)
                error(format->lineno, "Match overhead field %s(%d) not in bottom %d bits",
                      it->first.c_str(), i, limit); } }
    unsigned fmt_width = (format->size + 127)/128;
    word_info.resize(fmt_width);
    for (unsigned i = 0; i < group_info.size(); i++)
        if (group_info[i].match_group.size() > 1)
            for (auto &mgrp : group_info[i].match_group) {
                if ((mgrp.second = word_info[mgrp.first].size()) > 1)
                    error(format->lineno, "Too many multi-word groups using word %d", mgrp.first);
                word_info[mgrp.first].push_back(i); }
    LOG1("### Exact match table " << name());
    for (unsigned i = 0; i < group_info.size(); i++) {
        if (group_info[i].match_group.size() == 1)
            for (auto &mgrp : group_info[i].match_group) {
                if ((mgrp.second = word_info[mgrp.first].size()) > 4)
                    error(format->lineno, "Too many match groups using word %d", mgrp.first);
                word_info[mgrp.first].push_back(i); }
        group_info[i].word_group = group_info[i].match_group[group_info[i].overhead_word];
        LOG1("  format group " << i << " overhead in word " << group_info[i].overhead_word);
        for (auto &mgrp : group_info[i].match_group)
            LOG1("    match group " << mgrp.second << " in word " << mgrp.first); }
    for (unsigned i = 0; i < word_info.size(); i++)
        LOG1("  word " << i << " groups: " << word_info[i]);
    if (ways.empty())
        error(lineno, "No ways defined in table %s", name());
    else if (layout.size() % (ways.size()*fmt_width) != 0)
        error(lineno, "Rows is not a mulitple of ways in table %s", name());
    else {
        unsigned way = 0, word = 0;
        for (auto &row : layout) {
            if (word == 0) {
                if (ways[way].group >= EXACT_HASH_GROUPS ||
                    ways[way].subgroup >= 5 ||
                    (ways[way].mask &~ 0xfff)) {
                    error(ways[way].lineno, "invalid exact match way");
                    break; } }
            if (row.cols.size() != 1U << bitcount(ways[way].mask))
                error(ways[way].lineno, "Depth of way doesn't match number of columns on "
                      "row %d in table %s", row.row, name());
            if (++word == fmt_width) { word = 0; way++; } } }
    for (auto &r : match) r.check();
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
    if (error_count > 0) return;
    if (match.empty())
        for (auto it = input_xbar->all_begin(); it != input_xbar->all_end(); ++it)
            match.push_back(it->second.what);
}

void ExactMatchTable::pass2() {
    input_xbar->pass2(stage->exact_ixbar, 128);
    if (action_bus) {
        action_bus->pass2(this);
        action_bus->set_immed_offsets(this); }
    unsigned match_width = 0;
    for (auto &r : match)
        match_width += r->size();
    if (match_width != format->field("match")->size)
        warning(match[0].lineno, "Match width %d for table %s doesn't match format match width %d",
                match_width, name(), format->field("match")->size);
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
}

/* build the weird 18-bit byte/nibble mask for matching, checking for problems */
static bool mask2tofino_mask(bitvec &mask, int word, bitvec &ignored, unsigned &bytemask) {
    bytemask = 0;
    for (unsigned i = 0; i < 14; i++) {
        unsigned byte = mask.getrange(word*128+i*8, 8);
        if (byte) {
            byte |= ignored.getrange(word*128+i*8, 8);
            if (byte != 0xff) return false;
            bytemask |= 1U << i; } }
    for (unsigned i = 0; i < 4; i++) {
        unsigned nibble = mask.getrange(word*128+i*4+112, 4);
        if (nibble) {
            nibble |= ignored.getrange(word*128+i*4+112, 4);
            if (nibble != 0xf) return false;
            bytemask |= 1U << (i + 14); } }
    return true;
}

bool setup_match_input(unsigned bytes[16], std::vector<Phv::Ref> &match, Stage *stage, int group) {
    auto byte = 0;
    bool rv = true;
    for (auto &r : match) {
        bool found = false;
        for (auto *in : stage->exact_ixbar[group]) {
            if (auto *i = in->find(*r, group)) {
                for (int bit = r->lo; bit <= r->hi; bit += 8) {
                    assert(byte < 16);
                    bytes[byte++] = (i->lo + bit - i->what->lo)/8; }
                found = true;
                break; } }
        if (!found) {
            error(r.lineno, "Can't find %s in input xbar group %d", r.name(), group);
            rv = false; } }
    while (byte < 16)
        bytes[byte++] = 0xdeadbeef;
    return rv;
}

void ExactMatchTable::write_regs() {
    LOG1("### Exact match table " << name());
    if (input_xbar->width() > 1) {
        error(lineno, "FIXME -- can't deal with exact match larger than 128 bits");
        LOG1("  (skipped)");
        return; }
    MatchTable::write_regs(0, this);
    unsigned fmt_width = (format->size + 127)/128;
    int way = 0, word = fmt_width-1;
    int vpn = 0;
    bitvec match_mask, version_nibble_mask;
    match_mask.setrange(0, 128*fmt_width);
    version_nibble_mask.setrange(0, 32*fmt_width);
    for (unsigned i = 0; i < format->groups(); i++) {
        Format::Field *match = format->field("match", i);
        for (auto &piece : match->bits)
            match_mask.clrrange(piece.lo, piece.hi+1-piece.lo);
        if (Format::Field *version = format->field("version", i)) {
            match_mask.clrrange(version->bits[0].lo, version->size);
            version_nibble_mask.clrrange(version->bits[0].lo/4, 1); } }

    /* iterating through rows in the sram array;  while in this loop, 'row' is the
     * row we're on, 'word' is which word in a wide full-way the row is for, and 'way'
     * is which full-way of the match table the row is for.  For compatibility with the
     * compiler, we iterate over rows and ways in order, and words from msb to lsb (reversed) */
    int index = -1;
    for (auto &row : layout) {
        index++;  /* index of the row in the layout */
        /* setup match logic in rams */
        auto &vh_adr_xbar = stage->regs.rams.array.row[row.row].vh_adr_xbar;
        vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus]
            .enabled_3bit_muxctl_select = ways[way].group;
        vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus]
            .enabled_3bit_muxctl_enable = 1;
        MaskCounter bank(ways[way].mask);
        for (auto col : row.cols) {
            vh_adr_xbar.exactmatch_mem_hashadr_xbar_ctl[col]
                .enabled_4bit_muxctl_select = ways[way].subgroup + row.bus*5;
            vh_adr_xbar.exactmatch_mem_hashadr_xbar_ctl[col]
                .enabled_4bit_muxctl_enable = 1;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_bank_mask = ways[way].mask;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_bank_id = bank++;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_inp_sel |= 1 << row.bus;
            auto &ram = stage->regs.rams.array.row[row.row].ram[col];
            for (unsigned i = 0; i < 4; i++)
                ram.match_mask[i] = match_mask.getrange(word*128+i*32, 32);
            ram.unit_ram_ctl.match_ram_write_data_mux_select = 7; /* unused */
            ram.unit_ram_ctl.match_ram_read_data_mux_select = 7; /* unused */
            ram.unit_ram_ctl.match_result_bus_select = 1 << row.bus;
            if (auto cnt = word_info[word].size())
                ram.unit_ram_ctl.match_entry_enable = ~(~0U << cnt);
            auto &unitram_config = stage->regs.rams.map_alu.row[row.row].adrmux
                    .unitram_config[col/6][col%6];
            unitram_config.unitram_type = 1;
            unitram_config.unitram_logical_table = logical_id;
            switch (gress) {
            case INGRESS: unitram_config.unitram_ingress = 1; break;
            case EGRESS: unitram_config.unitram_egress = 1; break;
            default: assert(0); }
            unitram_config.unitram_enable = 1;

            int vpn_base = (vpn + word_info[word][0]) & ~3;
            ram.match_ram_vpn.match_ram_vpn0 = vpn_base >> 2;
            int vpn_use = 0;
            for (unsigned group = 0; group < word_info[word].size(); group++) {
                int vpn_off = vpn + word_info[word][group] - vpn_base;
                vpn_use |= vpn_off;
                ram.match_ram_vpn.match_ram_vpn_lsbs .set_subfield(vpn_off, group*3, 3); }
            if (vpn_use & 4)
                ram.match_ram_vpn.match_ram_vpn1 = (vpn_base >> 2) + 1;

            /* TODO -- Algorithmic TCAM support will require something else here */
            ram.match_nibble_s0q1_enable = version_nibble_mask.getrange(word*32, 32);
            ram.match_nibble_s1q0_enable = 0xffffffffUL;

            int word_group = 0;
            for (int group : word_info[word]) {
                unsigned tofino_mask = 0;
                bitvec mask;
                mask.clear();
                Format::Field *match = format->field("match", group);
                for (auto &piece : match->bits)
                    mask.setrange(piece.lo, piece.hi+1-piece.lo);
                if (Format::Field *version = format->field("version", group))
                    mask.setrange(version->bits[0].lo, version->size);
                LOG2(" : mask for group " << group << " is " << mask);
                if (!mask2tofino_mask(mask, word, match_mask, tofino_mask)) {
                    error(lineno, "Invalid match mask for group %d in table %s",
                          group, name());
                    return; }
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = ~tofino_mask & 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = ~(tofino_mask >> 14) & 0xf;
                word_group++; }
            for (; word_group < 5; word_group++) {
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = 0xf; }
        }
        /* setup input xbars to get data to the right places on the bus(es) */
        auto &vh_xbar = stage->regs.rams.array.row[row.row].vh_xbar;
        unsigned input_bus_locs[16];
        setup_match_input(input_bus_locs, match, stage, ways[way].group);
        for (unsigned i = 0; i < format->groups(); i++) {
            Format::Field *match = format->field("match", i);
            unsigned b = 0;
            for (auto &piece : match->bits) {
                if (piece.lo/128 != (unsigned)word) {
                    b += (piece.hi+1-piece.lo)/8;
                    continue; }
                for (unsigned byte = (piece.lo%128)/8; byte <= (piece.hi%128)/8; byte++)
                    vh_xbar[row.bus].exactmatch_row_vh_xbar_byteswizzle_ctl[byte/4]
                        .set_subfield(0x10 + input_bus_locs[b++], (byte%4)*5, 5); }
            assert(b == match->size/8);
            if (Format::Field *version = format->field("version", i)) {
                if (version->bits[0].lo/128 != (unsigned)word) continue;
                vh_xbar[row.bus].exactmatch_validselect |= 1U << (version->bits[0].lo%128)/4; } }
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_select = ways[way].group;
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_enable = 1;
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_thread = gress;
        /* setup match central config to extract results of the match */
        auto &merge = stage->regs.rams.match.merge;
        unsigned bus = row.row*2 + row.bus;
        /* FIXME -- factor this where possible with ternary match code */
        if (action) {
            int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
            if (action_args.size() == 1) {
                merge.mau_actiondata_adr_mask[0][bus] = 0x3fffff & (~0U << lo_huffman_bits);
            } else {
                /* FIXME -- support for multiple sizes of action data? */
                merge.mau_actiondata_adr_mask[0][bus] =
                    ((1U << action_args[1]->size) - 1) << lo_huffman_bits; }
            merge.mau_actiondata_adr_vpn_shiftcount[0][bus] =
                std::max(0, (int)action->format->log2size - 7); }
        for (unsigned word_group = 0; word_group < word_info[word].size(); word_group++) {
            int group = word_info[word][word_group];
            if (action_args[0]->by_group[group]->bits[0].lo/128 != (unsigned)word) continue;
            merge.mau_action_instruction_adr_exact_shiftcount[bus][word_group] =
                action_args[0]->by_group[group]->bits[0].lo % 128;
            if (format->immed) {
                assert(format->immed->by_group[group]->bits[0].lo/128 == (unsigned)word);
                merge.mau_immediate_data_exact_shiftcount[bus][word_group] =
                    format->immed->by_group[group]->bits[0].lo % 128; }
            /* FIXME -- factor this where possible with ternary match code */
            if (action) {
                int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
                if (action_args.size() == 1) {
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        69 + (format->log2size-2) - lo_huffman_bits;
                } else {
                    assert(action_args[1]->by_group[group]->bits[0].lo/128 == (unsigned)word);
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        action_args[1]->bits[0].lo + 5 - lo_huffman_bits; } } }
        for (auto col : row.cols) {
            merge.col[col].row_action_nxtable_bus_drive[row.row] = 1 << row.bus;
            int word_group = 0;
            for (int group : word_info[word]) {
                auto &overhead_row = layout[index + word - group_info[group].overhead_word];
                auto &hitmap_ixbar = merge.col[col].hitmap_output_map[2*row.row + word_group];
                hitmap_ixbar.enabled_4bit_muxctl_select =
                    overhead_row.row*2 + group_info[group].word_group;
                hitmap_ixbar.enabled_4bit_muxctl_enable = 1;
                if (++word_group > 1) break; }
            /*merge.col[col].hitmap_output_map[bus].enabled_4bit_muxctl_select =
                layout[index+word].row*2 + layout[index+word].bus;
            merge.col[col].hitmap_output_map[bus].enabled_4bit_muxctl_enable = 1;*/ }
        if (--word < 0) { word = fmt_width-1; way++; vpn += format->groups(); } }
    if (actions) actions->write_regs(this);
    if (gateway) gateway->write_regs();
}

void ExactMatchTable::gen_tbl_cfg(json::vector &out) {
}
