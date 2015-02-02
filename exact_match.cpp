#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "stage.h"
#include "tables.h"

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
                        gress, stage, logical_id, kv.value.map);
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
    if (!format->field("match"))
        error(format->lineno, "No 'match' field in format for table %s", name());
    else for (unsigned i = 0; i < format->groups(); i++) {
        Format::Field *match = format->field("match", i);
        if (match->bit % 8 != 0 || match->size % 8 != 0)
            error(format->lineno, "'match' field not byte aligned in table %s", name());
        if (auto *version = format->field("version"))
            if (version->size != 4 || (version->bit % 4) != 0)
                error(format->lineno, "'version' field not 4 bits and nibble aligned "
                      "in table %s", name()); }
    unsigned fmt_width = (format->size + 127)/128;
    if (ways.empty())
        error(lineno, "No ways defined in table %s", name());
    else if (layout.size() % (ways.size()*fmt_width) != 0)
        error(lineno, "Rows is not a mulitple of ways in table %s", name());
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
        if (++word == fmt_width) { word = 0; way++; } }
    for (auto &r : match) r.check();
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
}

void ExactMatchTable::pass2() {
    input_xbar->pass2(stage->exact_ixbar, 128);
    if (action_bus) {
        action_bus->pass2(this);
        action_bus->set_immed_offsets(this); }
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
}

class GroupsInWord {
    unsigned    groups[2];
    struct iter {
        const GroupsInWord      *self;
        unsigned                idx, ctr;
        iter(const GroupsInWord *s) : self(s), idx(0), ctr(0) {
            if (!((self->groups[idx] >> ctr) & 1)) ++*this; }
        iter() : self(0), idx(2), ctr(0) { }
        bool operator==(const iter &a) const { return idx == a.idx && ctr == a.ctr; }
        unsigned operator*() const { return ctr; }
        iter &operator++() {
            do { if (++ctr >= 32 || self->groups[idx] < (1U << ctr)) {
                    ctr=0; idx++; }
            } while (idx < 2 && (!((self->groups[idx] >> ctr) & 1)));
            return *this; }
    };
public:
    GroupsInWord(unsigned words, unsigned cross_words) {
        groups[0] = words&cross_words; groups[1] = words&~cross_words; }
    iter begin() const { return iter(this); }
    iter end() const { return iter(); }
};

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

static bool setup_match_input(unsigned bytes[16], std::vector<Phv::Ref> &match, Stage *stage, int group) {
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
    return rv;
}

void ExactMatchTable::write_regs() {
    if (input_xbar->width() > 1) {
        error(lineno, "FIXME -- can't deal with exact match larger than 128 bits");
        return; }
    MatchTable::write_regs(0, this);
    unsigned fmt_width = (format->size + 127)/128;
    unsigned way = 0, word = 0;
    int vpn = 0;
    bitvec match_mask, version_nibble_mask;
    unsigned groups_in_word[fmt_width];
    unsigned groups_cross_words = 0;
    unsigned words_in_group[format->groups()];
    match_mask.setrange(0, 128*fmt_width);
    version_nibble_mask.setrange(0, 32*fmt_width);
    for (unsigned i = 0; i < fmt_width; i++) groups_in_word[i] = 0;
    for (unsigned i = 0; i < format->groups(); i++) {
        words_in_group[i] = 0;
        Format::Field *match = format->field("match", i);
        match_mask.clrrange(match->bit, match->size);
        groups_in_word[match->bit/128] |= 1U << i;
        words_in_group[i] |= 1U << match->bit/128;
        if (match->bit%128 + match->size > 128) {
            groups_in_word[match->bit/128 + 1] |= 1U << i;
            words_in_group[i] |= 2U << match->bit/128; }
        if (Format::Field *version = format->field("version", i)) {
            match_mask.clrrange(version->bit, version->size);
            groups_in_word[version->bit/128] |= 1U << i;
            words_in_group[i] |= 1U << version->bit/128;
            version_nibble_mask.clrrange(version->bit/4, 1); }
        unsigned t = ((words_in_group[i] ^ (words_in_group[i]-1)) << 1) | 1;
        if (words_in_group[i] & ~t) {
            error(lineno, "Group %d in table %s tries to match over non-adjacent"
                  " rows", i, name());
            return; }
        if (words_in_group[i] & ~(t >> 1))
            groups_cross_words |= 1U << i; }
    for (unsigned i = 0; i < fmt_width; i++) {
        if (bitcount(groups_in_word[i]) > 5) {
            error(lineno, "More than 5 match groups in one word in table %s", name());
            return; }
        if (bitcount(groups_in_word[i]&groups_cross_words) > 2) {
            error(lineno, "More than 2 match groups that cross words in table %s", name());
            return; } }
    /* iterating through rows in the sram array;  while in this loop, 'row' is the
     * row we're on, 'word' is which word in a wide full-way the row is for, and 'way'
     * is which full-way of the match table the row is for */
    unsigned wide_bus = ~0;     /* bus used by first word of wide match */
    for (auto &row : layout) {
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
            auto &unitram_config = stage->regs.rams.map_alu.row[row.row].adrmux
                    .unitram_config[col/6][col%6];
            for (unsigned i = 0; i < 4; i++)
                ram.match_mask[i] = match_mask.getrange(word*128+i*32, 32);
            for (int v : VersionIter(config_version)) {
                ram.unit_ram_ctl[v].match_ram_write_data_mux_select = 7; /* unused */
                ram.unit_ram_ctl[v].match_ram_read_data_mux_select = 7; /* unused */
                ram.unit_ram_ctl[v].match_result_bus_select = 1 << row.bus;
                if (auto cnt = bitcount(groups_in_word[word]))
                    ram.unit_ram_ctl[v].match_entry_enable = ~(~0U << --cnt);
                unitram_config[v].unitram_type = 1;
                unitram_config[v].unitram_logical_table = logical_id;
                switch (gress) {
                case INGRESS: unitram_config[v].unitram_ingress = 1; break;
                case EGRESS: unitram_config[v].unitram_egress = 1; break;
                default: assert(0); }
                unitram_config[v].unitram_enable = 1; }
            ram.match_ram_vpn.match_ram_vpn0 = vpn >> 2;
            unsigned vpn_lsb = (vpn&3) - 1;
            for (unsigned i = 0; i < format->groups(); i++)
                ram.match_ram_vpn.match_ram_vpn_lsbs |= (++vpn_lsb) << i*3;
            if (vpn_lsb & 4)
                ram.match_ram_vpn.match_ram_vpn1 = (vpn >> 2) + 1;
            /* TODO -- Algorithmic TCAM support will require something else here */
            ram.match_nibble_s0q1_enable = version_nibble_mask.getrange(word*32, 32);
            ram.match_nibble_s1q0_enable = 0xffffffffUL;
            int word_group = 0;
            for (unsigned group : GroupsInWord(groups_in_word[word], groups_cross_words)) {
                unsigned tofino_mask = 0;
                bitvec mask;
                mask.clear();
                Format::Field *match = format->field("match", group);
                mask.setrange(match->bit, match->size);
                if (Format::Field *version = format->field("version", group))
                    mask.setrange(version->bit, version->size);
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
            if (match->bit >= (word+1)*128 || match->bit + match->size <= word*128)
                continue;
            unsigned byte = (match->bit%128)/8;
            for (unsigned b = 0; b < match->size/8; b++, byte++)
                vh_xbar[row.bus].exactmatch_row_vh_xbar_byteswizzle_ctl[byte/4]
                    .set_subfield(0x10 + input_bus_locs[b], (byte%4)*5, 5);
            if (Format::Field *version = format->field("version", i)) {
                if (version->bit/128 != word) continue;
                vh_xbar[row.bus].exactmatch_validselect |= 1U << (version->bit%128)/4; } }
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_select = ways[way].group;
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_enable = 1;
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_thread = gress;
        /* setup match central config to extract results of the match */
        auto &merge = stage->regs.rams.match.merge;
        unsigned bus = row.row*2 + row.bus;
        if (word == 0) wide_bus = bus;
        /* FIXME -- factor this where possible with ternary match code */
        if (action) {
            if (action_args.size() == 1) {
                /* FIXME -- fixed actiondata mask??  See
                 * get_direct_address_mau_actiondata_adr_tcam_mask in
                 * device/pipeline/mau/address_and_data_structures.py
                 * Maybe should be masking off bottom 6-format->log2size bits, as those
                 * will be coming from the top of the tcam_indir data bus?  They'll always
                 * be 0 anyways, unless the full data bus is in use */
                merge.mau_actiondata_adr_mask[0][bus] = 0x3fffff;
            } else {
                /* FIXME -- support for multiple sizes of action data? */
                int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
                merge.mau_actiondata_adr_mask[0][bus] =
                    ((1U << action_args[1]->size) - 1) << lo_huffman_bits; }
            merge.mau_actiondata_adr_vpn_shiftcount[0][bus] =
                std::max(0, (int)action->format->log2size - 7);
        } else {
            /* FIXME -- do we need to actually set this? */
            merge.mau_actiondata_adr_mask[0][bus] = 0x3fffff; }
        int word_group = 0;
        for (unsigned group : GroupsInWord(groups_in_word[word], groups_cross_words)) {
            assert(action_args[0]->by_group[group]->bit/128 == word);
            merge.mau_action_instruction_adr_exact_shiftcount[bus][word_group] =
                action_args[0]->by_group[group]->bit % 128;
            if (format->immed) {
                assert(format->immed->by_group[group]->bit/128 == word);
                merge.mau_immediate_data_exact_shiftcount[bus][word_group] =
                    format->immed->by_group[group]->bit % 128; }
            /* FIXME -- factor this where possible with ternary match code */
            if (action) {
                int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
                if (action_args.size() == 1) {
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        69 + (format->log2size-2) - lo_huffman_bits;
                } else {
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        action_args[1]->bit + 5 - lo_huffman_bits; }
            } else {
                /* FIXME -- do we actually need to set this? */
                merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] = 69;
            }
            word_group++; }
        for (auto col : row.cols) {
            merge.col[col].row_action_nxtable_bus_drive[row.row] = 1 << row.bus;
            merge.col[col].hitmap_output_map[bus].enabled_4bit_muxctl_select = wide_bus;
            merge.col[col].hitmap_output_map[bus].enabled_4bit_muxctl_enable = 1; }
        if (++word == fmt_width) { word = 0; way++; vpn += format->groups(); } }
    if (actions) actions->write_regs(this);
    if (gateway) gateway->write_regs();
}

void ExactMatchTable::gen_tbl_cfg(json::vector &out) {
}
