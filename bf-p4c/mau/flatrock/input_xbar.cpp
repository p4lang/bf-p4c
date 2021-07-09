#include "input_xbar.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/phv/phv.h"

namespace Flatrock {

static PHV::Container word_base(PHV::Container c) {
    switch (c.size()) {
    case 8:
        return PHV::Container(c.type(), c.index() & ~3);
    case 16:
        return PHV::Container(c.type(), c.index() & ~1);
    case 32:
        return c;
    default:
        BUG("%s invalid container size %d", c, c.size());
    }
}

void IXBar::find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                       safe_vector<IXBar::Use::Byte *> &alloced,
                       std::multimap<PHV::Container, Loc> &fields,
                       Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use) {
    for (auto &byte : alloc_use) {
        for (auto &l : ValuesForKey(fields, byte.container)) {
            if (l.group == 0 && byte_use[l.byte].second == byte.lo) {
                byte.loc = Loc(0, l.byte);
                break; }
            if (l.group == 1) {
                byte.loc = l;
                break; } }
        if (!byte.loc)
            alloced.push_back(&byte); }
}

bool IXBar::do_alloc(safe_vector<IXBar::Use::Byte *> &to_alloc,
                     Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use) {
    auto next = byte_use.begin();
    for (auto *byte : to_alloc) {
        while (next != byte_use.end() && next->first) next++;
        if (next == byte_use.end()) return false;
        byte->loc = Loc(0, next - byte_use.begin()); }
    return true;
}

bool IXBar::gateway_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                               safe_vector<IXBar::Use::Byte *> &alloced) {
    find_alloc(alloc_use, alloced, gateway_fields, gateway_use);
    return do_alloc(alloced, gateway_use);
}

bool IXBar::exact_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                             safe_vector<IXBar::Use::Byte *> &alloced) {
    find_alloc(alloc_use, alloced, exact_fields, exact_byte_use);
    if (alloced.empty()) return true;
    std::map<PHV::Container, std::set<IXBar::Use::Byte *>> by_word;
    for (auto *byte : alloced) {
        BUG_CHECK(byte->lo % 8U == 0, "misaligned byte for ixbar %s", *byte);
        by_word[word_base(byte->container)].insert(byte);
        byte->search_bus = 0;  // not relevant for flatrock
    }
    // Find the first free byte and word slots
    auto byte = std::find_if(exact_byte_use.begin(), exact_byte_use.end(),
            [](std::pair<PHV::Container, int> &a) { return !a.first; } );
    auto word = std::find_if(exact_word_use.begin(), exact_word_use.end(),
            [](std::pair<PHV::Container, int> &a) { return !a.first; } );
    for (auto &grp : Values(by_word)) {
        if ((grp.size() > 1 && word != exact_word_use.end()) || byte == exact_byte_use.end()) {
            // needs 2+ bytes in the word, or ran out of byte slots, so use a word slot
            if (word == exact_word_use.end()) return false;
            for (auto *b : grp)
                b->loc = Loc(1, word - exact_word_use.begin());
            ++word;
        } else {
            for (auto *b : grp) {
                if (byte == exact_byte_use.end()) return false;
                b->loc = Loc(0, byte - exact_byte_use.begin());
                ++byte; } } }
    return true;
}

bool IXBar::ternary_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                               safe_vector<IXBar::Use::Byte *> &alloced) {
    // find_alloc(alloc_use, alloced, ternary_fields);  -- can't share groups
    auto it = alloc_use.begin();
    for (int grp = 0; grp < TERNARY_GROUPS; grp++) {
        if (ternary_use[grp][0].first) continue;
        for (int b = 0; b < TERNARY_BYTES_PER_GROUP && it != alloc_use.end(); ++b, ++it) {
            // FIXME -- this ignores alignment limits for 16 and 32 bit PHVs in bytes 0..3
            it->loc = Loc(grp, b);
            alloced.push_back(&*it); }
        if (it == alloc_use.end()) break; }
    return it == alloc_use.end();;
}

bool IXBar::action_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                              safe_vector<IXBar::Use::Byte *> &alloced) {
    find_alloc(alloc_use, alloced, action_fields, action_use);
    return do_alloc(alloced, action_use);
}

bool IXBar::allocGateway(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                       const LayoutOption *lo) {
    if (tbl->gateway_rows.empty()) return true;
    LOG1("IXBar::allocGateway(" << tbl->name << ")");
    CollectGatewayFields *collect;

    if (lo && lo->layout.gateway_match) {
        collect = new CollectMatchFieldsAsGateway(phv);
    } else {
        collect = new CollectGatewayFields(phv);
    }

    tbl->apply(*collect);
    if (collect->info.empty()) return true;

    ContByteConversion map_alloc;

    for (auto &info : collect->info) {
        if (!info.second.xor_with.empty()) {
            error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%sTofino5 does not support "
                  "comparisons of two fields in a condition", tbl->srcInfo);
            return false;
        } else if (info.second.need_range) {
            error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%sTofino5 does not support "
                  "range comparisons in a condition", tbl->srcInfo);
            return false; }
        cstring aliasSourceName;
        if (collect->info_to_uses.count(&info.second)) {
            LOG5("Found gateway alias source name");
            aliasSourceName = collect->info_to_uses[&info.second];
        }
        if (aliasSourceName)
            add_use(map_alloc, info.first.field(), phv, tbl, aliasSourceName);
        else
            add_use(map_alloc, info.first.field(), phv, tbl, boost::none);
    }
    safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
    create_alloc(map_alloc, alloc);
    if (!gateway_find_alloc(alloc.use, xbar_alloced)) {
        alloc.clear();
        return false; }
    if (!collect->compute_offsets()) {
        alloc.clear();
        LOG3("collect.compute_offsets failed?");
        return false; }

    alloc.type = Use::GATEWAY;
    alloc.used_by = tbl->build_gateway_name();  // FIXME -- two different, inconsistent names
    update(tbl->name + "$gw", alloc);           // here?  Comes from tofino/input_xbar.cpp org
    return true;
}

void IXBar::setupMatchAlloc(const IR::MAU::Table *tbl, const PhvInfo &phv,
                            ContByteConversion &map_alloc, Use &alloc) {
    std::map<cstring, bitvec> fields_needed;
    KeyInfo ki;
    ki.is_atcam = tbl->layout.atcam;

    // For overlapping keys of different types where one type is "range", the
    // range key takes precedence to correctly set up dirtcam bits
    std::map<std::pair<cstring, le_bitrange>, const IR::MAU::TableKey*> validKeys;
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_match())
            continue;
        le_bitrange bits = {};
        auto *f = phv.field(ixbar_read->expr, &bits);
        if (!f) continue;
        auto idx = std::make_pair(f->name, bits);
        if (validKeys.count(idx)) {
            if (!(ixbar_read->for_range() && !validKeys[idx]->for_range()))
                continue;
        }
        validKeys[idx] = ixbar_read;
    }
    if (validKeys.empty()) return;

    for (auto vkey : validKeys) {
        FieldManagement(&map_alloc, alloc.field_list_order, vkey.second, &fields_needed,
                        phv, ki, tbl);
    }

    create_alloc(map_alloc, alloc);
    LOG3("need " << alloc.use.size() << " bytes for table " << tbl->name);
    return;
}

bool IXBar::exact_find_hash(Use &alloc, const LayoutOption *lo) {
    // FIXME -- TableLayout needs to be updated for Flatrock, laying out as either
    // 2-way cuckoo or BPH match tables.  Tofino-style n-way cuckoo won't work.
    // for now we choose a STM or LAMB unit based on sizing
    int unit = bitvec(exact_hash_inuse).ffz(0);
    if (lo->way.width > 1 || lo->way.match_groups < 2 ||        // must use BPH
        lo->layout.entries > 128*lo->way.match_groups) {        // too big for LAMB
        if (unit >= EXACT_MATCH_STM_UNITS) return false;
        // FIXME -- wide BPH need mulitple STM units.  Some BPH might want LAMB + STM
        // TableLayout needs to tell us when these apply
    } else {
        int lamb = bitvec(exact_hash_inuse).ffz(EXACT_MATCH_STM_UNITS);
        if (lamb < EXACT_MATCH_UNITS) unit = lamb;
    }
    if (unit < EXACT_MATCH_STM_UNITS)
        alloc.hash_table_inputs[unit] = 7;  // FIXME -- group<->hash mapping is wrong for flatrock
    else if (unit < EXACT_MATCH_UNITS)
        alloc.hash_table_inputs[unit] = 3;  // FIXME -- hack some numbers that work for now
    else
        return false;

    // FIXME -- Flatrock cuckoo have exact 2 ways, and BPH do not have ways, so this is
    // mostly irrelevant, but needs to match the layout option.  Hack to make something
    // work until TablePlacement and Memories are updated
    alloc.way_use.resize(lo->way_sizes.size(), Use::Way(0, 0, 0));

    return true;
}

bool IXBar::allocExact(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                       const LayoutOption *lo, const ActionData::Format::Use *af) {
    if (tbl->match_key.empty()) return true;
    LOG1("IXBar::allocExact(" << tbl->name << ")");
    ContByteConversion map_alloc;
    setupMatchAlloc(tbl, phv, map_alloc, alloc.match_ixbar);
    if (!alloc.match_ixbar.use.empty()) {
        safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
        if (!exact_find_hash(alloc.match_ixbar, lo) ||
            !exact_find_alloc(alloc.match_ixbar.use, xbar_alloced)) {
            alloc.match_ixbar.clear();
            return false; }
        alloc.match_ixbar.type = Use::EXACT_MATCH;
        alloc.match_ixbar.used_by = tbl->name;
        update(tbl->name, alloc.match_ixbar); }
    if (lo || af) return true;
    return true;
}

bool IXBar::allocTernary(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                         const LayoutOption *lo, const ActionData::Format::Use *af) {
    if (tbl->match_key.empty()) return true;
    LOG1("IXBar::allocTernary(" << tbl->name << ")");
    ContByteConversion map_alloc;
    setupMatchAlloc(tbl, phv, map_alloc, alloc.match_ixbar);
    if (!alloc.match_ixbar.use.empty()) {
        safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
        if (!ternary_find_alloc(alloc.match_ixbar.use, xbar_alloced)) {
            alloc.match_ixbar.clear();
            return false; }
        alloc.match_ixbar.type = Use::TERNARY_MATCH;
        alloc.match_ixbar.used_by = tbl->name;
        update(tbl->name, alloc.match_ixbar); }
    if (lo || af) return true;
    return true;
}

bool IXBar::allocSelector(const IR::MAU::Selector *sel, const IR::MAU::Table *tbl,
                          const PhvInfo &phv, Use &alloc, cstring name) {
    LOG1("IXBar::allocSelector(" << tbl->name << ")");
    if (sel || tbl || phv.field(0) || alloc.type || name)
        error("flatrock selector not implemented yet");
    return false;
}

bool IXBar::allocStateful(const IR::MAU::StatefulAlu *salu, const IR::MAU::Table *tbl,
                          const PhvInfo &phv, Use &alloc) {
    LOG1("IXBar::allocStateful(" << tbl->name << ")");
    if (salu || tbl || phv.field(0) || alloc.type)
        error("flatrock stateful not implemented yet");
    return false;
}

bool IXBar::allocMeter(const IR::MAU::Meter *meter, const IR::MAU::Table *tbl,
                       const PhvInfo &phv, Use &alloc) {
    LOG1("IXBar::allocMeter(" << tbl->name << ")");
    if (meter || tbl || phv.field(0) || alloc.type)
        error("flatrock meter not implemented yet");
    return false;
}

bool IXBar::allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                       const LayoutOption *lo, const ActionData::Format::Use *af,
                       const attached_entries_t &attached_entries) {
    if (!tbl) return true;
    LOG1("IXBar::allocTable(" << tbl->name << ")");
    if (tbl->layout.atcam) {
        BUG("flatrock ATCAM todo");
    } else if (tbl->layout.proxy_hash) {
        BUG("flatrock proxy hash todo");
    } else {
        if (tbl->layout.ternary) {
            if (!allocTernary(tbl, phv, alloc, lo, af))
                return false;
        } else {
            if (!allocExact(tbl, phv, alloc, lo, af))
                return false;
        }
    }

    for (auto back_at : tbl->attached) {
         auto at_mem = back_at->attached;
         if (attached_entries.at(at_mem).entries <= 0) continue;
         if (auto as = at_mem->to<IR::MAU::Selector>()) {
             if (!allocSelector(as, tbl, phv, alloc.selector_ixbar, tbl->name)) {
                 alloc.clear_ixbar();
                 return false; }
         } else if (auto mtr = at_mem->to<IR::MAU::Meter>()) {
             if (!allocMeter(mtr, tbl, phv, alloc.meter_ixbar)) {
                 alloc.clear_ixbar();
                 return false;
             }
         } else if (auto salu = at_mem->to<IR::MAU::StatefulAlu>()) {
             if (!allocStateful(salu, tbl, phv, alloc.salu_ixbar)) {
                 alloc.clear_ixbar();
                 return false; } } }

    if (!allocGateway(tbl, phv, alloc.gateway_ixbar, lo)) {
        alloc.clear_ixbar();
        return false; }
    return true;
}

void IXBar::update(cstring /* table_name */, const Use &use) {
    if (use.empty()) return;
    switch (use.type) {
    case Use::EXACT_MATCH:
        for (auto &byte : use.use) {
            BUG_CHECK((byte.loc.group|1) == 1, "invalid exact match group %d", byte.loc.group);
            if (byte.loc.group) {
                if (word_base(byte.container) == exact_word_use[byte.loc.byte].first) continue;
                if (exact_word_use[byte.loc.byte].first)
                    BUG("conflicting ixbar allocation at exact match word %d", byte.loc.byte);
                exact_word_use[byte.loc.byte].first = word_base(byte.container);
            } else {
                if (byte == exact_byte_use[byte.loc.byte]) continue;
                if (exact_byte_use[byte.loc.byte].first)
                    BUG("conflicting ixbar allocation at exact match byte %d", byte.loc.byte);
                exact_byte_use[byte.loc.byte] = byte; }
            exact_fields.emplace(byte.container, byte.loc); }
        break;
    case Use::TERNARY_MATCH:
        for (auto &byte : use.use) {
            if (byte == ternary_use[byte.loc]) continue;
            if (ternary_use[byte.loc].first)
                BUG("conflicting ixbar allocation at ternary byte %d:%d", byte.loc.group,
                    byte.loc.byte);
            ternary_use[byte.loc] = byte;
            ternary_fields.emplace(byte.container, byte.loc); }
        break;
    case Use::GATEWAY:
        for (auto &byte : use.use) {
            BUG_CHECK(byte.loc.group == 0, "invalid gateway group %d", byte.loc.group);
            if (byte == gateway_use[byte.loc.byte]) continue;
            if (gateway_use[byte.loc.byte].first)
                BUG("conflicting ixbar allocation at gateway byte %d", byte.loc.byte);
            gateway_use[byte.loc.byte] = byte;
            gateway_fields.emplace(byte.container, byte.loc); }
        break;
    case Use::PROXY_HASH:
    case Use::SELECTOR:
    case Use::METER:
    case Use::STATEFUL_ALU:
    case Use::HASH_DIST:
        for (auto &byte : use.use) {
            BUG_CHECK(byte.loc.group == 0, "invalid action ixbar group %d", byte.loc.group);
            if (byte == action_use[byte.loc.byte]) continue;
            if (action_use[byte.loc.byte].first)
                BUG("conflicting ixbar allocation at action byte %d", byte.loc.byte);
            action_use[byte.loc.byte] = byte;
            action_fields.emplace(byte.container, byte.loc); }
        break;
    default:
        BUG("Unhandled use type %d (%s)", use.type, use.used_for());
    }
}

void IXBar::update(cstring , const HashDistUse &) {
}

void IXBar::add_collisions() {
}

void IXBar::verify_hash_matrix() const {
}

void IXBar::dbprint(std::ostream &) const {
}


}  // namespace Flatrock
