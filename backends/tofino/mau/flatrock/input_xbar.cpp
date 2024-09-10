#include "input_xbar.h"
#include "backends/tofino/common/ir_utils.h"
#include "backends/tofino/logging/resources.h"
#include "backends/tofino/mau/gateway.h"
#include "backends/tofino/mau/resource.h"
#include "backends/tofino/phv/phv.h"

namespace Flatrock {

std::ostream &operator<<(std::ostream &out, const IXBar::xor_map_t &xor_map) {
    const char *sep = "";
    for (auto &p : xor_map) {
        out << sep << p.first.first << '[' << p.first.second << "]^" << p.second.first
            << '[' << p.second.second << ']';
        sep = ", "; }
    return out;
}

std::ostream &operator<<(std::ostream &out, const IXBar::cmp_map_t &cmp_map) {
    const char *sep = "";
    for (auto &p : cmp_map) {
        out << sep << p.first.first << '[' << p.first.second << "]~";
        if (p.second.size() != 1) out << '{';
        const char *setsep = "";
        for (auto &m : p.second) {
            out << setsep << m;
            setsep = ", "; }
        if (p.second.size() != 1) out << '}';
        sep = ", "; }
    return out;
}

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
    if (hash_groups) {
        for (unsigned i = 0, bits = xme_units; bits; ++i, bits >>= 2) {
            if (bits & 3)
                hash_groups->push_back(i); } }
    return rv;
}

/* when accessing a container on a word ixbar, it always accesses 4 bytes of containers
 * at a time.  This calculates the first container in a word of 4 bytes that includes
 * the specific container */
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

/* When accessing a container byte on a word xbar, this returns which byte within the
 * word needs to be accessed (which needs to be aligned properly within the word) */
static int word_offset(IXBar::Use::Byte &byte) {
    switch (byte.container.size()) {
    case 8:
        return byte.container.index() & 3;
    case 16:
        return (byte.container.index() & 1) * 2 + (byte.lo / 8);
    case 32:
        return byte.lo / 8;
    default:
        BUG("%s invalid container size %d", byte.container, byte.container.size());
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
    ::IXBar::Use::update_resources(stage, stageResource);
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
                       bool allow_word, const cmp_map_t *cmp_map, const xor_map_t *xor_map) {
    // for gateways, 'allow_word' allows use of the fixed bytes as they are set up
    // as group 1 (no actual word inputs to gateway)
    for (auto &byte : alloc_use) {
        unsigned wadb_usable_bytes = (byte.flags & Use::WadbByteUse) >> Use::WadbByteUse_shift;
        for (auto &l : ValuesForKey(fields, byte.container)) {
            if (l.group == 0 && byte_use[l.byte].second == byte.lo) {
                if (xor_map && xor_map->count(byte)) {
                    if (l.byte < GATEWAY_XOR_BYTES && gateway_xor[l.byte] == OFF)
                        continue;
                    if (byte_use[4^l.byte].first && byte_use[4^l.byte] != xor_map->at(byte))
                        continue;
                } else if (xor_map) {
                    if (l.byte < GATEWAY_XOR_BYTES && gateway_xor[l.byte] == ON)
                        continue; }
                if (cmp_map && gateway_match_bytes.count(l.byte) && cmp_map->count(byte) &&
                    !cmp_map->at(byte).count(gateway_match_bytes.at(l.byte)))
                    continue;
                byte.loc = Loc(0, l.byte);
                break; }
            if (l.group == 1) {
                if (wadb_usable_bytes && !(wadb_usable_bytes & (1U << word_offset(byte))))
                    continue;
                if (allow_word && (byte.flags & IXBar::Use::NeedXor) == 0) {
                    if (xor_map && xor_map->count(byte)) continue;
                    byte.loc = l;
                    break; } } }
        if (!byte.loc)
            alloced.push_back(&byte); }
}

bool IXBar::do_alloc(safe_vector<IXBar::Use::Byte *> &to_alloc,
                     BFN::Alloc1Dbase<std::pair<PHV::Container, int>> &byte_use,
                     const cmp_map_t *, const xor_map_t *xor_map) {
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
                    if (gateway_xor[i & 3] == OFF) return false;
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
    std::vector<IXBar::Use::Byte *> requires_badb;
    for (auto *byte : to_alloc) {
        BUG_CHECK(byte->lo % 8U == 0, "misaligned byte for ixbar %s", *byte);
        byte->search_bus = 0;  // not relevant for flatrock
        unsigned usable_bytes = (byte->flags & Use::WadbByteUse) >> Use::WadbByteUse_shift;
        if (usable_bytes && !(usable_bytes & (1U << word_offset(*byte)))) {
            requires_badb.push_back(byte);
        } else {
            by_word[word_base(byte->container)].insert(byte);
        }
    }
    // Find the free byte slots, and the first free word slot
    bitvec byte_free;
    int i = 0;
    for (auto &b : byte_use) {
        if (!b.first) byte_free[i] = 1;
        ++i; }
    auto word = std::find_if(word_use.begin(), word_use.end(),
            [](PHV::Container &a) { return !a; } );
    for (auto *b : requires_badb) {
        int i = find_free_byte(byte_free, b);
        if (i < 0) return false;
        b->loc = Loc(0, i);
        byte_free[i] = 0; }
    for (auto &grp : Values(by_word)) {
        // NOTE: Find free bytes on byte slots for any group size less than 4 bytes This may not
        // necessarily be the most efficient way to pack in all scenarios.
        if (grp.size() < 4 || word == word_use.end()) {
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
                               const cmp_map_t &cmp_map, const xor_map_t &xor_map) {
    find_alloc(alloc_use, alloced, gateway_fields, gateway_use, true, &cmp_map, &xor_map);
    return do_alloc(alloced, gateway_use, &cmp_map, &xor_map);
}

bool IXBar::gateway_setup_cmp(Use &alloc, const cmp_map_t &cmp_map) {
    alloc.gateway_match_bytes.clear();
    cmp_map_t                                           needed;
    std::map<cmp_map_t::key_type, std::set<int>>        avail_slots;
    for (auto &use : alloc.use) {
        if (use.loc.group) continue;
        if (cmp_map.count(use)) {
            if (!needed.count(use)) needed[use] = cmp_map.at(use);
            auto &need = needed.at(use);
            if (gateway_match_bytes.count(use.loc.byte)) {
                auto match = gateway_match_bytes.at(use.loc.byte);
                need.erase(match);
                alloc.gateway_match_bytes.emplace(use.loc.byte, match);
            } else {
                avail_slots[use].insert(use.loc.byte); } } }
    for (auto &need : needed) {
        for (auto &match : need.second) {
            auto &avail = avail_slots[need.first];
            if (avail.empty()) return false;
            int slot = *avail.begin();
            avail.erase(slot);
            alloc.gateway_match_bytes.emplace(slot, match); } }
    return true;
}


bool IXBar::gateway_setup_xor(Use &alloc, const xor_map_t &xor_map) {
    for (auto &xu : alloc.gateway_xor) xu = UNUSED;
    for (auto &use : alloc.use) {
        if (xor_map.count(use)) {
            if (gateway_xor[use.loc.byte & 3] == OFF) return false;
            if (alloc.gateway_xor[use.loc.byte & 3] == OFF) return false;
            alloc.gateway_xor[use.loc.byte & 3] = ON;
        } else if (use.loc.byte < GATEWAY_XOR_BYTES) {
            if (gateway_xor[use.loc.byte] == ON) return false;
            if (alloc.gateway_xor[use.loc.byte] == ON) return false;
            alloc.gateway_xor[use.loc.byte] = OFF; } }
    return true;
}

bool IXBar::exact_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                             safe_vector<IXBar::Use::Byte *> &alloced,
                             bool allow_word) {
    find_alloc(alloc_use, alloced, exact_fields, exact_byte_use, allow_word);
    if (allow_word) {
        return do_alloc(alloced, exact_byte_use, exact_word_use);
    } else {
        return do_alloc(alloced, exact_byte_use); }
}

/** Find the best suitable ternary group for the remaining xbar bytes required. The idea is that
 *  after one or more iteration, all of the alloc_use bytes are part of the alloced vector. This
 *  function only process one ternary group at a time. It analyses the requirement and select
 *  odd/even ternary group if it can reduce the global number of TCAM requirement. If selecting
 *  either group type will not have an impact on the global number of TCAM requirement, the group
 *  being the least used will be choosen. This behavior can be relaxed using the optimal flag set
 *  to false which is tried as the last resort.
 */
bool IXBar::ternary_find_grp_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                                   safe_vector<IXBar::Use::Byte *> &alloced,
                                   int &ternary_use_tbl, bool optimal) {
    // Always try to pack ternary group at the start to automatically balance even and odd group
    int first_grp = 0;
    int grp_inc = 1;
    if (optimal) {
        // Pre-analyse alignment needs
        int odd = 0;
        int even = 0;
        int total = 0;
        for (const IXBar::Use::Byte &byte : alloc_use) {
            // Byte was already allocated
            if (byte.loc)
                continue;

            // Only PHE16 and PHE32 have even/odd alignment constraint that must be tracked
            if (byte.container.is(PHV::Size::b16) || byte.container.is(PHV::Size::b32)) {
                if (byte.lo % 16)
                    odd++;
                else
                    even++;
            }
            total++;
        }

        int min_width = (total + (TERNARY_BYTES_PER_GROUP - 1)) / TERNARY_BYTES_PER_GROUP;
        int worst_width = (odd > even ? (odd + (TERNARY_MIN_EVEN_ODD_BYTES_PER_GROUP - 1)) /
                                         TERNARY_MIN_EVEN_ODD_BYTES_PER_GROUP :
                                        (even + (TERNARY_MIN_EVEN_ODD_BYTES_PER_GROUP - 1)) /
                                         TERNARY_MIN_EVEN_ODD_BYTES_PER_GROUP);
        // Only force a ternary group if this will make a difference
        if (worst_width > min_width) {
            first_grp = (odd > even ? 1 : 0);
            grp_inc = 2;
        }
    }

    // Find the first ternary group that is available and fit the required alignment constraints
    for (int grp = first_grp; grp < TERNARY_GROUPS; grp += grp_inc) {
        // We always start filling either the first or the second byte of a group
        if (ternary_use[grp][0].first || ternary_use[grp][1].first) continue;
        if (ternary_use_tbl & (1 << grp)) continue;

        ternary_use_tbl |= 1 << grp;

        for (int b = 0; b < TERNARY_BYTES_PER_GROUP; b++) {
            bool candidate = false;  // This is to track possible 8-bit container not alloced
            for (IXBar::Use::Byte &byte : alloc_use) {
                // Byte was already allocated
                if (byte.loc)
                    continue;

                if (byte.container.is(PHV::Size::b16) || byte.container.is(PHV::Size::b32)) {
                    bool odd_pos = ((grp & 0x1) + b) & 0x1;
                    bool odd_byte = (byte.lo % 16 ? true : false);
                    if (odd_byte == odd_pos) {
                        byte.loc = Loc(grp, b);
                        alloced.push_back(&byte);
                        candidate = false;
                        break;
                    }
                } else {
                    candidate = true;
                }
            }
            // This byte position was not filled by any PHE16 or PHE32 with alignment constraint
            // but PHE8 was available
            if (candidate) {
                for (IXBar::Use::Byte &byte : alloc_use) {
                    // Byte was already allocated
                    if (byte.loc)
                        continue;

                    if (byte.container.is(PHV::Size::b8)) {
                        byte.loc = Loc(grp, b);
                        alloced.push_back(&byte);
                        break;
                    }
                }
            }
            if (alloced.size() == alloc_use.size())
                break;
        }
        return true;
    }
    return false;
}

bool IXBar::ternary_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                               safe_vector<IXBar::Use::Byte *> &alloced) {
    int ternary_use_tbl = 0;  // Used to carry current tbl ternary use before update
    while (alloced.size() != alloc_use.size()) {
        if (!ternary_find_grp_alloc(alloc_use, alloced, ternary_use_tbl, true))
            if (!ternary_find_grp_alloc(alloc_use, alloced, ternary_use_tbl, false))
                return false;
    }
    return true;
}

bool IXBar::xcmp_find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                            safe_vector<IXBar::Use::Byte *> &alloced) {
    find_alloc(alloc_use, alloced, xcmp_fields, xcmp_byte_use, true);
    return do_alloc(alloced, xcmp_byte_use, xcmp_word_use);
}

/* compute the match_t values needed in the cmp_map to compare against each byte in
 * the gateway vector compare.  It relies on the expressions visted having been
 * successfully processed by CanonGatewayExpr without being flagged as too complex
 * for a gateway.  That means the expressions will be in disjunctive normal form with
 * each conjunct on a separate gateway row, and each term will be one of the limited
 * forms it allows */
class IXBar::SetupCmpMap : public Inspector {
    const PhvInfo               &phv;
    const IR::MAU::Table        *tbl;
    cmp_map_t                   &cmp_map;
    const PHV::Field            *field = nullptr;
    le_bitrange                 bits;
    uint64_t                    value = 0, mask = 0;

    // This is where all the work happens -- we've found a (possibly masked) comparison
    // of a field slice with a constant that needs to go into the vector compare
    void add_relation() {
        PHV::FieldUse READ(PHV::FieldUse::READ);
        field->foreach_byte(bits, tbl, &READ, [this](const PHV::AllocSlice &sl) {
            IXBar::Use::Byte byte(sl.container(), (sl.container_slice().lo/8U) * 8U);
            int offset = sl.field_slice().lo - bits.lo;
            unsigned m = (mask >> offset) & bitMask(sl.width());
            unsigned v = value >> offset;
            unsigned shift = sl.container_slice().lo % 8U;
            cmp_map[byte].insert(match_t(8, v << shift, m << shift));
        });
    }

    bool preorder(const IR::Constant *k) {
        if (k->value < 0)
            value = ~static_cast<uint64_t>(-k->value - 1);   // 2s complement
        else
            value = static_cast<uint64_t>(k->value);
        return false; }

    bool preorder(const IR::BoolLiteral *k) {
        value = k->value ? 1 : 0;
        return false; }

    bool preorder(const IR::Expression *e) {
        if (!(field = phv.field(e, &bits))) return true;
        if (!findContext<IR::Operation::Relation>()) {
            // bare boolean test
            BUG_CHECK(bits.size() == 1, "not a boolean test?");
            value = mask = 1;
            add_relation(); }
        return false; }

    bool preorder(const IR::Operation::Relation *) {
        field = nullptr;
        value = 0;
        mask = ~UINT64_C(0);
        return true; }

    void postorder(const IR::BAnd *) {
        mask = value;
        value = 0; }

    void postorder(const IR::BOr *) {
        mask = value ^ ~UINT64_C(0);
        value = 0; }

    void postorder(const IR::Operation::Relation *) {
        BUG_CHECK(field, "should have been rejected in CollectGatewayFields");
        add_relation(); }

 public:
    SetupCmpMap(const PhvInfo &phv, const IR::MAU::Table *tbl, cmp_map_t &cm)
    : phv(phv), tbl(tbl), cmp_map(cm) {
        for (auto &gw : tbl->gateway_rows)
            if (gw.first)
                gw.first->apply(*this);
    }
};

/* when a single gateway compares a byte against multiple different constants, it needs to
 * be replicated in the ixbar so that each byte can match a different constant, as there's
 * only a single vector match on flatrock and the gateway rows only match one bit per byte,
 * testing whether that byte matched its byte constant or not */
void IXBar::replicate_alloc_bytes(const cmp_map_t &cmp_map, safe_vector<Use::Byte> &alloc_use) {
    for (size_t i = 0; i < alloc_use.size(); ++i) {
        if (cmp_map.count(alloc_use[i])) {
            size_t matches = cmp_map.at(alloc_use[i]).size();
            if (matches > 1) {
                Use::Byte tmp = alloc_use[i];  // need a copy as insert invalidates references
                alloc_use.insert(alloc_use.begin()+i, matches-1, tmp);
                i += matches - 1; } } }
}

bool IXBar::allocGateway(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                         const LayoutOption *lo) {
    if (lo && lo->layout.no_match_rams()) {
        // tables with no memories require a gateway, so we need to allocate a dummy if
        // there isn't one yet.
    } else if (tbl->gateway_rows.empty()) {
        return true; }
    IndentCtl::TempIndent indent;
    LOG1("IXBar::allocGateway(" << tbl->name << ")" << indent);
    alloc.type = Use::GATEWAY;
    alloc.used_by = tbl->build_gateway_name();
    CollectGatewayFields *collect;

    int rows = tbl->gateway_rows.size();
    if (lo && lo->layout.gateway_match) {
        collect = new CollectMatchFieldsAsGateway(phv, &alloc);
        rows = tbl->entries_list->entries.size();
    } else {
        collect = new CollectGatewayFields(phv, &alloc);
    }

    tbl->apply(*collect);
    if (!collect->info.empty()) {
        ContByteConversion map_alloc;
        cmp_map_t   cmp_map;
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
                add_use(map_alloc, info.first.field(), phv, tbl, std::nullopt,
                        &info.first.range(), flags);
        }
        safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
        create_alloc(map_alloc, alloc);
        SetupCmpMap(phv, tbl, cmp_map);
        LOG4("cmp_map: " << cmp_map);
        if (!xor_map.empty()) LOG4("xor_map: " << xor_map);
        replicate_alloc_bytes(cmp_map, alloc.use);
        if (!gateway_find_alloc(alloc.use, xbar_alloced, cmp_map, xor_map) ||
            !gateway_setup_cmp(alloc, cmp_map) || !gateway_setup_xor(alloc, xor_map)) {
            alloc.clear();
            return false; }
        if (!collect->compute_offsets()) {
            alloc.clear();
            LOG3("collect.compute_offsets failed?");
            return false; }
    }
    if (rows < 1) rows = 1;
    alloc.num_gw_rows = rows;
    int start = -1;
    for (int i = 0; i <= GATEWAY_ROWS-rows; ++i) {
        if (start >= 0 && i > start+rows) break;
        if (gateway_rows[i])
            start = -1;
        else if (start < 0)
            start = i; }
    if (start < 0) return false;
    LOG5("alloc " << rows << " gateway rows starting at " << start);
    alloc.first_gw_row = start;

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
    std::map<le_bitrange, unsigned> slice_flags;
    bool preorder(const IR::MAU::Instruction *inst) {
        bool inPhvWrite = (inst->name == "or" || inst->name == "andc");
        slice_flags.clear();
        if (inPhvWrite || inst->name == "set") {
            le_bitrange bits = { };
            auto *dest = phv.field(inst->operands[0], &bits);
            BUG_CHECK(dest, "destination not a phv ref: %s", inst);
            PHV::FieldUse WRITE(PHV::FieldUse::WRITE);
            dest->foreach_alloc(bits, tbl, &WRITE, [&](const PHV::AllocSlice &sl) {
                auto cont = sl.container();
                auto &flags = slice_flags[sl.field_slice().shiftedByBits(-bits.lo)];
                switch (cont.size()) {
                case 8:
                    flags = 1 << (cont.index() & 3) << Use::WadbByteUse_shift;
                    break;
                case 16:
                    flags = 3 << ((cont.index() & 1)*2) << Use::WadbByteUse_shift;
                    break;
                case 32:
                    flags = Use::WadbByteUse;
                break;
                default:
                    BUG("invalid container size: %s", cont);
                    break; } });
        } else {
            // FIXME need to be in EALU -- what alignment applies?  Need to be in badb
            // for EALU8/16 and wadb for EALU32, but that may change with Pat's new proposal?
        }
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
        if (slice_flags.empty()) {
            add_use(map_alloc, finfo, phv, tbl, phv.get_alias_name(e), &bits);
        } else {
            for (auto &[slice, flags] : slice_flags) {
                auto sl = slice.shiftedByBits(bits.lo);
                add_use(map_alloc, finfo, phv, tbl, phv.get_alias_name(e), &sl, flags); } }
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

bool IXBar::exact_find_units(Use &alloc, const LayoutOption *lo) {
    // LOG3("Finding exact units for Layout : " << lo);
    unsigned avail_xme = lo->layout.is_lamb ? LAMB_XME_UNITS : STM_XME_UNITS;
    avail_xme &= ~xme_inuse;
    unsigned units = lo->way_sizes.size();
    if (lo->layout.is_lamb) {
        units = 0;
        for (auto sz : lo->way_sizes) units += sz; }
    if (units > bitcount(avail_xme)) return false;
    int unit;
    for (unit = ffs(avail_xme) - 1; units > 0; ++unit) {
        if (!(avail_xme >> unit)) break;
        if (!((avail_xme >> unit) & 1)) continue;
        if (units > 1 && (unit & 1) == 1) continue;
        alloc.xme_units |= 1 << unit;
        --units; }
    if (units == 1 && (unit = ffs(avail_xme &~ alloc.xme_units) - 1) >= 0) {
        alloc.xme_units |= 1 << unit;
        --units; }
    if (units != 0) return false;
    unsigned avail_xmu = lo->layout.is_lamb ? LAMB_XMU_UNITS : STM_XMU_UNITS;
    for (int unit : bitvec(avail_xmu)) {
        if (!xmu_output_use[unit]) {
            alloc.output_unit = unit;
            return true; } }
    return false;
}

bool IXBar::allocProxyHash(const IR::MAU::Table *, const PhvInfo &, Use &,
                           const LayoutOption *, const ActionData::Format::Use *) {
    BUG("flatrock proxy hash todo");
    return false;
}

bool IXBar::allocExact(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                       const LayoutOption *lo, const ActionData::Format::Use *af) {
    LOG1("IXBar::allocExact(" << tbl->name << ")");
    ContByteConversion map_alloc;
    setupMatchAlloc(tbl, phv, map_alloc, alloc);
    if (!alloc.use.empty()) {
        safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
        if (!exact_find_units(alloc, lo) ||
            !exact_find_alloc(alloc.use, xbar_alloced, !lo->layout.is_lamb)) {
            return false; }
        alloc.type = Use::EXACT_MATCH;
        alloc.used_by = tbl->name;
        update(tbl->name, alloc); }
    if (lo || af) return true;
    return true;
}

/* find the first free (zero) block of size bits in the bitvec, and set them */
static le_bitrange alloc_bitrange(bitvec &inuse, unsigned size) {
    if (size == 0) return le_bitrange(0, 0);
    int rv = inuse.ffz(0);
    while (inuse.getrange(rv, size) != 0) {
        rv = inuse.ffs(rv);
        rv = inuse.ffz(rv); }
    inuse.setrange(rv, size);
    return le_bitrange(rv, rv+size-1);;
}

bool IXBar::allocAllHashWays(Use &alloc, const LayoutOption *lo) {
    unsigned ram_depth = ceil_log2(lo->layout.get_sram_depth());  // index size in bits
    ram_depth += lo->layout.get_subword_bits();
    unsigned sel_size = 0;  // FIXME -- when will this ever be non-zero?
    int unit = ffs(alloc.xme_units) - 1;
    bitvec inuse;
    int inuse_xmu = -1;
    for (auto way_size : lo->way_sizes) {
        int depth_bits = lo->layout.is_lamb ? 0 : ceil_log2(way_size);
        for (int i = 0; i < way_size; ++i) {
            BUG_CHECK(unit >= 0, "didn't allocate enough units?");
            int xmu = unit/2;  // two XMEs per XMU
            if (inuse_xmu != xmu) {
                inuse_xmu = xmu;
                inuse = exact_hash_inuse[xmu]; }
            auto start = alloc_bitrange(inuse, ram_depth + depth_bits);
            if (start.hi >= EXACT_HASH_BITS) return false;
            auto sel = alloc_bitrange(inuse, sel_size);
            if (sel.hi >= EXACT_HASH_BITS) return false;
            alloc.way_use.emplace_back(xmu, start, sel, (1U << sel_size) - 1);
            while (!((alloc.xme_units >> ++unit) & 1)) {
                if (!(alloc.xme_units >> unit)) {
                    unit = -1;
                    break; } }
            if (!lo->layout.is_lamb) break; } }
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
    IndentCtl::TempIndent indent;
    LOG1("IXBar::allocActions(" << tbl->name << ")" << indent);
    ContByteConversion map_alloc;
    setupActionAlloc(tbl, phv, map_alloc, alloc);
    if (!alloc.use.empty()) {
        safe_vector<IXBar::Use::Byte *> xbar_alloced;  // FIXME -- not needed?
        if (!xcmp_find_alloc(alloc.use, xbar_alloced)) {
            return false; }
        alloc.type = Use::ACTION;
        alloc.used_by = tbl->name;
        LOG3("allocated: " << alloc);
        update(tbl->name + "$act", alloc); }
    return true;
}

bool IXBar::allocSelector(const IR::MAU::Selector *sel, const IR::MAU::Table *tbl,
                          const PhvInfo &phv, Use &alloc, cstring name) {
    IndentCtl::TempIndent indent;
    LOG1("IXBar::allocSelector(" << tbl->name << ")" << indent);
    if (sel || tbl || phv.field(0) || alloc.type || name)
        error("flatrock selector not implemented yet");
    return false;
}

bool IXBar::allocStateful(const IR::MAU::StatefulAlu *salu, const IR::MAU::Table *tbl,
                          const PhvInfo &phv, Use &alloc) {
    IndentCtl::TempIndent indent;
    LOG1("IXBar::allocStateful(" << tbl->name << ")" << indent);
    if (salu || tbl || phv.field(0) || alloc.type)
        error("flatrock stateful not implemented yet");
    return false;
}

bool IXBar::allocMeter(const IR::MAU::Meter *meter, const IR::MAU::Table *tbl,
                       const PhvInfo &phv, Use &alloc) {
    IndentCtl::TempIndent indent;
    LOG1("IXBar::allocMeter(" << tbl->name << ")" << indent);
    if (meter || tbl || phv.field(0) || alloc.type)
        error("flatrock meter not implemented yet");
    return false;
}

bool IXBar::allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                       const LayoutOption *lo, const ActionData::Format::Use *af,
                       const attached_entries_t &attached_entries) {
    if (!tbl) return true;
    IndentCtl::TempIndent indent;
    LOG1("IXBar::allocTable(" << tbl->name << ")" << indent);
    if (tbl->layout.atcam) {
        BUG("flatrock ATCAM todo");
    } else if (tbl->layout.proxy_hash) {
        BUG_CHECK(!alloc.proxy_hash_ixbar, "proxy hash ixbar already allocated?");
        auto &proxy_hash_ixbar = getUse(alloc.proxy_hash_ixbar);
        if (!allocProxyHash(tbl, phv, proxy_hash_ixbar, lo, af) ||
            !allocAllHashWays(proxy_hash_ixbar, lo)) {
            alloc.clear_ixbar();
            return false; }
    } else if (!tbl->match_key.empty()) {
        BUG_CHECK(!alloc.match_ixbar, "match ixbar already allocated?");
        if (tbl->layout.ternary) {
            if (!allocTernary(tbl, phv, getUse(alloc.match_ixbar), lo, af)) {
                alloc.clear_ixbar();
                return false; }
        } else {
            auto &match_ixbar = getUse(alloc.match_ixbar);
            if (!allocExact(tbl, phv, match_ixbar, lo, af) ||
                !allocAllHashWays(match_ixbar, lo)) {
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
    LOG2("Ixbar allocation on table successful");
    return true;
}

/* Allocate the gateway (if any) first, as if the match table requires a gateway and there
 * isn't one attached, we'll need to allocate a dummy (always match) gateway */
bool IXBar::allocTable(const IR::MAU::Table *tbl, const IR::MAU::Table *gw, const PhvInfo &phv,
                       TableResourceAlloc &alloc, const LayoutOption *lo,
                       const ActionData::Format::Use *af,
                       const attached_entries_t &attached_entries) {
    return allocTable(gw, phv, alloc, lo, nullptr, attached_entries) &&
           allocTable(tbl, phv, alloc, lo, af, attached_entries);
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
            if (byte.loc.group == 0)  {
                if (byte == gateway_use[byte.loc.byte]) continue;
                if (gateway_use[byte.loc.byte].first)
                    BUG("conflicting ixbar allocation at gateway byte %d", byte.loc.byte);
                gateway_use[byte.loc.byte] = byte;
                gateway_fields.emplace(byte.container, byte.loc);
            } else {
                BUG_CHECK(byte.loc.group == 1, "invalid gateway group %d", byte.loc.group);
                BUG_CHECK(byte.container == PHV::Container(PHV::Type::B, byte.loc.byte),
                          "wrong container %s in gateway fixed byte %d",
                          byte.container, byte.loc.byte); } }
        for (int i = 0; i < GATEWAY_XOR_BYTES; ++i) {
            if (use.gateway_xor[i] == UNUSED) continue;
            BUG_CHECK(gateway_xor[i] == UNUSED || gateway_xor[i] == use.gateway_xor[i],
                      "conflicting gateway xor use at byte %d", i);
            gateway_xor[i] = use.gateway_xor[i]; }
        for (auto &mb : use.gateway_match_bytes) {
            if (gateway_match_bytes.count(mb.first)) {
                BUG_CHECK(mb.second == gateway_match_bytes.at(mb.first),
                        "conflicting gateway vector match at byte %d", mb.first);
            } else {
                gateway_match_bytes.emplace(mb.first, mb.second); } }
        break;
    default:
        BUG("Unhandled use type %d (%s)", use.type, use.used_for()); }

    if (use.type != Use::GATEWAY) {
        for (auto xu : use.gateway_xor)
            BUG_CHECK(xu == UNUSED, "gateway match info in %s", use.type);
        BUG_CHECK(use.gateway_match_bytes.empty(), "gateway match info in %s", use.type); }

    xme_inuse |= use.xme_units;
    for (auto xme : bitvec(use.xme_units)) {
        if (xme_use[xme] && xme_use[xme] != table_name)
            BUG("conflicting use of xme %d between %s and %s", xme, xme_use[xme], table_name);
        xme_use[xme] = table_name; }
    if (use.output_unit >= 0) {
        if (xmu_output_use[use.output_unit] && xmu_output_use[use.output_unit] != table_name)
            BUG("conflicting use of xmu %d between %s and %s", use.output_unit,
                xmu_output_use[use.output_unit], table_name);
        xmu_output_use[use.output_unit] = table_name; }

    for (auto &way : use.way_use) {
        if (way.index.size() > 0) {
            exact_hash_inuse[way.source].setrange(way.index.lo, way.index.size());
            for (int bit = way.index.lo; bit <= way.index.hi; ++bit) {
                auto &u = exact_hash_use.at(way.source, bit);
                if (u && u != table_name)
                    BUG("conflicting use of exact hash %d bit %d between %s and %s",
                        way.source, bit, u, table_name); } }
        exact_hash_inuse[way.source] |= bitvec(way.select_mask) << way.select.lo;
        unsigned mask = way.select_mask;
        for (int bit = way.select.lo; mask; ++bit, mask >>= 1) {
            if (!(mask & 1)) continue;
            auto &u = exact_hash_use.at(way.source, bit);
            if (u && u != table_name)
                BUG("conflicting use of exact hash %d bit %d between %s and %s",
                    way.source, bit, u, table_name); }
    }
    for (int i = use.first_gw_row; i < use.first_gw_row + use.num_gw_rows; ++i) {
        if (gateway_rows[i] && gateway_rows[i] != table_name)
            BUG("conflicting use of gateway row %d between %s and %s", i,
                gateway_rows[i], table_name);
        gateway_rows[i] = table_name; }
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
    out << "ew e bytes  ternary ixbar                            gw    x wds  x bytes" << Log::endl;
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
            write_one(out, gateway_use[r], fields);
            out << ".|x"[gateway_xor[r]];
            write_one(out, gateway_use[r+4], fields);
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

void IXBar::Use::dbprint(std::ostream &out) const {
    ::IXBar::Use::dbprint(out);
}

/* Determine which bytes of a table's input xbar belong to an individual hash table,
   so that we can output the hash of this individual table. */
void IXBar::Use::emit_ixbar_hash_table(int hash_table, safe_vector<Slice> &match_data,
        safe_vector<Slice> &ghost, const ::TableMatch *fmt,
        std::map<int, std::map<int, Slice>> &sort) const {
    LOG5("Emitting ixbar hash table");
    if (sort.empty()) return;

    auto update_match_data = [&](Slice &reg){
        if (fmt != nullptr) {
            safe_vector<Slice> reg_ghost;
            safe_vector<Slice> reg_hash = reg.split(fmt->ghost_bits, reg_ghost);
            ghost.insert(ghost.end(), reg_ghost.begin(), reg_ghost.end());
            // P4C-4496: if dynamic_table_key_masks pragma is applied to the
            // table, ghost bits are disabled, as a result, match key must be
            // emitted as match data to generated the correct hash section in
            // bfa and context.json
            if (!fmt->identity_hash || fmt->dynamic_key_masks)
                match_data.insert(match_data.end(), reg_hash.begin(), reg_hash.end());
        } else {
            match_data.emplace_back(reg);
        }
    };

    for (auto [ht, m] : sort) {
        if (hash_table >= 0 && hash_table/2 != ht) continue;
        for (auto &match : m) {
            Slice reg = match.second;
            if (!reg) continue;
            update_match_data(reg);
        }
    }
    return;
}

int IXBar::Use::ternary_align(const Loc &loc) const {
    return (loc.group * IXBar::TERNARY_BYTES_PER_GROUP + loc.byte) % 4;
}

}  // namespace Flatrock
