#include "memories.h"
#include "resource_estimate.h"

void Memories::clear() {
    sram_use.clear();
    tcam_use.clear();
    mapram_use.clear();
    sram_match_bus.clear();
    tind_bus.clear();
    action_data_bus.clear();
    stateful_bus.clear();
}

bool Memories::alloc2Port(cstring name, int entries, int entries_per_word, Use &alloc) {
    int rams = (entries + 1024*entries_per_word - 1) / (1024*entries_per_word);
    alloc.type = Use::TWOPORT;
    for (int row = 0; row < SRAM_ROWS; row++) {
        if (stateful_bus[row]) continue;
        Use::Row *alloc_row = 0;
        for (int col = MAPRAM_COLUMNS-1; col >= 0; col--) {
            if (mapram_use[row][col]) continue;
            if (sram_use[row][col + SRAM_COLUMNS - MAPRAM_COLUMNS]) continue;
            stateful_bus[row] = mapram_use[row][col] =
            sram_use[row][col + SRAM_COLUMNS - MAPRAM_COLUMNS] = name;
            if (!alloc_row) {
                alloc.row.emplace_back(row);
                alloc_row = &alloc.row.back(); }
            alloc_row->col.push_back(col + SRAM_COLUMNS - MAPRAM_COLUMNS);
            alloc_row->mapcol.push_back(col);
            if (!--rams) return true; } }
    remove(name, alloc);
    alloc.row.clear();
    return false;
}

bool Memories::allocRams(cstring name, int width, int depth,
                         Alloc2Dbase<cstring> &use, Alloc2Dbase<cstring> *bus,
                         Use &alloc) {
    vector<int> free(use.rows()), free_bus(use.rows());
    for (int row = 0; row < use.rows(); row++) {
        for (auto col : use[row]) if (!col) free[row]++;
        if (bus) {
            free_bus[row] = -1;
            for (int col = 0; col < bus->cols(); col++)
                if (!(*bus)[row][col]) {
                    free_bus[row] = col;
                    break; } } }
    for (int row = 0; row + width <= use.rows(); row++) {
        if (free_bus[row] < 0) continue;
        int max = free[row];
        for (int i = 1; i < width; i++) {
            if (free_bus[row+i] < 0) max = 0;
            if (free[row+i] < max) max = free[row+i]; }
        if (!max) continue;
        if (max > depth) max = depth;
        for (int i = 0; i < width; i++) {
            alloc.row.emplace_back(row+i);
            auto &alloc_row = alloc.row.back();
            if (bus) {
                (*bus)[row+i][free_bus[row+i]] = name;
                alloc_row.bus = free_bus[row+i]; }
            int cnt = 0;
            int col_idx = -1;
            for (auto &col : use[row+i]) {
                ++col_idx;
                if (!col) {
                    col = name;
                    alloc_row.col.push_back(col_idx);
                    if (++cnt == max)
                        break; } } }
        row += width-1;
        if (!(depth -= max)) return true; }
    remove(name, alloc);
    alloc.row.clear();
    return false;
}

namespace {
class AllocAttached : public Inspector {
    const IR::MAU::Table        *tbl;
    Memories                    &mem;
    bool                        &ok;
    int                         entries;
    map<cstring, Memories::Use> &alloc;
    bool preorder(const IR::Counter *ctr) override {
        cstring name = ctr->name + "$ctr";
        assert(!alloc.count(name));
        if (!mem.alloc2Port(name, ctr->direct ? entries : ctr->instance_count,
                            CounterPerWord(ctr), alloc[name]))
            ok = false;
        return false; }
    bool preorder(const IR::Meter *mtr) override {
        cstring name = mtr->name + "$mtr";
        assert(!alloc.count(name));
        if (!mem.alloc2Port(name, mtr->direct ? entries : mtr->instance_count, 1, alloc[name]))
            ok = false;
        return false; }
    bool preorder(const IR::Register *reg) override {
        cstring name = reg->name + "$reg";
        assert(!alloc.count(name));
        if (!mem.alloc2Port(name, reg->direct ? entries : reg->instance_count,
                            RegisterPerWord(reg), alloc[name]))
            ok = false;
        return false; }
    bool preorder(const IR::MAU::TernaryIndirect *ti) override {
        assert(!alloc.count(ti->name));
        return false; }
    bool preorder(const IR::MAU::ActionData *ad) override {
        assert(!alloc.count(ad->name));
        return false; }
    bool preorder(const IR::ActionProfile *ap) override {
        assert(!alloc.count(ap->name));
        return false; }
    bool preorder(const IR::ActionSelector *as) override {
        cstring name = as->name + "$sel";
        assert(!alloc.count(name));
        return false; }
    bool preorder(const IR::Attached *att) override {
        throw Util::CompilerBug("Unknown attached table type %s", att->kind()); }
public:
    AllocAttached(Memories *m, const IR::MAU::Table *t, bool *o, int e,
                  map<cstring, Memories::Use> &a)
    : tbl(t), mem(*m), ok(*o), entries(e) , alloc(a) {}
};
}

bool Memories::allocTable(const IR::MAU::Table *table, int &entries,  map<cstring, Use> &alloc)
{
    bool ok = true;
    int width, depth, groups = 1;
    if (table->layout.ternary) {
        depth = (entries + 511U)/512U;
        width = (table->layout.match_width_bits + 47)/44;  // +4 bits for v/v, round up
        entries = depth * 512;
    } else if (table->match_table) {
        width = table->layout.match_width_bits + table->layout.overhead_bits + 4;  // valid/version
        groups = 128/width;
        if (groups) {
            width = 1;
        } else {
            groups = 1;
            width = (width+127)/128; }
        depth = ((entries + groups - 1U)/groups + 1023)/1024U;
        entries = depth * groups * 1024U;
    } else {
        width = depth = entries = 0; }
    for (auto at : table->attached)
        at->apply(AllocAttached(this, table, &ok, entries, alloc));
    assert(!alloc.count(table->name));
    if (table->layout.ternary) {
        alloc[table->name].type = Use::TERNARY;
        ok &= allocRams(table->name, width, depth, tcam_use, 0, alloc[table->name]);
    } else if (table->match_table) {
        alloc[table->name].type = Use::EXACT;
        ok &= allocRams(table->name, width, depth, sram_use, &sram_match_bus, alloc[table->name]);
    }
    return ok;
}

void Memories::Use::visit(Memories &mem, std::function<void(cstring &)> fn) const {
    Alloc2Dbase<cstring> *use, *mapuse = 0, *bus = 0;
    switch (type) {
    case EXACT:
        use = &mem.sram_use;
        bus = &mem.sram_match_bus;
        break;
    case TERNARY:
        use = &mem.tcam_use;
        break;
    case TIND:
        use = &mem.sram_use;
        bus = &mem.tind_bus;
        break;
    case TWOPORT:
        use = &mem.sram_use;
        mapuse = &mem.mapram_use;
        break;
    case ACTIONDATA:
        use = &mem.sram_use;
        bus = &mem.action_data_bus;
        break;
    default:
        throw Util::CompilerBug("Unhandled memory use type %d in Memories::Use::visit", type); }
    for (auto &r : row) {
        if (bus)
            fn((*bus)[r.row][r.bus]);
        if (type == TWOPORT)
            fn(mem.stateful_bus[r.row]);
        for (auto col : r.col)
            fn((*use)[r.row][col]);
        for (auto col : r.mapcol)
            fn((*mapuse)[r.row][col]); }
}

void Memories::update(cstring name, const Memories::Use &alloc) {
    alloc.visit(*this, [name](cstring &use) {
        if (use)
            throw Util::CompilerBug("conflicting memory use between %s and %s", use, name);
        use = name; });
}
void Memories::update(const map<cstring, Use> &alloc) {
    for (auto &a : alloc) update(a.first, a.second);
}

void Memories::remove(cstring name, const Memories::Use &alloc) {
    alloc.visit(*this, [name](cstring &use) {
        if (use != name)
            throw Util::CompilerBug("Undo failure for %s", name);
        use = nullptr; });
}
void Memories::remove(const map<cstring, Use> &alloc) {
    for (auto &a : alloc) remove(a.first, a.second);
}

/* MemoriesPrinter in .gdbinit should match this */
std::ostream &operator<<(std::ostream &out, const Memories &mem) {
    const Alloc2Dbase<cstring> *arrays[] = { &mem.tcam_use, &mem.sram_match_bus, &mem.tind_bus,
        &mem.action_data_bus, &mem.sram_use, &mem.mapram_use };
    std::map<cstring, char>     tables;
    out << "tc  eb  tib ab  srams       mapram  sb" << std::endl;
    for (int r = 0; r < Memories::TCAM_ROWS; r++) {
        for (auto arr : arrays) {
            for (int c = 0; c < arr->cols(); c++) {
                if (r >= arr->rows()) {
                    out << ' ';
                } else {
                    auto tbl = (*arr)[r][c];
                    if (tbl) {
                        if (!tables.count(tbl))
                            tables.emplace(tbl, 'A' + tables.size());
                        out << tables.at(tbl);
                    } else {
                        out << '.'; } } }
            out << "  "; }
        if (r < Memories::SRAM_ROWS) {
            auto tbl = mem.stateful_bus[r];
            if (tbl) {
                if (!tables.count(tbl))
                    tables.emplace(tbl, 'A' + tables.size());
                out << tables.at(tbl);
            } else {
                out << '.'; } }
        out << std::endl; }
    for (auto &tbl : tables)
        out << "   " << tbl.second << " " << tbl.first << std::endl;
    return out;
}
