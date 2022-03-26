#include "input_xbar.h"
#include "bf-p4c/logging/resources.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/phv/phv.h"

namespace Flatrock {

IXBar::Use &IXBar::getUse(autoclone_ptr<::IXBar::Use> &ac) {
    Use *rv;
    if (ac) {
        rv = dynamic_cast<Use *>(ac.get());
        BUG_CHECK(rv, "Wrong kind of IXBar::Use present");
    } else {
        ac.reset((rv = new Use)); }
    return *rv;
}

const IXBar::Use &IXBar::getUse(const autoclone_ptr<::IXBar::Use> &ac) {
    BUG_CHECK(ac, "Null autoclone");
    const Use *rv = dynamic_cast<const Use *>(ac.get());
    BUG_CHECK(rv, "Wrong kind of IXBar::Use present");
    return *rv;
}

IXBar::Use::TotalBytes IXBar::Use::match_hash(safe_vector<int> *hash_groups) const {
    TotalBytes rv = ::IXBar::Use::match_hash(hash_groups);
    if (!rv.empty()) return rv;

    // FIXME -- a hack to make something that will make TableFormat::analyze_layout_option
    // not crash until it gets updates for flatrock
    auto rv_index = new safe_vector<Byte>(use);
    rv.push_back(rv_index);
    if (hash_groups)
        hash_groups->push_back(exact_unit);
    return rv;
}

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

// bitmasks to separate the properly aligned slots for things in even and odd bytes
// of 16- and 32-bit PHEs.  64 bits is bigger than any set of bytes we need here.
static bitvec halfword_align[2] = { bitvec(0x5555555555555555ULL), bitvec(0xaaaaaaaaaaaaaaaaULL) };

static int find_free_byte(bitvec free, IXBar::Use::Byte *byte) {
    if (byte->container.size() != 8) {
        // 16 and 32 bit PHEs need to be halfword aligned
        free &= halfword_align[(byte->lo / 8U) & 1]; }
    return free.ffs();
}

void IXBar::Use::update_resources(int stage, BFN::Resources::StageResources &stageResource) const {
    LOG_FEATURE("resources", 2, "add_xbar_bytes_usage (stage=" << stage <<
                                "), table: " << used_by);
    for (auto &byte : use) {
        bool ternary = type == IXBar::Use::TERNARY_MATCH;
        LOG_FEATURE("resources", 3, "\tadding resource: xbar bytes " << byte.loc.getOrd(ternary));
        stageResource.xbarBytes[byte.loc.getOrd(ternary)].emplace(used_by, used_for(), byte);
    }
}

IXBar::IXBar() {
    // Initialize the fixed gateway inputs as preallocated fields;
    for (int i = 0; i < GATEWAY_FIXED_BYTES; ++i)
        gateway_fields.emplace(PHV::Container(PHV::Type::B, i), Loc(1, i));
}

void IXBar::find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                       safe_vector<IXBar::Use::Byte *> &alloced,
                       std::multimap<PHV::Container, Loc> &fields,
                       BFN::Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use,
                       bool allow_word, const xor_map_t *xor_map) {
    // for gateways, 'allow_word' allows use of the fixed bytes as they are set up
    // as group 1 (no actual word inputs to gateway)
    for (auto &byte : alloc_use) {
        for (auto &l : ValuesForKey(fields, byte.container)) {
            if (l.group == 0 && byte_use[l.byte].second == byte.lo) {
                if (xor_map && xor_map->count(byte) &&
                    byte_use[4^l.byte].first && byte_use[4^l.byte] != xor_map->at(byte))
                    continue;
                byte.loc = Loc(0, l.byte);
                break; }
            if (allow_word && (byte.flags & IXBar::Use::NeedXor) == 0 && l.group == 1) {
                if (xor_map && xor_map->count(byte)) continue;
                byte.loc = l;
                break; } }
        if (!byte.loc)
            alloced.push_back(&byte); }
}

bool IXBar::do_alloc(safe_vector<IXBar::Use::Byte *> &to_alloc,
                     BFN::Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use,
                     const xor_map_t *xor_map) {
    // Find the free byte slots
    bitvec byte_free;
    int i = 0;
    for (auto &b : byte_use) {
        if (!b.first) byte_free[i] = 1;
        ++i; }
    bitvec pair_free = (byte_free >> 4) & byte_free;
    for (auto *byte : to_alloc) {
        BUG_CHECK(byte->lo % 8U == 0, "misaligned byte for ixbar %s", *byte);
        byte->search_bus = 0;  // not relevant for flatrock
        int i = -1;
        if (xor_map && xor_map->count(*byte)) {
            for (i = GATEWAY_VEC_BYTES-1; i >= 0; --i) {
                if (byte_use[i^4] == xor_map->at(*byte)) {
                    if (!byte_free[i]) return false;
                    break; } }
            if (i < 0)
                i = find_free_byte(pair_free, byte);
        } else {
            i = find_free_byte(byte_free, byte); }
        if (i < 0) return false;
        byte_free[i] = 0;
        pair_free[i&3] = 0;
        byte->loc = Loc(0, i);
        byte_use[i] = *byte; }
    return true;
}

bool IXBar::do_alloc(safe_vector<IXBar::Use::Byte *> &to_alloc,
                     BFN::Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use,
                     BFN::Alloc1Dbase<PHV::Container> &word_use) {
    if (to_alloc.empty()) return true;
    std::map<PHV::Container, std::set<IXBar::Use::Byte *>> by_word;
    for (auto *byte : to_alloc) {
        BUG_CHECK(byte->lo % 8U == 0, "misaligned byte for ixbar %s", *byte);
        by_word[word_base(byte->container)].insert(byte);
        byte->search_bus = 0;  // not relevant for flatrock
    }
    // Find the free byte slots, and the first free word slot
    bitvec byte_free;
    int i = 0;
    for (auto &b : byte_use) {
        if (!b.first) byte_free[i] = 1;
        ++i; }
    auto word = std::find_if(word_use.begin(), word_use.end(),
            [](PHV::Container &a) { return !a; } );
    for (auto &grp : Values(by_word)) {
        if (grp.size() == 1 || word == word_use.end()) {
            // try to allocate byte slot(s)
            bool ok = true;
            for (auto *b : grp) {
                int i = find_free_byte(byte_free, b);
                if (i < 0) {
                    ok = false;
                    break; }
                b->loc = Loc(0, i);
                byte_free[i] = 0; }
            if (ok) continue; }
        // needs 2+ bytes in the word, or ran out of byte slots, so use a word slot
        if (word == word_use.end()) return false;
        for (auto *b : grp)
            b->loc = Loc(1, word - word_use.begin());
        while (++word != word_use.end() && *word) {} }
    return true;
}

bool IXBar::gateway_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                               safe_vector<IXBar::Use::Byte *> &alloced,
                               const xor_map_t &xor_map) {
    const xor_map_t *xmap = xor_map.empty() ? nullptr : &xor_map;
    find_alloc(alloc_use, alloced, gateway_fields, gateway_use, true, xmap);
    return do_alloc(alloced, gateway_use, xmap);
}

bool IXBar::exact_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                             safe_vector<IXBar::Use::Byte *> &alloced,
                             int exact_unit) {
    if (exact_unit < EXACT_MATCH_STM_UNITS) {  // only STM can use word slots
        find_alloc(alloc_use, alloced, exact_fields, exact_byte_use, true);
        return do_alloc(alloced, exact_byte_use, exact_word_use);
    } else {
        // LAMB match can't access the word slots
        find_alloc(alloc_use, alloced, exact_fields, exact_byte_use, false);
        return do_alloc(alloced, exact_byte_use); }
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

bool IXBar::xcmp_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                            safe_vector<IXBar::Use::Byte *> &alloced) {
    find_alloc(alloc_use, alloced, xcmp_fields, xcmp_byte_use, true);
    return do_alloc(alloced, xcmp_byte_use, xcmp_word_use);
}

bool IXBar::allocGateway(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                       const LayoutOption *lo) {
    if (tbl->gateway_rows.empty()) return true;
    LOG1("IXBar::allocGateway(" << tbl->name << ")");
    alloc.type = Use::GATEWAY;
    alloc.used_by = tbl->build_gateway_name();
    CollectGatewayFields *collect;

    if (lo && lo->layout.gateway_match) {
        collect = new CollectMatchFieldsAsGateway(phv, &alloc);
    } else {
        collect = new CollectGatewayFields(phv, &alloc);
    }

    tbl->apply(*collect);
    if (collect->info.empty()) return true;

    ContByteConversion map_alloc;
    xor_map_t   xor_map;
    PHV::FieldUse use_read(PHV::FieldUse::READ);

    for (auto &info : collect->info) {
        int flags = 0;
        if (info.second.need_range) {
            error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%sTofino5 does not support "
                  "range comparisons in a condition", tbl->srcInfo);
            return false; }
        if (!info.second.xor_with.empty()) {
            flags |= IXBar::Use::NeedXor;  // not needed?  xor_map used instead
            std::vector<std::pair<PHV::Container, int>>  bytes;
            info.first.foreach_byte(tbl, &use_read, [&](const PHV::AllocSlice &sl) {
                bytes.push_back(sl.container_byte()); });
            bool err = false;
            for (auto &with : info.second.xor_with) {
                auto it = bytes.begin();
                with.foreach_byte(tbl, &use_read, [&](const PHV::AllocSlice &sl) {
                    if (it == bytes.end() || xor_map.count(*it) ||
                        xor_map.count(sl.container_byte())) {
                        error("%scomplex comparison not supported", tbl->srcInfo);
                        err = true;
                        return; }
                    xor_map[*it] = sl.container_byte();
                    xor_map[sl.container_byte()] = *it;
                    ++it; });
                if (err) return false; } }

        cstring aliasSourceName;
        if (collect->info_to_uses.count(&info.second)) {
            LOG5("Found gateway alias source name");
            aliasSourceName = collect->info_to_uses[&info.second];
        }
        if (aliasSourceName)
            add_use(map_alloc, info.first.field(), phv, tbl, aliasSourceName,
                    &info.first.range(), flags);
        else
            add_use(map_alloc, info.first.field(), phv, tbl, boost::none,
                    &info.first.range(), flags);
    }
    safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
    create_alloc(map_alloc, alloc);
    if (!gateway_find_alloc(alloc.use, xbar_alloced, xor_map)) {
        alloc.clear();
        return false; }
    if (!collect->compute_offsets()) {
        alloc.clear();
        LOG3("collect.compute_offsets failed?");
        return false; }

    // FIXME -- different, inconsistent name from alloc.used_by here?
    update(tbl->name + "$gw", alloc);   //  Comes from tofino/input_xbar.cpp org
    return true;
}

void IXBar::setupMatchAlloc(const IR::MAU::Table *tbl, const PhvInfo &phv,
                                   ContByteConversion &map_alloc, Use &alloc) {
    std::map<cstring, bitvec> fields_needed;
    KeyInfo ki;
    ki.is_atcam = tbl->layout.atcam;
    alloc.clear();

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
        safe_vector<const IR::Expression *> field_list_order;
        FieldManagement(&map_alloc, field_list_order, vkey.second, &fields_needed,
                        phv, ki, tbl); }

    create_alloc(map_alloc, alloc);
    LOG3("need " << alloc.use.size() << " bytes for table " << tbl->name);
}

class IXBar::GetActionUse : public Inspector {
    const IR::MAU::Table *tbl;
    const PhvInfo &phv;
    ContByteConversion &map_alloc;
    std::map<cstring, bitvec> &fields_needed;
    bool preorder(const IR::MAU::Instruction *inst) {
        bool inPhvWrite = (inst->name == "or" || inst->name == "andc");
        for (unsigned i = 1; i < inst->operands.size(); ++i) {
            if (inPhvWrite && i == 1 && equiv(inst->operands[0], inst->operands[i]))
                continue;
            visit(inst->operands[i]); }
        return false; }
    bool preorder(const IR::Expression *e) {
        le_bitrange bits = { };
        auto *finfo = phv.field(e, &bits);
        BUG_CHECK(finfo, "operand not a phv ref: %s", e);
        bitvec field_bits(bits.lo, bits.hi - bits.lo + 1);
        if (fields_needed[finfo->name].contains(field_bits)) return false;  // already present
        fields_needed[finfo->name] |= field_bits;
        add_use(map_alloc, finfo, phv, tbl, phv.get_alias_name(e), &bits);
        return false; }
    bool preorder(const IR::Constant *) { return false; }
    bool preorder(const IR::MAU::ActionArg *) { return false; }
    bool preorder(const IR::Annotation *) { return false; }

 public:
    GetActionUse(const IR::MAU::Table *tbl, const PhvInfo &phv, ContByteConversion &map_alloc,
                 std::map<cstring, bitvec> &fields_needed)
    : tbl(tbl), phv(phv), map_alloc(map_alloc), fields_needed(fields_needed) {}
};

// Action sources are needed in the xcmp ixbar so they can be sourced by ALUs
void IXBar::setupActionAlloc(const IR::MAU::Table *tbl, const PhvInfo &phv,
                                    ContByteConversion &map_alloc, Use &alloc) {
    std::map<cstring, bitvec> fields_needed;
    GetActionUse gau(tbl, phv, map_alloc, fields_needed);
    for (auto *act : Values(tbl->actions))
        act->apply(gau);
    alloc.clear();
    create_alloc(map_alloc, alloc);
    LOG3("need " << alloc.use.size() << " bytes for actions in table " << tbl->name);
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
    if (unit >= EXACT_MATCH_UNITS)
        return false;
    alloc.exact_unit = unit;
    return true;
}

bool IXBar::allocExact(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                       const LayoutOption *lo, const ActionData::Format::Use *af) {
    LOG1("IXBar::allocExact(" << tbl->name << ")");
    ContByteConversion map_alloc;
    setupMatchAlloc(tbl, phv, map_alloc, alloc);
    if (!alloc.use.empty()) {
        safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
        if (!exact_find_hash(alloc, lo) ||
            !exact_find_alloc(alloc.use, xbar_alloced, alloc.exact_unit)) {
            return false; }
        alloc.type = Use::EXACT_MATCH;
        alloc.used_by = tbl->name;
        update(tbl->name, alloc); }
    if (lo || af) return true;
    return true;
}

bool IXBar::allocTernary(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                         const LayoutOption *lo, const ActionData::Format::Use *af) {
    LOG1("IXBar::allocTernary(" << tbl->name << ")");
    ContByteConversion map_alloc;
    setupMatchAlloc(tbl, phv, map_alloc, alloc);
    if (!alloc.use.empty()) {
        safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
        if (!ternary_find_alloc(alloc.use, xbar_alloced)) {
            return false; }
        alloc.type = Use::TERNARY_MATCH;
        alloc.used_by = tbl->name;
        update(tbl->name, alloc); }
    if (lo || af) return true;
    return true;
}

bool IXBar::allocActions(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc) {
    LOG1("IXBar::allocActions(" << tbl->name << ")");
    ContByteConversion map_alloc;
    setupActionAlloc(tbl, phv, map_alloc, alloc);
    if (!alloc.use.empty()) {
        safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
        if (!xcmp_find_alloc(alloc.use, xbar_alloced)) {
            return false; }
        alloc.type = Use::ACTION;
        alloc.used_by = tbl->name;
        update(tbl->name + "$act", alloc); }
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
    } else if (!tbl->match_key.empty()) {
        BUG_CHECK(!alloc.match_ixbar, "match ixbar already allocated?");
        if (tbl->layout.ternary) {
            if (!allocTernary(tbl, phv, getUse(alloc.match_ixbar), lo, af)) {
                alloc.clear_ixbar();
                return false; }
        } else {
            if (!allocExact(tbl, phv, getUse(alloc.match_ixbar), lo, af)) {
                alloc.clear_ixbar();
                return false; }
        }
    }

    if (!tbl->actions.empty() && !allocActions(tbl, phv, getUse(alloc.action_ixbar))) {
        alloc.clear_ixbar();
        return false; }

    for (auto back_at : tbl->attached) {
         auto at_mem = back_at->attached;
         if (attached_entries.at(at_mem).entries <= 0) continue;
         if (auto as = at_mem->to<IR::MAU::Selector>()) {
             if (!allocSelector(as, tbl, phv, getUse(alloc.selector_ixbar), tbl->name)) {
                 alloc.clear_ixbar();
                 return false; }
         } else if (auto mtr = at_mem->to<IR::MAU::Meter>()) {
             if (!allocMeter(mtr, tbl, phv, getUse(alloc.meter_ixbar))) {
                 alloc.clear_ixbar();
                 return false;
             }
         } else if (auto salu = at_mem->to<IR::MAU::StatefulAlu>()) {
             if (!allocStateful(salu, tbl, phv, getUse(alloc.salu_ixbar))) {
                 alloc.clear_ixbar();
                 return false; } } }

    if (!allocGateway(tbl, phv, getUse(alloc.gateway_ixbar), lo)) {
        alloc.clear_ixbar();
        return false; }
    return true;
}

void IXBar::update(cstring table_name, const ::IXBar::Use &use_) {
    auto &use = dynamic_cast<const Use &>(use_);
    if (use.empty()) return;
    for (auto &byte : use.use)
        field_users[byte.container].insert(table_name);
    switch (use.type) {
    case Use::EXACT_MATCH:
        for (auto &byte : use.use) {
            BUG_CHECK((byte.loc.group|1) == 1, "invalid exact match group %d", byte.loc.group);
            if (byte.loc.group) {
                if (word_base(byte.container) == exact_word_use[byte.loc.byte]) continue;
                if (exact_word_use[byte.loc.byte])
                    BUG("conflicting ixbar allocation at exact match word %d", byte.loc.byte);
                exact_word_use[byte.loc.byte] = word_base(byte.container);
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
    case Use::TRIE_MATCH:
        // FIXME -- trie needs input both via ternary xbar and xcmp xbar?  How do we
        // track which is which in and IXBar::Use?
    case Use::ACTION:
    case Use::PROXY_HASH:
    case Use::SELECTOR:
    case Use::METER:
    case Use::STATEFUL_ALU:
    case Use::HASH_DIST:
        for (auto &byte : use.use) {
            BUG_CHECK((byte.loc.group|1) == 1, "invalid exact match group %d", byte.loc.group);
            if (byte.loc.group) {
                if (word_base(byte.container) == xcmp_word_use[byte.loc.byte]) continue;
                if (xcmp_word_use[byte.loc.byte])
                    BUG("conflicting ixbar allocation at exact match word %d", byte.loc.byte);
                xcmp_word_use[byte.loc.byte] = word_base(byte.container);
            } else {
                if (byte == xcmp_byte_use[byte.loc.byte]) continue;
                if (xcmp_byte_use[byte.loc.byte].first)
                    BUG("conflicting ixbar allocation at exact match byte %d", byte.loc.byte);
                xcmp_byte_use[byte.loc.byte] = byte; }
            xcmp_fields.emplace(byte.container, byte.loc); }
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

void IXBar::dbprint(std::ostream &out) const {
    std::map<cstring, std::set<cstring>> field_users_names;
    for (const auto& kv : field_users) {
        field_users_names[kv.first.toString()] = kv.second;
    }
    std::map<cstring, char>     fields;
    add_names(exact_byte_use, fields);
    add_names(exact_word_use, fields);
    add_names(gateway_use, fields);
    add_names(ternary_use, fields);
    add_names(xcmp_byte_use, fields);
    add_names(xcmp_word_use, fields);
    sort_names(fields);
    out << "ew e bytes    ternary ixbar                  gw   x wds  x bytes" << Log::endl;
    for (int r = 0; r < 5; r++) {
        write_one(out, exact_word_use[r], fields);
        out << ' ';
        for (auto c = 0; c < EXACT_BYTES; c += 5)
            write_one(out, exact_byte_use[c+r], fields);
        out << ' ';
        for (auto c = 0; c < TERNARY_GROUPS; ++c)
            write_one(out, ternary_use[c][r], fields);
        if (r < 4) {  // onlye 4 rows for gw/xcmp
            out << ' ';
            for (auto c = 0; c < GATEWAY_VEC_BYTES; c += 4)
                write_one(out, gateway_use[c+r], fields);
            out << ' ';
            for (auto c = 0; c < XCMP_WORDS; c += 4)
                write_one(out, xcmp_word_use[c+r], fields);
            out << ' ';
            for (auto c = 0; c < XCMP_BYTES; c += 4)
                write_one(out, xcmp_byte_use[c+r], fields); }
        out << Log::endl; }
    for (auto &f : fields) {
        out << "   " << f.second << " " << f.first;
        const char *sep = " (";
        if (field_users_names.count(f.first)) {
            for (auto t : field_users_names.at(f.first)) {
                out << sep << t;
                sep = ", "; } }
        if (*sep == ',') out << ')';
        out << Log::endl; }

    // TODO -- hash functions
}

}  // namespace Flatrock
