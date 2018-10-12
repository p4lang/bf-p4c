#include "action_bus.h"
#include "algorithm.h"
#include "hex.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

Table::Format::Field *SRamMatchTable::lookup_field(const std::string &n,
        const std::string &act) const {
    auto *rv = format ? format->field(n) : nullptr;
    if (!rv && gateway)
        rv = gateway->lookup_field(n, act);
    if (!rv && !act.empty()) {
        if (auto call = get_action())
            rv = call->lookup_field(n, act); }
    if (!rv && n == "immediate" && !::Phv::get(gress, n)) {
        static Format::Field default_immediate(nullptr, 32, Format::Field::USED_IMMED);
        rv = &default_immediate; }
    return rv;
}

/* calculate the 18-bit byte/nybble mask tofino uses for matching in a 128-bit word */
static unsigned tofino_bytemask(int lo, int hi) {
    unsigned rv = 0;
    for (unsigned i = lo/4U; i <= hi/4U; i++)
        rv |= 1U << (i < 28 ? i/2 : i-14);
    return rv;
}

void SRamMatchTable::verify_format() {
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
            Format::Field &f = it->second;
            if (it->first == "match" || it->first == "version" || it->first == "proxy_hash")
                continue;
            if (f.bits.size() != 1) {
                error(format->lineno, "Can't deal with split field %s", it->first.c_str());
                continue; }
            unsigned limit = it->first == "next" ? 40 : 64;
            unsigned word = f.bit(0)/128;
            if (info.overhead_word < 0) {
                info.overhead_word = word;
                info.overhead_bit = f.bit(0)%128;
                info.match_group[word] = -1;
            } else if (info.overhead_word != (int)word)
                error(format->lineno, "Match overhead group %d split across words", i);
            else if (word != f.bit(f.size-1)/128 || f.bit(f.size-1)%128 >= limit)
                error(format->lineno, "Match overhead field %s(%d) not in bottom %d bits",
                      it->first.c_str(), i, limit);
            if ((unsigned)info.overhead_bit > f.bit(0)%128)
                info.overhead_bit = f.bit(0)%128; } }
    if (word_info.empty()) {
        word_info.resize(fmt_width);
        if (format->field("next")) {
            /* 'next' for match group 0 must be in bit 0, so make the format group with
             * overhead in bit 0 match group 0 in its overhead word */
            for (unsigned i = 0; i < group_info.size(); i++) {
                if (group_info[i].overhead_bit == 0) {
                    BUG_CHECK(error_count > 0 || word_info[group_info[i].overhead_word].empty());
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
                        if (next->bit(0)/128 != i) continue;
                        static unsigned limit[5] = { 0, 8, 32, 32, 32 };
                        unsigned bit = next->bit(0)%128U;
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
                                if (version->bit(0) == word*128 + (nibble^1)*4 + 112) {
                                    LOG1("      skip group " << group << " (version)");
                                    continue; } }
                            group_info[group].tofino_mask[word] |= 1 << (14 + nibble);
                            LOG1("      adding to group " << group); } } } } }

    if (table_type() == ATCAM) {
        int overhead_word = -1;
        int overhead_word_set = false;
        for (int i = 0; i < (int)group_info.size(); i++) {
            if (!overhead_word_set) {
                overhead_word = group_info[i].overhead_word;
            } else if (overhead_word != group_info[i].overhead_word) {
                error(format->lineno, "ATCAM tables can at most have only one overhead word");
                return;
            }
        }

        if (overhead_word < 0)
            overhead_word = word_info.size() - 1;

        if (word_info[overhead_word].size() != group_info.size()) {
            error(format->lineno, "ATCAM tables do not chain to the same overhead word");
            return;
        }

        for (int i = 0; i < (int)word_info[overhead_word].size(); i++) {
            if (i != word_info[overhead_word][i]) {
                error(format->lineno, "ATCAM priority not correctly formatted in the compiler");
                return;
            }
        }
    }

    for (auto &r : match) {
        r.check();
        if (r->reg.mau_id() < 0)
            error(r.lineno, "%s not accessable in mau", r->reg.name); }
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
                if ((piece.lo + mw->first - bit) % 8U != (mw->second->lo % 8U))
                    error(mw->second.lineno, "bit within byte misalignment matching %s in "
                          "match group %d of table %s", mw->second.name(), i, name());
                int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
                BUG_CHECK((unsigned)piece.lo/128 < fmt_width);
                //merge_phv_vec(match_in_word[piece.lo/128], Phv::Ref(mw->second, lo, hi));
                append(match_in_word[piece.lo/128],
                       split_phv_bytes(Phv::Ref(mw->second, lo, hi)));
                lo = 0;
                ++mw; }
            bit += piece.size(); } }
    for (unsigned i = 0; i < fmt_width; i++)
        LOG1("  match in word " << i << ": " << match_in_word[i]);
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
            InputXbar::Group ixbar_group(InputXbar::Group::EXACT, group);
            for (auto *in : table->stage->ixbar_use[ixbar_group]) {
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

void SRamMatchTable::setup_word_ixbar_group() {
    word_ixbar_group.resize(match_in_word.size());
    unsigned i = 0;
    for (auto &match : match_in_word)
        word_ixbar_group[i++] = match.empty() ? -1 : find_in_ixbar(this, match);
}

template<class REGS>
void SRamMatchTable::write_attached_merge_regs(REGS &regs, int bus, int word, int word_group) {
    int group = word_info[word][word_group];
    auto &merge = regs.rams.match.merge;
    for (auto &st : attached.stats) {
        if (group_info[group].overhead_word == (int)word
            // FIXME: If no match overhead, no overhead word assigned?
            || group_info[group].overhead_word == -1) {
            merge.mau_stats_adr_exact_shiftcount[bus][word_group]
                = st->to<CounterTable>()->determine_shiftcount(st, group, word, 0);
        } else if (options.match_compiler) {
            /* unused, so should not be set... */
            merge.mau_stats_adr_exact_shiftcount[bus][word_group] = 7;
        }
        break; /* all must be the same, only config once */ }
    for (auto &m : attached.meters) {
        if (group_info[group].overhead_word == (int)word
            || group_info[group].overhead_word == -1) {
            int shiftcount = m->to<MeterTable>()->determine_shiftcount(m, group, word, 0);
            merge.mau_meter_adr_exact_shiftcount[bus][word_group] = shiftcount;
            if (m->uses_colormaprams()) {
                int huffman_bits_out = 0;
                if (m.args[0].field() ||
                    (m.args[0].name() && strcmp(m.args[0].name(), "$DIRECT") == 0)) {
                    huffman_bits_out = METER_LOWER_HUFFMAN_BITS;
                }
                merge.mau_idletime_adr_exact_shiftcount[bus][word_group]
                    = std::max(shiftcount - METER_ADDRESS_ZERO_PAD + huffman_bits_out, 0);
                merge.mau_payload_shifter_enable[0][bus].idletime_adr_payload_shifter_en = 1;
            }
        } else if (options.match_compiler) {
            /* unused, so should not be set... */
            merge.mau_meter_adr_exact_shiftcount[bus][word_group] = 16;
        }
        break; /* all must be the same, only config once */ }
    for (auto &s : attached.statefuls) {
        if (group_info[group].overhead_word == (int)word
            || group_info[group].overhead_word == -1) {
            merge.mau_meter_adr_exact_shiftcount[bus][word_group] =
                s->to<StatefulTable>()->determine_shiftcount(s, group, word, 0);
        } else if (options.match_compiler) {
            /* unused, so should not be set... */
            merge.mau_meter_adr_exact_shiftcount[bus][word_group] = 16; }
        break; /* all must be the same, only config once */ }
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE,
                void SRamMatchTable::write_attached_merge_regs, mau_regs &, int, int, int)

void SRamMatchTable::common_sram_setup(pair_t &kv, const VECTOR(pair_t) &data) {
    if (kv.key == "ways") {
        if (!CHECKTYPE(kv.value, tVEC)) return;
        for (auto &w : kv.value.vec) {
            if (!CHECKTYPE(w, tVEC)) return;
            if (w.vec.size < 3 || w[0].type != tINT || w[1].type != tINT || w[2].type != tINT ||
                w[0].i < 0 || w[1].i < 0 || w[2].i < 0 || w[0].i >= EXACT_HASH_GROUPS ||
                w[1].i >= EXACT_HASH_ADR_GROUPS || w[2].i >= (1 << EXACT_HASH_SELECT_BITS)) {
                error(w.lineno, "invalid way descriptor");
                continue; }
            ways.emplace_back(Way{w.lineno, (int)w[0].i, (int)w[1].i, (int)w[2].i, {}});
            if (w.vec.size > 3) {
                for (int i = 3; i < w.vec.size; i++) {
                    if (!CHECKTYPE(w[i], tVEC)) return;
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
                value_desc(kv.key), name());
}

void SRamMatchTable::common_sram_checks() {
    alloc_rams(false, stage->sram_use, &stage->sram_match_bus_use);
    if (layout_size() > 0 && !format)
        error(lineno, "No format specified in table %s", name());
    if (!action.set() && !actions)
        error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (actions && !action_bus) action_bus = new ActionBus();
    if (!input_xbar)
        input_xbar = new InputXbar(this);
}

void SRamMatchTable::pass1() {
    LOG1("### SRam match table " << name() << " pass1");
    alloc_busses(stage->sram_match_bus_use);
    if (format) {
        verify_format();
        setup_ways(); }
    MatchTable::pass1();
    if (action_enable >= 0)
        if (action.args.size() < 1 || action.args[0].size() <= (unsigned)action_enable)
            error(lineno, "Action enable bit %d out of range for action selector", action_enable);
    if (gateway) {
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
}

void SRamMatchTable::setup_ways() {
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
                    BUG_CHECK(ridx + word < layout.size());
                    auto &row = layout[ridx + word];
                    BUG_CHECK(cidx < row.cols.size());
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
}

template<class REGS> void SRamMatchTable::write_regs(REGS &regs) {
    LOG1("### SRam match table " << name() << " write_regs");
    MatchTable::write_regs(regs, 0, this);
    auto &merge = regs.rams.match.merge;
    unsigned fmt_width = format ? (format->size + 127)/128 : 0;
    bitvec match_mask;
    match_mask.setrange(0, 128*fmt_width);
    version_nibble_mask.setrange(0, 32*fmt_width);
    for (unsigned i = 0; format && i < format->groups(); i++) {
        if (Format::Field *match = format->field("match", i)) {
            for (auto &piece : match->bits)
                match_mask.clrrange(piece.lo, piece.hi+1-piece.lo); }
        if (Format::Field *version = format->field("version", i)) {
            match_mask.clrrange(version->bit(0), version->size);
            version_nibble_mask.clrrange(version->bit(0)/4, 1); } }
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
            if (options.match_compiler || ways[way.way].mask) {
                // Glass always sets this.  When mask == 0, bank will also be 0, and the
                // comparison will always match, so the bus need not be read (inp_sel).
                // CSR suggests it should NOT be set if not needed to save power.
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
                    int pos = (next->by_group[group]->bit(0) % 128) - 1;
                    auto &n = ram.match_next_table_bitpos;
                    switch(group_info[group].word_group) {
                    case 0: break;
                    case 1: n.match_next_table1_bitpos = pos; break;
                    case 2: n.match_next_table2_bitpos = pos; break;
                    case 3: n.match_next_table3_bitpos = pos; break;
                    case 4: n.match_next_table4_bitpos = pos; break;
                    default: BUG(); } } }

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
            case INGRESS: case GHOST: unitram_config.unitram_ingress = 1; break;
            case EGRESS: unitram_config.unitram_egress = 1; break;
            default: BUG(); }
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

            int word_group = 0;
            for (int group : word_info[way.word]) {
                unsigned mask = group_info[group].tofino_mask[way.word];
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = ~mask & 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = ~(mask >> 14) & 0xf;
                word_group++; }
            for (; word_group < 5; word_group++) {
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = 0xf; }
            if (gress == EGRESS)
                regs.cfg_regs.mau_cfg_uram_thread[col/4U] |= 1U << (col%4U*8U + row.row);
            rams_row.emm_ecc_error_uram_ctl[timing_thread(gress)] |= 1U << (col - 2); }
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
                        BUG_CHECK(word_ixbar_group[word] >= 0);
                        int bus_loc = find_on_ixbar(sl, word_ixbar_group[word]);
                        BUG_CHECK(bus_loc >= 0 && bus_loc < 16);
                        for (unsigned b = 0; b < bits_in_byte; b++, fmt_bit++)
                            byteswizzle_ctl[byte][fmt_bit%8U] = 0x10 + bus_loc;
                        bit += bits_in_byte; } }
                BUG_CHECK(bit == match->size); }
            if (Format::Field *version = format->field("version", i)) {
                if (version->bit(0)/128U != word) continue;
                // don't need to enable vh_xbar just for version/valid, but do need to enable
                // at least one word of vh_xbar always, so use this one if there's no match
                if (!format->field("match", i))
                    using_match = true;
                for (unsigned j = 0; j < version->size; ++j) {
                    unsigned bit = version->bit(j);
                    unsigned byte = (bit%128)/8;
                    byteswizzle_ctl[byte][bit%8U] = 8; } } }
        if (using_match) {
            auto &vh_xbar_ctl = rams_row.vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl;
            if (word_ixbar_group[word] >= 0) {
                setup_muxctl(vh_xbar_ctl,  word_ixbar_group[word]);
            } else {
                // Need the bus for version/valid, but don't care what other data is on it.  So
                // just set the enable without actually selecting an input -- if another table
                // is sharing the bus, it will set it, otherwise we'll get ixbar group 0
                vh_xbar_ctl.exactmatch_row_vh_xbar_enable = 1; }
            vh_xbar_ctl.exactmatch_row_vh_xbar_thread = timing_thread(gress); }
        /* setup match central config to extract results of the match */
        unsigned bus = row.row*2 + row.bus;
        /* FIXME -- factor this where possible with ternary match code */
        if (action) {
            if (auto adt = action->to<ActionTable>()) {
                /* FIXME -- support for multiple sizes of action data? */
                merge.mau_actiondata_adr_mask[0][bus] = adt->determine_mask(action);
                merge.mau_actiondata_adr_vpn_shiftcount[0][bus]
                    = adt->determine_vpn_shiftcount(action);
            }
        }
        if (attached.selector) {
            merge.mau_selectorlength_default[0][bus] = 1;
            /* FIXME: The compiler currently doesn't handle selector length
            if (attached.selector.args.size() == 1)
            else {
                int width = attached.selector.args[1].size();
                if (attached.selector.args.size() == 3)
                    width += attached.selector.args[2].size();
                merge.mau_selectorlength_mask[0][bus] = (1 << width) - 1; } }
            */
        }
        for (unsigned word_group = 0; format && word_group < word_info[word].size(); word_group++) {
            int group = word_info[word][word_group];
            if (group_info[group].overhead_word == (int)word) {
                if (format->immed) {
                    BUG_CHECK(format->immed->by_group[group]->bit(0)/128U == word);
                    merge.mau_immediate_data_exact_shiftcount[bus][word_group] =
                        format->immed->by_group[group]->bit(0) % 128; }
                if (instruction) {
                    int shiftcount = 0;
                    if (auto field = instruction.args[0].field()) {
                        assert(field->by_group[group]->bit(0)/128U == word);
                        shiftcount = field->by_group[group]->bit(0) % 128U;
                    } else if (auto field = instruction.args[1].field()) {
                        assert(field->by_group[group]->bit(0)/128U == word);
                        shiftcount = field->by_group[group]->bit(0) % 128U;
                    }
                    merge.mau_action_instruction_adr_exact_shiftcount[bus][word_group] = shiftcount;
                }
            }
            /* FIXME -- factor this where possible with ternary match code */
            if (action) {
                if (group_info[group].overhead_word == (int)word ||
                    group_info[group].overhead_word == -1) {
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group]
                        = action->determine_shiftcount(action, group, word, 0);
                }
            }
            if (attached.selector) {
                if (group_info[group].overhead_word == (int)word) {
                    merge.mau_meter_adr_exact_shiftcount[bus][word_group] =
                        get_selector()->determine_shiftcount(attached.selector, group, word, 0);
                }
            }
            if (idletime)
                merge.mau_idletime_adr_exact_shiftcount[bus][word_group] =
                    idletime->direct_shiftcount();
            write_attached_merge_regs(regs, bus, word, word_group); }
        for (auto col : row.cols) {
            int word_group = 0;
            for (int group : word_info[word]) {
                int overhead_word = group_info[group].overhead_word;
                if (overhead_word < 0)
                    overhead_word = group_info[group].match_group.rbegin()->first;
                if (int(word) == overhead_word) {
                    merge.col[col].row_action_nxtable_bus_drive[row.row] |= 1 << row.bus;
                }
                if (word_group < 2) {
                    auto &way = way_map[std::make_pair(row.row, col)];
                    int idx = way.index + word - overhead_word;
                    int overhead_row = ways[way.way].rams[idx].first;
                    auto &hitmap_ixbar = merge.col[col].hitmap_output_map[2*row.row + word_group];
                    setup_muxctl(hitmap_ixbar, overhead_row*2 + group_info[group].word_group);
                }
                ++word_group;
            }
            /*setup_muxctl(merge.col[col].hitmap_output_map[bus],
                           layout[index+word].row*2 + layout[index+word].bus); */ }
        //if (gress == EGRESS)
        //    merge.exact_match_delay_config.exact_match_bus_thread |= 1 << bus;
        merge.exact_match_phys_result_en[bus/8U] |= 1U << (bus%8U);
        merge.exact_match_phys_result_thread[bus/8U] |= timing_thread(gress) << (bus%8U);
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


std::string SRamMatchTable::get_match_mode(const Phv::Ref &pref, int offset) const {
    return "unused";
}

void SRamMatchTable::add_field_to_pack_format(json::vector &field_list, int basebit,
                                               std::string name,
                                               const Table::Format::Field &field,
                                               const Table::Actions::Action *act) const {
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
            // get_cjson_source(mw_name, act, source, immediate_name, start_bit);
            get_cjson_source(mw_name, source, start_bit);
            if (source == "")
                error(lineno, "Cannot determine proper source for field %s", name.c_str());
            int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
            int width = hi - lo + 1;
            std::string field_name = mw->second.name();
            remove_aug_names(field_name);

            // If the name has a slice in it, remove it and add the lo bit of
            // the slice to field_bit.  This takes the place of
            // canon_field_list(), rather than extracting the slice component
            // of the field name, if present, and appending it to the key name.
            int slice_offset = remove_name_tail_range(field_name);

            // Look up this field in the param list to get a custom key
            // name, if present.
            std::string key_name = field_name;
            auto p = find_p4_param(field_name);
            if (!p && !p4_params_list.empty()) {
                warning(lineno, "Cannot find field name %s in p4_param_order "
                        "for table %s", field_name.c_str(), this->name());
            } else if (p && !p->key_name.empty()) {
                key_name = p->key_name;
                remove_aug_names(key_name); }

            field_list.push_back( json::map {
                    { "field_name", json::string(key_name) },
                    { "source", json::string(source) },
                    { "lsb_mem_word_offset", json::number(offset) },
                    { "start_bit", json::number(start_bit + lo + slice_offset + mw->second.lobit()) },
                    { "immediate_name", json::string(immediate_name) },
                    { "lsb_mem_word_idx", json::number(lsb_mem_word_idx) },
                    { "msb_mem_word_idx", json::number(msb_mem_word_idx) },
                    { "match_mode", json::string(get_match_mode(mw->second, mw->first)) }, //FIXME-JSON
                    { "enable_pfe", json::False() }, //FIXME-JSON
                    { "field_width", json::number(width) }});
            offset += width;
            lo = 0;
            ++mw; }
        bit += piece.size(); }
}

void SRamMatchTable::add_action_cfgs(json::map &tbl, json::map &stage_tbl) const {
   if (actions) {
       actions->gen_tbl_cfg(tbl["actions"]);
       actions->add_action_format(this, stage_tbl);
   } else if (action && action->actions) {
       action->actions->gen_tbl_cfg(tbl["actions"]);
       action->actions->add_action_format(this, stage_tbl); }
}

unsigned SRamMatchTable::get_format_width() const {
    return format ? (format->size + 127)/128 : 0;
}

unsigned SRamMatchTable::get_number_entries() const {
    unsigned fmt_width = get_format_width();
    unsigned number_entries = 0;
    if (format)
        number_entries = layout_size()/fmt_width * format->groups() * 1024;
    return number_entries;
}

json::map* SRamMatchTable::add_common_sram_tbl_cfgs(json::map &tbl,
        std::string match_type, std::string stage_table_type) const {
    common_tbl_cfg(tbl);
    json::map &match_attributes = tbl["match_attributes"];
    json::vector &stage_tables = match_attributes["stage_tables"];
    json::map *stage_tbl_ptr=
        add_stage_tbl_cfg(match_attributes, stage_table_type.c_str() , get_number_entries());
    json::map &stage_tbl = *stage_tbl_ptr;
    stage_tbl["default_next_table"] = default_next_table_id;
    match_attributes["match_type"] = match_type;
    add_hash_functions(stage_tbl);
    add_action_cfgs(tbl, stage_tbl);
    add_result_physical_buses(stage_tbl);
    MatchTable::gen_idletime_tbl_cfg(stage_tbl);
    if (context_json)
        stage_tbl.merge(*context_json);
    add_all_reference_tables(tbl);
    return stage_tbl_ptr;
}

void SRamMatchTable::alloc_vpns() {
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
