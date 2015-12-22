#include "input_xbar.h"
#include "lib/algorithm.h"
#include "lib/bitvec.h"
#include "lib/hex.h"
#include "lib/log.h"

void IXBar::clear() {
    exact_use.clear();
    ternary_use.clear();
    byte_group_use.clear();
    exact_fields.clear();
    ternary_fields.clear();
}

static bool find_alloc(IXBar::Use &alloc, int groups, int bytes_per_group,
                       Alloc2Dbase<std::pair<cstring, int>>     &use,
                       std::multimap<cstring, IXBar::Loc>       &fields,
                       bool second_try) {
    int groups_needed = (alloc.use.size() + bytes_per_group - 1)/bytes_per_group;
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

bool IXBar::allocTable(bool ternary, const IR::Table *tbl, Use &alloc) {
    alloc.clear();
    alloc.ternary = ternary;
    if (!tbl->reads) return true;
    set<cstring>                        fields_needed;
    bool                                rv;
    for (auto r : *tbl->reads) {
        auto field = dynamic_cast<const IR::FieldRef *>(r);
        if (auto mask = dynamic_cast<const IR::BAnd *>(r)) {
            field = dynamic_cast<const IR::FieldRef *>(mask->operands[0]);
        } else if (auto prim = dynamic_cast<const IR::Primitive *>(r)) {
            if (prim->name != "valid")
                throw Util::CompilerBug("unexpected reads expression %s", r);
            // FIXME -- for now just assuming we can fit the valid bit reads in as needed
            continue; }
        if (!field)
            throw Util::CompilerBug("unexpected reads expression %s", r);
        cstring fname = field->toString();
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
    }
    if (!rv) alloc.clear();
    return rv;
}

bool IXBar::allocGateway(const IR::Expression * /*tbl*/, Use &/*alloc*/) {
    // TODO(cdodd)
    return true;
}

void IXBar::update(const Use &alloc) {
    auto &use = alloc.ternary ? ternary_use.base() : exact_use.base();
    auto &fields = alloc.ternary ? ternary_fields : exact_fields;
    for (auto &byte : alloc.use) {
        if (!byte.loc) continue;
        if (byte == use[byte.loc]) continue;
        if (use[byte.loc].first)
            throw Util::CompilerBug("conflicting ixbar allocation");
        use[byte.loc] = byte;
        fields.emplace(byte.field, byte.loc); }
}

bool IXBar::allocTable(const IR::MAU::Table *tbl, Use &tbl_alloc, Use &gw_alloc) {
    if (!tbl) return true;
    if (tbl->match_table && !allocTable(tbl->layout.ternary, tbl->match_table, tbl_alloc))
        return false;
    if (tbl->gateway_expr && !allocGateway(tbl->gateway_expr, gw_alloc)) {
        tbl_alloc.clear();
        return false; }
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
    } else
        out << "..";
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
        out << "  ";
        write_group(out, ixbar.ternary_use[2*r], fields);
        out << " ";
        write_one(out, ixbar.byte_group_use[r], fields);
        out << " ";
        write_group(out, ixbar.ternary_use[2*r+1], fields);
        out << std::endl; }
    for (auto &f : fields)
        out << "   " << f.second << " " << f.first << std::endl;
    return out;
}
