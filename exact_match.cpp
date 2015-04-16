#include "action_bus.h"
#include "algorithm.h"
#include "hex.h"
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
                        gress, stage, -1, kv.value.map);
                gateway->set_match_table(this); }
        } else if (kv.key == "format") {
            /* done above to be done before action_bus and vpns */
        } else if (kv.key == "action") {
            action.setup(kv.value, this);
        } else if (kv.key == "actions") {
            if (CHECKTYPE(kv.value, tMAP))
                actions = new Actions(this, kv.value.map);
        } else if (kv.key == "action_bus") {
            if (CHECKTYPE(kv.value, tMAP))
                action_bus = new ActionBus(this, kv.value.map);
        } else if (kv.key == "selector") {
            selector.setup(kv.value, this);
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
                if (w.vec.size < 3 || w[0].type != tINT || w[1].type != tINT || w[2].type != tINT)
                    error(w.lineno, "invalid way descriptor");
                else ways.emplace_back(Way{w.lineno, w[0].i, w[1].i, w[2].i});
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
        } else if (kv.key == "vpns") {
            if (CHECKTYPE(kv.value, tVEC))
                setup_vpns(&kv.value.vec);
        } else if (kv.key == "p4_table") {
            if (CHECKTYPE(kv.value, tSTR))
                p4_table = kv.value.s;
        } else if (kv.key == "handle") {
            if (CHECKTYPE(kv.value, tINT))
                handle = kv.value.i;
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
    alloc_rams(false, stage->sram_use, &stage->sram_match_bus_use);
    if (action.set() && actions)
	error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
	error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action.args.size() > 2)
        error(lineno, "Unexpected number of action table arguments %zu", action.args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}

SelectionTable *ExactMatchTable::get_selector() {
    return dynamic_cast<SelectionTable *>((Table *)selector);
}

/* calculate the 18-bit byte/nybble mask tofino uses for matching in a 128-bit word */
static unsigned tofino_bytemask(int lo, int hi) {
    unsigned rv = 0;
    for (unsigned i = lo/4U; i <= hi/4U; i++)
        rv |= 1U << (i < 28 ? i/2 : i-14);
    return rv;
}

void ExactMatchTable::pass1() {
    LOG1("### Exact match table " << name() << " pass1");
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    alloc_vpns();
    check_next();
    if (action.check() && action->set_match_table(this) != ACTION)
        error(action.lineno, "%s is not an action table", action->name());
    if (selector.check()) {
        if (selector->set_match_table(this) != SELECTION)
            error(selector.lineno, "%s is not a selection table", selector->name());
        if (selector.args.size() != 1)
            error(selector.lineno, "selector requires one arg"); }
    if (action_bus) action_bus->pass1(this);
    if (actions) {
        assert(action.args.size() == 0);
        if (auto *sel = lookup_field("action"))
            action.args.push_back(sel);
        else if (actions->count() > 1)
            error(lineno, "No field 'action' to select between mulitple actions in "
                  "table %s format", name());
        actions->pass1(this); }
    input_xbar->pass1(stage->exact_ixbar, 128);
    format->setup_immed(this);
    group_info.resize(format->groups());
    unsigned fmt_width = (format->size + 127)/128;
    if (!format->field("match")) {
        error(format->lineno, "No 'match' field in format for table %s", name());
        return; }
    for (unsigned i = 0; i < format->groups(); i++) {
        auto &info = group_info[i];
        info.tofino_mask.resize(fmt_width);
        Format::Field *match = format->field("match", i);
        for (auto &piece : match->bits) {
            unsigned word = piece.lo/128;
            if (word != piece.hi/128)
                error(format->lineno, "'match' field must be explictly split across 128-bit "
                      "boundary in table %s", name());
            info.tofino_mask[word] |= tofino_bytemask(piece.lo%128, piece.hi%128);
            info.match_group[word] = -1; }
        if (auto *version = format->field("version", i)) {
            if (version->bits.size() != 1)
                error(format->lineno, "'version' field cannot be split");
            auto &piece = version->bits[0];
            unsigned word = piece.lo/128;
            if (version->size != 4 || (piece.lo % 4) != 0)
                error(format->lineno, "'version' field not 4 bits and nibble aligned "
                      "in table %s", name());
            info.tofino_mask[word] |= tofino_bytemask(piece.lo%128, piece.hi%128);
            info.match_group[word] = -1; }
        for (unsigned j = 0; j < i; j++)
            for (unsigned word = 0; word < fmt_width; word++)
                if (group_info[j].tofino_mask[word] & info.tofino_mask[word]) {
                    int bit = ffs(group_info[j].tofino_mask[word] & info.tofino_mask[word])-1;
                    if (bit >= 14) bit += 14;
                    error(format->lineno, "Match groups %d and %d both use %s %d in word %d",
                          i, j, bit > 20 ? "nibble" : "byte", bit, word);
                    break; }
        for (auto it = format->begin(i); it != format->end(i); it++) {
            if (it->first == "match" || it->first == "version") continue;
            if (it->second.bits.size() != 1) {
                error(format->lineno, "Can't deal with split field %s", it->first.c_str());
                continue; }
            unsigned limit = it->first == "next" ? 40 : 64;
            unsigned word = it->second.bits[0].lo/128;
            if (info.overhead_word < 0) {
                info.overhead_word = word;
                info.overhead_bit = it->second.bits[0].lo%128;
                if (!info.match_group.count(word))
                    error(format->lineno, "Overhead for group %d must be in the same word "
                          "as part of its match", i);
            } else if (info.overhead_word != (int)word)
                error(format->lineno, "Match overhead group %d split across words", i);
            else if (word != it->second.bits[0].hi/128 || it->second.bits[0].hi%128 >= limit)
                error(format->lineno, "Match overhead field %s(%d) not in bottom %d bits",
                      it->first.c_str(), i, limit);
            if ((unsigned)info.overhead_bit > it->second.bits[0].lo%128)
                info.overhead_bit = it->second.bits[0].lo%128; } }
    if (word_info.empty()) {
        word_info.resize(fmt_width);
        if (format->field("next")) {
            /* 'next' for match group 0 must be in bit 0, so make the format group with
             * overhead in bit 0 match group 0 in its overhead word */
            for (unsigned i = 0; i < group_info.size(); i++) {
                if (group_info[i].overhead_bit == 0) {
                    assert(error_count > 0 || word_info[group_info[i].overhead_word].empty());
                    group_info[i].match_group[group_info[i].overhead_word] = 0;
                    word_info[group_info[i].overhead_word].push_back(i); } } }
        for (unsigned i = 0; i < group_info.size(); i++)
            if (group_info[i].match_group.size() > 1)
                for (auto &mgrp : group_info[i].match_group) {
                    if (mgrp.second >= 0) continue;
                    if ((mgrp.second = word_info[mgrp.first].size()) > 1)
                        error(format->lineno, "Too many multi-word groups using word %d",
                              mgrp.first);
                    word_info[mgrp.first].push_back(i); }
    } else {
        if (word_info.size() != fmt_width)
            error(mgm_lineno, "Match group map doesn't match format size");
        for (unsigned i = 0; i < word_info.size(); i++) {
            for (unsigned j = 0; j < word_info[i].size(); j++) {
                int grp = word_info[i][j];
                if (grp < 0 || (unsigned)grp >= format->groups())
                    error(mgm_lineno, "Invalid group number %d", grp);
                else if (!group_info[grp].match_group.count(i))
                    error(mgm_lineno, "Format group %d doesn't match in word %d", grp, i);
                else {
                    group_info[grp].match_group[i] = j;
                    Format::Field *next = format->field("next", grp);
                    if (!j && next && next->bits[0].lo/128 == i && next->bits[0].lo%128)
                        error(mgm_lineno, "Next(%d) field must be at bit %d to be in match group 0",
                              grp, i*128); } } } }
    if (error_count > 0) return;
    for (int i = 0; i < (int)group_info.size(); i++) {
        if (group_info[i].match_group.size() == 1)
            for (auto &mgrp : group_info[i].match_group) {
                if (mgrp.second >= 0) continue;
                if ((mgrp.second = word_info[mgrp.first].size()) > 4)
                    error(format->lineno, "Too many match groups using word %d", mgrp.first);
                word_info[mgrp.first].push_back(i); }
        if (group_info[i].overhead_word < 0) {
            /* no overhead -- use the first match word */
            group_info[i].word_group = group_info[i].match_group.begin()->second;
            LOG1("  format group " << i << " no overhead");
        } else {
            group_info[i].word_group = group_info[i].match_group[group_info[i].overhead_word];
            LOG1("  format group " << i << " overhead in word " << group_info[i].overhead_word <<
                 " at bit " << group_info[i].overhead_bit); }
        LOG1("  masks: " << hexvec(group_info[i].tofino_mask));
        for (auto &mgrp : group_info[i].match_group)
            LOG1("    match group " << mgrp.second << " in word " << mgrp.first); }
    for (unsigned i = 0; i < word_info.size(); i++)
        LOG1("  word " << i << " groups: " << word_info[i]);
    if (options.match_compiler) {
        /* hack to match the compiler's nibble usage -- if any of the top 4 nibbles is
         * unused in a word, mark it as used by any group that uses the other nibble of the
         * byte, UNLESS it is used for the version.  This is ok, as the unused nibble will
         * end up being masked off by the match_mask anyways */
        for (unsigned word = 0; word < word_info.size(); word++) {
            unsigned used_nibbles = 0;
            for (auto group : word_info[word])
                used_nibbles |= group_info[group].tofino_mask[word] >> 14;
            for (unsigned nibble = 0; nibble < 4; nibble++) {
                if (!((used_nibbles >> nibble) & 1) && ((used_nibbles >> (nibble^1)) & 1)) {
                    LOG1("  ** fixup nibble " << nibble << " in word " << word);
                    for (auto group : word_info[word])
                        if ((group_info[group].tofino_mask[word] >> (14 + (nibble^1))) & 1) {
                            if (auto *version = format->field("version", group)) {
                                if (version->bits[0].lo == word*128 + (nibble^1)*4 + 112) {
                                    LOG1("      skip group " << group << " (version)");
                                    continue; } }
                            group_info[group].tofino_mask[word] |= 1 << (14 + nibble);
                            LOG1("      adding to group " << group); } } } } }
    setup_ways();
    for (auto &r : match) r.check();
    if (error_count > 0) return;
    if (match.empty())
        for (auto it = input_xbar->all_begin(); it != input_xbar->all_end(); ++it)
            match.push_back(it->second.what);
    unsigned bit = 0;
    for (auto &r : match) {
        match_by_bit[bit] = r;
        bit += r->size(); }
    if ((unsigned)bit != format->field("match")->size)
        warning(match[0].lineno, "Match width %d for table %s doesn't match format match width %d",
                bit, name(), format->field("match")->size);
    match_in_word.resize(fmt_width);
    for (unsigned i = 0; i < format->groups(); i++) {
        Format::Field *match = format->field("match", i);
        unsigned bit = 0;
        for (auto &piece : match->bits) {
            auto mw = --match_by_bit.upper_bound(bit);
            int lo = bit - mw->first;
            while(mw != match_by_bit.end() &&  mw->first < bit + piece.size()) {
                int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
                assert((unsigned)piece.lo/128 < fmt_width);
                //merge_phv_vec(match_in_word[piece.lo/128], Phv::Ref(mw->second, lo, hi));
                match_in_word[piece.lo/128].emplace_back(mw->second, lo, hi);
                lo = 0;
                ++mw; }
            bit += piece.size(); } }
    for (unsigned i = 0; i < fmt_width; i++)
        LOG1("  match in word " << i << ": " << match_in_word[i]);
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
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
        if (layout.size() % (ways.size()*fmt_width) != 0)
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
                for (auto col : row.cols) {
                    ways[way].rams.emplace_back(row.row, col);
                    way_map[ways[way].rams.back()].way = way; }
                if (++word == fmt_width) { word = 0; way++; } } }
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
    for (auto &w : ways) {
        MaskCounter bank(w.mask);
        unsigned index = 0, word = 0;
        int col = -1;
        for (auto &ram : w.rams) {
            auto &wm = way_map[ram];
            wm.index = index;
            wm.word = fmt_width - word - 1;
            wm.bank = bank;
            if (word && col != ram.second)
                error(w.lineno, "Wide exact match split across columns %d and %d",
                      col, ram.second);
            col = ram.second;
            ++index;
            if (++word == fmt_width) { word = 0; bank++; } } }
}

static int find_in_ixbar(Table *table, std::vector<Phv::Ref> &match) {
    int max_i = -1;
    LOG3("find_in_ixbar " << match);
    for (unsigned group = 0; group < EXACT_XBAR_GROUPS; group++) {
        LOG3(" looking in table in group " << group);
        bool ok = true;
        for (auto &r : match) {
            LOG3("  looking for " << r);
            if (!table->input_xbar->find(*r, group)) {
                LOG3("   -- not found");
                ok = false;
                break; } }
        if (ok) {
            LOG3(" success");
            return group; } }
    for (unsigned group = 0; group < EXACT_XBAR_GROUPS; group++) {
        LOG3(" looking in group " << group);
        bool ok = true;
        for (auto &r : match) {
            LOG3("  looking for " << r);
            bool found = false;
            for (auto *in : table->stage->exact_ixbar[group]) {
                if (in->find(*r, group)) {
                    found = true;
                    break; } }
            if (!found) {
                LOG3("   -- not found");
                if (&r - &match[0] > max_i)
                    max_i = &r - &match[0];
                ok = false;
                break; } }
        if (ok) {
            LOG3(" success");
            return group; } }
    if (max_i > 0)
        error(match[max_i].lineno, "%s: Can't find %s and %s in same input xbar group",
              table->name(), match[max_i].name(), match[0].name());
    else
        error(match[0].lineno, "%s: Can't find %s in any input xbar group",
              table->name(), match[0].name());
    return -1;
}

void ExactMatchTable::pass2() {
    LOG1("### Exact match table " << name() << " pass2");
    input_xbar->pass2(stage->exact_ixbar, 128);
    if (action_bus)
        action_bus->pass2(this);
    word_ixbar_group.resize(match_in_word.size());
    for (unsigned i = 0; i < match_in_word.size(); i++)
        word_ixbar_group[i] = find_in_ixbar(this, match_in_word[i]);
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
}

void ExactMatchTable::write_regs() {
    LOG1("### Exact match table " << name() << " write_regs");
    MatchTable::write_regs(0, this);
    unsigned fmt_width = (format->size + 127)/128;
    int word = fmt_width-1;  // FIXME -- don't need this anymore?
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
        bool first = true;
        int hash_group = -1;
        auto vpn_iter = row.vpns.begin();
        for (auto col : row.cols) {
            auto &way = way_map[std::make_pair(row.row, col)];
            if (first) {
                hash_group = ways[way.way].group;
                vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus]
                    .enabled_3bit_muxctl_select = hash_group;
                vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus]
                    .enabled_3bit_muxctl_enable = 1;
                first = false;
            } else
                assert(hash_group == ways[way.way].group);
            assert(way.word == word);
            vh_adr_xbar.exactmatch_mem_hashadr_xbar_ctl[col]
                .enabled_4bit_muxctl_select = ways[way.way].subgroup + row.bus*5;
            vh_adr_xbar.exactmatch_mem_hashadr_xbar_ctl[col]
                .enabled_4bit_muxctl_enable = 1;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_bank_mask = ways[way.way].mask;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_bank_id = way.bank;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_inp_sel |= 1 << row.bus;
            auto &ram = stage->regs.rams.array.row[row.row].ram[col];
            for (unsigned i = 0; i < 4; i++)
                ram.match_mask[i] = match_mask.getrange(word*128+i*32, 32);
            ram.unit_ram_ctl.match_ram_write_data_mux_select = 7; /* unused */
            ram.unit_ram_ctl.match_ram_read_data_mux_select = 7; /* unused */
            ram.unit_ram_ctl.match_ram_matchdata_bus1_sel = row.bus;
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

            /* TODO -- Algorithmic TCAM support will require something else here */
            ram.match_nibble_s0q1_enable = version_nibble_mask.getrange(word*32, 32);
            ram.match_nibble_s1q0_enable = 0xffffffffUL;

            int word_group = 0;
            for (int group : word_info[word]) {
                unsigned mask = group_info[group].tofino_mask[word];
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = ~mask & 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = ~(mask >> 14) & 0xf;
                word_group++; }
            for (; word_group < 5; word_group++) {
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = 0xf; }
        }
        /* setup input xbars to get data to the right places on the bus(es) */
        auto &vh_xbar = stage->regs.rams.array.row[row.row].vh_xbar;
        for (unsigned i = 0; i < format->groups(); i++) {
            Format::Field *match = format->field("match", i);
            unsigned bit = 0;
            for (auto &piece : match->bits) {
                if (piece.lo/128 != (unsigned)word) {
                    bit += piece.size();
                    continue; }
                for (unsigned fmt_bit = piece.lo; fmt_bit <= piece.hi;) {
                    unsigned byte = (fmt_bit%128)/8;
                    unsigned bits_in_byte = (byte+1)*8 - (fmt_bit%128);
                    if (fmt_bit + bits_in_byte > piece.hi + 1)
                        bits_in_byte = piece.hi + 1 - fmt_bit;
                    auto it = --match_by_bit.upper_bound(bit);
                    Phv::Slice sl(*it->second, bit-it->first, bit-it->first+bits_in_byte-1);
                    int bus_loc = find_on_ixbar(sl, word_ixbar_group[word]);
                    assert(bus_loc >= 0 && bus_loc < 16);
                    vh_xbar[row.bus].exactmatch_row_vh_xbar_byteswizzle_ctl[byte/4]
                        .set_subfield(0x10 + bus_loc, (byte%4)*5, 5);
                    fmt_bit += bits_in_byte;
                    bit += bits_in_byte; } }
            assert(bit == match->size);
            if (Format::Field *version = format->field("version", i)) {
                if (version->bits[0].lo/128 != (unsigned)word) continue;
                vh_xbar[row.bus].exactmatch_validselect |= 1U << (version->bits[0].lo%128)/4; } }
        auto &vh_xbar_ctl = vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl;
        vh_xbar_ctl.exactmatch_row_vh_xbar_select = word_ixbar_group[word];
        vh_xbar_ctl.exactmatch_row_vh_xbar_enable = 1;
        vh_xbar_ctl.exactmatch_row_vh_xbar_thread = gress;
        /* setup match central config to extract results of the match */
        auto &merge = stage->regs.rams.match.merge;
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
                    ((1U << action.args[1]->size) - 1) << lo_huffman_bits; } }
        if (selector)
            merge.mau_selectorlength_default[0][bus] = 0x601; // FIXME
        for (unsigned word_group = 0; word_group < word_info[word].size(); word_group++) {
            int group = word_info[word][word_group];
            if (group_info[group].overhead_word == word) {
                if (format->immed) {
                    assert(format->immed->by_group[group]->bits[0].lo/128 == (unsigned)word);
                    merge.mau_immediate_data_exact_shiftcount[bus][word_group] =
                        format->immed->by_group[group]->bits[0].lo % 128; }
                if (!action.args.empty()) {
                    assert(action.args[0]->by_group[group]->bits[0].lo/128 == (unsigned)word);
                    merge.mau_action_instruction_adr_exact_shiftcount[bus][word_group] =
                        action.args[0]->by_group[group]->bits[0].lo % 128; }
            } else if (!options.match_compiler) continue;
            /* FIXME -- factor this where possible with ternary match code */
            if (action) {
                int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
                if (action.args.size() <= 1) {
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        69 - lo_huffman_bits;
                } else if (group_info[group].overhead_word == word) {
                    assert(action.args[1]->by_group[group]->bits[0].lo/128 == (unsigned)word);
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        action.args[1]->by_group[group]->bits[0].lo%128 + 5 - lo_huffman_bits; } }
            if (selector) {
                merge.mau_meter_adr_exact_shiftcount[bus][word_group] = 
                    selector.args[0]->by_group[group]->bits[0].lo%128 -
                        get_selector()->address_shift(); } }
        for (auto col : row.cols) {
            int word_group = 0;
            for (int group : word_info[word]) {
                auto &hitmap_ixbar = merge.col[col].hitmap_output_map[2*row.row + word_group];
                if (group_info[group].overhead_word >= 0) {
                    auto &overhead_row = layout[index + word - group_info[group].overhead_word];
                    if (&overhead_row == &row)
                        merge.col[col].row_action_nxtable_bus_drive[row.row] |= 1 << row.bus;
                    hitmap_ixbar.enabled_4bit_muxctl_select =
                        overhead_row.row*2 + group_info[group].word_group;
                } else {
                    hitmap_ixbar.enabled_4bit_muxctl_select =
                        row.row*2 + group_info[group].word_group; }
                hitmap_ixbar.enabled_4bit_muxctl_enable = 1;
                if (++word_group > 1) break; }
            /*merge.col[col].hitmap_output_map[bus].enabled_4bit_muxctl_select =
                layout[index+word].row*2 + layout[index+word].bus;
            merge.col[col].hitmap_output_map[bus].enabled_4bit_muxctl_enable = 1;*/ }
        if (gress == EGRESS)
            merge.exact_match_delay_config.exact_match_bus_thread |= 1 << bus;
        if (--word < 0) { word = fmt_width-1; } }
    if (actions) actions->write_regs(this);
    if (gateway) gateway->write_regs();
}

std::unique_ptr<json::map> ExactMatchTable::gen_memory_resource_allocation_tbl_cfg(Way &way) {
    json::map mra;
    json::vector *t;
    mra["memory_type"] = "sram";
    int hash_id = -1;
    unsigned hash_groups = 0, vpn_ctr = 0;
    unsigned fmt_width = (format->size + 127)/128;
    for (auto &w : ways) {
        if (!((hash_groups >> w.group) & 1)) {
            ++hash_id;
            hash_groups |= 1 << w.group; }
        if (&w == &way) break; }
    mra["hash_function_id"] = hash_id;
    mra["hash_entry_bit_lo"] = way.subgroup*10;
    mra["hash_entry_bit_hi"] = way.subgroup*10 + 9;
    mra["number_entry_bits"] = 10;
    if (way.mask) {
        mra["hash_select_bit_lo"] = 40 + ffs(way.mask) - 1;
        mra["hash_select_bit_hi"] = 40 + floor_log2(way.mask);
    } else
        mra["hash_select_bit_lo"] = mra["hash_select_bit_hi"] = 40;
    mra["number_select_bits"] = bitcount(way.mask);
    json::vector *mem_units = 0;
    mra["memory_units_and_vpns"] = std::unique_ptr<json::obj>(t = new json::vector);
    for (auto &ram : way.rams) {
        if (!mem_units) {
            mem_units = new json::vector;
            vpn_ctr = layout_get_vpn(ram.first, ram.second); }
        mem_units->push_back(ram.first*12 + ram.second);
        if (mem_units->size() == fmt_width) {
            json::map tmp;
            tmp["memory_units"] = std::unique_ptr<json::obj>(mem_units);
            mem_units = 0;
            json::vector *vpns;
            tmp["vpns"] = std::unique_ptr<json::obj>(vpns = new json::vector);
            for (unsigned i = 0; i < format->groups(); i++)
                vpns->push_back(vpn_ctr++);
            t->emplace_back(std::make_unique<json::map>(std::move(tmp))); } }
    assert(!mem_units);
    return std::make_unique<json::map>(std::move(mra));
}

void ExactMatchTable::gen_tbl_cfg(json::vector &out) {
    json::map tbl, stage_tbl, pack_fmt;
    json::vector *t, *t2;
    unsigned fmt_width = (format->size + 127)/128;
    Stage::P4TableInfo *p4_info = p4_table.empty() ? 0 : &Stage::p4_tables[p4_table];
    if (!p4_info || !p4_info->desc) {
        tbl["name"] = name();
        if (handle) tbl["handle"] = handle;
        tbl["table_type"] = "match_entry";
        tbl["direction"] = gress ? "egress" : "ingress";
        tbl["stage_tables_length"] = 1; }
    stage_tbl["stage_number"] = stage->stageno;
    stage_tbl["number_entries"] = layout_size()/fmt_width * format->groups() * 1024;
    stage_tbl["stage_table_type"] = "hash_match";
    pack_fmt["table_word_width"] = 128 * fmt_width;
    pack_fmt["memory_word_width"] = 128;
    pack_fmt["entries_per_table_word"] = format->groups();
    pack_fmt["number_memory_units_per_table_word"] = fmt_width;
    stage_tbl["pack_format"] = std::unique_ptr<json::obj>(t = new json::vector);
    t->emplace_back(std::make_unique<json::map>(std::move(pack_fmt)));
    stage_tbl["way_stage_tables"] = std::unique_ptr<json::obj>(t = new json::vector);
    for (auto &way : ways) {
        json::map way_tbl, pack_fmt, mra;
        way_tbl["stage_number"] = stage->stageno;
        way_tbl["number_entries"] = way.rams.size()/fmt_width * format->groups() * 1024;
        way_tbl["stage_table_type"] = "hash_way";
        pack_fmt["table_word_width"] = 128 * fmt_width;
        pack_fmt["memory_word_width"] = 128;
        pack_fmt["entries_per_table_word"] = format->groups();
        pack_fmt["number_memory_units_per_table_word"] = fmt_width;
        way_tbl["pack_format"] = std::unique_ptr<json::obj>(t2 = new json::vector);
        t2->emplace_back(std::make_unique<json::map>(std::move(pack_fmt)));
        way_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg(way);
        t->emplace_back(std::make_unique<json::map>(std::move(way_tbl))); }
    if (!p4_info || !p4_info->desc) {
        tbl["stage_tables"] = std::unique_ptr<json::obj>(t = new json::vector);
        t->emplace_back(std::make_unique<json::map>(std::move(stage_tbl)));
        if (p4_info) p4_info->stage_tables = t;
        if (action) {
            json::map act;
            act["name"] = action->name();
            if (action->handle)
                act["handle_reference"] = action->handle;
            act["how_referenced"] = action.args.size() > 1 ? "indirect" : "direct";
            tbl["p4_action_data_tables"] =  std::unique_ptr<json::obj>(t = new json::vector);
            t->emplace_back(std::make_unique<json::map>(std::move(act))); }
        if (selector) {
            json::map sel;
            sel["name"] = selector->name();
            if (selector->handle)
                sel["handle_reference"] = selector->handle;
            tbl["p4_selection_tables"] =  std::unique_ptr<json::obj>(t = new json::vector);
            t->emplace_back(std::make_unique<json::map>(std::move(sel))); }
        out.emplace_back(std::make_unique<json::map>(std::move(tbl)));
        if (p4_info) {
            p4_info->desc = dynamic_cast<json::map *>(out.back().get());
            assert(p4_info->desc); }
    } else {
        p4_info->stage_tables->emplace_back(std::make_unique<json::map>(std::move(stage_tbl)));
        (*p4_info->desc)["stage_tables_length"] = p4_info->stage_tables->size(); }
}
