#include "action_bus.h"
#include "algorithm.h"
#include "hex.h"
#include "input_xbar.h"
#include "instruction.h"
#include "mask_counter.h"
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
    if (!rv && n == "immediate" && !::Phv::get(gress, stage->stageno, n)) {
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

/**
* Determining the result bus for an entry, if that entry has no overhead.  The result bus
* is still needed to get the direct address location to find action data / run an
* instruction, etc.
*
* This section maps the allocation scheme used in the TableFormat::Use in p4c, found
* in the function result_bus_words
*/
void SRamMatchTable::no_overhead_determine_result_bus_usage() {
    bitvec result_bus_words;

    for (int i = 0; i < static_cast<int>(group_info.size()); i++) {
        BUG_CHECK(group_info[i].overhead_word < 0);
        if (group_info[i].match_group.size() == 1) {
            group_info[i].result_bus_word = group_info[i].match_group.begin()->first;
            result_bus_words.setbit(group_info[i].result_bus_word);
        }
    }

    for (int i = 0; i < static_cast<int>(group_info.size()); i++) {
        if (group_info[i].overhead_word < 0 && group_info[i].match_group.size() > 1) {
            bool result_bus_set = false;
            for (auto match_group : group_info[i].match_group) {
                if (result_bus_words.getbit(match_group.first)) {
                    group_info[i].result_bus_word = match_group.first;
                    result_bus_set = true;
                }
            }
            if (!result_bus_set)
                group_info[i].result_bus_word = group_info[i].match_group.begin()->first;
            LOG1("  format group " << i << " no overhead multiple match groups");
        }
    }
}

void SRamMatchTable::verify_format() {
    if (format->log2size < 7)
        format->log2size = 7;
    format->pass1(this);
    group_info.resize(format->groups());
    unsigned fmt_width = (format->size + 127)/128;
    if (word_info.size() > fmt_width) {
        // FIXME -- temp workaround for P4C-3436/P4C-3407
        warning(format->lineno, "Match group map wider than format, padding out format");
        format->size = word_info.size() * 128;
        fmt_width = word_info.size();
        while ((1U << format->log2size) < format->size) ++format->log2size; }
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
                format->overhead_word = word;
                LOG5("Setting overhead word for format : " << word);
                info.overhead_bit = f.bit(0)%128;
                info.match_group[word] = -1;
            } else if (info.overhead_word != static_cast<int>(word)) {
                error(format->lineno, "Match overhead group %d split across words", i);
            } else if (word != f.bit(f.size-1)/128 || f.bit(f.size-1)%128 >= limit) {
                error(format->lineno, "Match overhead field %s(%d) not in bottom %d bits",
                      it->first.c_str(), i, limit);
            }
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
        for (unsigned i = 0; i < group_info.size(); i++) {
            if (group_info[i].match_group.size() > 1) {
                for (auto &mgrp : group_info[i].match_group) {
                    if (mgrp.second >= 0) continue;
                    if ((mgrp.second = word_info[mgrp.first].size()) > 1)
                        error(format->lineno, "Too many multi-word groups using word %d",
                              mgrp.first);
                    word_info[mgrp.first].push_back(i);
                }
            }
        }
    } else {
        if (word_info.size() != fmt_width)
            error(mgm_lineno, "Match group map doesn't match format size");
        for (unsigned i = 0; i < word_info.size(); i++) {
            for (unsigned j = 0; j < word_info[i].size(); j++) {
                int grp = word_info[i][j];
                if (grp < 0 || (unsigned)grp >= format->groups()) {
                    error(mgm_lineno, "Invalid group number %d", grp);
                } else if (!group_info[grp].match_group.count(i)) {
                    error(mgm_lineno, "Format group %d doesn't match in word %d", grp, i);
                } else {
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



    for (int i = 0; i < static_cast<int>(group_info.size()); i++) {
        if (group_info[i].match_group.size() == 1) {
            for (auto &mgrp : group_info[i].match_group) {
                if (mgrp.second >= 0) continue;
                if ((mgrp.second = word_info[mgrp.first].size()) > 4)
                    error(format->lineno, "Too many match groups using word %d", mgrp.first);
                word_info[mgrp.first].push_back(i);
            }
        }
        // Determining the result bus word, where the overhead is supposed to be
    }


    bool has_overhead_word = false;
    bool overhead_word_set = false;
    for (int i = 0; i < static_cast<int>(group_info.size()); i++) {
        if (overhead_word_set)
            BUG_CHECK((group_info[i].overhead_word >= 0) == has_overhead_word);
        if (group_info[i].overhead_word >= 0) {
            has_overhead_word = true;
            group_info[i].result_bus_word = group_info[i].overhead_word;
        }
        overhead_word_set = true;
    }


    if (!has_overhead_word)
        no_overhead_determine_result_bus_usage();

    /**
     * Determining the result bus for an entry, if that entry has no overhead.  The result bus
     * is still needed to get the direct address location to find action data / run an
     * instruction, etc.
     *
     * This section maps the allocation scheme used in the TableFormat::Use in p4c, found
     * in the function result_bus_words
     */

    for (int i = 0; i < static_cast<int>(group_info.size()); i++) {
        LOG1("  masks: " << hexvec(group_info[i].tofino_mask));
        for (auto &mgrp : group_info[i].match_group)
            LOG1("    match group " << mgrp.second << " in word " << mgrp.first);
    }

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

    verify_match(fmt_width);
}

/**
 * Guarantees that each match field is a PHV field, which is the standard unless the table is
 * a proxy hash table.
 */
bool SRamMatchTable::verify_match_key() {
    for (auto *match_key : match) {
        auto phv_p = dynamic_cast<Phv::Ref *>(match_key);
        if (phv_p == nullptr) {
            error(match_key->get_lineno(), "A non PHV match key in table %s", name());
            continue;
        }
        auto phv_ref = *phv_p;
        if (phv_ref.check() && phv_ref->reg.mau_id() < 0)
            error(phv_ref.lineno, "%s not accessable in mau", phv_ref->reg.name); }
    auto match_format = format->field("match");
    if (match_format && match.empty()) {
        for (auto ixbar_element : *input_xbar) {
            match.emplace_back(new Phv::Ref(ixbar_element.second.what));
        }
    }
    return error_count == 0;
}

std::unique_ptr<json::map>
        SRamMatchTable::gen_memory_resource_allocation_tbl_cfg(const Way &way) const {
    json::map mra;
    unsigned vpn_ctr = 0;
    unsigned fmt_width = format ? (format->size + 127)/128 : 0;
    if (hash_fn_ids.count(way.group) > 0)
        mra["hash_function_id"] = hash_fn_ids.at(way.group);
    mra["hash_entry_bit_lo"] = way.subgroup*10;
    mra["hash_entry_bit_hi"] = way.subgroup*10 + 9;
    mra["number_entry_bits"] = 10;
    if (way.mask) {
        int lo = ffs(way.mask) - 1, hi = floor_log2(way.mask);
        mra["hash_select_bit_lo"] = EXACT_HASH_FIRST_SELECT_BIT + lo;
        mra["hash_select_bit_hi"] = EXACT_HASH_FIRST_SELECT_BIT + hi;
        if (way.mask != (1 << (hi+1)) - (1 << lo)) {
            warning(way.lineno, "driver does not support discontinuous bits in a way mask");
            mra["hash_select_bit_mask"] = way.mask >> lo; }
    } else {
        mra["hash_select_bit_lo"] = mra["hash_select_bit_hi"] = 40;
    }
    mra["number_select_bits"] = bitcount(way.mask);
    json::vector mem_units;
    json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"] = json::vector();
    for (auto &ram : way.rams) {
        if (mem_units.empty())
            vpn_ctr = layout_get_vpn(ram.first, ram.second);
        else
            BUG_CHECK(vpn_ctr == layout_get_vpn(ram.first, ram.second));
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
    BUG_CHECK(mem_units.empty());
    return json::mkuniq<json::map>(std::move(mra));
}

/**
 * The purpose of this function is to generate the hash_functions JSON node.  The hash functions
 * are for the driver to determine what RAM/RAM line to write the match data into during entry
 * adds.
 *
 * The JSON nodes for the hash functions are the following:
 *     - hash_bits - A vector determining what each bit is calculated from.  Look at the comments
 *           over the function gen_hash_bits
 *     The following two fields are required for High Availability mode and Entry Reads from HW
 *     - ghost_bit_to_hash_bit - A vector describing where the ghost bits are in the hash matrix
 *     - ghost_bit_info - A vector indicating which p4 fields are used as the ghost bits
 *     The following field is only necessary for dynamic_key_masks
 *     - hash_function_number - which of the 8 hash functions this table is using.
 *
 * The order of the hash functions must coordinate to the order of the hash_function_ids used
 * in the Way JSON, as this is how a single way knows which hash function to use for its lookup
 */
void SRamMatchTable::add_hash_functions(json::map &stage_tbl) const {
    auto &ht = input_xbar->get_hash_tables();
    if (ht.size() == 0)
        return;
    // Output cjson node only if hash tables present
    std::map<int, bitvec> hash_bits_per_group;
    for (auto &way : ways) {
        bitvec way_impact;
        way_impact.setrange(way.subgroup * 10, 10);
        bitvec select_impact;
        select_impact |= way.mask;
        way_impact |= select_impact << 40;
        hash_bits_per_group[way.group] |= way_impact;
    }

    // Order so that the order is the same of the hash_function_ids in the ways
    std::vector<std::pair<int, bitvec>> hash_function_to_hash_bits(hash_fn_ids.size());
    for (auto entry : hash_bits_per_group) {
         int hash_fn_id = hash_fn_ids.at(entry.first);
         if (hash_fn_id >= hash_fn_ids.size())
             BUG();
         hash_function_to_hash_bits[hash_fn_id] = entry;
    }

    json::vector &hash_functions = stage_tbl["hash_functions"] = json::vector();
    for (auto entry : hash_function_to_hash_bits) {
        int hash_group_no = entry.first;

        json::map hash_function;
        json::vector &hash_bits = hash_function["hash_bits"] = json::vector();
        hash_function["hash_function_number"] = hash_group_no;
        json::vector &ghost_bits_to_hash_bits = hash_function["ghost_bit_to_hash_bit"]
                                             = json::vector();
        json::vector &ghost_bits_info = hash_function["ghost_bit_info"] = json::vector();
            // Get the hash group data
        auto *hash_group = input_xbar->get_hash_group(hash_group_no);
        if (hash_group) {
            // Process only hash tables used per hash group
            for (unsigned hash_table_id : bitvec(hash_group->tables)) {
                auto hash_table = input_xbar->get_hash_table(hash_table_id);
                gen_hash_bits(hash_table, hash_table_id, hash_bits, hash_group_no, entry.second);
            }
            gen_ghost_bits(hash_group_no, ghost_bits_to_hash_bits, ghost_bits_info);
            hash_functions.push_back(std::move(hash_function));
        }
    }
}

void SRamMatchTable::verify_match(unsigned fmt_width) {
    if (!verify_match_key())
        return;
    // Build the match_by_bit
    unsigned bit = 0;
    for (auto &r : match) {
        match_by_bit.emplace(bit, r);
        bit += r->size();
    }
    auto match_format = format->field("match");
    if ((unsigned)bit != (match_format ? match_format->size : 0))
        warning(match[0]->get_lineno(), "Match width %d for table %s doesn't match format match "
                "width %d", bit, name(), match_format->size);
    match_in_word.resize(fmt_width);
    for (unsigned i = 0; i < format->groups(); i++) {
        Format::Field *match = format->field("match", i);
        if (!match) continue;
        unsigned bit = 0;
        for (auto &piece : match->bits) {
            auto mw = --match_by_bit.upper_bound(bit);
            int lo = bit - mw->first;
            while (mw != match_by_bit.end() &&  mw->first < bit + piece.size()) {
                if ((piece.lo + mw->first - bit) % 8U != (mw->second->slicelobit() % 8U))
                    error(mw->second->get_lineno(), "bit within byte misalignment matching %s in "
                          "match group %d of table %s", mw->second->name(), i, name());
                int hi = std::min((unsigned)mw->second->size()-1, bit+piece.size()-mw->first-1);
                BUG_CHECK((unsigned)piece.lo/128 < fmt_width);
                // merge_phv_vec(match_in_word[piece.lo/128], Phv::Ref(mw->second, lo, hi));

                if (auto phv_p = dynamic_cast<Phv::Ref *>(mw->second)) {
                    auto phv_ref = *phv_p;
                    auto vec = split_phv_bytes(Phv::Ref(phv_ref, lo, hi));
                    for (auto ref : vec) {
                        match_in_word[piece.lo/128].emplace_back(new Phv::Ref(ref));
                    }

                } else if (auto hash_p = dynamic_cast<HashMatchSource *>(mw->second)) {
                    match_in_word[piece.lo/128].push_back(new HashMatchSource(*hash_p));
                } else {
                    BUG();
                }
                lo = 0;
                ++mw;
            }
            bit += piece.size();
        }
    }
    for (unsigned i = 0; i < fmt_width; i++) {
        std::string match_word_info = "[ ";
        std::string sep = "";
        for (auto entry : match_in_word[i]) {
            match_word_info += sep + entry->toString();
            sep = ", ";
        }
        LOG1("  match in word " << i << ": " << match_word_info);
    }
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
    for (auto &match : match_in_word) {
        std::vector<Phv::Ref> phv_ref_match;
        for (auto *source : match) {
            auto phv_ref = *(dynamic_cast<Phv::Ref *>(source));
            phv_ref_match.push_back(phv_ref);
        }
        word_ixbar_group[i++] = phv_ref_match.empty() ? -1 : find_in_ixbar(this, phv_ref_match);
    }
}

#if HAVE_FLATROCK
// flatrock-specific template specializations
#include "flatrock/sram_match.cpp"                              // NOLINT(build/include)
#endif  /* HAVE_FLATROCK */

template<class REGS>
void SRamMatchTable::write_attached_merge_regs(REGS &regs, int bus, int word, int word_group) {
    int group = word_info[word][word_group];
    auto &merge = regs.rams.match.merge;
    for (auto &st : attached.stats) {
        if (group_info[group].result_bus_word == static_cast<int>(word)) {
            merge.mau_stats_adr_exact_shiftcount[bus][word_group]
                = st->to<CounterTable>()->determine_shiftcount(st, group, word, 0);
        } else if (options.match_compiler) {
            /* unused, so should not be set... */
            merge.mau_stats_adr_exact_shiftcount[bus][word_group] = 7;
        }
        break; /* all must be the same, only config once */ }
    for (auto &m : attached.meters) {
        if (group_info[group].overhead_word == static_cast<int>(word)
            || group_info[group].overhead_word == -1) {
            m->to<MeterTable>()->setup_exact_shift(regs, bus, group, word, word_group,
                                                   m, attached.meter_color);
        } else if (options.match_compiler) {
            /* unused, so should not be set... */
            merge.mau_meter_adr_exact_shiftcount[bus][word_group] = 16;
        }
        break; /* all must be the same, only config once */ }
    for (auto &s : attached.statefuls) {
        if (group_info[group].overhead_word == static_cast<int>(word)
            || group_info[group].overhead_word == -1) {
            merge.mau_meter_adr_exact_shiftcount[bus][word_group] =
                s->to<StatefulTable>()->determine_shiftcount(s, group, word, 0);
        } else if (options.match_compiler) {
            /* unused, so should not be set... */
            merge.mau_meter_adr_exact_shiftcount[bus][word_group] = 16; }
        break; /* all must be the same, only config once */ }
}
FOR_ALL_REGISTER_SETS(INSTANTIATE_TARGET_TEMPLATE,
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
            ways.emplace_back(Way{w.lineno, static_cast<int>(w[0].i), static_cast<int>(w[1].i),
                static_cast<int>(w[2].i), {}});
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
        if (kv.value.type == tVEC) {
            for (auto &v : kv.value.vec) {
                 if (v == "hash_group")
                     match.emplace_back(new HashMatchSource(v));
                 else
                     match.emplace_back(new Phv::Ref(gress, stage->stageno, v));
            }
        } else {
            if (kv.value == "hash_group")
                match.emplace_back(new HashMatchSource(kv.value));
            else
                match.emplace_back(new Phv::Ref(gress, stage->stageno, kv.value));
        }
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
    } else {
        warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                value_desc(kv.key), name());
    }
}

void SRamMatchTable::common_sram_checks() {
    alloc_rams(false, stage->sram_use, &stage->sram_search_bus_use);
    if (layout_size() > 0 && !format)
        error(lineno, "No format specified in table %s", name());
    if (!action.set() && !actions)
        error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (actions && !action_bus) action_bus.reset(new ActionBus());
    if (!input_xbar)
        input_xbar.reset(new InputXbar(this));
}

void SRamMatchTable::pass1() {
    LOG1("### SRam match table " << name() << " pass1 " << loc());
    alloc_busses(stage->sram_search_bus_use);
    if (format) {
        verify_format();
        setup_ways();
        determine_word_and_result_bus();
    }
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

void SRamMatchTable::setup_hash_function_ids() {
    unsigned hash_fn_id = 0;
    for (auto &w : ways) {
        if (hash_fn_ids.count(w.group) == 0)
            hash_fn_ids[w.group] = hash_fn_id++;
    }
}

void SRamMatchTable::setup_ways() {
    unsigned fmt_width = (format->size + 127)/128;
    if (ways.empty()) {
        if (Target::TABLES_REQUIRE_WAYS())
            error(lineno, "No ways defined in table %s", name());
    } else if (ways[0].rams.empty()) {
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
            if (table_type() != ATCAM) {
                if ((w.rams.size() != (1U << bitcount(w.mask)) * fmt_width))
                    error(w.lineno, "Depth of way doesn't match number of rams in table %s",
                          name());
            } else {
                // Allowed to not fully match, as the partition index can be set from the
                // control plane
                if (!((w.rams.size() <= (1U << bitcount(w.mask)) * fmt_width) &&
                     (w.rams.size() % fmt_width) == 0))
                    error(w.lineno, "RAMs in ATCAM is not a legal multiple of the format width %s",
                          name());
            }
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
    setup_hash_function_ids();
}

/**
 * Either fills out the word/result bus information each row, if it is not provided directly by
 * the compiler, or verifies that the word/result_bus information matches directly with
 * what has been calculated through the way information provided.
 */
void SRamMatchTable::determine_word_and_result_bus() {
    for (auto &row : layout) {
        int word = -1;
        bool word_set = false;
        for (auto col : row.cols) {
            auto &way = way_map.at(std::make_pair(row.row, col));
            if (word_set) {
                BUG_CHECK(word == way.word);
            } else {
                word = way.word;
                word_set = true;
            }
        }
        if (row.word_initialized()) {
            if (word != row.word)
                error(lineno, "Word on row %d bus %d does not align with word in RAM",
                      row.row, row.bus);
        } else {
            row.word = word;
        }
    }

    for (auto &row : layout) {
        bool result_bus_needed = false;
        if (row.word < 0) {
            // row with no rams -- assume it needs a result bus for the payload
            result_bus_needed = true;
        } else {
            for (auto group_in_word : word_info.at(row.word)) {
                if (group_info[group_in_word].result_bus_word == row.word)
                    result_bus_needed = true;
            }
        }
        if (!row.result_bus_initialized()) {
            if (result_bus_needed)
                row.result_bus = row.bus;
            else
                row.result_bus = -1;
        } else if (!row.result_bus_used() && result_bus_needed) {
            error(row.lineno, "Row %d: Bus %d requires a result bus, but has not been allocated "
                              "one", row.row, row.bus);
        }
        if (row.result_bus >= 0) {
            auto *old = stage->match_result_bus_use[row.row][row.result_bus];
            if (old && old != this)
                error(row.lineno, "inconsistent use of match result bus %d on row %d between "
                      "table %s and %s", row.row, row.result_bus, name(), old->name());
            stage->match_result_bus_use[row.row][row.result_bus] = this;
        }
    }
}

int SRamMatchTable::determine_pre_byteswizzle_loc(MatchSource *ms, int lo, int hi, int word) {
    auto phv_p = dynamic_cast<Phv::Ref *>(ms);
    auto phv_ref = *phv_p;
    Phv::Slice sl(*phv_ref, lo, hi);
    BUG_CHECK(word_ixbar_group[word] >= 0);
    return find_on_ixbar(sl, word_ixbar_group[word]);
}

template<class REGS> void SRamMatchTable::write_regs_vt(REGS &regs) {
    LOG1("### SRam match table " << name() << " write_regs " << loc());
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
            } else if (hash_group != ways[way.way].group || static_cast<int>(word) != way.word) {
                auto first_way = way_map[std::make_pair(row.row, row.cols[0])];
                error(ways[way.way].lineno, "table %s ways #%d and #%d use the same row bus "
                      "(%d.%d) but different %s", name(), first_way.way, way.way, row.row,
                      row.bus, static_cast<int>(word) == way.word ? "hash groups" : "word order");
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
                    if (group_info[group].result_bus_word != way.word) continue;
                    int pos = (next->by_group[group]->bit(0) % 128) - 1;
                    auto &n = ram.match_next_table_bitpos;
                    switch (group_info[group].result_bus_word_group()) {
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
            if (row.result_bus >= 0)
                ram.unit_ram_ctl.match_result_bus_select = 1 << row.result_bus;
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
            int vpn_base = vpn & ~3;
            // FIXME -- temp workaround for P4C-3436 allows unused words in the match
            if (!word_info[way.word].empty())
                vpn_base = (vpn + *min_element(word_info[way.word])) & ~3;
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
        // Loop for determining the config to indicate which bytes from the search bus
        // are compared to the bytes on the RAM line
        if (!row.cols.empty()) {
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
                            int lo = bit - it->first;
                            int hi = lo + bits_in_byte - 1;
                            int bus_loc = determine_pre_byteswizzle_loc(it->second, lo, hi, word);
                            BUG_CHECK(bus_loc >= 0 && bus_loc < 16);
                            for (unsigned b = 0; b < bits_in_byte; b++, fmt_bit++)
                                byteswizzle_ctl[byte][fmt_bit%8U] = 0x10 + bus_loc;
                            bit += bits_in_byte; } }
                    BUG_CHECK(bit == match->size); }
                if (Format::Field *version = format->field("version", i)) {
                    if (version->bit(0)/128U != word) continue;
                    ///> P4C-1552: if no match, but a version/valid is, the vh_xbar needs to be
                    ///> enabled.  This was preventing anything from running
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
        }
        /* setup match central config to extract results of the match */
        BUG_CHECK(row.result_bus_initialized());
        ssize_t r_bus = row.result_bus_used() ? row.row*2 + row.result_bus : -1;
        // If the result bus is not to be used, then the registers are not necessary to set up
        // for shift/mask/default etc.
        /* FIXME -- factor this where possible with ternary match code */
        if (action) {
            if (auto adt = action->to<ActionTable>()) {
                if (r_bus >= 0) {
                    /* FIXME -- support for multiple sizes of action data? */
                    merge.mau_actiondata_adr_mask[0][r_bus] = adt->determine_mask(action);
                    merge.mau_actiondata_adr_vpn_shiftcount[0][r_bus]
                        = adt->determine_vpn_shiftcount(action);
                }
            }
        }

        if (format && word < word_info.size()) {
            for (unsigned word_group = 0; word_group < word_info[word].size(); word_group++) {
                int group = word_info[word][word_group];
                if (group_info[group].result_bus_word == static_cast<int>(word)) {
                    BUG_CHECK(r_bus >= 0);
                    if (format->immed) {
                        BUG_CHECK(format->immed->by_group[group]->bit(0)/128U == word);
                        merge.mau_immediate_data_exact_shiftcount[r_bus][word_group] =
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
                        merge.mau_action_instruction_adr_exact_shiftcount[r_bus][word_group]
                            = shiftcount;
                    }
                }
                /* FIXME -- factor this where possible with ternary match code */
                if (action) {
                    if (group_info[group].result_bus_word == static_cast<int>(word)) {
                        BUG_CHECK(r_bus >= 0);
                        merge.mau_actiondata_adr_exact_shiftcount[r_bus][word_group]
                            = action->determine_shiftcount(action, group, word, 0);
                    }
                }
                if (attached.selector) {
                    if (group_info[group].result_bus_word == static_cast<int>(word)) {
                        BUG_CHECK(r_bus >= 0);
                        auto sel = get_selector();
                        merge.mau_meter_adr_exact_shiftcount[r_bus][word_group] =
                            sel->determine_shiftcount(attached.selector, group, word, 0);
                        merge.mau_selectorlength_shiftcount[0][r_bus] =
                            sel->determine_length_shiftcount(attached.selector_length, group, word);
                        merge.mau_selectorlength_mask[0][r_bus] =
                            sel->determine_length_mask(attached.selector_length);
                        merge.mau_selectorlength_default[0][r_bus] =
                            sel->determine_length_default(attached.selector_length);
                    }
                }
                if (idletime) {
                    if (group_info[group].result_bus_word == static_cast<int>(word)) {
                        BUG_CHECK(r_bus >= 0);
                        merge.mau_idletime_adr_exact_shiftcount[r_bus][word_group] =
                            idletime->direct_shiftcount();
                    }
                }
                if (r_bus >= 0)
                    write_attached_merge_regs(regs, r_bus, word, word_group);
            }
        } else if (format) {
            // If we have a result bus without any attached memories, program
            // the registers on this row because a subset of the registers have been
            // programmed elsewhere and it can break things if we have a partial configuration.
            // FIXME: avoid programming any registers if we don't actually use the result bus.
            if (r_bus >= 0)
                write_attached_merge_regs(regs, r_bus, 0, 0);
        }
        for (auto col : row.cols) {
            int word_group = 0;
            for (int group : word_info[word]) {
                int result_bus_word = group_info[group].result_bus_word;
                if (int(word) == result_bus_word) {
                    BUG_CHECK(r_bus >= 0);
                    merge.col[col].row_action_nxtable_bus_drive[row.row] |= 1 << (r_bus % 2); }
                if (word_group < 2) {
                    auto &way = way_map[std::make_pair(row.row, col)];
                    int idx = way.index + word - result_bus_word;
                    int overhead_row = ways[way.way].rams[idx].first;
                    auto &hitmap_ixbar = merge.col[col].hitmap_output_map[2*row.row + word_group];
                    setup_muxctl(hitmap_ixbar,
                                 overhead_row*2 + group_info[group].result_bus_word_group());
                }
                ++word_group;
            }
            // setup_muxctl(merge.col[col].hitmap_output_map[bus],
            //                layout[index+word].row*2 + layout[index+word].bus);
        }
        // if (gress == EGRESS)
        //     merge.exact_match_delay_config.exact_match_bus_thread |= 1 << bus;
        if (r_bus >= 0) {
            merge.exact_match_phys_result_en[r_bus/8U] |= 1U << (r_bus%8U);
            merge.exact_match_phys_result_thread[r_bus/8U] |= timing_thread(gress) << (r_bus%8U);
            if (stage->tcam_delay(gress))
                merge.exact_match_phys_result_delay[r_bus/8U] |= 1U << (r_bus%8U);
        }
    }

    merge.exact_match_logical_result_en |= 1 << logical_id;
    if (stage->tcam_delay(gress) > 0)
        merge.exact_match_logical_result_delay |= 1 << logical_id;
    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}
FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
    void SRamMatchTable::write_regs, (mau_regs &regs), { write_regs_vt(regs); })

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
    LOG3("Adding fields for " << name << " - " << field << " to pack format for SRAM table "
            << this->name() << " in action : " << act);
    unsigned bit = 0;
    for (auto &piece : field.bits) {
        auto mw = --match_by_bit.upper_bound(bit);
        int lo = bit - mw->first;
        int lsb_mem_word_idx = piece.lo / MEM_WORD_WIDTH;
        int msb_mem_word_idx = piece.hi / MEM_WORD_WIDTH;
        int offset = piece.lo % MEM_WORD_WIDTH;
        while (mw != match_by_bit.end() &&  mw->first < bit + piece.size()) {
            std::string source = "";
            std::string immediate_name = "";
            std::string mw_name = mw->second->name();
            int start_bit = 0;

            get_cjson_source(mw_name, source, start_bit);
            if (source == "")
                error(lineno, "Cannot determine proper source for field %s", name.c_str());
            std::string field_name, global_name = "";
            std::string match_mode;
            if (auto phv_p = dynamic_cast<Phv::Ref *>(mw->second)) {
                field_name = mw->second->name();
                // If the name has a slice in it, remove it and add the lo bit of
                // the slice to field_bit.  This takes the place of
                // canon_field_list(), rather than extracting the slice component
                // of the field name, if present, and appending it to the key name.
                int slice_offset = remove_name_tail_range(field_name);
                start_bit = lo + slice_offset + mw->second->fieldlobit();
                global_name = field_name;
                auto p = find_p4_param(field_name, "", start_bit);
                if (!p && !p4_params_list.empty()) {
                    warning(lineno, "Cannot find field name %s in p4_param_order "
                            "for table %s", field_name.c_str(), this->name());
                } else if (p && !p->key_name.empty()) {
                    field_name = p->key_name;
                }
                match_mode = get_match_mode(*phv_p, mw->first);
            } else if (dynamic_cast<HashMatchSource *>(mw->second)) {
                field_name = "--proxy_hash--";
                match_mode = "unused";
                start_bit = mw->second->fieldlobit();
            } else {
                BUG();
            }

            field_list.push_back(json::map {
                    { "field_name", json::string(field_name) },
                    { "global_name", json::string(global_name) },
                    { "source", json::string(source) },
                    { "lsb_mem_word_offset", json::number(offset) },
                    { "start_bit", json::number(start_bit) },
                    { "immediate_name", json::string(immediate_name) },
                    { "lsb_mem_word_idx", json::number(lsb_mem_word_idx) },
                    { "msb_mem_word_idx", json::number(msb_mem_word_idx) },
                    // FIXME-JSON
                    { "match_mode", json::string(match_mode) },
                    { "enable_pfe", json::False() },  // FIXME-JSON
                    { "field_width", json::number(mw->second->size()) }});
            LOG5("Adding json field  " << field_list.back());
            offset += mw->second->size();
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
        action->actions->add_action_format(this, stage_tbl);
    }
}

unsigned SRamMatchTable::get_format_width() const {
    return format ? (format->size + 127)/128 : 0;
}

unsigned SRamMatchTable::get_number_entries() const {
    unsigned fmt_width = get_format_width();
    unsigned number_entries = 0;
    if (format)
        number_entries = layout_size()/fmt_width * format->groups() * entry_ram_depth();
    return number_entries;
}

json::map* SRamMatchTable::add_common_sram_tbl_cfgs(json::map &tbl,
        std::string match_type, std::string stage_table_type) const {
    common_tbl_cfg(tbl);
    json::map &match_attributes = tbl["match_attributes"];
    json::vector &stage_tables = match_attributes["stage_tables"];
    json::map *stage_tbl_ptr =
        add_stage_tbl_cfg(match_attributes, stage_table_type.c_str() , get_number_entries());
    json::map &stage_tbl = *stage_tbl_ptr;
    // This is a only a glass required field, as it is only required when no default action
    // is specified, which is impossible for Brig through p4-16
    stage_tbl["default_next_table"] = Stage::end_of_pipe();
    match_attributes["match_type"] = match_type;
    add_hash_functions(stage_tbl);
    add_action_cfgs(tbl, stage_tbl);
    add_result_physical_buses(stage_tbl);
    MatchTable::gen_idletime_tbl_cfg(stage_tbl);
    merge_context_json(tbl, stage_tbl);
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
