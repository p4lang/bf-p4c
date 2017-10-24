#include "action_bus.h"
#include "algorithm.h"
#include "hex.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

Table::Format::Field *SRamMatchTable::lookup_field(const std::string &n, const std::string &) {
    if (format) return format->field(n);
    if (n == "immediate" && !::Phv::get(gress, n)) {
        static Format::Field default_immediate(nullptr, 32, Format::Field::USED_IMMED);
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
                int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
                assert((unsigned)piece.lo/128 < fmt_width);
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

void SRamMatchTable::setup_word_ixbar_group() {
    word_ixbar_group.resize(match_in_word.size());
    for (unsigned i = 0; i < match_in_word.size(); i++)
        word_ixbar_group[i] = find_in_ixbar(this, match_in_word[i]);
}
