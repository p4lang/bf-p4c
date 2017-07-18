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

Table::Format::Field *ExactMatchTable::lookup_field(const std::string &n, const std::string &) {
    if (format) return format->field(n);
    if (n == "immediate" && !::Phv::get(gress, n)) {
        static Format::Field default_immediate(32, Format::Field::USED_IMMED);
        return &default_immediate; }
    return nullptr;
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
        if (format->log2size < 7)
            format->log2size = 7;
        format->pass1(this);
        group_info.resize(format->groups());
        unsigned fmt_width = (format->size + 127)/128;
        for (unsigned i = 0; i < format->groups(); i++) {
            auto &info = group_info[i];
            info.tofino_mask.resize(fmt_width);
            if (Format::Field *match = format->field("match", i)) {
                for (auto &piece : match->bits) {
                    unsigned word = piece.lo/128;
                    if (word != piece.hi/128)
                        error(format->lineno, "'match' field must be explictly split across "
                              "128-bit boundary in table %s", name());
                    info.tofino_mask[word] |= tofino_bytemask(piece.lo%128, piece.hi%128);
                    info.match_group[word] = -1; } }
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
                if (it->first == "match" || it->first == "version" || it->first == "proxy_hash")
                    continue;
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
                        auto *next = format->field("next", grp);
                        if (!next && hit_next.size() > 1)
                            next = format->field("action", grp);
                        if (next) {
                            if (next->bits[0].lo/128 != i) continue;
                            static unsigned limit[5] = { 0, 8, 32, 32, 32 };
                            unsigned bit = next->bits[0].lo%128U;
                            if (!j && bit)
                                error(mgm_lineno, "Next(%d) field must start at bit %d to be in "
                                      "match group 0", grp, i*128);
                            else if (j && (!bit || bit > limit[j]))
                                warning(mgm_lineno, "Next(%d) field must start in range %d..%d "
                                        "to be in match group %d", grp, i*128+1, i*128+limit[j], j);
                            } } } } }
        if (hit_next.size() > 1 && !format->field("next") && !format->field("action"))
            error(format->lineno, "No 'next' field in format");
        if (error_count > 0) return;
        for (int i = 0; i < (int)group_info.size(); i++) {
            if (group_info[i].match_group.size() == 1)
                for (auto &mgrp : group_info[i].match_group) {
                    if (mgrp.second >= 0) continue;
                    if ((mgrp.second = word_info[mgrp.first].size()) > 4)
                        error(format->lineno, "Too many match groups using word %d", mgrp.first);
                    word_info[mgrp.first].push_back(i); }
            if (group_info[i].overhead_word < 0) {
                /* no overhead -- use the last match word */
                group_info[i].word_group = group_info[i].match_group.rbegin()->second;
                LOG1("  format group " << i << " no overhead");
            } else {
                group_info[i].word_group = group_info[i].match_group[group_info[i].overhead_word];
                LOG1("  format group " << i << " overhead in word " << group_info[i].overhead_word
                     << " at bit " << group_info[i].overhead_bit); }
            LOG1("  masks: " << hexvec(group_info[i].tofino_mask));
            for (auto &mgrp : group_info[i].match_group)
                LOG1("    match group " << mgrp.second << " in word " << mgrp.first); }
        for (unsigned i = 0; i < word_info.size(); i++)
            LOG1("  word " << i << " groups: " << word_info[i]);
        if (options.match_compiler && 0) {
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
        for (auto &r : match) r.check(true);
        if (error_count > 0) return;
        auto match_format = format->field("match");
        if (match_format && match.empty())
            for (auto ixbar_element : *input_xbar)
                match.push_back(ixbar_element.second.what);
        unsigned bit = 0;
        for (auto &r : match) {
            match_by_bit[bit] = r;
            bit += r->size(); }
        if ((unsigned)bit != (match_format ? match_format->size : 0))
            warning(match[0].lineno, "Match width %d for table %s doesn't match format match "
                    "width %d", bit, name(), match_format->size);
        match_in_word.resize(fmt_width);
        for (unsigned i = 0; i < format->groups(); i++) {
            Format::Field *match = format->field("match", i);
            if (!match) continue;
            unsigned bit = 0;
            for (auto &piece : match->bits) {
                auto mw = --match_by_bit.upper_bound(bit);
                int lo = bit - mw->first;
                while(mw != match_by_bit.end() &&  mw->first < bit + piece.size()) {
                    int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
                    assert((unsigned)piece.lo/128 < fmt_width);
                    //merge_phv_vec(match_in_word[piece.lo/128], Phv::Ref(mw->second, lo, hi));
                    append(match_in_word[piece.lo/128],
                           split_phv_bytes(Phv::Ref(mw->second, lo, hi)));
                    lo = 0;
                    ++mw; }
                bit += piece.size(); } }
        for (unsigned i = 0; i < fmt_width; i++)
            LOG1("  match in word " << i << ": " << match_in_word[i]); }
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

static int find_in_ixbar(Table *table, std::vector<Phv::Ref> &match) {
    int max_i = -1;
    LOG3("find_in_ixbar " << match);
    for (unsigned group = 0; group < EXACT_XBAR_GROUPS; group++) {
        LOG3(" looking in table in group " << group);
        bool ok = true;
        for (auto &r : match) {
            LOG3("  looking for " << r);
            if (!table->input_xbar->find_exact(*r, group)) {
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
            for (auto *in : table->stage->ixbar_use[InputXbar::Group(false, group)]) {
                if (in->find_exact(*r, group)) {
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
    if (logical_id < 0) choose_logical_id();
    input_xbar->pass2();
    word_ixbar_group.resize(match_in_word.size());
    for (unsigned i = 0; i < match_in_word.size(); i++)
        word_ixbar_group[i] = find_in_ixbar(this, match_in_word[i]);
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
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_bank_mask = ways[way.way].mask;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_bank_id = way.bank;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_inp_sel |= 1 << row.bus;
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
            for (auto &st : attached.stats) {
                if (st.args.empty())
                    merge.mau_stats_adr_exact_shiftcount[bus][word_group] = st->direct_shiftcount();
                else if (group_info[group].overhead_word == (int)word) {
                    assert(st.args[0].field()->by_group[group]->bits[0].lo/128U == word);
                    merge.mau_stats_adr_exact_shiftcount[bus][word_group] =
                        st.args[0].field()->by_group[group]->bits[0].lo%128U + 7;
                } else if (options.match_compiler) {
                    /* unused, so should not be set... */
                    merge.mau_stats_adr_exact_shiftcount[bus][word_group] = 7; }
                break; /* all must be the same, only config once */ }
            for (auto &m : attached.meter) {
                if (m.args.empty()) {
                    merge.mau_meter_adr_exact_shiftcount[bus][word_group] = m->direct_shiftcount() + 16;
                    if (idletime)
                        merge.mau_idletime_adr_exact_shiftcount[bus][word_group] = m->direct_shiftcount();
                } else if (group_info[group].overhead_word == (int)word) {
                    if (m.args[0].type == Call::Arg::Field) {
                        assert(m.args[0].field()->by_group[group]->bits[0].lo/128U == word);
                        merge.mau_meter_adr_exact_shiftcount[bus][word_group] =
                            m.args[0].field()->by_group[group]->bits[0].lo%128U + 16;
                        if (idletime)
                            merge.mau_idletime_adr_exact_shiftcount[bus][word_group] =
                                m.args[0].field()->by_group[group]->bits[0].lo%128U;
                    } else {
                        assert(m.args[0].type == Call::Arg::HashDist);
                        merge.mau_meter_adr_exact_shiftcount[bus][word_group] = 0; }
                } else if (options.match_compiler) {
                    /* unused, so should not be set... */
                    merge.mau_meter_adr_exact_shiftcount[bus][word_group] = 16;
                    if (idletime)
                        merge.mau_idletime_adr_exact_shiftcount[bus][word_group] = 0; }
                break; /* all must be the same, only config once */ } }
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
}

std::unique_ptr<json::map> ExactMatchTable::gen_memory_resource_allocation_tbl_cfg(Way &way) {
    if (options.new_ctx_json) {
        json::map mra;
        int hash_id = -1;
        unsigned hash_groups = 0, vpn_ctr = 0;
        unsigned fmt_width = format ? (format->size + 127)/128 : 0;
        if (options.match_compiler) {
            for (auto &w : ways) {
                if (!((hash_groups >> w.group) & 1)) {
                    ++hash_id;
                    hash_groups |= 1 << w.group; }
                if (&w == &way) break; }
        } else
            hash_id = way.group;
        mra["hash_function_id"] = hash_id;
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
    } else {
        json::map mra;
        mra["memory_type"] = "sram";
        int hash_id = -1;
        unsigned hash_groups = 0, vpn_ctr = 0;
        unsigned fmt_width = format ? (format->size + 127)/128 : 0;
        if (options.match_compiler) {
            for (auto &w : ways) {
                if (!((hash_groups >> w.group) & 1)) {
                    ++hash_id;
                    hash_groups |= 1 << w.group; }
                if (&w == &way) break; }
        } else
            hash_id = way.group;
        mra["hash_function_id"] = hash_id;
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
        return json::mkuniq<json::map>(std::move(mra)); }
}

void ExactMatchTable::add_field_to_pack_format(json::vector &field_list, int basebit,
                                std::string name, const Table::Format::Field &field,
                                const std::vector<Table::Actions::Action::alias_value_t *> &alias) {
    if (options.new_ctx_json) {
        if (name == "action") name = "--instruction_address--";
        if (name == "version") name = "--version_valid--";
        if (name == "immediate") name = "--immediate--";
        if (name != "match") {
            Table::add_field_to_pack_format(field_list, basebit, name, field, alias);
            return; }
        unsigned bit = 0;
        for (auto &piece : field.bits) {
            auto mw = --match_by_bit.upper_bound(bit);
            int lo = bit - mw->first;
            int offset = piece.lo - 1;
            while(mw != match_by_bit.end() &&  mw->first < bit + piece.size()) {
                std::string source = "spec"; //FIXME-JSON 
                std::string immediate_name = "";
                std::string mw_name = mw->second.name(); 
                if (mw_name == "--version_valid--")
                    source = "version";
                else if (mw_name == "--immediate--") {
                    source = "immediate";
                    immediate_name = name; }
                int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
                int width = hi - lo + 1;
                offset += width;
                field_list.push_back( json::map {
                    { "field_name", json::string(mw->second.name()) },
                    { "source", json::string(source) },
                    { "lsb_mem_word_offset", json::number(piece.lo) },
                    { "start_bit", json::number(lo + mw->second.lobit()) },
                    { "immediate_name", json::string(immediate_name) },
                    { "lsb_mem_word_idx", json::number(0) }, //FIXME-JSON 
                    { "match_mode", json::string("") }, //FIXME-JSON 
                    { "field_width", json::number(width) }});
                lo = 0;
                ++mw; }
            bit += piece.size(); }
    } else {
        if (name == "action") name = "--instruction_address--";
        if (name == "version") name = "--version_valid--";
        // if (name == "immediate") name = "--immediate--";
        if (name != "match") {
            Table::add_field_to_pack_format(field_list, basebit, name, field, alias);
            return; }
        unsigned bit = 0;
        for (auto &piece : field.bits) {
            auto mw = --match_by_bit.upper_bound(bit);
            int lo = bit - mw->first;
            int offset = piece.lo - 1;
            while(mw != match_by_bit.end() &&  mw->first < bit + piece.size()) {
                int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
                int width = hi - lo + 1;
                offset += width;
                field_list.push_back( json::map {
                    { "name", json::string(mw->second.name()) },
                    { "start_offset", json::number(basebit - offset) },
                    { "start_bit", json::number(lo + mw->second.lobit()) },
                    { "bit_width", json::number(width) }});
                lo = 0;
                ++mw; }
            bit += piece.size(); } }
}

void ExactMatchTable::gen_tbl_cfg(json::vector &out) {
    if (options.new_ctx_json) {
        unsigned fmt_width = format ? (format->size + 127)/128 : 0;
        unsigned number_entries = format ? layout_size()/fmt_width * format->groups() * 1024 : 0;
        json::map &tbl = *base_tbl_cfg(out, "match", number_entries);
        common_tbl_cfg(tbl, "exact");
        json::map &match_attributes = tbl["match_attributes"] = json::map();
        tbl.erase("stage_tables");
        json::vector stage_tables;
        json::map stage_tbl;
        stage_tbl["stage_number"] = stage->stageno;
        stage_tbl["stage_table_type"] = "hash_match";
        stage_tbl["logical_table_id"] = logical_id;
        json::vector &hash_functions = stage_tbl["hash_functions"] = json::vector();
        for (auto &hash : input_xbar->get_hash_tables()) {
            json::map hash_function;
            json::vector &hash_bits = hash_function["hash_bits"] = json::vector();
            for (auto &col: hash.second) {
                json::map hash_bit;
                hash_bit["hash_bit"] = col.first; 
                json::vector &bits_to_xor = hash_bit["bits_to_xor"] = json::vector();
                for (const auto &bit: col.second.data) {
                    json::map field;
                    //std::string field_name = input_xbar->get_field_name(bit);
                    //if (!field_name.empty()) remove_name_tail_range(field_name);
                    //field["field_name"] = field_name; 
                    //field["field_bit"] = bit;
                    if (auto ref = input_xbar->get_group_bit(InputXbar::Group(false, hash.first/2), bit + 64*(hash.first&1))) {
                        std::string field_name = ref.name();
                        field["field_bit"] = remove_name_tail_range(field_name) + ref.lobit();
                        field["field_name"] = field_name; }
                    bits_to_xor.push_back(std::move(field)); }
                hash_bits.push_back(std::move(hash_bit)); } 
            hash_functions.push_back(std::move(hash_function)); }
        stage_tbl["action_handles"] = json::vector();
        if (actions) {
            actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
            actions->add_action_format(this, stage_tbl);
        } else if (action && action->actions) {
            action->actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
            action->actions->add_action_format(this, stage_tbl); }
        if (format)
            add_pack_format(stage_tbl, format);
        json::vector &way_stage_tables = stage_tbl["ways"] = json::vector();
        for (auto &way : ways) {
            json::map way_tbl;
            way_tbl["stage_number"] = stage->stageno;
            way_tbl["stage_table_type"] = "hash_way";
            add_pack_format(way_tbl, format);
            way_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg(way);
            way_stage_tables.push_back(std::move(way_tbl)); }
        stage_tables.push_back(std::move(stage_tbl));
        match_attributes["stage_tables"] = std::move(stage_tables);
        match_attributes["match_type"] = "exact";
        tbl["meter_table_refs"] = json::vector();
        tbl["selection_table_refs"] = json::vector();
        tbl["stateful_table_refs"] = json::vector();
    } else {
        unsigned fmt_width = format ? (format->size + 127)/128 : 0;
        unsigned number_entries = format ? layout_size()/fmt_width * format->groups() * 1024 : 0;
        json::map &tbl = *base_tbl_cfg(out, "match_entry", number_entries);
        if (!tbl.count("preferred_match_type"))
            tbl["preferred_match_type"] = "exact";
        json::map &stage_tbl = *add_stage_tbl_cfg(tbl, "hash_match", number_entries);
        if (format)
            add_pack_format(stage_tbl, format);
        if (options.match_compiler)
            stage_tbl["memory_resource_allocation"] = nullptr;
        json::vector match_field_list;
        for (auto field : *input_xbar) {
            if (field.first.ternary) continue;
            match_field_list.push_back( json::map {
                { "name", json::string(field.second.what.name()) },
                { "start_offset", json::number(1023 - field.first.index*128 - field.second.hi) },
                { "start_bit", json::number(field.second.what.lobit()) },
                { "bit_width", json::number(field.second.hi - field.second.lo + 1) }}); }
        canon_field_list(match_field_list);
        stage_tbl["match_group_resource_allocation"] = json::map {
            { "field_list", std::move(match_field_list) } };
        // FIXME -- need action_to_immediate_mapping -- need extra asmgen?
        json::vector &way_stage_tables = stage_tbl["way_stage_tables"] = json::vector();
        for (auto &way : ways) {
            json::map way_tbl;
            way_tbl["stage_number"] = stage->stageno;
            way_tbl["number_entries"] = way.rams.size()/fmt_width * format->groups() * 1024;
            way_tbl["stage_table_type"] = "hash_way";
            add_pack_format(way_tbl, format);
            way_tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg(way);
            way_stage_tables.push_back(std::move(way_tbl)); }
        if (actions) {
            actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
            actions->add_immediate_mapping(stage_tbl);
            actions->add_next_table_mapping(this, stage_tbl);
        } else if (action && action->actions) {
            action->actions->gen_tbl_cfg((tbl["actions"] = json::vector()));
            action->actions->add_immediate_mapping(stage_tbl);
            action->actions->add_next_table_mapping(this, stage_tbl); }
        common_tbl_cfg(tbl, "exact");
        if (idletime)
            idletime->gen_stage_tbl_cfg(stage_tbl);
        else if (options.match_compiler)
            stage_tbl["stage_idletime_table"] = nullptr;
        tbl["uses_versioning"] = format ? format->field("version") != nullptr : false; }
}
