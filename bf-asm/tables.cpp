#include <config.h>

#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

#include <unordered_map>

extern unsigned unique_action_handle;

std::map<std::string, Table *> Table::all;
std::map<std::string, Table::Type *> *Table::Type::all;

Table::Table(int line, std::string &&n, gress_t gr, Stage *s, int lid) :
    name_(n), stage(s), gress(gr), lineno(line), logical_id(lid)
{
    if (lineno >= 0) {
        assert(all.find(name_) == all.end());
        all.emplace(name_, this); }
    if (stage)
        stage->all_refs.insert(&stage);
}
Table::~Table() {
    if (lineno >= 0)
        all.erase(name_);
    if (stage)
        stage->all_refs.erase(&stage);
}

Table::Type::Type(std::string &&name) {
    if (!all) all = new std::map<std::string, Type *>();
    if (get(name)) {
        fprintf(stderr, "Duplicate table type %s\n", name.c_str());
        exit(1); }
    self = all->emplace(name, this).first;
}

Table::Type::~Type() {
    all->erase(self);
    if (all->empty()) {
        delete all;
        all = 0; }
}

int Table::table_id() const { return (stage->stageno << 4) + logical_id; }

void Table::Call::setup(const value_t &val, Table *tbl) {
    if (!CHECKTYPE2(val, tSTR, tCMD)) return;
    if (val.type == tSTR) {
        Ref::operator=(val);
        return; }
    Ref::operator=(val[0]);
    for (int i = 1; i < val.vec.size; i++) {
        if (val[i].type == tINT)
            args.emplace_back(val[i].i);
        else if (val[i].type == tCMD && val[i] == "hash_dist") {
            if (PCHECKTYPE(val[i].vec.size > 1, val[i][1], tINT)) {
                if (auto hd = tbl->find_hash_dist(val[i][1].i))
                    args.emplace_back(hd);
                else
                    error(val[i].lineno, "hash_dist %d not defined in table %s", val[i][1].i,
                          tbl->name()); }
        } else if (!CHECKTYPE(val[i], tSTR)) {
            ;  // syntax error message emit by CHEKCTYPE
        } else if (auto arg = tbl->lookup_field(val[i].s)) {
            if (arg->bits.size() != 1)
                error(val[i].lineno, "arg fields can't be split in format");
            args.emplace_back(arg);
        } else {
            args.emplace_back(val[i].s); } }
    lineno = val.lineno;
}

unsigned Table::Call::Arg::size() const {
    switch(type) {
    case Field:
        return fld ? fld->size : 0;
    case HashDist:
        return hd ? hd->expand >= 0 ? 23 : 16 : 0;
    case Const:
    case Name:
        return 0;
    default:
        assert(0);
    }
}

static void add_row(int lineno, std::vector<Table::Layout> &layout, int row) {
    layout.push_back(Table::Layout(lineno, row));
}

static int add_rows(std::vector<Table::Layout> &layout, const value_t &rows) {
    if (!CHECKTYPE2(rows, tINT, tRANGE)) return 1;
    if (rows.type == tINT)
        add_row(rows.lineno, layout, rows.i);
    else {
        int step = rows.lo > rows.hi ? -1 : 1;
        for (int i = rows.lo; i != rows.hi; i += step)
            add_row(rows.lineno, layout, i);
        add_row(rows.lineno, layout, rows.hi); }
    return 0;
}

static int add_col(int lineno, Table::Layout &row, int col) {
    if (contains_if(row.cols, [col](int &p)->bool { return p == col; })) {
        error(lineno, "column %d duplicated", col);
        return 1; }
    row.cols.push_back(col);
    return 0;
}

static int add_cols(Table::Layout &row, const value_t &cols) {
    int rv = 0;
    if (cols.type == tVEC) {
        if (cols.vec.size == 1)
            return add_cols(row, cols.vec[0]);
        for (auto &col : cols.vec) {
            if (col.type == tVEC) {
                error(col.lineno, "Column shape doesn't match rows");
                rv |= 1;
            } else
                rv |= add_cols(row, col); }
        return rv; }
    if (!CHECKTYPE2(cols, tINT, tRANGE)) return 1;
    if (cols.type == tINT) return add_col(cols.lineno, row, cols.i);
    int step = cols.lo > cols.hi ? -1 : 1;
    for (int i = cols.lo; i != cols.hi; i += step)
        rv |= add_col(cols.lineno, row, i);
    rv |= add_col(cols.lineno, row, cols.hi);
    return rv;
}

void Table::setup_layout(std::vector<Layout> &layout, const value_t *row,
                         const value_t *col,
                         const value_t *bus, const char *subname) {
    if (!row) {
        error(lineno, "No 'row' attribute in table %s%s", name(), subname);
        return; }
    int err = 0;
    if (row->type == tVEC)
        for (value_t &r : row->vec) err |= add_rows(layout, r);
    else
        err |= add_rows(layout, *row);
    if (err) return;
    if (col) {
        if (col->type == tVEC && col->vec.size == (int)layout.size()) {
            for (int i = 0; i < col->vec.size; i++)
                err |= add_cols(layout[i], col->vec[i]);
        } else {
            for (auto &lrow : layout)
                if ((err |= add_cols(lrow, *col))) break; }
    } else if (layout.size() > 1) {
        error(lineno, "No 'column' attribute in table %s%s", name(), subname);
        return; }
    if (bus) {
        if (!CHECKTYPE2(*bus, tINT, tVEC)) err = 1;
        else if (bus->type == tVEC) {
            if (bus->vec.size != (int)layout.size()) {
                error(bus->lineno, "Bus shape doesn't match rows");
                err = 1;
            } else
                for (int i = 0; i < bus->vec.size; i++)
                    if (CHECKTYPE(bus->vec[i], tINT))
                        layout[i].bus = bus->vec[i].i;
                    else err = 1;
        } else
            for (auto &lrow : layout)
              lrow.bus = bus->i; }
    if (err) return;
    for (auto i = layout.begin(); i != layout.end(); i++)
        for (auto j = i+1; j != layout.end(); j++)
            if (i->row == j->row && i->bus == j->bus) {
                char bus[16] = { 0 };
                if (i->bus >= 0) sprintf(bus, " bus %d", i->bus);
                error(i->lineno, "row %d%s duplicated in table %s%s", i->row, bus,
                      name(), subname); }
}

void Table::setup_logical_id() {
    if (logical_id >= 0) {
        if (Table *old = stage->logical_id_use[logical_id]) {
            error(lineno, "table %s wants logical id %d:%d", name(),
                  stage->stageno, logical_id);
            error(old->lineno, "already in use by %s", old->name()); }
        stage->logical_id_use[logical_id] = this; }
}

void Table::setup_maprams(VECTOR(value_t) *rams) {
    auto r = rams->begin();
    for (auto &row : layout) {
        if (r == rams->end()) {
            error(r->lineno, "Mapram layout doesn't match table layout");
            break; }
        auto &maprow = *r++;
        VECTOR(value_t) *maprow_rams, tmp;
        if (maprow.type == tINT) {
            if (layout.size() == 1) {
                maprow_rams = rams;
            } else {
                // treat as a vector of length 1
                maprow_rams = &tmp;
                tmp.size = tmp.capacity = 1;
                tmp.data = &maprow; }
        } else if (CHECKTYPE(maprow, tVEC)) {
            maprow_rams = &maprow.vec;
        } else continue;
        if (maprow_rams->size != (int)row.cols.size()) {
            error(r->lineno, "Mapram layout doesn't match table layout");
            continue; }
        for (auto mapcol : *maprow_rams)
            if (CHECKTYPE(mapcol, tINT)) {
                if (mapcol.i < 0 || mapcol.i >= MAPRAM_UNITS_PER_ROW)
                    error(mapcol.lineno, "Invalid mapram column %d", mapcol.i);
                else
                    row.maprams.push_back(mapcol.i); } }
}

void Table::setup_vpns(std::vector<Layout> &layout, VECTOR(value_t) *vpn, bool allow_holes) {
    int period, width, depth;
    const char *period_name;
    vpn_params(width, depth, period, period_name);
    if (vpn && vpn->size % (depth/period) != 0) {
        error(vpn->data[0].lineno, "Vpn list length doesn't match layout (is %d, should be %d)",
              vpn->size, depth/period);
        return; }
    int word = width;
    Layout *firstrow = 0;
    auto vpniter = vpn ? vpn->begin() : 0;
    int vpn_ctr = 0;
    bitvec used_vpns;
    bool on_repeat = false;
    for (auto &row : layout) {
        if (++word < width) {
            if (row.cols != firstrow->cols)
                error(row.lineno, "Columns across wide rows don't match in table %s", name());
            row.vpns = firstrow->vpns;
            continue; }
        word = 0;
        firstrow = &row;
        row.vpns.resize(row.cols.size());
        for (int &el : row.vpns) {
            if (vpniter) {
                if (vpniter == vpn->end()) {
                    on_repeat = true;
                    vpniter = vpn->begin(); }
                if (CHECKTYPE(*vpniter, tINT) && (el = vpniter->i) % period != 0)
                    error(vpniter->lineno, "%d is not a multiple of the %s %d", el,
                          period_name, period);
                if (!on_repeat && used_vpns[el/period].set(true))
                    error(vpniter->lineno, "Vpn %d used twice in table %s", el, name());
                ++vpniter;
            } else {
                el = vpn_ctr;
                if ((vpn_ctr += period) == depth) vpn_ctr = 0; } } }
    if (vpn && !allow_holes && error_count == 0) {
        for (int i = 0; i < vpn->size; i++)
            if (!used_vpns[i]) {
                error((*vpn)[0].lineno, "Hole in vpn list (%d) for table %s", i*period, name());
                break; } }
}

void Table::common_init_setup(const VECTOR(pair_t) &data, bool, P4Table::type) {
    setup_layout(layout, get(data, "row"), get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
        if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map"))
            format = new Format(this, fmt->map); }
    if (auto *hd = get(data, "hash_dist"))
        HashDistribution::parse(hash_dist, *hd);
}

bool Table::common_setup(pair_t &kv, const VECTOR(pair_t) &data, P4Table::type p4type) {
    if (kv.key == "format" || kv.key == "row" || kv.key == "column" || kv.key == "bus") {
        /* done in Table::common_init_setup */
    } else if (kv.key == "action") {
        action.setup(kv.value, this);
    } else if (kv.key == "action_enable") {
        if (CHECKTYPE(kv.value, tINT))
            action_enable = kv.value.i;
        if (get(data, "action"))
            enable_action_data_enable = true;
        enable_action_instruction_enable = true;
    } else if (kv.key == "enable_action_data_enable") {
        enable_action_data_enable = get_bool(kv.value);
    } else if (kv.key == "enable_action_instruction_enable") {
        enable_action_instruction_enable = get_bool(kv.value);
    } else if (kv.key == "actions") {
        if (CHECKTYPE(kv.value, tMAP))
            actions = new Actions(this, kv.value.map);
    } else if (kv.key == "action_bus") {
        if (CHECKTYPE(kv.value, tMAP))
            action_bus = new ActionBus(this, kv.value.map);
    } else if ((kv.key == "default_action")
            || (kv.key == "default_only_action")) {
        if (kv.key == "default_only_action")
            default_only_action = true;
        default_action_lineno = kv.value.lineno;
        if (CHECKTYPE2(kv.value, tSTR, tCMD))
            if (CHECKTYPE(kv.value, tSTR))
                default_action = kv.value.s;
    } else if (kv.key == "default_action_parameters") {
        if (CHECKTYPE(kv.value, tMAP))
            for(auto &v : kv.value.map)
                if (CHECKTYPE(v.key, tSTR) && CHECKTYPE(v.value, tINT))
                    default_action_parameters[v.key.s] = v.value.i;
    } else if (kv.key == "default_action_handle") {
        default_action_handle = kv.value.i;
    } else if (kv.key == "hit") {
        if (!hit_next.empty())
            error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
        else if (kv.value.type == tVEC) {
            if (kv.value.vec.size > NEXT_TABLE_SUCCESSOR_TABLE_DEPTH)
                error(kv.value.lineno, "More than %d hit entries not supported",
                      NEXT_TABLE_SUCCESSOR_TABLE_DEPTH);
            for (auto &v : kv.value.vec)
                if (CHECKTYPE(v, tSTR))
                    hit_next.emplace_back(v);
        } else if (CHECKTYPE(kv.value, tSTR))
            hit_next.emplace_back(kv.value);
    } else if (kv.key == "miss") {
        if (CHECKTYPE(kv.value, tSTR))
            miss_next = kv.value;
    } else if (kv.key == "next") {
        if (!hit_next.empty()) {
            error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
        } else if (CHECKTYPE(kv.value, tSTR)) {
            hit_next.emplace_back(kv.value);
            miss_next = kv.value; }
    } else if (kv.key == "vpns") {
        if (CHECKTYPE(kv.value, tVEC))
            setup_vpns(layout, &kv.value.vec);
    } else if (kv.key == "p4") {
        if (CHECKTYPE(kv.value, tMAP))
            p4_table = P4Table::get(p4type, kv.value.map);
    } else if (kv.key == "p4_param_order") {
        if (CHECKTYPE(kv.value, tMAP)) {
            unsigned position = 0;
            for (auto &v : kv.value.map) {
                if ((CHECKTYPE(v.key, tSTR)) && (CHECKTYPE(v.value, tMAP))) {
                    p4_param p(v.key.s, position++);
                    for (auto &w : v.value.map) {
                        if (CHECKTYPE(w.key, tSTR) && CHECKTYPE2(w.value, tSTR, tINT)) {
                            if (w.key == "type") p.type = w.value.s;
                            else if (w.key == "size") p.bit_width = w.value.i;
                            else error(lineno, "Incorrect param type %s in p4_param_order", w.key.s); } }
                    p4_params_list.emplace_back(p); } } }
    } else if (kv.key == "context_json") {
        if (CHECKTYPE(kv.value, tMAP))
            context_json = toJson(kv.value.map);
    } else
        return false;
    return true;
}

/** check two tables to see if they can share ram.
 * FIXME -- for now we just allow a STATEFUL and a SELECTION to share -- we should
 * FIXME -- check to make sure they're mutually exclusive and use the memory in
 * FIXME -- a compatible way
 */
bool Table::allow_ram_sharing(const Table *t1, const Table *t2) {
    if (t1->table_type() == STATEFUL && t2->table_type() == SELECTION)
        return true;
    if (t2->table_type() == STATEFUL && t1->table_type() == SELECTION)
        return true;
    return false;
}

void Table::alloc_rams(bool logical, Alloc2Dbase<Table *> &use, Alloc2Dbase<Table *> *bus_use) {
    for (auto &row : layout) {
        for (int col : row.cols) {
            int r = row.row, c = col;
            if (logical) {
                c += 6 * (r&1);
                r >>= 1; }
            try {
                if (Table *old = use[r][c]) {
                    if (!allow_ram_sharing(this, old))
                        error(lineno, "Table %s trying to use (%d,%d) which is already in use "
                              "by table %s", name(), row.row, col, old->name());
                } else
                    use[r][c] = this;
            } catch(const char *oob) {
                error(lineno, "Table %s using out-of-bounds (%d,%d)", name(),
                      row.row, col);
            }
        }
        if (row.bus >= 0 && bus_use) {
            if (Table *old = (*bus_use)[row.row][row.bus]) {
                if (old != this)
                    error(lineno, "Table %s trying to use bus %d on row %d which is already in "
                          "use by table %s", name(), row.bus, row.row, old->name());
            } else (*bus_use)[row.row][row.bus] = this;
        }
    }
}

void Table::alloc_busses(Alloc2Dbase<Table *> &bus_use) {
    for (auto &row : layout) {
        if (row.bus < 0) {
            if (bus_use[row.row][0] == this)
                row.bus = 0;
            else if (bus_use[row.row][1] == this)
                row.bus = 1;
            else if (!bus_use[row.row][0])
                bus_use[row.row][row.bus=0] = this;
            else if (!bus_use[row.row][1])
                bus_use[row.row][row.bus=1] = this;
            else
                error(lineno, "No bus available on row %d for table %s",
                      row.row, name()); } }
}

void Table::alloc_id(const char *idname, int &id, int &next_id, int max_id,
                     bool order, Alloc1Dbase<Table *> &use)
{
    if (id >= 0) {
        next_id = id;
        return; }
    while (++next_id < max_id && use[next_id]);
    if (next_id >= max_id && !order) {
        next_id = -1;
        while (++next_id < max_id && use[next_id]); }
    if (next_id < max_id)
        use[id = next_id] = this;
    else
        error(lineno, "Can't pick %s id for table %s (ran out)", idname, name());
}

void Table::alloc_maprams() {
    for (auto &row : layout) {
        int sram_row = row.row/2;
        if ((row.row & 1) == 0) {
            error(row.lineno, "Can only use 2-port rams on right side srams (odd logical rows)");
            continue; }
        if (row.maprams.empty()) {
            int use = 0;
            for (unsigned i = 0; i < row.cols.size(); i++) {
                while (use < MAPRAM_UNITS_PER_ROW && stage->mapram_use[sram_row][use]) use++;
                if (use >= MAPRAM_UNITS_PER_ROW) {
                    error(row.lineno, "Ran out of maprams on row %d in stage %d", sram_row,
                          stage->stageno);
                    break; }
                row.maprams.push_back(use);
                stage->mapram_use[sram_row][use++] = this; }
        } else {
            for (auto mapcol : row.maprams) {
                if (auto *old = stage->mapram_use[sram_row][mapcol]) {
                    if (!allow_ram_sharing(this, old))
                        error(lineno, "Table %s trying to use mapram %d,%d which is use by "
                              "table %s", name(), sram_row, mapcol, old->name());
                } else
                    stage->mapram_use[sram_row][mapcol] = this; } } }
}

void Table::alloc_vpns() {
    if (no_vpns || layout_size() == 0 || layout[0].vpns.size() > 0) return;
    setup_vpns(layout, 0);
}

void Table::check_next(Table::Ref &n, Table::Actions::Action *act) {
    if (n == "END") return;
    if (n.check()) {
        if (logical_id >= 0 && n->logical_id >= 0 ? table_id() > n->table_id()
                                                  : stage->stageno > n->stage->stageno)
            error(n.lineno, "Next table %s comes before %s", n->name(), name());
        auto &s = n->pred[this];
        if (act)
            s.insert(act); }
}

void Table::check_next() {
    auto *actions = get_actions();
    if (actions) {
        auto action = actions->begin();
        for (auto &n : hit_next)
            check_next(n, action == actions->end() ? nullptr : &*action++);
    } else {
        for (auto &n : hit_next)
            check_next(n); }
    check_next(miss_next, actions ? actions->action(default_action) : nullptr);
    if (hit_next.size() == 1 && hit_next[0] && !miss_next && actions)
        for (auto &act : *actions)
            hit_next[0]->pred[this].insert(&act);
}

bool Table::choose_logical_id(const slist<Table *> *work) {
    if (logical_id >= 0) return true;
    if (work && find(*work, this) != work->end()) {
        error(lineno, "Logical table loop with table %s", name());
        for (auto *tbl : *work) {
            if (tbl == this) break;
            warning(tbl->lineno, "loop involves table %s", tbl->name()); }
        return false; }
    slist<Table *> local(this, work);
    for (auto *p : Keys(pred))
        if (!p->choose_logical_id(&local))
            return false;
    int min_id = 0, max_id = LOGICAL_TABLES_PER_STAGE-1;
    for (auto *p : Keys(pred))
        if (p->stage->stageno == stage->stageno && p->logical_id >= min_id)
            min_id = p->logical_id + 1;
    for (auto &n : hit_next)
        if (n && n->stage->stageno == stage->stageno &&
            n->logical_id >= 0 && n->logical_id <= max_id)
            max_id = n->logical_id - 1;
    if (miss_next && miss_next->stage->stageno == stage->stageno &&
        miss_next->logical_id >= 0 && miss_next->logical_id <= max_id)
        max_id = miss_next->logical_id - 1;
    for (int id = min_id; id <= max_id; ++id) {
        if (!stage->logical_id_use[id]) {
            logical_id = id;
            stage->logical_id_use[id] = this;
            return true; } }
    error(lineno, "Can't find a logcial id for table %s", name());
    return false;
}

void Table::need_bus(int lineno, Alloc1Dbase<Table *> &use, int idx, const char *busname)
{
    if (use[idx] && use[idx] != this) {
        error(lineno, "%s bus conflict on row %d between tables %s and %s", busname, idx,
              name(), use[idx]->name());
        error(use[idx]->lineno, "%s defined here", use[idx]->name());
    } else
        use[idx] = this;
}

static void overlap_test(int lineno,
    unsigned a_bit, std::map<std::string, Table::Format::Field>::iterator a,
    unsigned b_bit, std::map<std::string, Table::Format::Field>::iterator b)
{
    if (b_bit <= a->second.hi(a_bit)) {
        if (a->second.group || b->second.group)
            error(lineno, "Field %s(%d) overlaps with %s(%d)",
                  a->first.c_str(), a->second.group,
                  b->first.c_str(), b->second.group);
        else
            error(lineno, "Field %s overlaps with %s",
                  a->first.c_str(), b->first.c_str()); }
}

static void append_bits(std::vector<Table::Format::bitrange_t> &vec, int lo, int hi) {
    /* split any chunks that cross a word (128-bit) boundary */
    while (lo < hi && lo/128U != hi/128U) {
        vec.emplace_back(lo, lo | 127);
        lo = (lo | 127) + 1; }
    vec.emplace_back(lo, hi);
}

Table::Format::Format(Table *t, const VECTOR(pair_t) &data, bool may_overlap) : tbl(t) {
    unsigned nextbit = 0;
    fmt.resize(1);
    for (auto &kv : data) {
        if (lineno < 0) lineno = kv.key.lineno;
        if (!CHECKTYPE2M(kv.key, tSTR, tCMD, "expecting field desc"))
            continue;
        value_t &name = kv.key.type == tSTR ? kv.key : kv.key[0];
        unsigned idx = 0;
        if (kv.key.type == tCMD &&
            (kv.key.vec.size != 2 || !CHECKTYPE(kv.key[1], tINT) || (idx = kv.key[1].i) > 15)) {
            error(kv.key.lineno, "Invalid field group");
            continue; }
        if (kv.value.type != tVEC &&
            !(CHECKTYPE2(kv.value, tINT, tRANGE) && VALIDATE_RANGE(kv.value)))
            continue;
        if (idx >= fmt.size()) fmt.resize(idx+1);
        if (fmt[idx].count(name.s) > 0) {
            if (kv.key.type == tCMD)
                error(name.lineno, "Duplicate key %s(%d) in format", name.s, idx);
            else
                error(name.lineno, "Duplicate key %s in format", name.s);
            continue; }
        Field *f = &fmt[idx].emplace(name.s, Field(this)).first->second;
        f->group = idx;
        if (kv.value.type == tINT) {
            if (kv.value.i <= 0)
                error(kv.value.lineno, "invalid size %d for format field %s",
                      kv.value.i, name.s);
            f->size = kv.value.i;
            append_bits(f->bits, nextbit, nextbit+f->size-1);
        } else if (kv.value.type == tRANGE) {
            if (kv.value.lo > kv.value.hi)
                error(kv.value.lineno, "invalid range %d..%d", kv.value.lo, kv.value.hi);
            append_bits(f->bits, kv.value.lo, kv.value.hi);
            f->size = kv.value.hi - kv.value.lo + 1;
        } else if (kv.value.type == tVEC) {
            f->size = 0;
            for (auto &c : kv.value.vec)
                if (CHECKTYPE(c, tRANGE) && VALIDATE_RANGE(c)) {
                    append_bits(f->bits, c.lo, c.hi);
                    f->size += c.hi - c.lo + 1;
                    if ((size_t)c.hi+1 > size) size = c.hi+1; } }
        nextbit = f->bits.back().hi + 1;
        if (nextbit > size) size = nextbit; }
    if (!may_overlap) {
        for (auto &grp : fmt) {
            for (auto it = grp.begin(); it != grp.end(); ++it) {
                for (auto &piece : it->second.bits) {
                    auto p = byindex.upper_bound(piece.lo);
                    if (p != byindex.end())
                        overlap_test(lineno, piece.lo, it, p->first, p->second);
                    if (p != byindex.begin()) {
                        --p;
                        overlap_test(lineno, p->first, p->second, piece.lo, it);
                        if (p->first == piece.lo && piece.hi <= p->second->second.hi(piece.lo))
                            continue; }
                    byindex[piece.lo] = it; } } } }
    for (size_t i = 1; i < fmt.size(); i++)
        if (fmt[0] != fmt[i])
            error(data[0].key.lineno, "Format group %zu doesn't match group 0", i);
    for (log2size = 0; (1U << log2size) < size; log2size++);
    if (error_count > 0) return;
    for (auto &f : fmt[0]) {
        f.second.by_group = new Field *[fmt.size()];
        f.second.by_group[0] = &f.second; }
    for (size_t i = 1; i < fmt.size(); i++)
        for (auto &f : fmt[i]) {
            Field &f0 = fmt[0].emplace(f.first, Field(this)).first->second;
            f.second.by_group = f0.by_group;
            f.second.by_group[i] = &f.second; }
}

Table::Format::~Format() {
    for (auto &f : fmt[0])
        delete [] f.second.by_group;
}

void Table::Format::pass1(Table *tbl) {
    std::map<unsigned, Field *> immed_fields;
    unsigned lo = INT_MAX, hi = 0;
    for (auto &f : fmt[0]) {
        if (!(f.second.flags & Field::USED_IMMED))
            continue;
        if (f.second.bits.size() > 1)
            error(lineno, "Immmediate action data %s cannot be split", f.first.c_str());
        immed_fields[f.second.bits[0].lo] = &f.second;
        if (f.second.bits[0].lo < lo) {
            immed = &f.second;
            lo = immed->bits[0].lo; }
        if (f.second.bits[0].hi > hi) hi = f.second.bits[0].hi; }
    if (immed_fields.empty()) {
        LOG2("table " << tbl->name() << " has no immediate data");
        return; }
    LOG2("table " << tbl->name() << " has " << immed_fields.size() << " immediate data fields "
         "over " << (hi + 1 - lo) << " bits");
    if (hi - lo >= MAX_IMMED_ACTION_DATA) {
        error(lineno, "Immediate data for table %s spread over more than %d bits",
              tbl->name(), MAX_IMMED_ACTION_DATA);
        return; }
    immed_size = hi + 1 - lo;
    for (unsigned i = 1; i < fmt.size(); i++) {
        int delta = (int)immed->by_group[i]->bits[0].lo - (int)immed->bits[0].lo;
        for (auto &f : fmt[0]) {
            if (!(f.second.flags & Field::USED_IMMED))
                continue;
            if (delta != (int)f.second.by_group[i]->bits[0].lo - (int)f.second.bits[0].lo) {
                error(lineno, "Immediate data field %s for table %s does not match across "
                      "ways in a ram", f.first.c_str(), tbl->name());
                break; } } }
}

void Table::Format::pass2(Table *tbl) {
    int byte[4] = { -1, -1, -1, -1 };
    int half[2] = { -1, -1 };
    int word = -1;
    bool err = false;
    for (auto &f : fmt[0]) {
        int byte_slot = tbl->find_on_actionbus(&f.second, 0, f.second.size);
        if (byte_slot < 0) continue;
        int slot = Stage::action_bus_slot_map[byte_slot];
        unsigned off = f.second.bits[0].lo - immed->bits[0].lo;
        switch (Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned b = off/8; b <= (off + f.second.size - 1)/8; b++) {
                if (b >= 4 || (b&3) != (slot&3) || (byte[b] >= 0 && byte[b] != slot) ||
                    (byte[b^1] >= 0 && byte[b^1] != (slot^1)) ||
                    Stage::action_bus_slot_size[slot] != 8) {
                    err = true;
                    break; }
                byte[b] = slot++; }
            break;
        case 16:
            for (unsigned w = off/16; w <= (off + f.second.size - 1)/16; w++) {
                if (w >= 2 || (w&1) != (slot&1) || (half[w] >= 0 && half[w] != slot) ||
                    Stage::action_bus_slot_size[slot] != 16) {
                    err = true;
                    break; }
                half[w] = slot++; }
            break;
        case 32:
            if (word >= 0 && word != slot) err = true;
            word = slot;
            break;
        default:
            assert(0); }
        if (err)
            error(lineno, "Immediate data misaligned for action bus byte %d", byte_slot); }
}

std::ostream &operator<<(std::ostream &out, const Table::Format::Field &f) {
    out << "(size = " << f.size << " ";
    for (auto b: f.bits) out << "[" << b.lo << ".." << b.hi << "]";
    out << ")";
    return out;
}


bool Table::Actions::Action::equiv(Action *a) {
    if (instr.size() != a->instr.size()) return false;
    for (unsigned i = 0; i < instr.size(); i++)
        if (!instr[i]->equiv(a->instr[i]))
            return false;
    if (attached.size() != a->attached.size()) return false;
    for (unsigned i = 0; i < attached.size(); i++)
        if (attached[i] != a->attached[i]) return false;
    return true;
}

std::map<std::string, std::vector<Table::Actions::Action::alias_value_t *>>
Table::Actions::Action::reverse_alias() const {
    std::map<std::string, std::vector<alias_value_t *>>      rv;
    for (auto &a : alias)
        rv[a.second.name].push_back(&a);
    return rv;
}

std::string Table::Actions::Action::alias_lookup(int lineno, std::string name,
                                                 int &lo, int &hi) const {
    while (alias.count(name)) {
        auto &a = alias.at(name);
        if (lo >= 0) {
            if (a.lo >= 0) {
                lo += a.lo;
                hi += a.lo;
                if (a.hi >= 0 && hi > a.hi)
                    error(lineno, "invalid bitslice of %s", name.c_str()); }
        } else {
            lo = a.lo;
            hi = a.hi; }
        name = a.name;
        lineno = a.lineno; }
    return name;
}

Table::Actions::Action::alias_t::alias_t(value_t &data) {
    lineno = data.lineno;
    if (CHECKTYPE3(data, tSTR, tCMD, tINT)) {
        if (data.type == tSTR) {
            name = data.s;
            lo = 0; hi = -1;
        } else if (data.type == tCMD) {
            name = data.vec[0].s;
            if (CHECKTYPE2(data.vec[1], tINT, tRANGE)) {
                if (data.vec[1].type == tINT)
                    lo = hi = data.vec[1].i;
                else {
                    lo = data.vec[1].lo;
                    hi = data.vec[1].hi; } }
        } else
            is_constant = true;
            value = data.i; }
}

Table::Actions::Action::Action(Table *tbl, Actions *actions, pair_t &kv) {
    lineno = kv.key.lineno;
    if (kv.key.type == tCMD) {
        name = kv.key[0].s;
        if (CHECKTYPE(kv.key[1], tINT)) {
            if (actions->code_use[(code = kv.key[1].i)])
                error(kv.key.lineno, "Duplicate action code %d", code);
            actions->code_use[code] = true; }
    } else if (kv.key.type == tINT) {
        name = std::to_string(kv.key.i);
        if (actions->code_use[(code = kv.key.i)])
            error(kv.key.lineno, "Duplicate action code %d", code);
        actions->code_use[code] = true;
    } else
        name = kv.key.s;
    for (auto &i : kv.value.vec) {
        if (i.type == tINT && instr.empty()) {
            if ((addr = i.i) >= ACTION_IMEM_ADDR_MAX)
                error(i.lineno, "Invalid instruction address %d", i.i);
        } else if (i.type == tMAP) {
            for (auto &a : i.map)
                if (CHECKTYPE(a.key, tSTR)) {
                    if (a.key == "p4_param_order") {
                        if CHECKTYPE(a.value, tMAP) {
                            unsigned position = 0;
                            for (auto &p : a.value.map) {
                                if (CHECKTYPE(p.key, tSTR) && CHECKTYPE(p.value, tINT))
                                    p4_params_list.emplace_back(p.key.s, position++, p.value.i); } }
                    } else if (a.key == "default_action") {
                        if CHECKTYPE(a.value, tMAP) {
                            for (auto &p : a.value.map) {
                                if (CHECKTYPE(p.key, tSTR) && CHECKTYPE(p.value, tSTR)) {
                                    if (p.key == "allowed")
                                        default_allowed = get_bool(p.value);
                                    else if (p.key == "reason")
                                        default_disallowed_reason = p.value.s; } } }
                    } else if (CHECKTYPE3(a.value, tSTR, tCMD, tINT)) {
                        if (a.value.type == tINT) {
                            auto k = alias.find(a.key.s);
                            if (k == alias.end())
                                alias.emplace(a.key.s, a.value);
                            else {
                                k->second.is_constant = true;
                                k->second.value = a.value.i; }
                        } else alias.emplace(a.key.s, a.value); } }
        } else if (CHECKTYPE2(i, tSTR, tCMD)) {
            VECTOR(value_t) tmp;
            if (i.type == tSTR)
                VECTOR_init1(tmp, i);
            else
                VECTOR_initcopy(tmp, i.vec);
            if (auto *p = Instruction::decode(tbl, this, tmp))
                instr.push_back(p);
            else if (tbl->to<MatchTable>() || tbl->to<TernaryIndirectTable>() ||
                     tbl->to<ActionTable>())
                attached.emplace_back(i, tbl);
            else
                error(i.lineno, "Unknown instruction %s", tmp[0].s);
            VECTOR_fini(tmp); } }
}

Table::Actions::Actions(Table *tbl, VECTOR(pair_t) &data) {
    table = tbl;
    for (auto &kv : data) {
        if ((kv.key.type != tINT && !CHECKTYPE2M(kv.key, tSTR, tCMD, "action")) ||
            !CHECKTYPE(kv.value, tVEC))
            continue;
        std::string name = kv.key.type == tINT ? std::to_string(kv.key.i) :
                           kv.key.type == tSTR ? kv.key.s : kv.key[0].s;
        if (actions.count(name)) {
            error(kv.key.lineno, "Duplicate action %s", name.c_str());
            continue; }
        actions.emplace(name, Action(tbl, this, kv)); }
}

void Table::Actions::Action::set_action_handle(Table *tbl) {
    // For actions in tables shared across multiple stages, the action handles
    // must be same. p4_table stores a map of actions and their handles. If
    // action present store the same handle else assign a new one.
    auto p4_table = tbl->p4_table;
    if (p4_table) {
        if (p4_table->action_handles.count(name) > 0)
            handle = p4_table->action_handles[name]; }
    if (handle == 0) {
        handle = unique_action_handle++;
        if (p4_table) p4_table->action_handles[name] = handle; }
}

void Table::Actions::Action::pass1(Table *tbl) {
    set_action_handle(tbl);
    if ((tbl->default_action == name) &&
        (!tbl->default_action_handle))
        tbl->default_action_handle = handle;
    /* SALU actions always have addr == -1 (so iaddr == -1) */
    int iaddr = -1;
    if (addr >= 0) {
        if (auto old = tbl->stage->imem_addr_use[tbl->gress][addr]) {
            if (equiv(old)) {
                return; }
            error(lineno, "action instruction addr %d in use elsewhere", addr);
            warning(old->lineno, "also defined here"); }
        tbl->stage->imem_addr_use[tbl->gress][addr] = this;
        iaddr = addr/ACTION_IMEM_COLORS; }
    for (auto &inst : instr) {
        inst = inst->pass1(tbl, this);
        if (inst->slot >= 0) {
            if (slot_use[inst->slot])
                error(inst->lineno, "instruction slot %d used multiple times in action %s",
                      inst->slot, name.c_str());
            slot_use[inst->slot] = 1; }
        if (inst->slot >= 0 && iaddr >= 0) {
            if (tbl->stage->imem_use[iaddr][inst->slot])
                error(lineno, "action instruction slot %d.%d in use elsewhere",
                      iaddr, inst->slot);
            tbl->stage->imem_use[iaddr][inst->slot] = 1; } }
    for (auto &a : alias) {
        while (alias.count(a.second.name)) {
            // the alias refers to something else in the alias list
            auto &rec = alias.at(a.second.name);
            if (rec.name == a.first) {
                error(a.second.lineno, "recursive alias %s", a.first.c_str());
                break; }
            if (rec.lo > 0) {
                a.second.lo += rec.lo;
                if (a.second.hi >= 0)
                    a.second.hi += rec.lo; }
            if (rec.hi > 0 && a.second.hi < 0)
                a.second.hi = rec.hi;
            if (a.second.lo < rec.lo || (rec.hi >= 0 && a.second.hi > rec.hi)) {
                error(a.second.lineno,
                        "alias for %s:%s(%d:%d) has out of range index from allowed %s:%s(%d:%d)",
                        a.first.c_str(), a.second.name.c_str(), a.second.lo, a.second.hi,
                        a.second.name.c_str(), rec.name.c_str(), rec.lo, rec.hi );
                break; }
            a.second.name = rec.name;
            a.second.is_constant = rec.is_constant;
            a.second.value = rec.value; }
        if (auto *f = tbl->lookup_field(a.second.name, name)) {
            if (a.second.hi < 0)
                a.second.hi = f->size - 1;
        } else if (a.second.name == "hash_dist" && a.second.lo >= 0) {
            // nothing to be done for now.  lo..hi is the hash dist index rather than
            // a bit index, which will cause problems if we want to later slice the alias
            // to access only some bits of it.
        } else
            error(a.second.lineno, "No field %s(%d:%d) in table %s",
                    a.second.name.c_str(), a.second.lo, a.second.hi, tbl->name()); }
    //Update default value for params if default action parameters present
    for (auto &p : p4_params_list) {
        if (tbl->default_action_parameters.count(p.name) > 0) {
            p.default_value = tbl->default_action_parameters[p.name];
            p.defaulted = true; } }
    for (auto &c : attached) {
        if (!c) {
            error(c.lineno, "Unknown instruction or table %s", c.name.c_str());
            continue; }
        if (c->table_type() != COUNTER && c->table_type() != METER && c->table_type() != STATEFUL) {
            error(c.lineno, "%s is not a counter, meter or stateful table", c.name.c_str());
            continue; } }
}

void Table::Actions::pass1(Table *tbl) {
    for (auto &act : *this) {
        act.pass1(tbl);
        slot_use |= act.slot_use; }
}

static void find_pred_in_stage(int stageno,
        std::map<MatchTable *, std::set<Table::Actions::Action *>> &pred,
        Table *tbl, const std::set<Table::Actions::Action *> &acts) {
    for (auto *mt : tbl->get_match_tables()) {
        if (mt->stage->stageno != stageno) continue;
        pred[mt].insert(acts.begin(), acts.end());
        for (auto &p : tbl->pred)
            find_pred_in_stage(stageno, pred, p.first, p.second); }
}

void Table::Actions::pass2(Table *tbl) {
    /* We do NOT call this for SALU actions, so we can assume VLIW actions here */
    assert(tbl->table_type() != STATEFUL);
    int code = tbl->get_gateway() ? 1 : 0;  // if there's a gateway, reserve code 0 for a NOP
                                            // to run when the gateway inhibits the table

    /* figure out how many codes we can encode in the match table(s), and if we need a distinct
     * code for every action to handle next_table properly */
    int code_limit = 0x10000;
    MatchTable *limit_match_table = nullptr;
    bool have_next_hit_map = false;
    for (auto match : tbl->get_match_tables()) {
        auto &args = match->get_action().args;
        if (args.size() > 0 && (1 << args[0].size()) < code_limit) {
            code_limit = 1 << args[0].size();
            limit_match_table = match; }
        if (match->hit_next_size() > 1)
            have_next_hit_map = true; }

    /* figure out if we need more codes than can fit in the action_instruction_adr_map.
     * use code = -1 to signal that condition. */
    if (have_next_hit_map) {
        if (code + actions.size() > ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH)
            code = -1;
    } else {
        int non_nop_actions = 0;
        for (auto &act : *this)
            if (act.instr.empty())
                code = 1;   // nop action -- always uses code 0
            else
                ++non_nop_actions;  // FIXME -- should combine identical actions
        if (code + non_nop_actions > ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH)
            code = -1; }

    for (auto &act : *this) {
        for (auto *inst : act.instr)
            inst->pass2(tbl, &act);
        if (act.addr < 0) {
            for (int i = 0; i < ACTION_IMEM_ADDR_MAX; i++) {
                if (auto old = tbl->stage->imem_addr_use[tbl->gress][i]) {
                    if (act.equiv(old)) {
                        act.addr = i;
                        break; }
                    continue; }
                if (tbl->stage->imem_use[i/ACTION_IMEM_COLORS].intersects(act.slot_use))
                    continue;
                act.addr = i;
                tbl->stage->imem_use[i/ACTION_IMEM_COLORS] |= act.slot_use;
                tbl->stage->imem_addr_use[tbl->gress][i] = &act;
                break; } }
        if (act.addr < 0)
            error(act.lineno, "Can't find an available instruction address");
        if (act.code < 0) {
            if (code < 0 && !code_use[act.addr])
                act.code = act.addr;
            else if (act.instr.empty() && !have_next_hit_map)
                act.code = 0;
            else
                act.code = code; }
        else if (code < 0 && act.code != act.addr) {
            error(act.lineno, "Action code must be the same as action instruction address "
                  "when there are more than %d actions", ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH);
            if (act.code < 0)
                warning(act.lineno, "Code %d is already in use by another action", act.addr); }
        if (act.code >= 0)
            code_use[act.code] = true;
        if (act.name != tbl->default_action || !tbl->default_only_action) {
            if (act.code >= code_limit)
                error(act.lineno, "Action code %d for %s too large for action specifier in "
                      "table %s", act.code, act.name.c_str(), limit_match_table->name());
            if (act.code > max_code) max_code = act.code; }
        while (code >= 0 && code_use[code]) code++; }
    actions.sort([](const value_type &a, const value_type &b) -> bool {
        return a.second.code < b.second.code; });
    if (!tbl->default_action.empty() && !exists(tbl->default_action))
        error(tbl->default_action_lineno, "no action %s in table %s", tbl->default_action.c_str(),
              tbl->name());
    std::map<MatchTable *, std::set<Action *>> pred;
    find_pred_in_stage(tbl->stage->stageno, pred, tbl, std::set<Action *>());
    for (auto &p : pred) {
        auto *actions = p.first->get_actions();
        if (!actions || actions == this) continue;
        if (!slot_use.intersects(actions->slot_use)) continue;
        for (auto &a1 : *this) {
            bool first = false;
            for (auto a2 : p.second) {
                if (a1.slot_use.intersects(a2->slot_use)) {
                    if (!first)
                        warning(a1.lineno, "Conflicting instruction slot usage for non-exlusive "
                                "table %s action %s", tbl->name(), a1.name.c_str());
                    first = true;
                    warning(a2->lineno, "and table %s action %s", p.first->name(),
                            a2->name.c_str()); } } } }
}

void Table::Actions::stateful_pass2(Table *tbl) {
    assert(tbl->table_type() == STATEFUL);
    for (auto &act : *this) {
        if (act.code >= 4)
            error(act.lineno, "Only 4 actions in a stateful table");
        else if (act.code >= 0)
            code_use[act.code] = 1;
        for (auto *inst : act.instr)
            inst->pass2(tbl, &act); }
    for (auto &act : *this) {
        if (act.code < 0) {
            if ((act.code = code_use.ffz(0)) >= 4) {
                error(act.lineno, "Only 4 actions in a stateful table");
                break; }
            code_use[act.code] = 1; } }
}

template<class REGS> void Table::Actions::write_regs(REGS &regs, Table *tbl) {
    for (auto &act : *this) {
        LOG2("# action " << act.name << " code=" << act.code << " addr=" << act.addr);
        for (auto *inst : act.instr)
            inst->write_regs(regs, tbl, &act); }
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE, void Table::Actions::write_regs, mau_regs &, Table *)

static void gen_override(json::map &cfg, Table::Call &att) {
    auto type = att->table_type();
    std::string base;
    switch (type) {
    case Table::COUNTER:  base = "override_stat";     break;
    case Table::METER:    base = "override_meter";    break;
    case Table::STATEFUL: base = "override_stateful"; break;
    default:
        error(att.lineno, "unsupported table type in action call"); }
    unsigned full_addr = 0;
    cfg[base + "_addr"] = true;
    if (att->to<AttachedTable>()->has_per_flow_enable()) {
        cfg[base + "_addr_pfe"] = true;
        full_addr |= 1U << (type == Table::COUNTER ? STATISTICS_PER_FLOW_ENABLE_START_BIT
                                                   : METER_PER_FLOW_ENABLE_START_BIT); }
    int idx = -1;
    for (auto &arg : att.args) {
        ++idx;
        if (arg.type == Table::Call::Arg::Name) {
            if (auto *st = att->to<StatefulTable>()) {
                if (auto *act = st->actions->action(arg.name())) {
                    full_addr |= 1 << METER_TYPE_START_BIT;
                    full_addr |= act->code << (METER_TYPE_START_BIT + 1); } }
            // FIXME -- else assume its a reference to a format field, so doesn't need to
            // FIXME -- be in the override.  Should check that somewhere, but need access
            // FIXME -- to the match_table to do it here.
        } else if (arg.type == Table::Call::Arg::Const) {
            if (idx == 0 && att.args.size() > 1) {
                full_addr |= 1 << METER_TYPE_START_BIT;
                full_addr |= arg.value() << (METER_TYPE_START_BIT + 1);
            } else {
                full_addr |= arg.value(); }
        } else {
            error(att.lineno, "argument not a constant"); } }
    cfg[base + "_full_addr"] = full_addr;
}

void Table::Actions::Action::add_indirect_resources(json::vector &indirect_resources) {
    for (auto &att : attached) {
        for (auto &arg : att.args) {
            json::map indirect_resource;
            if (arg.type == Table::Call::Arg::Name) {
                auto *p = has_param(arg.name());
                if (p) {
                    indirect_resource["access_mode"] = "index";
                    indirect_resource["parameter_name"] = p->name;
                    indirect_resource["parameter_index"] = p->position;
                } else continue;
            } else if (arg.type == Table::Call::Arg::Const) {
                indirect_resource["access_mode"] = "constant";
                indirect_resource["value"] = arg.value();
            } else continue;
            indirect_resource["resource_name"] = att->p4_name();
            indirect_resources.push_back(std::move(indirect_resource)); } }
}

void Table::Actions::gen_tbl_cfg(json::vector &cfg) {
    for (auto &act : *this) {
        json::map action_cfg;
        action_cfg["name"] = act.name;
        action_cfg["handle"] = act.handle; //FIXME-JSON
        act.add_indirect_resources(action_cfg["indirect_resources"]);
        // XXX(amresh): allowed_as_default_action info is directly passed through assembly
        // This will be 'false' for following conditions:
        // 1. Action requires hardware in hit path i.e. hash distribution or
        // random number generator
        // 2. There is a default action declared constant in program which
        // implies all other actions cannot be set to default
        action_cfg["allowed_as_default_action"] = act.default_allowed;
        // XXX(amresh): "disallowed_as_default_action" is not used by driver.
        // Keeping it here as debugging info. Will be set to "none",
        // "has_const_default", "has_hash_dist". Once rng support is added
        // to the compiler this must reflect "has_rng" or similar string.
        if (!act.default_allowed)
            action_cfg["disallowed_as_default_action_reason"] = act.default_disallowed_reason;
        json::vector &p4_params = action_cfg["p4_parameters"] = json::vector();
        add_p4_params(act, p4_params);
        action_cfg["override_meter_addr"] = false;
        action_cfg["override_meter_addr_pfe"] = false;
        action_cfg["override_meter_full_addr"] = 0;
        action_cfg["override_stat_addr"] = false;
        action_cfg["override_stat_addr_pfe"] = false;
        action_cfg["override_stat_full_addr"] = 0;
        action_cfg["override_stateful_addr"] = false;
        action_cfg["override_stateful_addr_pfe"] = false;
        action_cfg["override_stateful_full_addr"] = 0;
        for (auto &att : act.attached)
            gen_override(action_cfg, att);
        if (!this->table->to<ActionTable>())
            action_cfg["is_action_meter_color_aware"] = false;
        json::vector &prim_cfg = action_cfg["primitives"] = json::vector();
        gen_prim_cfg(act, prim_cfg);
        cfg.push_back(std::move(action_cfg)); }
}

void Table::Actions::add_p4_params(const Action &act, json::vector &cfg) {
    int index = 0;
    unsigned start_bit = 0;
    for (auto &a : act.p4_params_list) {
        json::map param;
        param["name"] = a.name;
        param["start_bit"] = start_bit;
        param["position"] = a.position;
        if (a.defaulted)
            param["default_value"] = a.default_value;
        param["bit_width"] = a.bit_width;
        cfg.push_back(std::move(param));
        start_bit += a.bit_width; }
}

void Table::Actions::add_action_format(Table *table, json::map &tbl) {
    /* FIXME -- this is mostly a hack, since the actions need not map 1-to-1 to the
     * hit_next entries.  Need a way of speicfying next table in the actual action */
    //if (table->hit_next.size() <= 1) return;
    unsigned hit_index = 0;
    bool hit_index_inc = true;
    // If hit and miss tables are same, set next table for all actions
    if (table->hit_next.size() == 1)
        if (table->hit_next[0] == table->miss_next)
            hit_index_inc = false;
    // If miss table not in any hit tables, set next table to miss table for all actions
    // This is the default action next table or miss table which runtime updates
    bool set_miss_table = true;
    for (auto &htbl : table->hit_next)
        if (htbl == table->miss_next)
            set_miss_table = false;
    json::vector &action_format = tbl["action_format"] = json::vector();
    for (auto &act : *this) {
        json::map action_format_per_action;
        // compute what is the next table and set next to "nullptr" if either this is the
        // last table or it ran out of indices
        auto next = hit_index < table->hit_next.size() ? table->hit_next[hit_index] : Table::Ref();
        if (set_miss_table) next = table->miss_next;
        if(next && next->name_ == "END") next = Table::Ref();
        if (hit_index_inc) hit_index++;
        std::string next_table_name = next ? next->name() : "--END_OF_PIPELINE--";
        unsigned next_table = next ? hit_index : 0;
        unsigned next_table_full = next ? next->table_id() : 0xff;
        action_format_per_action["action_name"] = act.name;
        action_format_per_action["action_handle"] = act.handle;
        action_format_per_action["table_name"] = next_table_name;
        action_format_per_action["next_table"] = next_table;
        action_format_per_action["next_table_full"] = next_table_full;
        action_format_per_action["vliw_instruction"] = act.code;
        action_format_per_action["vliw_instruction_full"] = ACTION_INSTRUCTION_ADR_ENABLE | act.addr;

        json::vector &action_format_per_action_imm_fields =
          action_format_per_action["immediate_fields"] = json::vector();
        for (auto &a : act.alias) {
            json::string name = a.first;
            int lo = remove_name_tail_range(name);
            json::string immed_name = a.second.name;
            if (immed_name != "immediate") continue; // output only immediate fields
            if (!(act.has_param(name) || a.second.is_constant))
                continue;   // and fields that are parameters or constants
            json::map action_format_per_action_imm_field;
            action_format_per_action_imm_field["param_name"] = name;
            action_format_per_action_imm_field["param_type"] = "parameter";
            if (a.second.is_constant) {
                action_format_per_action_imm_field["param_type"] = "constant";
                action_format_per_action_imm_field["const_value"] = a.second.value;
                action_format_per_action_imm_field["param_name"] = "constant_" + std::to_string(a.second.value);
            }
            action_format_per_action_imm_field["param_shift"] = lo;
            action_format_per_action_imm_field["dest_start"] = a.second.lo;
            action_format_per_action_imm_field["dest_width"] = a.second.size();
            action_format_per_action_imm_fields.push_back(std::move(action_format_per_action_imm_field));
        }
        action_format.push_back(std::move(action_format_per_action));
    }
}

std::ostream &operator<<(std::ostream &out, const Table::Actions::Action::alias_t &a) {
    out << "(" << a.name << ", lineno = " << a.lineno
        << ", lo = " << a.lo << ", hi = " << a.hi
        << ", is_constant = " << a.is_constant << ", value = 0x"
        << std::hex << a.value << std::dec << ")";
    return out;
}

std::ostream &operator<<(std::ostream &out, const Table::Actions::Action &a) {
    out << a.name << "(";
    auto indent = a.name.length() + 10;
    for (auto &p: a.p4_params_list)
        out << p << std::endl << std::setw(indent);
    out << ")";
    return out;
}

std::ostream &operator<<(std::ostream &out, const Table::p4_param &p) {
    out << p.name << "[ w =" << p.bit_width << ", w_full =" << p.bit_width_full
        << " type =" << p.type << "]";
    return out;
}


void Table::Actions::add_immediate_mapping(json::map &tbl) {
    for (auto &act : *this) {
        if (act.alias.empty()) continue;
        json::vector &map = tbl["action_to_immediate_mapping"][act.name];
        for (auto &a : act.alias) {
            json::string name = a.first;
            json::string immed_name = a.second.name;
            if (immed_name == "immediate") immed_name = "--immediate--";
            int lo = remove_name_tail_range(name);
            map.push_back( json::vector { json::map {
                { "name", std::move(name) },
                { "parameter_least_significant_bit", json::number(lo) },
                { "parameter_most_significant_bit", json::number(lo + a.second.hi - a.second.lo) },
                { "immediate_least_significant_bit", json::number(a.second.lo) },
                { "immediate_most_significant_bit", json::number(a.second.hi) },
                { "field_called", std::move(immed_name) } } } ); } }
}

void Table::Actions::add_next_table_mapping(Table *table, json::map &tbl) {
    /* FIXME -- this is mostly a hack, since the actions need not map 1-to-1 to the
     * hit_next entries.  Need a way of speicfying next table in the actual action */
    if (table->hit_next.size() <= 1) return;
    unsigned hit_index = 0;
    for (auto &act : *this) {
        if (hit_index >= table->hit_next.size()) break;
        auto next = table->hit_next[hit_index++];
        json::map &map = tbl["action_to_next_table_mapping"][act.name];
        map["next_table_address_to_use"] = hit_index;
        map["action_name"] = act.name;
        map["next_table_full_address"] = next ? next->table_id() : 0xff;
        if (next)
            map["next_table_name"] = next->name(); }
}

void Table::Actions::gen_prim_cfg(const Action& act, json::vector &out) {
    auto instrs = act.instr;
    for (unsigned i = 0; i < instrs.size(); i++) {
        auto oneinstr = instrs[i];
        json::map oneprim;
        oneinstr->gen_prim_cfg(oneprim);
        out.push_back(std::move(oneprim));
    }
}

template<class REGS>
void Table::write_mapram_regs(REGS &regs, int row, int col, int vpn, int type) {
    auto &mapram_config = regs.rams.map_alu.row[row].adrmux.mapram_config[col];
    //auto &mapram_ctl = map_alu_row.adrmux.mapram_ctl[col];
    mapram_config.mapram_type = type;
    mapram_config.mapram_logical_table = logical_id;
    mapram_config.mapram_vpn_members = 0;
    if (!options.match_compiler) // FIXME -- compiler doesn't set this?
        mapram_config.mapram_vpn = vpn;
    if (gress == INGRESS)
        mapram_config.mapram_ingress = 1;
    else
        mapram_config.mapram_egress = 1;
    mapram_config.mapram_enable = 1;
    mapram_config.mapram_ecc_check = 1;
    mapram_config.mapram_ecc_generate = 1;
    //if (!options.match_compiler) // FIXME -- compiler doesn't set this?
    //    mapram_ctl.mapram_vpn_limit = maxvpn;
    if (gress)
        regs.cfg_regs.mau_cfg_mram_thread[col/3U] |= 1U << (col%3U*8U + row);
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE,
                void Table::write_mapram_regs, mau_regs &, int, int, int, int)

HashDistribution *Table::find_hash_dist(int unit) {
    for (auto &hd : hash_dist)
        if (hd.id == unit)
            return &hd;
    for (auto t : get_match_tables())
        for (auto &hd : t->hash_dist)
            if (hd.id == unit)
                return &hd;
    if (auto *a = get_attached())
        for (auto &call : a->meters)
            for (auto &hd : call->hash_dist)
                if (hd.id == unit)
                    return &hd;
    return nullptr;
}

int Table::find_on_actionbus(Format::Field *f, int off, int size) {
    return action_bus ? action_bus->find(f, off, size) : -1;
}

void Table::need_on_actionbus(Format::Field *f, int off, int size) {
    if (action_bus) action_bus->need_alloc(this, f, off, size);
}

int Table::find_on_actionbus(const char *name, int off, int size, int *len) {
    return action_bus ? action_bus->find(name, off, size, len) : -1;
}

void Table::need_on_actionbus(Table *attached, int off, int size) {
    if (action_bus) action_bus->need_alloc(this, attached, off, size);
}

int Table::find_on_actionbus(HashDistribution *hd, int off, int size) {
    return action_bus ? action_bus->find(hd, off, size) : -1;
}

void Table::need_on_actionbus(HashDistribution *hd, int off, int size) {
    if (action_bus) action_bus->need_alloc(this, hd, off, size);
}

int Table::find_on_ixbar(Phv::Slice sl, int group) {
    if (input_xbar)
        if (auto *i = input_xbar->find_exact(sl, group)) {
            unsigned bit = (i->lo + sl.lo - i->what->lo);
            assert(bit < 128);
            return bit/8; }
    for (auto *in : stage->ixbar_use[InputXbar::Group(false, group)]) {
        if (auto *i = in->find_exact(sl, group)) {
            unsigned bit = (i->lo + sl.lo - i->what->lo);
            assert(bit < 128);
            return bit/8; } }
    return -1;
}

std::unique_ptr<json::map> Table::gen_memory_resource_allocation_tbl_cfg(const char *type, std::vector<Layout> &layout, bool skip_spare_bank) {
    int width, depth, period;
    const char *period_name;
    // FIXME -- calling vpn_params here is only valid when layout == this->layout, but we also
    // FIXME -- get here for color_maprams.  It works out as we don't use depth or width, only
    // FIXME -- period, which will always be 1 for meter layout or color_maprams
    vpn_params(width, depth, period, period_name);
    json::map mra;
    mra["memory_type"] = type;
    std::vector<json::vector> mem_units;
    json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"] = json::vector();
    int ctr = 0;
    bool no_vpns = false;
    for (auto &row : layout) {
        auto vpn = row.vpns.begin();
        for (auto col : row.cols) {
            if (vpn == row.vpns.end())
                no_vpns = true;
            else ctr = *vpn++;
            int unit = ctr++/period;
            if (size_t(unit) >= mem_units.size())
                mem_units.resize(unit + 1);
            mem_units[unit].push_back(memunit(row.row, col)); } }
    int vpn = 0;
    for (auto &mem : mem_units) {
        if (skip_spare_bank && &mem == &mem_units.back()) {
            if (mem.size() == 1)
                mra["spare_bank_memory_unit"] = mem[0]->clone();
            else
                mra["spare_bank_memory_unit"] = mem.clone();
            if (table_type() == SELECTION) break; }
        //FIXME-JSON -- Hack to match glass json
        //if (table_type() != ACTION) break; }
        std::sort(mem.begin(), mem.end(), json::obj::ptrless());
        json::map tmp;
        tmp["memory_units"] = std::move(mem);
        json::vector vpns;
        if (no_vpns)
            vpns.push_back(nullptr);
        else
            vpns.push_back(vpn);
        tmp["vpns"] = std::move(vpns);
        mem_units_and_vpns.push_back(std::move(tmp));
        vpn += period; }
    return json::mkuniq<json::map>(std::move(mra));
}

json::map *Table::base_tbl_cfg(json::vector &out, const char *type, int size) {
    return p4_table->base_tbl_cfg(out, size, this);
}

json::map *Table::add_stage_tbl_cfg(json::map &tbl, const char *type, int size) {
    json::vector &stage_tables = tbl["stage_tables"];
    json::map stage_tbl;
    stage_tbl["stage_number"] = stage->stageno;
    stage_tbl["size"] = size;
    stage_tbl["stage_table_type"] = type;
    stage_tbl["logical_table_id"] = logical_id;
    if (this->to<MatchTable>()) {
        stage_tbl["has_attached_gateway"] = false;
        if (get_gateway())
            stage_tbl["has_attached_gateway"] = true; }
    if (!strcmp(type, "selection") && get_stateful())
        tbl["bound_to_stateful_table_handle"] = get_stateful()->handle();
    stage_tables.push_back(std::move(stage_tbl));
    return &(stage_tables.back()->to<json::map>());
}

void Table::add_reference_table(json::vector &table_refs, const Table::Call& c) {
    if (c) {
        json::map table_ref;
        table_ref["how_referenced"] = c->to<AttachedTable>()->is_direct() ? "direct" : "indirect";
        table_ref["handle"] = c->handle();
        table_ref["name"] = c->name();
            if (c->p4_table)
                table_ref["name"] = c->p4_table->p4_name();
        table_refs.push_back(std::move(table_ref)); }
}

json::map &Table::add_pack_format(json::map &stage_tbl, int memword, int words, int entries) {
    json::map pack_fmt;
    pack_fmt["table_word_width"] = memword * words;
    pack_fmt["memory_word_width"] = memword;
    if (entries >= 0)
        pack_fmt["entries_per_table_word"] = entries;
    pack_fmt["number_memory_units_per_table_word"] = words;
    json::vector &pack_format = stage_tbl["pack_format"];
    pack_format.push_back(std::move(pack_fmt));
    return pack_format.back()->to<json::map>();
}

void Table::canon_field_list(json::vector &field_list) {
    for (auto &field_ : field_list) {
        auto &field = field_->to<json::map>();
        auto &name = field["field_name"]->to<json::string>();
        if (int lo = remove_name_tail_range(name))
            field["start_bit"]->to<json::number>().val += lo; }
}

void Table::get_cjson_source(const std::string &field_name,
			     const Table::Actions::Action *act,
		             std::string &source, std::string &imm_name,
                             int &start_bit) {
    // FIXME -- these should be based on the USES of the field in the table (as indexes
    // FIXME -- to attached tables), and not on the name of the field.

    source = act ? "" : "spec";
    start_bit = 0;
    if (field_name == "version")
        source = "version";
    else if (field_name == "immediate") {
        source = "immediate";
        imm_name = field_name;
    } else if (field_name == "action")
        source = "instr";
    else if (field_name == "action_addr")
        source = "adt_ptr";
    else if ((field_name == "meter_addr") && get_selector())
        source = "sel_ptr";
    else if ((field_name == "meter_addr") && get_stateful())
        source = "stful_ptr";
    else if ((field_name == "meter_pfe") && get_selector())
        source = "sel_ptr";
        // FIXME start_bit = ??
    else if ((field_name == "meter_pfe") && get_stateful()) {
        source = "stful_ptr";
        start_bit = METER_PER_FLOW_ENABLE_START_BIT;
    } else if ((field_name == "meter_type") && get_stateful()) {
        source = "stful_ptr";
        start_bit = METER_TYPE_START_BIT; }
}

void Table::add_field_to_pack_format(json::vector &field_list, int basebit, std::string name,
                                     const Table::Format::Field &field,
                                     const Table::Actions::Action *act)
{
    decltype(act->reverse_alias()) aliases;
    if (act) aliases = act->reverse_alias();
    auto alias = get(aliases, name);

    // we need to add only those aliases that are parameters, and there can be multiple
    // such fields that contain slices of one or more other aliases
    // FIXME: why aren't we de-aliasing in setup?
    for (auto a : alias) {
        json::string param_name = a->first;
        int lo = remove_name_tail_range(param_name);
        if (act->has_param(param_name) || a->second.is_constant) {
            auto newField = field;
            if (a->second.hi != -1) {
                unsigned fieldSize = a->second.hi - a->second.lo + 1;
                if (field.bits.size() > 1) warning(0, "multiple bit ranges for %s", name.c_str());
                newField = Table::Format::Field(field.fmt, fieldSize, a->second.lo + field.bits[0].lo,
                                                static_cast<Format::Field::flags_t>(field.flags));
            }

            if (a->second.is_constant)
                output_field_to_pack_format(field_list, basebit, a->first, "constant", 0,
                                            newField, a->second.value);
            else
                output_field_to_pack_format(field_list, basebit, a->first, "spec", 0, newField);
        }
    }

    // Determine the source of the field. If called recursively for an alias,
    // act will be a nullptr
    std::string source = "", immediate_name = "";
    int start_bit;
    get_cjson_source(name, act, source, immediate_name, start_bit);

    if (field.flags == Format::Field::ZERO)
        source = "zero";

    if (source != "")
        output_field_to_pack_format(field_list, basebit, name, source, start_bit, field);
}

void Table::output_field_to_pack_format(json::vector &field_list,
                                        int basebit,
                                        std::string name,
                                        std::string source,
                                        int start_bit,
                                        const Table::Format::Field &field,
                                        unsigned value)
{
    unsigned add_width = 0;
    bool pfe_enable = false;
    auto a = this->get_attached();
    if (a && a->stats.size() > 0) {
        // If field is an attached table address specified by a pfe
        // param, set source to "stats_ptr" and pfe_enable to true
        // Discard pfe bit fields
        auto s = a->stats[0]->to<Synth2Port>();
        std::string pfe_param = s->get_per_flow_enable_param();
        std::string pfe_name = pfe_param.substr(0, pfe_param.find("_pfe"));
        if (name == (pfe_name + "_pfe"))
            return; //Do not output per flow enable parameter
        if (name == (pfe_name + "_addr")) {
            source = "stats_ptr";
            // FIXME-DRIVER: Currently driver assumes pfe bit is at the MSB of
            // address. Hence the fields <field>_addr and
            // <field>_pfe should be merged in the context json
            // i.e. field_width should be incremented by 1
            // Once driver supports a new "source" type for a
            // separate pfe bit this hack will go away and pfe
            // fields wont be dropped from the entry format
            add_width = 1;
            pfe_enable = true; }
    }

    int lobit = 0;
    for (auto &bits : field.bits) {
        json::map field_entry;
        field_entry["start_bit"] = lobit + start_bit;
        if (this->to<TernaryIndirectTable>() || this->to<ExactMatchTable>()) {
            auto selector = get_selector();
            if (selector && selector->get_per_flow_enable_param() == name)
                return; // Do not output per flow enable parameter
            field_entry["enable_pfe"] = pfe_enable;
            if ((name == "meter_addr") && selector) {
                field_entry["start_bit"] = SELECTOR_LOWER_HUFFMAN_BITS;
                field_entry["enable_pfe"] = selector->get_per_flow_enable();
            }
            if (name == "action_addr")
                if (auto adt = action->to<ActionTable>())
                    field_entry["start_bit"] = std::min(5U, adt->get_log2size() - 2);
        }
        field_entry["field_width"] = bits.size() + add_width;
        field_entry["lsb_mem_word_idx"] = bits.lo / MEM_WORD_WIDTH;
        field_entry["msb_mem_word_idx"] = bits.hi / MEM_WORD_WIDTH;
        field_entry["source"] = json::string(source);
        if (source == "constant") {
            field_entry["const_tuples"] = json::vector {
                json::map {
                    { "dest_start",  json::number(0) },
                    { "value", json::number(value) },
                    { "dest_width", json::number(bits.size()) }
                }};
        }
        field_entry["lsb_mem_word_offset"] = basebit + (bits.lo % MEM_WORD_WIDTH);
        field_entry["field_name"] = json::string(name);
        //field_entry["immediate_name"] = json::string(immediate_name);
        if (this->to<ExactMatchTable>())
            //FIXME-JSON : match_mode only matters for ATCAM's not clear if
            //'unused' or 'exact' is used by driver
            field_entry["match_mode"] = json::string("unused");
        field_list.push_back(std::move(field_entry));
        lobit += bits.size();
    }

}


void Table::add_zero_padding_fields(Table::Format *format, Table::Actions::Action *act,
                                    unsigned format_width) {
    if (!format) return;
    // For an action with no format pad zeros for action table size
    unsigned pad_count = 0;
    if (format->log2size == 0) {
        if (auto at = this->to<ActionTable>()) {
            format->size = at->get_size();
            format->log2size = at->get_log2size();
            // For wide action formats, entries per word is 1, so plug in a
            // single pad field of 256 bits
            unsigned action_entries_per_word = std::max(1U, 128U/format->size);
            // Add a flag type to specify padding?
            Format::Field f(format, format->size, 0, Format::Field::ZERO);
            for (int i = 0; i < action_entries_per_word; i++)
                format->add_field(f, "--padding--");
        } else {
            error(lineno,
                "Adding zero padding to a non action table which has no action entries in format"); }
        return; }
    decltype(act->reverse_alias()) alias;
    if (act) alias = act->reverse_alias();

    // Determine the zero padding necessary by creating a bitvector that has all
    // bits cleared, and then iterate through parameters and immediates and set the
    // bits that are used. Create padding for the remaining bit ranges.
    bitvec padbits;
    padbits.clrrange(0, format_width-1);
    for (auto &field : *format) {
        auto aliases = get(alias, field.first);
        for (auto a : aliases) {
            auto newField = field.second;
            json::string param_name = a->first;
            int lo = remove_name_tail_range(param_name);
            if (act->has_param(param_name) || a->second.is_constant) {
                auto newField = Table::Format::Field(field.second.fmt, a->second.size(),
                                                     a->second.lo + field.second.bits[0].lo,
                                                     static_cast<Format::Field::flags_t>(field.second.flags));
                newField.set_field_bits(padbits);
            }
        }
        if (aliases.size() == 0)
            field.second.set_field_bits(padbits);
    }

    unsigned idx_lo = 0;
    for (auto p : padbits) {
        if (p > idx_lo) {
            Format::Field f(format, p - idx_lo, idx_lo, Format::Field::ZERO);
            std::string pad_name = "--padding_" + std::to_string(idx_lo)
                + "_" + std::to_string(p - 1) + "--";
            format->add_field(f, pad_name);
        }
        idx_lo = p + 1; }
    if (idx_lo < format_width) {
        Format::Field f(format, format_width - idx_lo, idx_lo, Format::Field::ZERO);
        std::string pad_name = "--padding_" + std::to_string(idx_lo)
            + "_" + std::to_string(format_width - 1) + "--";
        format->add_field(f, pad_name);
    }
}

bool Table::is_wide_format() {
    if (format) {
        if (format->log2size >= 7 || format->groups() > 1)
	    return true;
	return false; }
    return false;
}

int Table::get_entries_per_table_word() {
    if (format) {
    	if (is_wide_format())
    	    return format->groups();
    	return format->log2size ? (1U << (ceil_log2(MEM_WORD_WIDTH) - format->log2size)) : 0; }
    return 1;
}

int Table::get_mem_units_per_table_word() {
    if (format) {
        if (is_wide_format())
	    return ((format->size - 1)/MEM_WORD_WIDTH) + 1; }
    return 1;
}

int Table::get_table_word_width() {
    if (format) {
	if (is_wide_format())
            return MEM_WORD_WIDTH * get_mem_units_per_table_word(); }
    return MEM_WORD_WIDTH;
}

int Table::get_padding_format_width() {
    if (format) {
        if (is_wide_format())
            return get_mem_units_per_table_word() * MEM_WORD_WIDTH;
        return (1U << format->log2size); }
    return -1;
}

json::map &Table::add_pack_format(json::map &stage_tbl, Table::Format *format,
        bool pad_zeros, bool print_fields, Table::Actions::Action *act) {
    // Add zero padding fields to format
    // FIXME: Can this be moved to a format pass?
    if (pad_zeros)
        add_zero_padding_fields(format, act, get_padding_format_width());
    json::map pack_fmt;
    pack_fmt["memory_word_width"] = MEM_WORD_WIDTH;
    pack_fmt["table_word_width"] = get_table_word_width();
    pack_fmt["entries_per_table_word"] = get_entries_per_table_word();
    pack_fmt["number_memory_units_per_table_word"] = get_mem_units_per_table_word();
    if (print_fields) {
        int basebit = std::max(0, MEM_WORD_WIDTH - (1 << format->log2size));
        json::vector &entry_list = pack_fmt["entries"];
        if (is_wide_format()) {
            for (int i = format->groups()-1; i >= 0; --i) {
                json::vector field_list;
                for (auto it = format->begin(i); it != format->end(i); ++it)
                    add_field_to_pack_format(field_list, basebit, it->first, it->second, act);
                canon_field_list(field_list);
                entry_list.push_back( json::map {
                        { "entry_number", json::number(i) },
                        { "fields", std::move(field_list) }}); }
        } else {
            for (int i = get_entries_per_table_word()-1; i >= 0; --i) {
                json::vector field_list;
                for (auto &field : *format)
                    add_field_to_pack_format(field_list, basebit, field.first, field.second, act);
                canon_field_list(field_list);
                entry_list.push_back( json::map {
                        { "entry_number", json::number(i) },
                        { "fields", std::move(field_list) }});
                basebit -= 1 << format->log2size; } } }
    if (act)
        pack_fmt["action_handle"] = act->handle;
    json::vector &pack_format = stage_tbl["pack_format"];
    pack_format.push_back(std::move(pack_fmt));
    return pack_format.back()->to<json::map>();
}


void Table::common_tbl_cfg(json::map &tbl) {
    if (!default_action.empty())
        tbl["default_action_handle"] = default_action_handle;
    tbl["action_profile"] = p4_table->action_profile;
    // FIXME-JSON : If next table is present, set default_next_table_mask to
    // 2^(width of next table field called '--next_tbl--') - 1
    // matters if test is changing default action
    tbl["default_next_table_mask"] = 0;
    //FIXME-JSON: No brig support yet, uncomment when driver support is
    //added to validate json
    //tbl["uses_dynamic_key_masks"] = false;
    //tbl["static_entries"] = json::vector();
    //FIXME-JSON: PD related pragma
    tbl["ap_bind_indirect_res_to_match"] = json::vector();
    //FIXME-JSON: PD related, check glass examples for false (ALPM)
    tbl["is_resource_controllable"] = true;
    tbl["uses_range"] = false; //FIXME-JSON: Ranges not yet implemented by brig
    json::vector &params = tbl["match_key_fields"] = json::vector();
    if ((!p4_params_list.empty()) &&
            (this->to<MatchTable>() || this->to<Phase0MatchTable>())) {
        for (auto &p : p4_params_list) {
            unsigned start_bit = 0;
            json::map param;
            param["name"] = p.name;
            param["position"] = p.position;
            param["match_type"] = p.type;
            param["start_bit"] = start_bit;
            param["bit_width"] = p.bit_width;
            param["bit_width_full"] = p.bit_width_full;
            param["is_valid"] = p.is_valid;
            /* BRIG-288 */
            std::string fieldname, instname;
            gen_instfield_name(p.name, instname, fieldname);
            param["instance_name"] = instname;
            param["field_name"] = fieldname;
            params.push_back(std::move(param));
            start_bit += p.bit_width_full; } }
}

void Table::add_result_physical_buses(json::map &stage_tbl) {
    json::vector &result_physical_buses = stage_tbl["result_physical_buses"] = json::vector();
    for (auto l : layout) {
        result_physical_buses.push_back(l.row * 2 + l.bus); }
}
