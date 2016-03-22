#include "input_xbar.h"
#include "lib/algorithm.h"
#include "lib/bitvec.h"
#include "lib/bitops.h"
#include "lib/hex.h"
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

static bool find_alloc(IXBar::Use &alloc, int groups, int bytes_per_group,
                       Alloc2Dbase<std::pair<cstring, int>>     &use,
                       std::multimap<cstring, IXBar::Loc>       &fields,
                       bool second_try) {
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
            if (!grp.free) continue;
            need_alloc[&need - &alloc.use[0]] = true;
            need.loc.group = grp.group;
            need.loc.byte = *grp.free.min();
            grp.free.min() = false;
            found = true;
            break; }
        if (!found) {
            LOG3("failed to fit");
            return false; } }
    /* succeded -- update the use info */
    for (int i : need_alloc) {
        fields.emplace(alloc.use[i].field, alloc.use[i].loc);
        use[alloc.use[i].loc] = alloc.use[i]; }
    return /* alloc */ true;
}

bool IXBar::allocTable(bool ternary, const IR::Table *tbl, const PhvInfo &phv, Use &alloc) {
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
        cstring fname = finfo->name;
        if (fields_needed.count(fname))
            throw Util::CompilationError("field %s read twice by table %s", fname, tbl->name);
        fields_needed.insert(fname);
        int size = (field->type->width_bits() + 7)/8U;
        for (int i = 0; i < size; i++)
            alloc.use.emplace_back(fname, i); }
    LOG1("need " << alloc.use.size() << " bytes for table " << tbl->name);
    if (ternary) {
        rv = find_alloc(alloc, TERNARY_GROUPS, TERNARY_BYTES_PER_GROUP,
                        ternary_use, ternary_fields, false)
          || find_alloc(alloc, TERNARY_GROUPS, TERNARY_BYTES_PER_GROUP,
                        ternary_use, ternary_fields, true);
    } else {
        rv = find_alloc(alloc, EXACT_GROUPS, EXACT_BYTES_PER_GROUP,
                        exact_use, exact_fields, false)
          || find_alloc(alloc, EXACT_GROUPS, EXACT_BYTES_PER_GROUP,
                        exact_use, exact_fields, true);
        if (rv) alloc.compute_hash_tables();
    }
    if (!rv) alloc.clear();
    return rv;
}

static int way_groups_allocated(const IXBar::Use &alloc) {
    for (unsigned i = 1; i < alloc.way_use.size(); ++i)
        if (alloc.way_use[i].slice == alloc.way_use[0].slice)
            return i;
    return alloc.way_use.size();
}

bool IXBar::allocHashWay(const IR::MAU::Table *tbl, const IR::MAU::Table::Way &way, Use &alloc) {
    if (alloc.hash_group < 0) {
        for (int i = 0; i < HASH_GROUPS; i++) {
            if (!hash_group_use[i] || hash_group_use[i] == tbl->name) {
                hash_group_use[i] = tbl->name;
                alloc.hash_group = i;
                break; } } }
    if (alloc.hash_group < 0) {
        LOG2("failed to allocate hash group");
        return false; }
    int way_bits = ceil_log2(way.entries/1024U/way.match_groups);
    int group;
    unsigned way_mask = 0;
    LOG3("Need " << way_bits << " mask bits for way " << alloc.way_use.size() <<
         " in table " << tbl->name);
    for (group = 0; group < HASH_INDEX_GROUPS; group++) {
        if (!(hash_index_inuse[group] & alloc.hash_table_input))
            break; }
    if (group >= HASH_INDEX_GROUPS) {
        group = alloc.way_use[alloc.way_use.size() % way_groups_allocated(alloc)].slice;
        LOG3("all hash slices in use, reusing " << group); }
    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        if (way_bits <= 0) break;
        if (!(hash_single_bit_inuse[bit] & alloc.hash_table_input)) {
            way_mask |= 1U << bit;
            way_bits--; } }
    if (way_bits > 0)
        LOG3("failed to allocate enough way mask bit, will need to reuse some");
    alloc.way_use.emplace_back(Use::Way{ group, way_mask });
    hash_index_inuse[group] |= alloc.hash_table_input;
    for (auto bit : bitvec(way_mask))
        hash_single_bit_inuse[bit] |= alloc.hash_table_input;
    for (auto ht : bitvec(alloc.hash_table_input)) {
        hash_index_use[ht][group] = tbl->name;
        for (auto bit : bitvec(way_mask))
            hash_single_bit_use[ht][bit] = tbl->name; }
    return true;
}

bool IXBar::allocGateway(const IR::Expression * /*tbl*/, const PhvInfo &/*phv*/, Use &/*alloc*/) {
    // TODO(cdodd)
    return true;
}

void IXBar::update(const Use &alloc) {
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
}

bool IXBar::allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv,
                       Use &tbl_alloc, Use &gw_alloc) {
    if (!tbl) return true;
    tbl_alloc.clear();
    gw_alloc.clear();
    if (tbl->match_table && !allocTable(tbl->layout.ternary, tbl->match_table, phv, tbl_alloc))
        return false;
    for (auto &way : tbl->ways) {
        if (!allocHashWay(tbl, way, tbl_alloc)) {
            tbl_alloc.clear();
            return false; } }
    for (auto &gw : tbl->gateway_rows) {
        if (!allocGateway(gw.first, phv, gw_alloc)) {
            tbl_alloc.clear();
            gw_alloc.clear();
            return false; } }
    return true;
}

template<class T>
static void write_one(std::ostream &out, const T &f, std::map<cstring, char> &fields) {
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

template<class T>
static void write_group(std::ostream &out, const T &grp, std::map<cstring, char> &fields) {
    for (auto &a : grp) write_one(out, a, fields);
}

/* IXBarPrinter in .gdbinit should match this */
std::ostream &operator<<(std::ostream &out, const IXBar &ixbar) {
    std::map<cstring, char>     fields;
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
    return out;
}

void pIXBar(const IXBar *ixbar) {
    std::cout << *ixbar;
}
