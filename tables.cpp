#include "action_bus.h"
#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

std::map<std::string, Table *> Table::all;
std::map<std::string, Table::Type *> *Table::Type::all;

Table::Table(int line, std::string &&n, gress_t gr, Stage *s, int lid) :
    name_(n), stage(s), gress(gr), lineno(line), logical_id(lid)
{
    assert(all.find(name_) == all.end());
    all.emplace(name_, this);
    stage->all_refs.insert(&stage);
}
Table::~Table() {
    all.erase(name_);
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
        Format::Field *arg = 0;
        if (val[i].type == tINT && val[i].i == 0)
            ; // ok
        else if (val[i].type == tCMD && val[i] == "hash_dist") {
            if (PCHECKTYPE(val[i].vec.size > 1, val[i][1], tINT)) {
		bool ok = false;
		for (auto &hd : tbl->hash_dist)
		    if (hd.id == val[i][1].i) {
			args.emplace_back(&hd);
			ok = true;
			break; }
		if (!ok)
		    error(val[i].lineno, "hash_dist %d not defined in table %s", val[i][1].i,
			  tbl->name()); }
            continue; }
        else if (CHECKTYPE(val[i], tSTR) &&
            !(arg = tbl->lookup_field(val[i].s)))
            error(val[i].lineno, "No field named %s in format for %s", val[i].s, tbl->name());
        if (arg && arg->bits.size() != 1)
            error(val[i].lineno, "arg fields can't be split in format");
        args.emplace_back(arg); }
    lineno = val.lineno;
}

unsigned Table::Call::Arg::size() const {
    switch(type) {
    case Field:
	return fld ? fld->size : 0;
    case HashDist:
	return hd ? hd->expand >= 0 ? 23 : 16 : 0;
    default:
	assert(0);
    }
}

static void add_row(int lineno, std::vector<Table::Layout> &layout, int row) {
    layout.push_back(Table::Layout{lineno, row, -1});
}

static int add_rows(std::vector<Table::Layout> &layout, value_t &rows) {
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

static int add_cols(Table::Layout &row, value_t &cols) {
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

void Table::setup_layout(std::vector<Layout> &layout, value_t *row, value_t *col, value_t *bus, const char *subname) {
    if (!row) {
        error(lineno, "No 'row' attribute in table %s%s", name(), subname);
        return; }
    if (!col) {
        error(lineno, "No 'column' attribute in table %s%s", name(), subname);
        return; }
    int err = 0;
    if (row->type == tVEC)
        for (value_t &r : row->vec) err |= add_rows(layout, r);
    else
        err |= add_rows(layout, *row);
    if (err) return;
    if (col->type == tVEC && col->vec.size == (int)layout.size()) {
        for (int i = 0; i < col->vec.size; i++)
            err |= add_cols(layout[i], col->vec[i]);
    } else {
        for (auto &row : layout)
            if ((err |= add_cols(row, *col))) break; }
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
            for (auto &row : layout)
                row.bus = bus->i; }
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
        int sram_row = row.row/2;
        if (r == rams->end()) {
            error(r->lineno, "Mapram layout doesn't match table layout");
            break; }
        auto &maprow = *r++;
        VECTOR(value_t) *maprow_rams;
        if (maprow.type == tINT && layout.size() == 1) {
            maprow_rams = rams;
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
                else if (auto *old = stage->mapram_use[sram_row][mapcol.i])
                    error(mapcol.lineno, "Mapram col %d in row %d already in use by table %s",
                          sram_row, mapcol.i, old->name());
                else {
                    stage->mapram_use[sram_row][mapcol.i] = this;
                    row.maprams.push_back(mapcol.i); } } }
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
            if (row.cols.size() != firstrow->cols.size())
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

bool Table::common_setup(pair_t &kv) {
    if (kv.key == "action") {
        action.setup(kv.value, this);
    } else if (kv.key == "action_enable") {
        if (CHECKTYPE(kv.value, tINT))
            action_enable = kv.value.i;
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
    } else if (kv.key == "hit") {
        if (!hit_next.empty())
            error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
        else if (kv.value.type == tVEC) {
            for (auto &v : kv.value.vec)
                if (CHECKTYPE(v, tSTR))
                    hit_next.emplace_back(v);
        } else if (CHECKTYPE(kv.value, tSTR))
            hit_next.emplace_back(kv.value);
    } else if (kv.key == "miss") {
        if (CHECKTYPE(kv.value, tSTR))
            miss_next = kv.value;
    } else if (kv.key == "next") {
        if (!hit_next.empty())
            error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
        else if (CHECKTYPE(kv.value, tSTR))
            hit_next.emplace_back(kv.value);
            miss_next = kv.value;
    } else if (kv.key == "vpns") {
        if (CHECKTYPE(kv.value, tVEC))
            setup_vpns(layout, &kv.value.vec);
    } else if (kv.key == "p4") {
        if (CHECKTYPE(kv.value, tMAP))
            p4_table = P4Table::get(P4Table::MatchEntry, kv.value.map);
    } else
        return false;
    return true;
}

bool MatchTable::common_setup(pair_t &kv) {
    if (Table::common_setup(kv)) {
        return true; }
    if (kv.key == "gateway") {
        if (CHECKTYPE(kv.value, tMAP)) {
            gateway = GatewayTable::create(kv.key.lineno, name_+" gateway",
                                           gress, stage, -1, kv.value.map);
            gateway->set_match_table(this, false); }
        return true; }
    if (kv.key == "idletime") {
        if (CHECKTYPE(kv.value, tMAP)) {
            idletime = IdletimeTable::create(kv.key.lineno, name_+" idletime",
                                             gress, stage, -1, kv.value.map);
            idletime->set_match_table(this, false); }
        return true; }
    if (kv.key == "selector") {
        attached.selector.setup(kv.value, this);
        return true; }
    if (kv.key == "stats") {
        if (kv.value.type == tVEC)
            for (auto &v : kv.value.vec)
                attached.stats.emplace_back(v, this);
        else attached.stats.emplace_back(kv.value, this);
        return true; }
    if (kv.key == "meter") {
        if (kv.value.type == tVEC)
            for (auto &v : kv.value.vec)
                attached.meter.emplace_back(v, this);
        else attached.meter.emplace_back(kv.value, this);
        return true; }
    if (kv.key == "table_counter") {
        if (kv.value == "table_miss") table_counter = TABLE_MISS;
        else if (kv.value == "table_hit") table_counter = TABLE_HIT;
        else if (kv.value == "gateway_miss") table_counter = GATEWAY_MISS;
        else if (kv.value == "gateway_hit") table_counter = GATEWAY_HIT;
        else if (kv.value == "gateway_inhibit") table_counter = GATEWAY_INHIBIT;
        else error(kv.value.lineno, "Invalid table counter %s", value_desc(kv.value));
        return true; }
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
                if (Table *old = use[r][c])
                    error(lineno, "Table %s trying to use (%d,%d) which is already in use "
                          "by table %s", name(), row.row, col, old->name());
                else
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
        if (!row.maprams.empty()) continue;
        int use = 0;
        for (unsigned i = 0; i < row.cols.size(); i++) {
            while (use < MAPRAM_UNITS_PER_ROW && stage->mapram_use[sram_row][use]) use++;
            if (use >= MAPRAM_UNITS_PER_ROW) {
                error(row.lineno, "Ran out of maprams on row %d in stage %d", sram_row,
                      stage->stageno);
                break; }
            row.maprams.push_back(use);
            stage->mapram_use[sram_row][use++] = this; } }
}

void Table::alloc_vpns() {
    if (no_vpns || layout.size() == 0 || layout[0].vpns.size() > 0) return;
    setup_vpns(layout, 0);
}

void Table::check_next() {
    for (auto &n : hit_next)
        if (n != "END") n.check();
    if (miss_next != "END")
        miss_next.check();
}

void Table::need_bus(int lineno, Alloc1Dbase<Table *> &use, int idx, const char *busname)
{
    if (use[idx]) {
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
    while (lo/128U != hi/128U) {
        vec.emplace_back(lo, lo | 127);
        lo = (lo | 127) + 1; }
    vec.emplace_back(lo, hi);
}

Table::Format::Format(VECTOR(pair_t) &data, bool may_overlap) {
    unsigned nextbit = 0;
    for (auto &kv : data) {
        if (lineno < 0) lineno = kv.key.lineno;
        if (!CHECKTYPE2M(kv.key, tSTR, tCMD, "expecting field desc"))
            continue;
        value_t &name = kv.key.type == tSTR ? kv.key : kv.key[0];
        unsigned idx = 0;
        if (kv.key.type == tCMD &&
            (kv.key.vec.size != 2 || !CHECKTYPE(kv.key[1], tINT) ||
             (idx = kv.key[1].i) < 0 || idx > 15)) {
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
        //auto it = fmt[idx].emplace(name.s, Field{ nextbit, 0, idx, 0, -1 }).first;
        Field *f = &fmt[idx][name.s];
        f->group = idx;
        if (kv.value.type == tINT) {
            f->size  = kv.value.i;
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
            auto &f0 = fmt[0][f.first];
            f.second.by_group = f0.by_group;
            f.second.by_group[i] = &f.second; }
}

Table::Format::~Format() {
    for (auto &f : fmt[0])
        delete [] f.second.by_group;
}

void Table::Format::setup_immed(Table *tbl) {
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
    int byte[4] = { -1, -1, -1, -1 };
    bool err = false;
    for (auto &f : fmt[0]) {
        int byte_slot = tbl->find_on_actionbus(&f.second, 0);
        if (byte_slot < 0) continue;
        int slot = Stage::action_bus_slot_map[byte_slot];
        unsigned off = f.second.bits[0].lo - immed->bits[0].lo;
        switch (Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned b = off/8; b <= (off + f.second.size - 1)/8; b++) {
                if (b >= 4 || (byte[b] >= 0 && byte[b] != slot) ||
                    Stage::action_bus_slot_size[slot] != 8) {
                    err = true;
                    break; }
                byte[b] = slot++; }
            break;
        case 16:
            for (unsigned w = off/16; w <= (off + f.second.size - 1)/16; w++) {
                if (w >= 2 || (byte[2*w] >= 0 && byte[2*w] != slot) ||
                    (byte[2*w+1] >= 0 && byte[2*w+1] != slot) ||
                    Stage::action_bus_slot_size[slot] != 16) {
                    err = true;
                    break; }
                byte[2*w] = slot;
                byte[2*w+1] = slot++; }
            break;
        case 32:
            for (int b = 0; b < 4; b++) {
                if (byte[b] >= 0 && byte[b] != slot) { err = true; break; }
                byte[b] = slot; }
            break;
        default:
            assert(0); }
        if (err)
            error(lineno, "Immediate data misaligned for action bus byte %d", byte_slot); }
}

Table::Actions::Actions(Table *tbl, VECTOR(pair_t) &data) {
    for (auto &kv : data) {
        if (!CHECKTYPE2(kv.key, tSTR, tCMD) || !CHECKTYPE(kv.value, tVEC))
            continue;
        const char *name = kv.key.type == tSTR ? kv.key.s : kv.key[0].s;
        if (by_name.count(name)) {
            error(kv.key.lineno, "Duplicate action %s", name);
            continue; }
        by_name[name] = actions.size();
        actions.emplace_back(name, kv.key.lineno);
        auto &ins = actions.back();
        if (kv.key.type == tCMD && CHECKTYPE(kv.key[1], tINT))
            code_use |= 1U << (ins.code = kv.key[1].i);
        for (auto &i : kv.value.vec) {
            if (i.type == tINT && ins.instr.empty()) {
                if ((ins.addr = i.i) >= ACTION_IMEM_ADDR_MAX)
                    error(i.lineno, "Invalid instruction address %d", i.i);
                continue; }
            if (!CHECKTYPE(i, tCMD)) continue;
            if (auto *p = Instruction::decode(tbl, name, i.vec))
                ins.instr.push_back(p);
        }
    }
}

void Table::Actions::pass1(Table *tbl) {
    for (auto &act : actions) {
        int iaddr = -1;
        if (act.addr >= 0) {
            if (tbl->stage->imem_addr_use[tbl->gress][act.addr])
                error(act.lineno, "action instruction addr %d in use elsewhere", act.addr);
            tbl->stage->imem_addr_use[tbl->gress][act.addr] = 1;
            iaddr = act.addr/ACTION_IMEM_COLORS; }
        for (auto *inst : act.instr) {
            inst->pass1(tbl);
            if (inst->slot >= 0 && iaddr >= 0) {
                if (tbl->stage->imem_use[iaddr][inst->slot])
                    error(act.lineno, "action instruction slot %d.%d in use elsewhere",
                          iaddr, inst->slot);
                tbl->stage->imem_use[iaddr][inst->slot] = 1; } } }
}

void Table::Actions::pass2(Table *tbl) {
    int code = tbl->get_gateway() ? 1 : 0;
    if (code + actions.size() > ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH)
        code = -1;
    for (auto &act : actions) {
        if (act.addr < 0) {
            bitvec use;
            for (auto *inst : act.instr)
                if (inst->slot >= 0) use[inst->slot] = 1;
            for (int i = 0; i < ACTION_IMEM_ADDR_MAX; i++) {
                if (tbl->stage->imem_addr_use[tbl->gress][i]) continue;
                if (tbl->stage->imem_use[i/ACTION_IMEM_COLORS].intersects(use))
                    continue;
                act.addr = i;
                tbl->stage->imem_use[i/ACTION_IMEM_COLORS] |= use;
                tbl->stage->imem_addr_use[tbl->gress][i] = 1;
                break; } }
        if (act.addr < 0)
            error(act.lineno, "Can't find an available instruction address");
        if (act.code < 0)
            act.code = code < 0 ? act.addr : code;
        else if (code < 0 && act.code != act.addr)
            error(act.lineno, "Action code must be the same as action instruction address "
                  "when there are more than 8 actions");
        code_use |= 1U << act.code;
        if (act.code > max_code) max_code = act.code;
        while (code >= 0 && ((code_use >> code) & 1)) code++; }
}

static int parity(unsigned v) {
    v ^= v >> 16;
    v ^= v >> 8;
    v ^= v >> 4;
    v ^= v >> 2;
    v ^= v >> 1;
    return v&1;
}

void Table::Actions::write_regs(Table *tbl) {
    auto &imem = tbl->stage->regs.dp.imem;
    for (auto &act : actions) {
        int iaddr = act.addr/ACTION_IMEM_COLORS;
        int color = act.addr%ACTION_IMEM_COLORS;
        for (auto *inst : act.instr) {
            unsigned bits = inst->encode();
            assert(inst->slot >= 0);
            LOG2(inst);
            switch (Phv::reg(inst->slot).size) {
            case 8:
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_instr = bits;
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_color = color;
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_parity =
                    parity(bits) ^ color;
                break;
            case 16:
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_instr = bits;
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_color = color;
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_parity =
                    parity(bits) ^ color;
                break;
            case 32:
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_instr = bits;
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_color = color;
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_parity =
                    parity(bits) ^ color;
                break;
            default:
                assert(0); } } }
}

int get_address_mau_actiondata_adr_default(unsigned log2size, bool per_flow_enable) {
    int huffman_ones = log2size > 2 ? log2size - 3 : 0;
    assert(huffman_ones < 7);
    int rv = (1 << huffman_ones) - 1;
    rv = ((rv << 10) & 0xf8000) | ( rv & 0x1f);
    if (!per_flow_enable)
        rv |= 1 << 22;
    return rv;
}

void MatchTable::pass1(int type) {
    /* FIXME -- move common stuff from Exact/Ternary/HashAction here. */
    if (table_counter >= GATEWAY_MISS && !gateway)
        error(lineno, "Can't count gateway events on table %s as it doesn't have a gateway",
              name());
}

void MatchTable::write_regs(int type, Table *result) {
    /* this follows the order and behavior in stage_match_entry_table.py
     * it can be reorganized to be clearer */

    /*------------------------
     * data path
     *-----------------------*/
    if (gress == EGRESS)
        stage->regs.dp.imem_table_addr_egress |= 1 << logical_id;

    /*------------------------
     * Match Merge
     *-----------------------*/
    auto &merge = stage->regs.rams.match.merge;
    merge.predication_ctl[gress].table_thread |= 1 << logical_id;
    if (result) {
        unsigned action_enable = 0;
        if (result->action_enable >= 0)
            action_enable = 1 << result->action_enable;
        for (auto &row : result->layout) {
            int bus = row.row*2 | row.bus;
            setup_muxctl(merge.match_to_logical_table_ixbar_outputmap[type][bus], logical_id);
            if (result->action.args.size() >= 1 && result->action.args[0].field()) {
                merge.mau_action_instruction_adr_mask[type][bus] =
                    ((1U << result->action.args[0].size()) - 1) & ~action_enable;
            } else
                merge.mau_action_instruction_adr_mask[type][bus] = 0;
            merge.mau_action_instruction_adr_default[type][bus] =
                result->enable_action_instruction_enable ? 0 : 0x40;
            if (action_enable)
                merge.mau_action_instruction_adr_per_entry_en_mux_ctl[type][bus] =
                    result->action_enable;
            if (idletime)
                idletime->write_merge_regs(type, bus);
            if (result->action)
                /* FIXME -- deal with variable-sized actions */
                merge.mau_actiondata_adr_default[type][bus] =
                    get_address_mau_actiondata_adr_default(result->action->format->log2size,
                                                           result->enable_action_data_enable);
            result->write_merge_regs(type, bus); }
    } else {
        /* ternary match with no indirection table */
        assert(type == 1);
        result = this; }

    /*------------------------
     * Action instruction Address
     *-----------------------*/
    Actions *actions = result->actions;
    if (result->action) {
        assert(!actions);
        actions = result->action->actions; }
    assert(actions);

    if (actions->max_code < ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH) {
        merge.mau_action_instruction_adr_map_en[type] |= (1U << logical_id);
        for (auto &act : *actions)
            merge.mau_action_instruction_adr_map_data[type][logical_id][act.code/4]
                .set_subfield(act.addr + 0x40, (act.code%4) * 7, 7); }

    /*------------------------
     * Next Table
     *-----------------------*/
    Table *next = result->hit_next.size() > 0 ? result : this;
    if (next->hit_next.empty()) {
        /* nothing to do... */
    } else if (next->hit_next.size() < NEXT_TABLE_SUCCESSOR_TABLE_DEPTH) {
        merge.next_table_map_en |= (1U << logical_id);
        auto &mp = merge.next_table_map_data[logical_id];
        ubits<8> *map_data[8] = { &mp[0].next_table_map_data0, &mp[0].next_table_map_data1,
            &mp[0].next_table_map_data2, &mp[0].next_table_map_data3, &mp[1].next_table_map_data0,
            &mp[1].next_table_map_data1, &mp[1].next_table_map_data2, &mp[1].next_table_map_data3 };
        int i = 0;
        for (auto &n : next->hit_next)
            *map_data[i++] = n ? n->table_id() : 0xff;
    } else {
        /* FIXME */
        assert(0);
    }
    if (next->miss_next || next->miss_next == "END") {
        merge.next_table_format_data[logical_id].match_next_table_adr_miss_value =
            next->miss_next ? next->miss_next->table_id() : 0xff; }
    if (next->hit_next.size() > 0) {
        assert(((next->hit_next.size()-1) & next->hit_next.size()) == 0);
        merge.next_table_format_data[logical_id].match_next_table_adr_mask =
            next->hit_next.size() - 1; }

    /*------------------------
     * Immediate data found in overhead
     *-----------------------*/
    if (result->format) {
        for (auto &row : result->layout) {
            int bus = row.row*2 | row.bus;
            merge.mau_immediate_data_mask[type][bus] = (1UL << result->format->immed_size)-1; } }
    if (result->action_bus)
        result->action_bus->write_immed_regs(result);

    if (input_xbar) input_xbar->write_regs();

    if (options.match_compiler && dynamic_cast<HashActionTable *>(this))
        return; // skip the rest
    stage->regs.cfg_regs.mau_cfg_lt_thread |= 1U << logical_id;

    if (table_counter)
        merge.mau_table_counter_ctl[logical_id/8U].set_subfield(
            table_counter, 4 * (logical_id%8U), 4);
}

int Table::find_on_actionbus(Format::Field *f, int off) {
    return action_bus ? action_bus->find(f, off) : -1;
}

int Table::find_on_actionbus(const char *name, int off, int *len) {
    return action_bus ? action_bus->find(name, off, len) : -1;
}

int Table::find_on_ixbar(Phv::Slice sl, int group) {
    if (input_xbar)
        if (auto *i = input_xbar->find(sl, group)) {
            unsigned bit = (i->lo + sl.lo - i->what->lo);
            assert(bit < 128);
            return bit/8; }
    for (auto *in : stage->exact_ixbar[group]) {
        if (auto *i = in->find(sl, group)) {
            unsigned bit = (i->lo + sl.lo - i->what->lo);
            assert(bit < 128);
            return bit/8; } }
    assert(0);
    return -1;
}

std::unique_ptr<json::map> Table::gen_memory_resource_allocation_tbl_cfg(const char *type, bool skip_spare_bank) {
    int width, depth, period;
    const char *period_name;
    vpn_params(width, depth, period, period_name);
    json::map mra;
    mra["memory_type"] = type;
    json::vector mem_units[depth/period];
    json::vector &mem_units_and_vpns = mra["memory_units_and_vpns"] = json::vector();
    int ctr = 0;
    bool no_vpns = false;
    for (auto &row : layout) {
        auto vpn = row.vpns.begin();
        for (auto col : row.cols) {
            if (vpn == row.vpns.end())
                no_vpns = true;
            else ctr = *vpn++;
            mem_units[ctr++/period].push_back(memunit(row.row, col)); } }
    int vpn = 0;
    for (auto &mem : mem_units) {
        if (skip_spare_bank && &mem == &mem_units[depth/period - 1]) break;
        std::sort(mem.begin(), mem.end(), json::obj::ptrless());
        json::map tmp;
        tmp["memory_units"] = std::move(mem);
        json::vector vpns;
        if (no_vpns)
            vpns.push_back("null");
        else
            vpns.push_back(vpn);
        tmp["vpns"] = std::move(vpns);
        mem_units_and_vpns.push_back(std::move(tmp));
        vpn += period; }
    return std::make_unique<json::map>(std::move(mra));
}

SelectionTable *AttachedTables::get_selector() const {
    return dynamic_cast<SelectionTable *>((Table *)selector); }

bool AttachedTables::run_at_eop() {
    if (meter.size() > 0) return true;
    for (auto &s : stats)
        if (s->run_at_eop()) return true;
    return false;
}

void AttachedTables::pass1(MatchTable *self) {
    if (selector.check()) {
        if (selector->set_match_table(self, true) != Table::SELECTION)
            error(selector.lineno, "%s is not a selection table", selector->name());
        if (selector.args.size() < 1 || selector.args.size() > 3)
            error(selector.lineno, "Selector requires 1-3 args");
        if (selector->stage != self->stage)
            error(selector.lineno, "Selector table %s not in same stage as %s",
                  selector->name(), self->name());
        else if (selector->gress != self->gress)
            error(selector.lineno, "Selector table %s not in same thread as %s",
                  selector->name(), self->name()); }
    for (auto &s : stats) if (s.check()) {
        if (s->set_match_table(self, s.args.size() >= 1) != Table::COUNTER)
            error(s.lineno, "%s is not a counter table", s->name());
        if (s.args.size() > 1)
            error(s.lineno, "Stats table requires zero or one args");
        else if (s.args != stats[0].args)
            error(s.lineno, "Must pass same args to all stats tables in a single table");
        if (s->stage != self->stage)
            error(s.lineno, "Counter %s not in same stage as %s", s->name(), self->name());
        else if (s->gress != self->gress)
            error(s.lineno, "Counter %s not in same thread as %s", s->name(), self->name()); }
    for (auto &m : meter) if (m.check()) {
        if (m->set_match_table(self, m.args.size() >= 1) != Table::METER)
            error(m.lineno, "%s is not a meter table", m->name());
        if (m.args.size() > 1)
            error(m.lineno, "Meter table requires zero or one args");
        else if (m.args != meter[0].args)
            error(m.lineno, "Must pass same args to all meter tables in a single table");
        if (m->stage != self->stage)
            error(m.lineno, "Meter %s not in same stage as %s", m->name(), self->name());
        else if (m->gress != self->gress)
            error(m.lineno, "Meter %s not in same thread as %s", m->name(), self->name()); }
}

void AttachedTables::write_merge_regs(Table *self, int type, int bus) {
    for (auto &s : stats) s->write_merge_regs(type, bus, s.args);
    for (auto &m : meter) m->write_merge_regs(type, bus, m.args);
    if (selector)
        get_selector()->write_merge_regs(type, bus, selector.args, self->action);
}

json::map *Table::base_tbl_cfg(json::vector &out, const char *type, int size) {
    return p4_table->base_tbl_cfg(out, size, this);
}

json::map *Table::add_stage_tbl_cfg(json::map &tbl, const char *type, int size) {
    auto &stage_tables = dynamic_cast<json::vector &>(*tbl["stage_tables"]);
    stage_tables.push_back(json::map());
    auto &stage_tbl = dynamic_cast<json::map &>(*stage_tables.back());
    tbl["stage_tables_length"] = stage_tables.size();
    stage_tbl["stage_number"] = stage->stageno;
    stage_tbl["number_entries"] = size;
    stage_tbl["stage_table_type"] = type;
    if (options.match_compiler && !strcmp(type, "selection")) {
    } else if (logical_id >= 0)
        stage_tbl["stage_table_handle"] = logical_id;
    return &stage_tbl;
}

void add_pack_format(json::map &stage_tbl, int memword, int words, int entries) {
    json::map pack_fmt;
    pack_fmt["table_word_width"] = memword * words;
    pack_fmt["memory_word_width"] = memword;
    if (entries >= 0)
        pack_fmt["entries_per_table_word"] = entries;
    pack_fmt["number_memory_units_per_table_word"] = words;
    if (stage_tbl.count("pack_format")) {
        auto &pack_format = dynamic_cast<json::vector &>(*stage_tbl["pack_format"]);
        pack_format.push_back(std::move(pack_fmt));
    } else
        (stage_tbl["pack_format"] = json::vector()).push_back(std::move(pack_fmt));
}
