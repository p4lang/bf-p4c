#include "lib/bitops.h"
#include "lib/range.h"
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

void Memories::add_table(const IR::MAU::Table *t, int entries) {
    if (!t)
        tables.push_back(std::make_pair(t, entries));
}

bool Memories::analyze_tables(mem_info &mi) {

    for (auto &t_p : tables) {
        if (t_p.second == -1) continue;
        auto table = t_p.first;
        int entries = t_p.second;
        if (!table->layout.ternary) {
            mi.match_tables++;
            int width = table->ways[0].width;
            int groups = table->ways[0].match_groups;
            int depth = ((entries + groups - 1U)/groups + 1023)/1024U;
            mi.match_bus_min += width;
            mi.match_RAMs += depth;
        }
        for (auto at : table->attached) {
            if (at->is<IR::MAU::ActionData>()) {
                mi.action_tables++;
                int sz = ceil_log2(table->layout.action_data_bytes) + 3;
                int width = sz > 7 ? 1 << (sz - 7) : 1;
                mi.action_bus_min += width;
                int per_ram = sz > 7 ? 10 : 17 - sz;
                int depth = ((entries - 1) >> per_ram) + 1;
                mi.action_RAMs += depth;
            } else if (at->is<IR::MAU::TernaryIndirect>()) {
                mi.tind_tables++;
                mi.tind_RAMs += (entries + 1023U) / 1024U; 
            }
        }
    }

    if (mi.match_tables > 16 || mi.match_bus_min > 16 || mi.tind_tables > 8 
        || mi.action_tables > 16 || mi.action_bus_min > 16 
        || mi.match_RAMs + mi.action_RAMs + mi.tind_RAMs > 80) {
        return false;
    }
    return true;    
}

bool Memories::allocate_all_exact(Memories::mem_info &mi) {
    return true;

}

bool Memories::allocate_all() {
    mem_info mi;
    if (!analyze_tables(mi)) {
        return false;
    }

    if (!allocate_all_exact(mi)) {
        return false;
    }

    return true;
}



bool Memories::alloc2Port(cstring name, int entries, int entries_per_word, Use &alloc) {
    LOG3("alloc2Port(" << name << ", " << entries << ", " << entries_per_word << ")");
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
    LOG3("failed");
    return false;
}

bool Memories::allocActionRams(cstring name, int width, int depth, Use &alloc) {
    LOG3("allocActionRams(" << name << ", " << width << 'x' << depth << ")");
    int count = 0;
    auto left = Range(0, LEFT_SIDE_COLUMNS-1);
    auto right = Range(LEFT_SIDE_COLUMNS, SRAM_COLUMNS-1);
    for (int row : Range(sram_use.rows()-1, 0)) {
        for (int side : Range(1, 0)) {
            Use::Row *current = nullptr;
            if (action_data_bus[row][side]) continue;
            action_data_bus[row][side] = name;
            for (int col : side ? right : left) {
                if (sram_use[row][col]) continue;
                if (!current) {
                    alloc.row.emplace_back(row, side);
                    current = &alloc.row.back(); }
                current->col.push_back(col);
                sram_use[row][col] = name;
                if (++count == depth) {
                    count = 0;
                    if (!--width) return true; } } } }
    remove(name, alloc);
    alloc.row.clear();
    LOG3("failed");
    return false;
}

bool Memories::allocBus(cstring name, Alloc2Dbase<cstring> &bus_use, Use &alloc) {
    for (int row : Range(0, bus_use.rows()-1)) {
        for (int bus : Range(0, bus_use.cols()-1)) {
            if (bus_use[row][bus]) continue;
            bus_use[row][bus] = name;
            alloc.row.emplace_back(row, bus);
            return true; } }
    return false;
}

bool Memories::allocRams(cstring name, int width, int depth, Alloc2Dbase<cstring> &use,
                         Alloc2Dbase<cstring> *bus, Use &alloc) {
    LOG3("allocRams(" << name << ", " << width << 'x' << depth << ")");
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
        LOG3("The max rows available " << max);
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
                    LOG3("Allocating the RAM at " << row << "," << col_idx);
                    alloc_row.col.push_back(col_idx);
                    if (++cnt == max)
                        break; } } }
        row += width-1;
        if (!(depth -= max)) return true; }
    remove(name, alloc);
    alloc.row.clear();
    LOG3("failed");
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
        int sz = ceil_log2(tbl->layout.overhead_bits);
        if (sz < 3) sz = 3;  // min 8 bits
        if (sz > 6)
            throw new Util::CompilationError("%1%: more than 64 bits of overhead for ternary "
                                             "table", tbl->match_table);
        alloc[ti->name].type = Memories::Use::TIND;
        if (!mem.allocRams(ti->name, 1, ((entries - 1) >> (17 - sz)) + 1, mem.sram_use,
                           &mem.tind_bus, alloc[ti->name]))
            ok = false;
        return false; }
    bool preorder(const IR::MAU::ActionData *ad) override {
        assert(!alloc.count(ad->name));
        int sz = ceil_log2(tbl->layout.action_data_bytes) + 3;
        if (sz > 10)
            throw new Util::CompilationError("%1%: more than 1024 bits wide for action data "
                                             "table", tbl->match_table);
        alloc[ad->name].type = Memories::Use::ACTIONDATA;
        int width = sz > 7 ? 1 << (sz - 7) : 1;
        int per_ram = sz > 7 ? 10 : 17 - sz;
        if (!mem.allocActionRams(ad->name, width, ((entries - 1) >> per_ram) + 1, alloc[ad->name]))
            ok = false;
        return false; }
    bool preorder(const IR::ActionProfile *ap) override {
        assert(!alloc.count(ap->name));
        return false; }
    bool preorder(const IR::ActionSelector *as) override {
        cstring name = as->name + "$sel";
        assert(!alloc.count(name));
        return false; }
    bool preorder(const IR::Attached *att) override {
        BUG("Unknown attached table type %s", att->kind()); }

 public:
    AllocAttached(Memories *m, const IR::MAU::Table *t, bool *o, int e,
                  map<cstring, Memories::Use> &a)
    : tbl(t), mem(*m), ok(*o), entries(e) , alloc(a) {}
};
}  // namespace

bool Memories::allocTable(cstring name, const IR::MAU::Table *table, int &entries,
                          map<cstring, Use> &alloc, const IXBar::Use &match_ixbar) {
    if (!table) return true;
    LOG2("Memories::allocTable(" << name << ", &" << entries << ")");
    bool ok = true;
    int width, depth, groups = 1;
    if (table->layout.ternary) {
        depth = (entries + 511U)/512U;
        width = (table->layout.match_width_bits + 47)/44;  // +4 bits for v/v, round up
        if (width < 12)
            width = std::max(width, match_ixbar.groups());
        entries = depth * 512;
    } else if (!table->ways.empty()) {
        /* Assuming all ways have the same format and width (only differ in depth) */
        width = table->ways[0].width;
        groups = table->ways[0].match_groups;
        depth = ((entries + groups - 1U)/groups + 1023)/1024U;
        if (depth < static_cast<int>(table->ways.size()))
            depth = table->ways.size();
        entries = depth * groups * 1024U;
    } else {
        width = depth = entries = 0; }
    LOG3("   " << width << 'x' << depth << " entries=" << entries);
    if (table->layout.ternary) {
        assert(!alloc.count(name));
        alloc[name].type = Use::TERNARY;
        ok &= allocRams(name, width, depth, tcam_use, 0, alloc[name]);
    } else if (!table->ways.empty()) {
        assert(match_ixbar.way_use.size() == table->ways.size());
        struct waybits {
            bitvec              bits;
            decltype(bits.end()) next;
            waybits() : next(bits.end()) {} };
        std::map<int, waybits> alloc_bits;
        for (auto &way : match_ixbar.way_use) {
            LOG3("The way is m|s|g " << way.mask << " " << way.slice << " " << way.group);
            alloc_bits[way.group].bits |= way.mask;
        }
        assert(!alloc.count(name));
        alloc[name].type = Use::EXACT;
        int alloc_depth = 0;
        auto ixbar_way = match_ixbar.way_use.begin();
        for (int i = table->ways.size(); i > 0; --i, ++ixbar_way) {
            int log2size = std::max(ceil_log2((depth+i-1)/i), 0);
            int sz = 1 << log2size;
            ok &= allocRams(name, width, sz, sram_use, &sram_match_bus, alloc[name]);
            alloc_depth += sz;
            unsigned mask = 0;
            auto &bits = alloc_bits[ixbar_way->group];
            for (int bit = 0; bit < log2size; bit++) {
                if (!++bits.next) ++bits.next;
                if (!bits.next || (mask & (1 << *bits.next))) {
                    ok = false;
                    WARNING("Not enough way select bits allocated in group " <<
                            ixbar_way->group << " for table " << name);
                    break; }
                mask |= 1 << *bits.next; }
            alloc[name].ways.emplace_back(sz, mask);
            if ((depth -= sz) < 1) depth = 1; }
        entries = alloc_depth * groups * 1024U; }
    if (ok) {
        for (auto at : table->attached)
            at->apply(AllocAttached(this, table, &ok, entries, alloc));
        if (table->uses_gateway()) {
            auto gwname = name + "$gw";
            alloc[gwname].type = Use::GATEWAY;
            ok &= allocBus(gwname, sram_match_bus, alloc[gwname]); } }
    return ok;
}

void Memories::Use::visit(Memories &mem, std::function<void(cstring &)> fn) const {
    Alloc2Dbase<cstring> *use = 0, *mapuse = 0, *bus = 0;
    switch (type) {
    case EXACT:
        use = &mem.sram_use;
        bus = &mem.sram_match_bus;
        break;
    case TERNARY:
        use = &mem.tcam_use;
        break;
    case GATEWAY:
        bus = &mem.sram_match_bus;
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
        BUG("Unhandled memory use type %d in Memories::Use::visit", type); }
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
            BUG("conflicting memory use between %s and %s", use, name);
        use = name; });
}
void Memories::update(const map<cstring, Use> &alloc) {
    for (auto &a : alloc) update(a.first, a.second);
}

void Memories::remove(cstring name, const Memories::Use &alloc) {
    alloc.visit(*this, [name](cstring &use) {
        if (use != name)
            BUG("Undo failure for %s", name);
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

void dump(const Memories *mem) {
    std::cout << *mem;
}
