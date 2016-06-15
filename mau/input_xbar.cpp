#include "gateway.h"
#include "input_xbar.h"
#include "resource.h"
#include "lib/algorithm.h"
#include "lib/bitvec.h"
#include "lib/bitops.h"
#include "lib/hex.h"
#include "lib/range.h"
#include "lib/log.h"
#include "tofino/phv/phv_fields.h"

void IXBar::clear() {
    exact_use.clear();
    ternary_use.clear();
    byte_group_use.clear();
    exact_fields.clear();
    ternary_fields.clear();
    hash_index_use.clear();
    hash_single_bit_use.clear();
    memset(hash_index_inuse, 0, sizeof(hash_index_inuse));
    hash_group_use.clear();
    memset(hash_single_bit_inuse, 0, sizeof(hash_single_bit_inuse));
}

int IXBar::Use::groups() const {
    int rv = 0;
    unsigned counted = 0;
    for (auto &b : use) {
        assert(b.loc.group >= 0);
        if (!(1 & (counted >> b.loc.group))) {
            ++rv;
            counted |= 1U << b.loc.group; } }
    return rv;
}
void IXBar::Use::compute_hash_tables() {
    hash_table_input = 0;
    for (auto &b : use) {
        unsigned grp = 1U << (b.loc.group * 2);
        if (b.loc.byte >= 8) grp <<= 1;
        hash_table_input |= grp; }
}

static int align_flags[4] = {
    /* these flags are the alignment restrictions that FAIL for each byte in 4 */
    IXBar::Use::Align16hi | IXBar::Use::Align32hi,
    IXBar::Use::Align16lo | IXBar::Use::Align32hi,
    IXBar::Use::Align16hi | IXBar::Use::Align32lo,
    IXBar::Use::Align16lo | IXBar::Use::Align32lo,
};

bool IXBar::find_alloc(IXBar::Use &alloc, bool ternary, bool second_try) {
    int groups = ternary ? TERNARY_GROUPS : EXACT_GROUPS;
    int bytes_per_group = ternary ? TERNARY_BYTES_PER_GROUP : EXACT_BYTES_PER_GROUP;
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    int groups_needed = (alloc.use.size() + bytes_per_group - 1)/bytes_per_group;

    if (groups_needed > groups)
        return false;
    struct grp_use {
        int group, found, free_cnt; bitvec free;
        void dbprint(std::ostream &out) const {
            out << group << ": " << found << ' ' << free_cnt << ' ' << free; }
    };
    vector<grp_use> order(groups);
    for (int i = 0; i < groups; i++) order[i].group = i;
    /* figure out how many needed bytes have already been allocated to each group the xbar */
    for (auto &need : alloc.use)
        for (auto &p : Values(fields.equal_range(need.field)))
            if (use[p.group][p.byte].second == need.byte)
                order[p.group].found++;
    /* and how many (and which) bytes are still free in each group */
    for (int grp = 0; grp < groups; grp++)
        for (int byte = 0; byte < bytes_per_group; byte++)
            if (!use[grp][byte].first) {
                order[grp].free_cnt++;
                order[grp].free[byte] = true; }
    /* sort group pref order: prefer groups with most bytes already in, then most free */
    std::sort(order.begin(), order.end(), [=](const grp_use &a, const grp_use &b) {
        if (!second_try && a.found != b.found) return a.found > b.found;
        if (a.free_cnt != b.free_cnt) return a.free_cnt > b.free_cnt;
        return a.group < b.group; });
    LOG3(order);
    /* figure out which group(s) to use */
    bitvec groups_to_use;
    for (int i = 0; i < groups_needed; i++)
        groups_to_use[order[i].group] = true;
    /* now try to allocate all bytes to those groups */
    bitvec need_alloc;
    for (auto &need : alloc.use) {
        bool found = false;
        for (auto &p : Values(fields.equal_range(need.field)))
            if (groups_to_use[p.group] && use[p.group][p.byte].second == need.byte) {
                need.loc = p;
                found = true;
                break; }
        if (found) continue;
        for (auto &grp : order) {
            if (!groups_to_use[grp.group]) break;
            int align = (ternary ? (grp.group * 11 + 1)/2 : 0) & 3;
            for (auto byte : grp.free) {
                if (align_flags[(byte+align)&3] & need.flags) continue;
                need_alloc[&need - &alloc.use[0]] = true;
                need.loc.group = grp.group;
                need.loc.byte = byte;
                grp.free[byte] = false;
                found = true;
                break; }
            if (found) break; }
        if (!found) {
            LOG3("failed to fit");
            return false; } }
    /* succeded -- update the use info */
    for (int i : need_alloc) {
        fields.emplace(alloc.use[i].field, alloc.use[i].loc);
        use[alloc.use[i].loc] = alloc.use[i]; }
    return /* alloc */ true;
}

int need_align_flags[3][4] = { { 0, 0, 0, 0 },  // 8bit -- no alignment needed
    { IXBar::Use::Align16lo, IXBar::Use::Align16hi, IXBar::Use::Align16lo, IXBar::Use::Align16hi },
    { IXBar::Use::Align16lo | IXBar::Use::Align32lo,
      IXBar::Use::Align16hi | IXBar::Use::Align32lo,
      IXBar::Use::Align16lo | IXBar::Use::Align32hi,
      IXBar::Use::Align16hi | IXBar::Use::Align32hi } };


static void add_use(IXBar::Use &alloc, const PhvInfo::Info *field, int flags) {
    if (field->alloc.empty()) {
        int size = (field->size + 7)/8U;
        for (int i = 0; i < size; i++) {
            alloc.use.emplace_back(field->name, i);
            alloc.use.back().flags = flags; }
    } else {
        int byte = 0;
        for (auto it = field->alloc.rbegin(); it != field->alloc.rend(); ++it) {
            if (it->container.tagalong()) continue;
            for (int cbyte = it->container_bit/8U;
                 cbyte <= (it->container_bit + it->width - 1)/8U;
                 ++cbyte, ++byte) {
                alloc.use.emplace_back(field->name, byte);
                alloc.use.back().flags =
                    flags | need_align_flags[it->container.log2sz()][cbyte & 3];; } }
        if (!byte)
            BUG("field %s allocated to tagalong but used in MAU pipe", field->name); }
}

bool IXBar::allocMatch(bool ternary, const IR::V1Table *tbl, const PhvInfo &phv, Use &alloc) {
    alloc.ternary = ternary;
    if (!tbl->reads) return true;
    set<cstring>                        fields_needed;
    bool                                rv;
    for (auto r : *tbl->reads) {
        auto *field = r;
        if (auto mask = r->to<IR::Mask>()) {
            field = mask->left;
        } else if (auto prim = r->to<IR::Primitive>()) {
            if (prim->name != "valid")
                BUG("unexpected reads expression %s", r);
            // FIXME -- for now just assuming we can fit the valid bit reads in as needed
            continue; }
        const PhvInfo::Info *finfo;
        if (!field || !(finfo = phv.field(field)))
            BUG("unexpected reads expression %s", r);
        if (fields_needed.count(finfo->name))
            throw Util::CompilationError("field %s read twice by table %s", finfo->name, tbl->name);
        fields_needed.insert(finfo->name);
        add_use(alloc, finfo, 0); }
    LOG1("need " << alloc.use.size() << " bytes for table " << tbl->name);
    LOG3("need fields " << fields_needed);
    rv = find_alloc(alloc, ternary , false) || find_alloc(alloc, ternary , true);
    if (!ternary && rv)
        alloc.compute_hash_tables();
    if (!rv) alloc.clear();
    return rv;
}

static int way_groups_allocated(const IXBar::Use &alloc) {
    for (unsigned i = 1; i < alloc.way_use.size(); ++i)
        if (alloc.way_use[i].slice == alloc.way_use[0].slice)
            return i;
    return alloc.way_use.size();
}

int IXBar::getHashGroup(cstring name) {
    int hash_group = find(hash_group_use, name) - hash_group_use.begin();
    if (hash_group >= HASH_GROUPS)
        hash_group = find(hash_group_use, cstring()) - hash_group_use.begin();
    if (hash_group >= HASH_GROUPS) {
        LOG2("failed to allocate hash group");
        return -1; }
    hash_group_use[hash_group] = name;
    return hash_group;
}

bool IXBar::allocHashWay(const IR::MAU::Table *tbl, const IR::MAU::Table::Way &way, Use &alloc) {
    int hash_group = getHashGroup(tbl->name);
    if (hash_group < 0) return false;
    int way_bits = ceil_log2(way.entries/1024U/way.match_groups);
    int group;
    unsigned way_mask = 0;
    LOG3("Need " << way_bits << " mask bits for way " << alloc.way_use.size() <<
         " in table " << tbl->name);
    for (group = 0; group < HASH_INDEX_GROUPS; group++) {
        if (!(hash_index_inuse[group] & alloc.hash_table_input))
            break; }
    if (group >= HASH_INDEX_GROUPS) {
        if (alloc.way_use.empty())
            group = 0;  // share with another table?
        else
            group = alloc.way_use[alloc.way_use.size() % way_groups_allocated(alloc)].slice;
        LOG3("all hash slices in use, reusing " << group); }
    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        if (way_bits <= 0) break;
        if (!(hash_single_bit_inuse[bit] & alloc.hash_table_input)) {
            way_mask |= 1U << bit;
            way_bits--; } }
    if (way_bits > 0)
        LOG3("failed to allocate enough way mask bits, will need to reuse some");
    alloc.way_use.emplace_back(Use::Way{ hash_group, group, way_mask });
    hash_index_inuse[group] |= alloc.hash_table_input;
    for (auto bit : bitvec(way_mask))
        hash_single_bit_inuse[bit] |= alloc.hash_table_input;
    for (auto ht : bitvec(alloc.hash_table_input)) {
        hash_index_use[ht][group] = tbl->name;
        for (auto bit : bitvec(way_mask))
            hash_single_bit_use[ht][bit] = tbl->name; }
    return true;
}

bool IXBar::allocGateway(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc) {
    CollectGatewayFields collect(phv);
    tbl->apply(collect);
    if (collect.info.empty() && collect.valid_offsets.empty()) return true;
    for (auto &info : collect.info) {
        int flags = 0;
        if (info.second.xor_with)
            flags |= IXBar::Use::NeedXor;
        if (info.second.need_range)
            flags |= IXBar::Use::NeedRange;
        add_use(alloc, info.first, flags); }
    for (auto &valid : collect.valid_offsets) {
        alloc.use.emplace_back(valid.first + ".$valid", 0); }
    LOG3("gw needs alloc: " << alloc.use);
    if (!find_alloc(alloc, false, false) && !find_alloc(alloc, false, true)) {
        alloc.clear();
        return false; }
    if (!collect.compute_offsets()) {
        alloc.clear();
        LOG3("collect.compute_offsets failed?");
        return false; }
    if (collect.bits > 0) {
        int hash_group = getHashGroup(tbl->name + "$gw");
        if (hash_group < 0) {
            alloc.clear();
            return false; }
        /* FIXME -- don't need use all hash tables that we're using the ixbar for -- just those
         * tables for bytes we want to put through the hash table to get into the upper gw bits */
        alloc.compute_hash_tables();
        unsigned avail = 0;
        unsigned need = (1U << collect.bits) - 1;
        for (auto i : Range(0, HASH_SINGLE_BITS-1)) {
            if ((hash_single_bit_inuse[i] & alloc.hash_table_input) == 0)
                avail |= (1U << i); }
        int shift = 0;
        while (((avail >> shift) & need) != need && avail < need)
            shift += 4;
        if (((avail >> shift) & need) != need) {
            alloc.clear();
            LOG3("failed to find " << collect.bits << " continuous nibble aligend bits in 0x" <<
                 hex(avail));
            return false; }
        for (auto &info : collect.info) {
            if (info.second.offset < 32) continue;
            info.second.offset += shift;
            alloc.bit_use.emplace_back(info.first->name, hash_group, 0,
                                       info.second.offset - 32, info.first->size); }
        for (auto &valid : collect.valid_offsets) {
            if (valid.second < 32) continue;
            valid.second += shift;
            alloc.bit_use.emplace_back(valid.first + ".$valid", hash_group, 0,
                                       valid.second - 32, 1); }
        for (auto ht : bitvec(alloc.hash_table_input))
            for (int i = 0; i < collect.bits; ++i)
                hash_single_bit_use[ht][shift + i] = tbl->name + "$gw";
        for (int i = 0; i < collect.bits; ++i)
            hash_single_bit_inuse[shift + i] |= alloc.hash_table_input; }
    return true;
}

bool IXBar::allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv,
                       Use &tbl_alloc, Use &gw_alloc) {
    if (!tbl) return true;
    LOG2("IXBar::allocTable(" << tbl->name << ")");
    if (tbl->match_table && !allocMatch(tbl->layout.ternary, tbl->match_table, phv, tbl_alloc))
        return false;
    for (auto &way : tbl->ways) {
        if (!allocHashWay(tbl, way, tbl_alloc)) {
            tbl_alloc.clear();
            return false; } }
    if (!allocGateway(tbl, phv, gw_alloc)) {
        tbl_alloc.clear();
        gw_alloc.clear();
        return false; }
    return true;
}

void IXBar::update(cstring name, const Use &alloc) {
    auto &use = alloc.ternary ? ternary_use.base() : exact_use.base();
    auto &fields = alloc.ternary ? ternary_fields : exact_fields;
    for (auto &byte : alloc.use) {
        if (!byte.loc) continue;
        if (byte.loc.byte == 5 && alloc.ternary) {
            /* the sixth byte in a ternary group is actually half a byte group it shares with
             * the adjacent ternary group */
            int byte_group = byte.loc.group/2;
            if (byte == byte_group_use[byte_group]) continue;
            if (byte_group_use[byte_group].first)
                BUG("conflicting ixbar allocation");
            byte_group_use[byte_group] = byte;
        } else {
            if (byte == use[byte.loc]) continue;
            if (use[byte.loc].first)
                BUG("conflicting ixbar allocation");
            use[byte.loc] = byte; }
        fields.emplace(byte.field, byte.loc); }
    for (auto &bits : alloc.bit_use) {
        const Loc *loc = nullptr;
        for (int b = 0; b < bits.width; b++) {
            if ((!loc || loc->byte != (b + bits.lo)/8) &&
                !(loc = findExactByte(bits.field, (b + bits.lo)/8)))
                BUG("ixbar hashing bits from %s, but they're not on the bus", bits.field);
            for (auto ht : bitvec(alloc.hash_table_input)) {
                if (hash_single_bit_use.at(ht, b + bits.bit))
                    BUG("conflicting ixbar hash bit allocation");
                hash_single_bit_use.at(ht, b + bits.bit) = name; }
            hash_single_bit_inuse[b + bits.bit] |= alloc.hash_table_input; }
        if (!hash_group_use[bits.group])
            hash_group_use[bits.group] = name;
        else if (hash_group_use[bits.group] != name)
            BUG("conflicting hash group use between %s and %s", name, hash_group_use[bits.group]); }
    for (auto &way : alloc.way_use) {
        if (!hash_group_use[way.group])
            hash_group_use[way.group] = name;
        hash_index_inuse[way.slice] |= alloc.hash_table_input;
        for (int hash : bitvec(alloc.hash_table_input)) {
            if (!hash_index_use[hash][way.slice])
                hash_index_use[hash][way.slice] = name;
            for (auto bit : bitvec(way.mask)) {
                hash_single_bit_inuse[bit] |= alloc.hash_table_input;
                if (!hash_single_bit_use[hash][bit])
                    hash_single_bit_use[hash][bit] = name; } } }
}

void IXBar::update(cstring name, const TableResourceAlloc *rsrc) {
    update(name + "$gw", rsrc->gateway_ixbar);
    update(name, rsrc->match_ixbar);
}

static void write_one(std::ostream &out, const std::pair<cstring, int> &f,
                      std::map<cstring, char> &fields) {
    if (f.first) {
        if (!fields.count(f.first)) {
            if (fields.size() >= 26)
                fields.emplace(f.first, 'a' + fields.size() - 26);
            else
                fields.emplace(f.first, 'A' + fields.size()); }
        out << fields[f.first] << hex(f.second);
    } else {
        out << ".."; }
}
static void write_one(std::ostream &out, cstring n, std::map<cstring, char> &names) {
    if (n) {
        if (!names.count(n)) {
            if (names.size() >= 26)
                names.emplace(n, 'a' + names.size() - 26);
            else
                names.emplace(n, 'A' + names.size()); }
        out << names[n];
    } else {
        out << '.'; }
}

template<class T>
static void write_group(std::ostream &out, const T &grp, std::map<cstring, char> &fields) {
    for (auto &a : grp) write_one(out, a, fields);
}

/* IXBarPrinter in .gdbinit should match this */
std::ostream &operator<<(std::ostream &out, const IXBar &ixbar) {
    std::map<cstring, char>     fields;
    out << "Input Xbar:" << std::endl;
    for (int r = 0; r < IXBar::EXACT_GROUPS; r++) {
        write_group(out, ixbar.exact_use[r], fields);
        if (r < IXBar::BYTE_GROUPS) {
            out << "  ";
            write_group(out, ixbar.ternary_use[2*r], fields);
            out << " ";
            write_one(out, ixbar.byte_group_use[r], fields);
            out << " ";
            write_group(out, ixbar.ternary_use[2*r+1], fields); }
        out << std::endl; }
    for (auto &f : fields)
        out << "   " << f.second << " " << f.first << std::endl;
    std::map<cstring, char>     tables;
    out << "Hash:" << std::endl;
    for (int h = 0; h < IXBar::HASH_TABLES; ++h) {
        write_group(out, ixbar.hash_index_use[h], tables);
        out << " ";
        write_group(out, ixbar.hash_single_bit_use[h], tables);
        if (h < IXBar::HASH_GROUPS) {
            out << "   ";
            write_one(out, ixbar.hash_group_use[h], tables); }
        out << std::endl; }
    for (auto &t : tables)
        out << "   " << t.second << " " << t.first << std::endl;
    return out;
}

void dump(const IXBar *ixbar) {
    std::cout << *ixbar;
}
void dump(const IXBar &ixbar) {
    std::cout << ixbar;
}

std::ostream &operator<<(std::ostream &out, const IXBar::Use &use) {
    for (auto &b : use.use)
        out << b << std::endl;
    for (auto &w : use.way_use)
        out << "[ " << w.group << ", " << w.slice << ", 0x" << hex(w.mask) << " ]" << std::endl;
    return out;
}

void dump(const IXBar::Use *use) {
    std::cout << *use;
}
void dump(const IXBar::Use &use) {
    std::cout << use;
}
