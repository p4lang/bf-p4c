#include "algorithm.h"
#include "input_xbar.h"
#include "instruction.h"
#include "stage.h"
#include "tables.h"

std::map<std::string, Table *> Table::all;
std::map<std::string, Table::Type *> *Table::Type::all;

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

int Table::table_id() { return (stage->stageno << 4) + logical_id; }

void Table::setup_action_table(value_t &val) {
    if (CHECKTYPE2(val, tSTR, tCMD)) {
        if (val.type == tSTR)
            action = val;
        else {
            action = val[0];
            for (int i = 1; i < val.vec.size; i++) {
                Format::Field *arg = 0;
                if (CHECKTYPE(val[i], tSTR) &&
                    !(arg = lookup_field(val[i].s)))
                    error(val[i].lineno, "No field named %s in format for %s",
                          val[i].s, name());
                action_args.push_back(arg); } }
        action.lineno = val.lineno; }
}

static int add_row(int lineno, Table *t, int row) {
    if (contains_if(t->layout, [row](Table::Layout &p)->bool { return p.row == row; })) {
        error(lineno, "row %d duplicated in table %s", row, t->name());
        return 1; }
    t->layout.push_back(Table::Layout{lineno, row, -1});
    return 0;
}

static int add_rows(Table *t, value_t &rows) {
    if (!CHECKTYPE2(rows, tINT, tRANGE)) return 1;
    if (rows.type == tINT) return add_row(rows.lineno, t, rows.i);
    int rv = 0;
    int step = rows.lo > rows.hi ? -1 : 1;
    for (int i = rows.lo; i != rows.hi; i += step)
        rv |= add_row(rows.lineno, t, i);
    rv |= add_row(rows.lineno, t, rows.hi);
    return rv;
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

void Table::setup_layout(value_t *row, value_t *col, value_t *bus) {
    if (!row) {
        error(lineno, "No 'row' attribute in table %s", name());
        return; }
    if (!col) {
        error(lineno, "No 'column' attribute in table %s", name());
        return; }
    int err = 0;
    if (row->type == tVEC)
        for (value_t &r : row->vec) err |= add_rows(this, r);
    else
        err |= add_rows(this, *row);
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
            if (bus->vec.size != (int)layout.size())
                error(bus->lineno, "Bus shape doesn't match rows");
            else
                for (int i = 0; i < bus->vec.size; i++)
                    if (CHECKTYPE(bus->vec[i], tINT))
                        layout[i].bus = bus->vec[i].i;
        } else
            for (auto &row : layout)
                row.bus = bus->i; }
}

void Table::setup_logical_id() {
    if (logical_id >= 0) {
        if (Table *old = stage->logical_id_use[logical_id]) {
            error(lineno, "table %s wants logical id %d:%d", name(),
                  stage->stageno, logical_id);
            error(old->lineno, "already in use by %s", old->name()); }
        stage->logical_id_use[logical_id] = this; }
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
            if (Table *old = (*bus_use)[row.row][row.bus])
                error(lineno, "Table %s trying to use bus %d on row %d which is already in use "
                      "by table %s", name(), row.bus, row.row, old->name());
        }
    }
}

void Table::alloc_busses(Alloc2Dbase<Table *> &bus_use) {
    for (auto &row : layout) {
        if (row.bus < 0) {
            if (!bus_use[row.row][0])
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

void Table::check_next() {
    for (auto &n : hit_next)
        if (n != "END") n.check();
    if (miss_next != "END")
        miss_next.check();
}

static void overlap_test(int lineno,
    std::map<std::string, Table::Format::Field>::iterator a,
    std::map<std::string, Table::Format::Field>::iterator b)
{
    if (b->second.bit < a->second.bit + a->second.size) {
        if (a->second.group || b->second.group)
            error(lineno, "Field %s(%d) overlaps with %s(%d)",
                  a->first.c_str(), a->second.group,
                  b->first.c_str(), b->second.group);
        else
            error(lineno, "Field %s overlaps with %s",
                  a->first.c_str(), b->first.c_str()); }
}

Table::Format::Format(VECTOR(pair_t) &data) :
    lineno(data[0].key.lineno), size(0), immed_size(0), immed(0), log2size(0)
{
    unsigned nextbit = 0;
    for (auto &kv : data) {
        if (!CHECKTYPE2M(kv.key, tSTR, tCMD, "expecting field desc"))
            continue;
        value_t &name = kv.key.type == tSTR ? kv.key : kv.key[0];
        unsigned idx = 0;
        if (kv.key.type == tCMD &&
            (kv.key.vec.size != 2 || !CHECKTYPE(kv.key[1], tINT) ||
             (idx = kv.key[1].i) < 0 || idx > 15)) {
            error(kv.key.lineno, "Invalid field group");
            continue; }
        if (!CHECKTYPE2(kv.value, tINT, tRANGE)) continue;
        if (idx <= fmt.size()) fmt.resize(idx+1);
        if (fmt[idx].count(name.s) > 0) {
            error(name.lineno, "Duplicate key %s in format", name.s);
            continue; }
        //auto it = fmt[idx].emplace(name.s, Field{ nextbit, 0, idx, 0, -1 }).first;
        Field *f = &fmt[idx][name.s];
        f->group = idx;
        if (kv.value.type == tINT) {
            f->bit = nextbit;
            f->size  = kv.value.i;
        } else {
            f->bit = kv.value.lo;
            f->size = kv.value.hi - kv.value.lo + 1; }
        nextbit = f->bit + f->size;
        auto it = fmt[idx].find(name.s);
        if (byindex.empty())
            byindex[f->bit] = it;
        else {
            auto p = byindex.upper_bound(f->bit);
            if (p != byindex.end())
                overlap_test(kv.value.lineno, it, p->second);
            p--;
            overlap_test(kv.value.lineno, p->second, it);
            if (nextbit > p->second->second.bit + p->second->second.size)
                byindex[f->bit] = it; }
        if (nextbit > size) size = nextbit; }
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
        if (f.second.action_xbar < 0 && !(f.second.flags & Field::USED_IMMED))
            continue;
        immed_fields[f.second.bit] = &f.second;
        if (f.second.bit < lo) {
            immed = &f.second;
            lo = immed->bit; }
        if (f.second.bit + f.second.size > hi) hi = f.second.bit + f.second.size - 1; }
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
        int delta = (int)immed->by_group[i]->bit - (int)immed->bit;
        for (auto &f : fmt[0]) {
            if (f.second.action_xbar < 0 && !(f.second.flags & Field::USED_IMMED))
                continue;
            if (delta != (int)f.second.by_group[i]->bit - (int)f.second.bit) {
                error(lineno, "Immediate data field %s for table %s does not match across "
                      "ways in a ram", f.first.c_str(), tbl->name());
                break; } } }
    int byte[4] = { -1, -1, -1, -1 };
    bool err = false;
    for (auto &f : fmt[0]) {
        if (f.second.action_xbar < 0)
            continue;
        int slot = Stage::action_bus_slot_map[f.second.action_xbar];
        unsigned off = f.second.bit - immed->bit;
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
            error(lineno, "Immediate data misaligned for action bus byte %d",
                  f.second.action_xbar); }
}

Table::Actions::Actions(Table *tbl, VECTOR(pair_t) &data) : lineno(data[0].key.lineno) {
    for (auto &kv : data) {
        if (!CHECKTYPE(kv.key, tSTR) || !CHECKTYPE(kv.value, tVEC))
            continue;
        if (actions.count(kv.key.s)) {
            error(kv.key.lineno, "Duplicate action %s", kv.key.s);
            continue; }
        auto &ins = actions[kv.key.s];
        ins.first = -1;
        order.push_back(actions.find(kv.key.s));
        for (auto &i : kv.value.vec) {
            if (i.type == tINT && ins.second.empty()) {
                if ((ins.first = i.i) >= ACTION_IMEM_ADDR_MAX)
                    error(i.lineno, "invalid instruction address %d", i.i);
                continue; }
            if (!CHECKTYPE(i, tCMD)) continue;
            if (auto *p = Instruction::decode(tbl, kv.key.s, i.vec))
                ins.second.push_back(p);
        }
    }
}

void Table::Actions::pass1(Table *tbl) {
    for (auto &act : actions) {
        int iaddr = -1;
        if (act.second.first >= 0) {
            if (tbl->stage->imem_addr_use[tbl->gress][act.second.first])
                error(lineno, "action instruction addr %d in use elsewhere",
                      act.second.first);
            tbl->stage->imem_addr_use[tbl->gress][act.second.first] = 1;
            iaddr = act.second.first/ACTION_IMEM_COLORS; }
        for (auto *inst : act.second.second) {
            inst->pass1(tbl);
            if (inst->slot >= 0 && iaddr >= 0) {
                if (tbl->stage->imem_use[iaddr][inst->slot])
                    error(lineno, "action instruction slot %d.%d in use elsewhere",
                          iaddr, inst->slot);
                tbl->stage->imem_use[iaddr][inst->slot] = 1; } } }
}

void Table::Actions::pass2(Table *tbl) {
    for (auto &act : actions) {
        if (act.second.first >= 0)
            continue;
        bitvec use;
        for (auto *inst : act.second.second) 
            if (inst->slot >= 0) use[inst->slot] = 1;
        for (int i = 0; i < ACTION_IMEM_ADDR_MAX; i++) {
            if (tbl->stage->imem_addr_use[tbl->gress][i]) continue;
            if (tbl->stage->imem_use[i/ACTION_IMEM_COLORS].intersects(use))
                continue;
            act.second.first = i;
            tbl->stage->imem_use[i/ACTION_IMEM_COLORS] |= use;
            tbl->stage->imem_addr_use[tbl->gress][i] = 1;
            break; }
        if (act.second.first < 0)
            error(lineno, "Can't find an available instruction address");
    }
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
        int iaddr = act.second.first/ACTION_IMEM_COLORS;
        int color = act.second.first%ACTION_IMEM_COLORS;
        for (auto *inst : act.second.second) {
            unsigned bits = inst->encode();
            assert(inst->slot >= 0);
            LOG2(inst);
            switch (inst->slot/32) {
            case 0: case 1: /* 32 bit */
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_instr = bits;
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_color = color;
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_parity =
                    parity(bits) ^ color;
                break;
            case 2: case 3: /* 8 bit */
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_instr = bits;
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_color = color;
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_parity =
                    parity(bits) ^ color;
                break;
            case 4: case 5: case 6: /* 16 bit */
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_instr = bits;
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_color = color;
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_parity =
                    parity(bits) ^ color;
                break;
            default:
                assert(0); } } }
}

Table::ActionBus::ActionBus(Table *tbl, VECTOR(pair_t) &data) {
    lineno = data[0].key.lineno;
    for (auto &kv : data) {
	if (!CHECKTYPE2(kv.key, tINT, tRANGE)) continue;
	if (!CHECKTYPE(kv.value, tSTR)) continue;
	Format::Field *f = tbl->lookup_field(kv.value.s, "*");
	if (!f) {
	    error(kv.value.lineno, "No field %s in format", kv.value.s);
	    continue; }
	unsigned idx = kv.key.i;
	if (kv.key.type == tRANGE) {
	    idx = kv.key.lo;
	    unsigned size = (kv.key.hi-idx+1) * 8;
	    if (size != f->size) {
		error(kv.key.lineno, "Byte range doesn't match size %d of %s",
		      f->size, kv.value.s);
		continue; } }
        if (idx >= ACTION_DATA_BUS_BYTES) {
            error(kv.key.lineno, "Action bus index out of range");
            continue; }
        tbl->apply_to_field(kv.value.s, [idx](Format::Field *f){ f->action_xbar = idx; });
	by_name[kv.value.s].first.push_back(idx);
	by_name[kv.value.s].second = f;
        by_byte[idx] = std::make_pair(std::string(kv.value.s), f); }
}

class MatchTable : public Table {
protected:
    MatchTable(int l, std::string &&n, gress_t g, Stage *s, int lid)
        : Table(l, std::move(n), g, s, lid) {}
    void link_action(Table::Ref &ref);
    void write_regs(int type, Table *result);
};

#define DEFINE_TABLE_TYPE(TYPE, PARENT, NAME, ...)                      \
class TYPE : public PARENT {                                            \
    static struct Type : public Table::Type {                           \
        Type() : Table::Type(NAME) {}                                   \
        TYPE *create(int lineno, const char *name, gress_t gress,       \
                      Stage *stage, int lid, VECTOR(pair_t) &data);     \
    } table_type;                                                       \
    friend struct Type;                                                 \
    TYPE(int l, const char *n, gress_t g, Stage *s, int lid)            \
        : PARENT(l, n, g, s, lid) {}                                    \
    void setup(VECTOR(pair_t) &data);                                   \
public:                                                                 \
    void pass1();                                                       \
    void pass2();                                                       \
    void write_regs();                                                  \
private:                                                                \
    __VA_ARGS__                                                         \
};                                                                      \
TYPE::Type TYPE::table_type;                                            \
TYPE *TYPE::Type::create(int lineno, const char *name, gress_t gress,  \
                          Stage *stage, int lid, VECTOR(pair_t) &data) {\
    TYPE *rv = new TYPE(lineno, name, gress, stage, lid);               \
    rv->setup(data);                                                    \
    return rv;                                                          \
}

static int get_address_mau_actiondata_adr_default(unsigned log2size) {
    int huffman_ones = log2size > 2 ? log2size - 3 : 0;
    assert(huffman_ones < 7);
    int rv = (1 << huffman_ones) - 1;
    rv = ((rv << 10) & 0xf8000) | ( rv & 0x1f);
    return rv;
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
    for (int v : VersionIter(config_version))
        merge.predication_ctl[gress][v].table_thread |=
            1 << logical_id;
    for (auto &row : result->layout) {
        int bus = row.row*2 | row.bus;
        assert(bus >= 0 && bus < 15);
        merge.match_to_logical_table_ixbar_outputmap[type][bus].enabled_4bit_muxctl_select = logical_id;
        merge.match_to_logical_table_ixbar_outputmap[type][bus].enabled_4bit_muxctl_enable = 1;
        assert(result->action_args.size() >= 1 && result->action_args[0]);
        merge.mau_action_instruction_adr_mask[type][bus] = (1U << result->action_args[0]->size) - 1;
        if (result->action) {
            /* FIXME -- deal with variable-sized actions */
            merge.mau_actiondata_adr_default[type][bus] =
                get_address_mau_actiondata_adr_default(result->action->format->log2size);
        }
    }
    /*------------------------
     * Action instruction Address
     *-----------------------*/
    Actions *actions = result->actions;
    if (result->action) {
        assert(!actions);
        actions = result->action->actions; }
    assert(actions);

    assert(result->action_args[0]);
    if ((1U << result->action_args[0]->size) <= ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH) {
        merge.mau_action_instruction_adr_map_en[type] |= (1U << logical_id);
        int idx = 0;
        int shift = 0;
        for (auto act : *actions) {
            merge.mau_action_instruction_adr_map_data[type][logical_id][idx]
                |= act->second.first << shift;
            if ((shift += 6) >= 24) {
                shift = 0;
                idx++;
                assert(idx < 2); } }
    } else {
        /* FIXME */
        assert(0);
    }

    /*------------------------
     * Next Table
     *-----------------------*/
    Table *next = result->hit_next.size() > 0 ? result : this;
    if (next->hit_next.size() < NEXT_TABLE_SUCCESSOR_TABLE_DEPTH) {
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
    assert(((next->hit_next.size()-1) & next->hit_next.size()) == 0);
    merge.next_table_format_data[logical_id].match_next_table_adr_mask = next->hit_next.size()-1;

    /*------------------------
     * Immediate data found in overhead
     *-----------------------*/
    for (auto &row : result->layout) {
        int bus = row.row*2 | row.bus;
        assert(bus >= 0 && bus < 15);
	merge.mau_immediate_data_mask[type][bus] = (1UL << result->format->immed_size)-1; }
    if (result->action_bus)
        result->action_bus->write_immed_regs(result);

    input_xbar->write_regs();
}

void Table::ActionBus::set_immed_offsets(Table *tbl) {
    for (auto &f : by_byte) {
        Format::Field *field = f.second.second;
        assert(field->action_xbar == (int)f.first);
        int slot = Stage::action_bus_slot_map[f.first];
        unsigned off = field->bit - tbl->format->immed->bit;
        field->action_xbar_bit = off % Stage::action_bus_slot_size[slot]; }
}

void Table::ActionBus::write_immed_regs(Table *tbl) {
    auto &adrdist = tbl->stage->regs.rams.match.adrdist;
    int tid = tbl->logical_id;
    for (auto &f : by_byte) {
        assert(f.second.second->action_xbar == (int)f.first);
        int slot = Stage::action_bus_slot_map[f.first];
        unsigned off = f.second.second->bit - tbl->format->immed->bit;
        unsigned size = f.second.second->size;
        switch(Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned b = off/8; b <= (off + size - 1)/8; b++) {
                adrdist.immediate_data_8b_ixbar_ctl[tid*4 + b]
                    .enabled_4bit_muxctl_select = slot++;
                adrdist.immediate_data_8b_ixbar_ctl[tid*4 + b]
                    .enabled_4bit_muxctl_enable = 1; }
            break;
        case 16:
            slot -= ACTION_DATA_8B_SLOTS;
            for (unsigned w = off/16; w <= (off + size - 1)/16; w++) {
                adrdist.immediate_data_16b_ixbar_ctl[tid*2 + w]
                    .enabled_5bit_muxctl_select = slot++;
                adrdist.immediate_data_16b_ixbar_ctl[tid*2 + w]
                    .enabled_5bit_muxctl_enable = 1; }
            break;
        case 32:
            slot -= ACTION_DATA_8B_SLOTS + ACTION_DATA_16B_SLOTS;
            adrdist.immediate_data_32b_ixbar_ctl[tid].enabled_5bit_muxctl_select = slot;
            adrdist.immediate_data_32b_ixbar_ctl[tid].enabled_5bit_muxctl_enable = 1;
            break;
        default:
            assert(0); } }
}

DEFINE_TABLE_TYPE(ExactMatchTable, MatchTable, "exact_match",
    struct Way {
        int        lineno;
        int        group, subgroup, mask;
    };
    std::vector<Way>            ways;
    std::vector<Phv::Ref>       match;
)
DEFINE_TABLE_TYPE(TernaryMatchTable, MatchTable, "ternary_match",
public:
    int tcam_id;
    Table::Ref indirect;
    Format::Field *lookup_field(const std::string &name, const std::string &action) {
        assert(!format);
        return indirect ? indirect->lookup_field(name, action) : 0; }
)
DEFINE_TABLE_TYPE(TernaryIndirectTable, Table, "ternary_indirect",)
DEFINE_TABLE_TYPE(ActionTable, Table, "action",
    std::map<std::string, Format *>     action_formats;
    Format::Field *lookup_field(const std::string &name, const std::string &action);
    void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn);
)
DEFINE_TABLE_TYPE(GatewayTable, Table, "gateway",
    uint64_t                    payload;
    int                         gw_unit;
    std::vector<Phv::Ref>       match, xor_match;
    struct Match {
        match_t                 val;
        bool                    run_table;
        Ref                     next;
        Match() : val{0,0}, run_table(false) {}
        Match(match_t &v, value_t &data);
    }                           miss;
    std::vector<Match>          table;
public:
    static GatewayTable *create(int lineno, const std::string &name, gress_t gress,
                                Stage *stage, int lid, VECTOR(pair_t) &data)
        { return table_type.create(lineno, name.c_str(), gress, stage, lid, data); }
)

void MatchTable::link_action(Table::Ref &ref) {
    if (ref) {
        if (!dynamic_cast<ActionTable *>((Table *)ref))
            error(ref.lineno, "%s is not an action table", ref->name());
        if (ref->match_table)
            error(ref->lineno, "Multiple references to action table %s",
                  ref->name());
        ref->match_table = this;
        ref->logical_id = logical_id; }
}

void ExactMatchTable::setup(VECTOR(pair_t) &data) {
    setup_layout(get(data, "row"), get(data, "column"), get(data, "bus"));
    setup_logical_id();
    if (auto *fmt = get(data, "format")) {
       if (CHECKTYPE(*fmt, tMAP))
           format = new Format(fmt->map);
    } else
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "input_xbar") {
	    if (CHECKTYPE(kv.value, tMAP))
		input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "gateway") {
	    if (CHECKTYPE(kv.value, tMAP)) {
                gateway = GatewayTable::create(kv.key.lineno, name_+" gateway",
                        gress, stage, logical_id, kv.value.map);
                gateway->match_table = this; }
        } else if (kv.key == "format") {
            /* done above to be done before action_bus */
        } else if (kv.key == "action") {
            setup_action_table(kv.value);
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
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else if (kv.key == "ways") {
            if (!CHECKTYPE(kv.value, tVEC)) continue;
            for (auto &w : kv.value.vec) {
                if (!CHECKTYPE(w, tVEC)) continue;
                if (w.vec.size != 3 || w[0].type != tINT || w[1].type != tINT || w[2].type != tINT)
                    error(w.lineno, "invalid way descriptor");
                else ways.emplace_back(Way{w.lineno, w[0].i, w[1].i, w[2].i}); }
        } else if (kv.key == "match") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    match.emplace_back(gress, v);
            else
                match.emplace_back(gress, kv.value);
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
    alloc_rams(false, stage->sram_use, &stage->sram_match_bus_use);
    if (action.set() && actions)
	error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
	error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action.set() && (action_args.size() < 1 || action_args.size() > 2))
        error(lineno, "Unexpected number of action table arguments %zu", action_args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}
void ExactMatchTable::pass1() {
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    check_next();
    link_action(action);
    if (action_bus)
        action_bus->pass1(this);
    if (actions) {
        assert(action_args.size() == 0);
        if (auto *sel = lookup_field("action"))
            action_args.push_back(sel);
        else
            error(lineno, "No field 'action' in table %s format", name());
        actions->pass1(this); }
    input_xbar->pass1(stage->exact_ixbar, 128);
    format->setup_immed(this);
    if (!format->field("match"))
        error(format->lineno, "No 'match' field in format for table %s", name());
    else for (unsigned i = 0; i < format->groups(); i++) {
        Format::Field *match = format->field("match", i);
        if (match->bit % 8 != 0 || match->size % 8 != 0)
            error(format->lineno, "'match' field not byte aligned in table %s", name());
        if (auto *version = format->field("version"))
            if (version->size != 4 || (version->bit % 4) != 0)
                error(format->lineno, "'version' field not 4 bits and nibble aligned "
                      "in table %s", name()); }
    unsigned fmt_width = (format->size + 127)/128;
    if (ways.empty())
        error(lineno, "No ways defined in table %s", name());
    else if (layout.size() % (ways.size()*fmt_width) != 0)
        error(lineno, "Rows is not a mulitple of ways in table %s", name());
    unsigned way = 0, word = 0;
    for (auto &row : layout) {
        if (word == 0) {
            if (ways[way].group >= EXACT_HASH_GROUPS ||
                ways[way].subgroup >= 5 ||
                (ways[way].mask &~ 0xfff)) {
                error(ways[way].lineno, "invalid exact match way");
                break; } }
        if (row.cols.size() != 1U << bitcount(ways[way].mask))
            error(ways[way].lineno, "Depth of way doesn't match number of columns on "
                  "row %d in table %s", row.row, name());
        if (++word == fmt_width) { word = 0; way++; } }
    for (auto &r : match) r.check();
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
}

void ExactMatchTable::pass2() {
    input_xbar->pass2(stage->exact_ixbar, 128);
    if (action_bus) {
        action_bus->pass2(this);
        action_bus->set_immed_offsets(this); }
    if (actions) actions->pass2(this);
    if (gateway) gateway->pass2();
}

class GroupsInWord {
    unsigned    groups[2];
    struct iter {
        const GroupsInWord      *self;
        unsigned                idx, ctr;
        iter(const GroupsInWord *s) : self(s), idx(0), ctr(0) {
            if (!((self->groups[idx] >> ctr) & 1)) ++*this; }
        iter() : self(0), idx(2), ctr(0) { }
        bool operator==(const iter &a) const { return idx == a.idx && ctr == a.ctr; }
        unsigned operator*() const { return ctr; }
        iter &operator++() {
            do { if (++ctr >= 32 || self->groups[idx] < (1U << ctr)) {
                    ctr=0; idx++; }
            } while (idx < 2 && (!((self->groups[idx] >> ctr) & 1)));
            return *this; }
    };
public:
    GroupsInWord(unsigned words, unsigned cross_words) {
        groups[0] = words&cross_words; groups[1] = words&~cross_words; }
    iter begin() const { return iter(this); }
    iter end() const { return iter(); }
};

/* build the weird 18-bit byte/nibble mask for matching, checking for problems */
bool mask2tofino_mask(bitvec &mask, int word, bitvec &ignored, unsigned &bytemask) {
    bytemask = 0;
    for (unsigned i = 0; i < 14; i++) {
        unsigned byte = mask.getrange(word*128+i*8, 8);
        if (byte) {
            byte |= ignored.getrange(word*128+i*8, 8);
            if (byte != 0xff) return false;
            bytemask |= 1U << i; } }
    for (unsigned i = 0; i < 4; i++) {
        unsigned nibble = mask.getrange(word*128+i*4+112, 4);
        if (nibble) {
            nibble |= ignored.getrange(word*128+i*4+112, 4);
            if (nibble != 0xf) return false;
            bytemask |= 1U << (i + 14); } }
    return true;
}

bool setup_match_input(unsigned bytes[16], std::vector<Phv::Ref> &match, Stage *stage, int group) {
    auto byte = 0;
    bool rv = true;
    for (auto &r : match) {
        bool found = false;
        for (auto *in : stage->exact_ixbar[group]) {
            if (auto *i = in->find(*r, group)) {
                for (int bit = r->lo; bit <= r->hi; bit += 8) {
                    assert(byte < 16);
                    bytes[byte++] = (i->lo + bit - i->what->lo)/8; }
                found = true;
                break; } }
        if (!found) {
            error(r.lineno, "Can't find %s in input xbar group %d", r.name(), group);
            rv = false; } }
    return rv;
}

void ExactMatchTable::write_regs() {
    if (input_xbar->width() > 1) {
        error(lineno, "FIXME -- can't deal with exact match larger than 128 bits");
        return; }
    MatchTable::write_regs(0, this);
    unsigned fmt_width = (format->size + 127)/128;
    unsigned way = 0, word = 0;
    int vpn = 0;
    bitvec match_mask, version_nibble_mask;
    unsigned groups_in_word[fmt_width];
    unsigned groups_cross_words = 0;
    unsigned words_in_group[format->groups()];
    match_mask.setrange(0, 128*fmt_width);
    version_nibble_mask.setrange(0, 32*fmt_width);
    for (unsigned i = 0; i < fmt_width; i++) groups_in_word[i] = 0;
    for (unsigned i = 0; i < format->groups(); i++) {
        words_in_group[i] = 0;
        Format::Field *match = format->field("match", i);
        match_mask.clrrange(match->bit, match->size);
        groups_in_word[match->bit/128] |= 1U << i;
        words_in_group[i] |= 1U << match->bit/128;
        if (match->bit%128 + match->size > 128) {
            groups_in_word[match->bit/128 + 1] |= 1U << i;
            words_in_group[i] |= 2U << match->bit/128; }
        if (Format::Field *version = format->field("version", i)) {
            match_mask.clrrange(version->bit, version->size);
            groups_in_word[version->bit/128] |= 1U << i;
            words_in_group[i] |= 1U << version->bit/128;
            version_nibble_mask.clrrange(version->bit/4, 1); }
        unsigned t = ((words_in_group[i] ^ (words_in_group[i]-1)) << 1) | 1;
        if (words_in_group[i] & ~t) {
            error(lineno, "Group %d in table %s tries to match over non-adjacent"
                  " rows", i, name());
            return; }
        if (words_in_group[i] & ~(t >> 1))
            groups_cross_words |= 1U << i; }
    for (unsigned i = 0; i < fmt_width; i++) {
        if (bitcount(groups_in_word[i]) > 5) {
            error(lineno, "More than 5 match groups in one word in table %s", name());
            return; }
        if (bitcount(groups_in_word[i]&groups_cross_words) > 2) {
            error(lineno, "More than 2 match groups that cross words in table %s", name());
            return; } }
    /* iterating through rows in the sram array;  while in this loop, 'row' is the
     * row we're on, 'word' is which word in a wide full-way the row is for, and 'way'
     * is which full-way of the match table the row is for */
    unsigned wide_bus = ~0;     /* bus used by first word of wide match */
    for (auto &row : layout) {
        /* setup match logic in rams */
        auto &vh_adr_xbar = stage->regs.rams.array.row[row.row].vh_adr_xbar;
        vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus]
            .enabled_3bit_muxctl_select = ways[way].group;
        vh_adr_xbar.exactmatch_row_hashadr_xbar_ctl[row.bus]
            .enabled_3bit_muxctl_enable = 1;
        MaskCounter bank(ways[way].mask);
        for (auto col : row.cols) {
            vh_adr_xbar.exactmatch_mem_hashadr_xbar_ctl[col]
                .enabled_4bit_muxctl_select = ways[way].subgroup + row.bus*5;
            vh_adr_xbar.exactmatch_mem_hashadr_xbar_ctl[col]
                .enabled_4bit_muxctl_enable = 1;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_bank_mask = ways[way].mask;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_bank_id = bank++;
            vh_adr_xbar.exactmatch_bank_enable[col]
                .exactmatch_bank_enable_inp_sel |= 1 << row.bus;
            auto &ram = stage->regs.rams.array.row[row.row].ram[col];
            auto &unitram_config = stage->regs.rams.map_alu.row[row.row].adrmux
                    .unitram_config[col/6][col%6];
            for (unsigned i = 0; i < 4; i++)
                ram.match_mask[i] = match_mask.getrange(word*128+i*32, 32);
            for (int v : VersionIter(config_version)) {
                ram.unit_ram_ctl[v].match_ram_write_data_mux_select = 7; /* unused */
                ram.unit_ram_ctl[v].match_ram_read_data_mux_select = 7; /* unused */
                ram.unit_ram_ctl[v].match_result_bus_select = 1 << row.bus;
                if (auto cnt = bitcount(groups_in_word[word]))
                    ram.unit_ram_ctl[v].match_entry_enable = ~(~0U << --cnt);
                unitram_config[v].unitram_type = 1;
                unitram_config[v].unitram_logical_table = logical_id;
                switch (gress) {
                case INGRESS: unitram_config[v].unitram_ingress = 1; break;
                case EGRESS: unitram_config[v].unitram_egress = 1; break;
                default: assert(0); }
                unitram_config[v].unitram_enable = 1; }
            ram.match_ram_vpn.match_ram_vpn0 = vpn >> 2;
            unsigned vpn_lsb = (vpn&3) - 1;
            for (unsigned i = 0; i < format->groups(); i++)
                ram.match_ram_vpn.match_ram_vpn_lsbs |= (++vpn_lsb) << i*3;
            if (vpn_lsb & 4)
                ram.match_ram_vpn.match_ram_vpn1 = (vpn >> 2) + 1;
            /* TODO -- Algorithmic TCAM support will require something else here */
            ram.match_nibble_s0q1_enable = version_nibble_mask.getrange(word*32, 32);
            ram.match_nibble_s1q0_enable = 0xffffffffUL;
            int word_group = 0;
            for (unsigned group : GroupsInWord(groups_in_word[word], groups_cross_words)) {
                unsigned tofino_mask = 0;
                bitvec mask;
                mask.clear();
                Format::Field *match = format->field("match", group);
                mask.setrange(match->bit, match->size);
                if (Format::Field *version = format->field("version", group))
                    mask.setrange(version->bit, version->size);
                if (!mask2tofino_mask(mask, word, match_mask, tofino_mask)) {
                    error(lineno, "Invalid match mask for group %d in table %s",
                          group, name());
                    return; }
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = ~tofino_mask & 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = ~(tofino_mask >> 14) & 0xf;
                word_group++; }
            for (; word_group < 5; word_group++) {
                ram.match_bytemask[word_group].mask_bytes_0_to_13 = 0x3fff;
                ram.match_bytemask[word_group].mask_nibbles_28_to_31 = 0xf; }
        }
        /* setup input xbars to get data to the right places on the bus(es) */
        auto &vh_xbar = stage->regs.rams.array.row[row.row].vh_xbar;
        unsigned input_bus_locs[16];
        setup_match_input(input_bus_locs, match, stage, ways[way].group);
        for (unsigned i = 0; i < format->groups(); i++) {
            Format::Field *match = format->field("match", i);
            if (match->bit >= (word+1)*128 || match->bit + match->size <= word*128)
                continue;
            unsigned byte = (match->bit%128)/8;
            for (unsigned b = 0; b < match->size/8; b++, byte++)
                vh_xbar[row.bus].exactmatch_row_vh_xbar_byteswizzle_ctl[byte/4]
                    .set_subfield(0x10 + input_bus_locs[b], (byte%4)*5, 5);
            if (Format::Field *version = format->field("version", i)) {
                if (version->bit/128 != word) continue;
                vh_xbar[row.bus].exactmatch_validselect |= 1U << (version->bit%128)/4; } }
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_select = ways[way].group;
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_enable = 1;
        vh_xbar[row.bus].exactmatch_row_vh_xbar_ctl.exactmatch_row_vh_xbar_thread = gress;
        /* setup match central config to extract results of the match */
        auto &merge = stage->regs.rams.match.merge;
        unsigned bus = row.row*2 + row.bus;
        if (word == 0) wide_bus = bus;
        /* FIXME -- factor this where possible with ternary match code */
        if (action) {
            if (action_args.size() == 1) {
                /* FIXME -- fixed actiondata mask??  See
                 * get_direct_address_mau_actiondata_adr_tcam_mask in
                 * device/pipeline/mau/address_and_data_structures.py
                 * Maybe should be masking off bottom 6-format->log2size bits, as those
                 * will be coming from the top of the tcam_indir data bus?  They'll always
                 * be 0 anyways, unless the full data bus is in use */
                merge.mau_actiondata_adr_mask[0][bus] = 0x3fffff;
            } else {
                /* FIXME -- support for multiple sizes of action data? */
                int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
                merge.mau_actiondata_adr_mask[0][bus] =
                    ((1U << action_args[1]->size) - 1) << lo_huffman_bits; }
            merge.mau_actiondata_adr_vpn_shiftcount[0][bus] =
                std::max(0, (int)action->format->log2size - 7);
        } else {
            /* FIXME -- do we need to actually set this? */
            merge.mau_actiondata_adr_mask[0][bus] = 0x3fffff; }
        int word_group = 0;
        for (unsigned group : GroupsInWord(groups_in_word[word], groups_cross_words)) {
            assert(action_args[0]->by_group[group]->bit/128 == word);
            merge.mau_action_instruction_adr_exact_shiftcount[bus][word_group] =
                action_args[0]->by_group[group]->bit % 128;
            if (format->immed) {
                assert(format->immed->by_group[group]->bit/128 == word);
                merge.mau_immediate_data_exact_shiftcount[bus][word_group] =
                    format->immed->by_group[group]->bit % 128; }
            /* FIXME -- factor this where possible with ternary match code */
            if (action) {
                int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
                if (action_args.size() == 1) {
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        69 + (format->log2size-2) - lo_huffman_bits;
                } else {
                    merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] =
                        action_args[1]->bit + 5 - lo_huffman_bits; }
            } else {
                /* FIXME -- do we actually need to set this? */
                merge.mau_actiondata_adr_exact_shiftcount[bus][word_group] = 69;
            }
            word_group++; }
        for (auto col : row.cols) {
            merge.col[col].row_action_nxtable_bus_drive[row.row] = 1 << row.bus;
            merge.col[col].hitmap_output_map[bus].enabled_4bit_muxctl_select = wide_bus;
            merge.col[col].hitmap_output_map[bus].enabled_4bit_muxctl_enable = 1; }
        if (++word == fmt_width) { word = 0; way++; vpn += format->groups(); } }
    if (actions) actions->write_regs(this);
    if (gateway) gateway->write_regs();
}

void TernaryMatchTable::setup(VECTOR(pair_t) &data) {
    tcam_id = -1;
    setup_layout(get(data, "row"), get(data, "column"), get(data, "bus"));
    setup_logical_id();
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "input_xbar") {
	    if (CHECKTYPE(kv.value, tMAP))
		input_xbar = new InputXbar(this, true, kv.value.map);
        } else if (kv.key == "gateway") {
	    if (CHECKTYPE(kv.value, tMAP)) {
                gateway = GatewayTable::create(kv.key.lineno, name_+" gateway",
                        gress, stage, logical_id, kv.value.map);
                gateway->match_table = this; }
        } else if (kv.key == "indirect") {
            if (CHECKTYPE(kv.value, tSTR))
                indirect = kv.value;
        } else if (kv.key == "tcam_id") {
            if (CHECKTYPE(kv.value, tINT)) {
		if ((tcam_id = kv.value.i) < 0 || tcam_id >= TCAM_TABLES_PER_STAGE)
		    error(kv.key.lineno, "Invalid tcam_id %d", tcam_id);
                else if (stage->tcam_id_use[tcam_id])
                    error(kv.key.lineno, "Tcam id %d already in use by table %s",
                          tcam_id, stage->tcam_id_use[tcam_id]->name());
                else
                    stage->tcam_id_use[tcam_id] = this; }
        } else if (kv.key == "hit") {
            if (!hit_next.empty())
                error(kv.key.lineno, "Specifying both 'hit' and 'next' in table %s", name());
            else if (CHECKTYPE(kv.value, tSTR))
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
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
    alloc_rams(false, stage->tcam_use, &stage->tcam_match_bus_use);
}
void TernaryMatchTable::pass1() {
    stage->table_use[gress] |= Stage::USE_TCAM;
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_id("tcam", tcam_id, stage->pass1_tcam_id,
	     TCAM_TABLES_PER_STAGE, false, stage->tcam_id_use);
    alloc_busses(stage->tcam_match_bus_use);
    check_next();
    indirect.check();
    link_action(action);
    if (indirect) {
        if (!dynamic_cast<TernaryIndirectTable *>((Table *)indirect))
            error(indirect.lineno, "%s is not a ternary indirect table", indirect->name());
        if (indirect->match_table)
            error(indirect->lineno, "Multiple references to ternary indirect table %s",
                  indirect->name());
        indirect->match_table = this;
        indirect->logical_id = logical_id;
        link_action(indirect->action);
        if (hit_next.size() > 0 && indirect->hit_next.size() > 0)
            error(hit_next[0].lineno, "Ternary Match table with both direct and indirect "
                  "next tables"); }
    if (hit_next.size() > 2)
        error(hit_next[0].lineno, "Ternary Match tables cannot directly specify more"
              "than 2 hit next tables");
    input_xbar->pass1(stage->tcam_ixbar, 44);
    if (actions) actions->pass1(this);
    if (gateway) {
        gateway->logical_id = logical_id;
        gateway->pass1(); }
}
void TernaryMatchTable::pass2() {
    input_xbar->pass2(stage->tcam_ixbar, 44);
    if (gateway) gateway->pass2();
}
void TernaryMatchTable::write_regs() {
    MatchTable::write_regs(1, indirect);
    int vpn = 0;
    unsigned word = 0;
    auto &merge = stage->regs.rams.match.merge;
    for (Layout &row : layout) {
	for (int col : row.cols) {
	    auto &tcam_mode = stage->regs.tcams.col[col].tcam_mode[row.row];
	    /* TODO -- always setting dirtcam mode to 0 */
	    tcam_mode.tcam_data_dirtcam_mode = 0;
	    tcam_mode.tcam_data1_select = row.bus;
	    tcam_mode.tcam_chain_out_enable = word > 0;
	    if (gress == INGRESS)
		tcam_mode.tcam_ingress = 1;
	    else
		tcam_mode.tcam_egress = 1;
	    tcam_mode.tcam_match_output_enable = (word == 0);
	    tcam_mode.tcam_vpn = vpn;
	    tcam_mode.tcam_logical_table = tcam_id;
	    /* TODO -- always disable tcam_validbit_xbar? */
	    auto &tcam_vh_xbar = stage->regs.tcams.vh_data_xbar;
            int off = (row.row&1) * 4;
	    for (int i = 0; i < 4; i++)
		tcam_vh_xbar.tcam_validbit_xbar_ctl[row.bus][row.row/2][i+off] = 15;
            if (word+1 == input_xbar->width()) {
                tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row]
                    .tcam_row_halfbyte_mux_ctl_select = 3;
                tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row]
                    .tcam_row_halfbyte_mux_ctl_enable = 1;
                tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row]
                    .tcam_row_search_thread = gress; }
            /* FIXME:
            tcam_vh_xbar.tcam_extra_byte_ctl[row.bus][row.row/2]
                .enabled_3bit_muxctl_select = byte_match_group_number;
            tcam_vh_xbar.tcam_extra_byte_ctl[row.bus][row.row/2]
                .enabled_3bit_muxctl_enable = 1; */
	    tcam_vh_xbar.tcam_row_output_ctl[row.bus][row.row]
		.enabled_4bit_muxctl_select = input_xbar->group_for_word(word);
	    tcam_vh_xbar.tcam_row_output_ctl[row.bus][row.row]
		.enabled_4bit_muxctl_enable = 1;
            if (word == 0)
                stage->regs.tcams.col[col].tcam_table_map[tcam_id] |= 1U << row.row;
	}
        if (++word == input_xbar->width()) { word = 0; vpn++; } }
    merge.tcam_hit_to_logical_table_ixbar_outputmap[tcam_id]
        .enabled_4bit_muxctl_select = logical_id;
    merge.tcam_hit_to_logical_table_ixbar_outputmap[tcam_id]
        .enabled_4bit_muxctl_enable = 1;
    /* FIXME -- unconditionally setting piped mode -- only need it for wide
     * match across a 4-row boundary */
    merge.tcam_table_prop[tcam_id].tcam_piped = 1;
    stage->table_use[gress] |= Stage::USE_TCAM_PIPED;
    merge.tcam_table_prop[tcam_id].thread = gress;
    merge.tcam_table_prop[tcam_id].enabled = 1;
    stage->regs.tcams.tcam_output_table_thread[tcam_id] = 1 << gress;
    if (gateway) gateway->write_regs();
}

void TernaryIndirectTable::setup(VECTOR(pair_t) &data) {
    match_table = 0;
    setup_layout(get(data, "row"), get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
       if (CHECKTYPE(*fmt, tMAP))
           format = new Format(fmt->map);
        if (format->size > 64)
            error(fmt->lineno, "ternary indirect format larger than 64 bits");
        if (format->size < 4) {
            /* pad out to minumum size */
            format->size = 4;
            format->log2size = 2; }
    } else
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "format") {
            /* done above to be done before action_bus */
        } else if (kv.key == "action") {
            setup_action_table(kv.value);
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
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
    alloc_rams(false, stage->sram_use, &stage->tcam_indirect_bus_use);
    if (action.set() && actions)
	error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
	error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action.set() && (action_args.size() < 1 || action_args.size() > 2))
        error(lineno, "Unexpected number of action table arguments %zu", action_args.size());
    if (actions && !action_bus) action_bus = new ActionBus();
}
void TernaryIndirectTable::pass1() {
    alloc_busses(stage->tcam_indirect_bus_use);
    check_next();
    if (action_bus) action_bus->pass1(this);
    if (actions) {
        assert(action_args.size() == 0);
        if (auto *sel = lookup_field("action"))
            action_args.push_back(sel);
        else
            error(lineno, "No field 'action' in table %s format", name());
        actions->pass1(this); }
    if (format) format->setup_immed(this);
}
void TernaryIndirectTable::pass2() {
    if (!match_table)
        error(lineno, "No match table for ternary indirect table %s", name());
    if (action_bus) {
        action_bus->pass2(this);
        action_bus->set_immed_offsets(this); }
    if (actions) actions->pass2(this);
}
void TernaryIndirectTable::write_regs() {
    int tcam_id = dynamic_cast<TernaryMatchTable *>(match_table)->tcam_id;
    stage->regs.tcams.tcam_match_adr_shift[tcam_id] = format->log2size-2;
    int vpn = 0;
    auto &merge = stage->regs.rams.match.merge;
    for (Layout &row : layout) {
	for (int col : row.cols) {
            auto &unit_ram_ctl = stage->regs.rams.array.row[row.row].ram[col].unit_ram_ctl;
            for (int v : VersionIter(config_version)) {
                unit_ram_ctl[v].match_ram_write_data_mux_select = 7; /* disable */
                unit_ram_ctl[v].match_ram_read_data_mux_select = 7; /* disable */
                unit_ram_ctl[v].tind_result_bus_select = 1U << row.bus; }
            auto &mux_ctl = stage->regs.rams.map_alu.row[row.row].adrmux
                    .ram_address_mux_ctl[col/6][col%6];
            for (int v : VersionIter(config_version))
                mux_ctl[v].ram_unitram_adr_mux_select = row.bus + 2;
            auto &unitram_config = stage->regs.rams.map_alu.row[row.row].adrmux
                    .unitram_config[col/6][col%6];
            for (int v : VersionIter(config_version)) {
                unitram_config[v].unitram_type = 6;
                unitram_config[v].unitram_vpn = vpn;
                unitram_config[v].unitram_logical_table = logical_id;
                if (gress == INGRESS)
                    unitram_config[v].unitram_ingress = 1;
                else
                    unitram_config[v].unitram_egress = 1;
                unitram_config[v].unitram_enable = 1; }
            auto &xbar_ctl = stage->regs.rams.map_alu.row[row.row].vh_xbars
                    .adr_dist_tind_adr_xbar_ctl[row.bus];
            for (int v : VersionIter(config_version)) {
                xbar_ctl[v].enabled_3bit_muxctl_select = tcam_id;
                xbar_ctl[v].enabled_3bit_muxctl_enable = 1; }
            vpn++; }
        int bus = row.row*2 + row.bus;
        merge.tind_ram_data_size[bus] = format->log2size - 1;
        merge.tcam_match_adr_to_physical_oxbar_outputmap[bus].enabled_3bit_muxctl_select = tcam_id;
        merge.tcam_match_adr_to_physical_oxbar_outputmap[bus].enabled_3bit_muxctl_enable = 1;
        merge.tind_bus_prop[bus].tcam_piped = 1;
        merge.tind_bus_prop[bus].thread = gress;
        merge.tind_bus_prop[bus].enabled = 1;
        merge.mau_action_instruction_adr_tcam_shiftcount[bus] = action_args[0]->bit;
        if (format->immed)
            merge.mau_immediate_data_tcam_shiftcount[bus] = format->immed->bit;
        if (action) {
            int lo_huffman_bits = std::min(action->format->log2size-2, 5U);
            if (action_args.size() == 1) {
                /* FIXME -- fixed actiondata mask??  See
                 * get_direct_address_mau_actiondata_adr_tcam_mask in
                 * device/pipeline/mau/address_and_data_structures.py
                 * Maybe should be masking off bottom 6-format->log2size bits, as those
                 * will be coming from the top of the tcam_indir data bus?  They'll always
                 * be 0 anyways, unless the full data bus is in use */
                merge.mau_actiondata_adr_mask[1][bus] = 0x3fffff;
                merge.mau_actiondata_adr_tcam_shiftcount[bus] =
                    69 + (format->log2size-2) - lo_huffman_bits;
            } else {
                /* FIXME -- support for multiple sizes of action data? */
                merge.mau_actiondata_adr_mask[1][bus] =
                    ((1U << action_args[1]->size) - 1) << lo_huffman_bits;
                merge.mau_actiondata_adr_tcam_shiftcount[bus] =
                    action_args[1]->bit + 5 - lo_huffman_bits; }
            merge.mau_actiondata_adr_vpn_shiftcount[1][bus] =
                std::max(0, (int)action->format->log2size - 7);
        } else {
            /* FIXME -- are these actually needed?  Duplicating what the compiler does */
            merge.mau_actiondata_adr_mask[1][bus] = 0x3fffff;
            merge.mau_actiondata_adr_tcam_shiftcount[bus] = 73; }
    }
    if (actions) actions->write_regs(this);
}

Table::Format::Field *ActionTable::lookup_field(const std::string &name, const std::string &action)
{
    if (action == "*" || action == "") {
        if (auto *rv = format ? format->field(name) : 0)
            return rv;
        if (action == "*")
            for (auto &fmt : action_formats)
                if (auto *rv = fmt.second->field(name))
                    return rv;
    } else { 
        if (auto *fmt = get(action_formats, name)) {
            if (auto *rv = fmt->field(name))
                return rv;
        } else if (auto *rv = format ? format->field(name) : 0)
            return rv; }
    if (match_table) {
        assert((Table *)match_table != (Table *)this);
        return match_table->lookup_field(name); }
    return 0;
}
void ActionTable::apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn) {
    for (auto &fmt : action_formats)
        fmt.second->apply_to_field(n, fn);
    if (format)
        format->apply_to_field(n, fn);
}

void ActionTable::setup(VECTOR(pair_t) &data) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(row, get(data, "column"), get(data, "bus"));
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "format") {
            if (CHECKTYPE(kv.value, tMAP))
                format = new Format(kv.value.map);
        } else if (kv.key.type == tCMD && kv.key[0] == "format") {
            if (!PCHECKTYPE(kv.key.vec.size > 1, kv.key[1], tSTR)) continue;
            if (action_formats.count(kv.key[1].s)) {
                error(kv.key.lineno, "Multiple formats for action %s", kv.key[1].s);
                return; }
            if (CHECKTYPE(kv.value, tMAP))
                action_formats[kv.key[1].s] = new Format(kv.value.map); } }
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "format") {
            /* done above to be done before action_bus */
        } else if (kv.key.type == tCMD && kv.key[0] == "format") {
            /* done above to be done before action_bus */
        } else if (kv.key == "actions") {
            if (CHECKTYPE(kv.value, tMAP))
                actions = new Actions(this, kv.value.map);
        } else if (kv.key == "action_bus") {
            if (CHECKTYPE(kv.value, tMAP))
                action_bus = new ActionBus(this, kv.value.map);
        } else if (kv.key == "row" || kv.key == "logical_row" ||
                   kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(true, stage->sram_use, 0);
    if (!actions)
        error(lineno, "No actions in action table %s", name());
    if (actions && !action_bus) action_bus = new ActionBus();
}
void ActionTable::pass1() {
    for (Layout &row : layout) {
        if (row.row > layout[0].row)
            error(row.lineno, "Action table %s home row must be first", name());
    }
    for (auto &fmt : action_formats) {
        if (!actions->exists(fmt.first)) {
            error(fmt.second->lineno, "Format for non-existant action %s", fmt.first.c_str());
            continue; }
        for (auto &fld : *fmt.second) {
            if (auto *f = format ? format->field(fld.first) : 0) {
                if (fld.second.bit != f->bit || fld.second.size != f->size) {
                    error(fmt.second->lineno, "Action %s format for field %s incompatible "
                          "with default format", fmt.first.c_str(), fld.first.c_str());
                    continue; } }
            for (auto &fmt2 : action_formats) {
                if (fmt.second == fmt2.second) break;
                if (auto *f = fmt2.second->field(fld.first)) {
                    if (fld.second.bit != f->bit || fld.second.size != f->size) {
                        error(fmt.second->lineno, "Action %s format for field %s incompatible "
                              "with action %s format", fmt.first.c_str(), fld.first.c_str(),
                              fmt2.first.c_str());
                        break; } } } } }
    action_bus->pass1(this);
    if (actions) actions->pass1(this);
}
void ActionTable::pass2() {
    if (!match_table)
        error(lineno, "No match table for action table %s", name());
    action_bus->pass2(this);
    action_bus->set_action_offsets(this);
    if (actions) actions->pass2(this);
}

void Table::ActionBus::pass1(Table *tbl) {
    for (auto &ent : by_byte) {
        int slot = Stage::action_bus_slot_map[ent.first];
        Format::Field *field = ent.second.second;
        bool err = false;
        for (int space = field->size; space > 0; space -= Stage::action_bus_slot_size[slot++]) {
            if (slot >= ACTION_DATA_BUS_SLOTS) {
                error(lineno, "%s extends past the end of the actions bus",
                      ent.second.first.c_str());
                err = true;
                break; }
            if (tbl->stage->action_bus_use[slot]) {
                error(lineno, "Action bus byte %d set in table %s and table %s", ent.first,
                      tbl->name(), tbl->stage->action_bus_use[slot]->name());
                err = true;
                break; }
            tbl->stage->action_bus_use[slot] = tbl;
        }
        if (err) continue;
    }
}
void Table::ActionBus::pass2(Table *tbl) {
    /* FIXME -- allocate action bus slots for things that need to be on the action bus
     * FIXME -- and aren't */
}

void Table::ActionBus::set_action_offsets(Table *tbl) {
    for (auto &f : by_byte) {
        Format::Field *field = f.second.second;
        assert(field->action_xbar == (int)f.first);
        int slot = Stage::action_bus_slot_map[f.first];
        field->action_xbar_bit = field->bit % Stage::action_bus_slot_size[slot]; }
}

void Table::ActionBus::write_action_regs(Table *tbl, unsigned home_row, unsigned action_slice) {
    /* FIXME -- home_row is the wrong row to use for action_slice != 0 */
    auto &action_hv_xbar = tbl->stage->regs.rams.array.row[home_row/2].action_hv_xbar;
    unsigned side = home_row%2;  /* 0 == left,  1 == right */
    for (auto &el : by_byte) {
        unsigned byte = el.first;
        Format::Field *f = el.second.second;
        if ((f->bit >> 7) != action_slice)
            continue;
        unsigned bit = f->bit & 0x7f;
        if (bit + f->size > 128) {
            error(lineno, "Action bus setup can't deal with field split across "
                  "SRAM rows");
            continue; }
        unsigned slot = Stage::action_bus_slot_map[byte];
        switch (Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned sbyte = bit/8; sbyte <= (bit+f->size-1)/8; sbyte++, byte++, slot++) {
                unsigned code, mask;
                switch (sbyte >> 2) {
                case 0: code = sbyte>>1; mask = 1; break;
                case 1: code = 2; mask = 3; break;
                case 2: case 3: code = 3; mask = 7; break;
                default: assert(0); }
                if ((sbyte^byte) & mask) {
                    error(lineno, "Can't put field %s into byte %d on action xbar",
                          el.second.first.c_str(), byte);
                    break; }
                action_hv_xbar.action_hv_xbar_ctl_byte[side].set_subfield(code, slot*2, 2);
                action_hv_xbar.action_hv_xbar_ctl_byte_enable[side] |= 1 << slot; }
            break;
        case 16:
            slot -= ACTION_DATA_8B_SLOTS;
            for (unsigned word = bit/16; word <= (bit+f->size-1)/16; word++, byte+=2, slot++) {
                unsigned code, mask;
                switch (word >> 1) {
                case 0: code = 1; mask = 3; break;
                case 1: code = 2; mask = 3; break;
                case 2: case 3: code = 3; mask = 7; break;
                default: assert(0); }
                if (((word << 1)^byte) & mask) {
                    error(lineno, "Can't put field %s into byte %d on action xbar",
                          el.second.first.c_str(), byte);
                    break; }
                action_hv_xbar.action_hv_xbar_ctl_half[side][slot/4]
                        .set_subfield(code, (slot%4)*2, 2); }
            break;
        case 32: {
            slot -= ACTION_DATA_8B_SLOTS + ACTION_DATA_16B_SLOTS;
            unsigned word = bit/32;
            unsigned code = 1 + word/2;
            if (((word << 2)^byte) & 7)
                error(lineno, "Can't put field %s into byte %d on action xbar",
                      el.second.first.c_str(), byte);
            else
                action_hv_xbar.action_hv_xbar_ctl_word[side][slot/2]
                        .set_subfield(code, (slot%2)*2, 2);
            break; }
        default:
            assert(0); }
    }
}

void ActionTable::write_regs() {
    Layout &home = layout[0];
    unsigned home_top = home.row >= 8;
    for (unsigned slice = 0; slice <= (format->size-1)/128; slice++)
        action_bus->write_action_regs(this, home.row, slice);
    int vpn = 0;
    bool home_row = true;
    auto &icxbar = stage->regs.rams.match.adrdist.adr_dist_action_data_adr_icxbar_ctl[logical_id];
    for (Layout &logical_row : layout) {
        unsigned row = logical_row.row/2;
        unsigned side = logical_row.row&1;   /* 0 == left  1 == right */
        unsigned top = logical_row.row >= 8; /* 0 == bottom  1 == top */
        for (int logical_col : logical_row.cols) {
            unsigned col = logical_col + 6*side;
            auto &ram = stage->regs.rams.array.row[row].ram[col];
            auto &map_alu_row =  stage->regs.rams.map_alu.row[row];
            auto &oflo_adr_xbar = map_alu_row.vh_xbars.adr_dist_oflo_adr_xbar_ctl[side];
            auto &unitram_config = map_alu_row.adrmux.unitram_config[side][logical_col];
            auto &ram_mux = map_alu_row.adrmux.ram_address_mux_ctl[side][logical_col];
            for (int v : VersionIter(config_version)) {
                ram.unit_ram_ctl[v].match_ram_write_data_mux_select = 7; /*disable*/
                ram.unit_ram_ctl[v].match_ram_read_data_mux_select = home_row ? 4 : 2;
                if (!home_row) {
                    if (home_top == top) {
                        oflo_adr_xbar[v].adr_dist_oflo_adr_xbar_source_index = logical_row.row % 8;
                        oflo_adr_xbar[v].adr_dist_oflo_adr_xbar_source_sel = 0;
                    } else {
                        assert(home_top);
                        oflo_adr_xbar[v].adr_dist_oflo_adr_xbar_source_index = 0;
                        oflo_adr_xbar[v].adr_dist_oflo_adr_xbar_source_sel = 2;
                        if (!icxbar.address_distr_to_overflow)
                            icxbar.address_distr_to_overflow = 1; }
                    oflo_adr_xbar[v].adr_dist_oflo_adr_xbar_enable = 1; }
                unitram_config[v].unitram_type = 2;
                unitram_config[v].unitram_vpn = vpn;
                unitram_config[v].unitram_logical_table = logical_id;
                if (gress == INGRESS)
                    unitram_config[v].unitram_ingress = 1;
                else
                    unitram_config[v].unitram_egress = 1;
                if (home_row)
                    unitram_config[v].unitram_action_subword_out_en = 1;
                unitram_config[v].unitram_enable = 1;
                if (home_row)
                    ram_mux[v].ram_unitram_adr_mux_select = 1;
                else {
                    ram_mux[v].ram_unitram_adr_mux_select = 4;
                    ram_mux[v].ram_oflo_adr_mux_select_oflo = 1; } }
            vpn++; }
        icxbar.address_distr_to_logical_rows |= 1U << logical_row.row;
        home_row = false; }

    if (actions) actions->write_regs(this);
}

GatewayTable::Match::Match(match_t &v, value_t &data) : val(v), run_table(false) {
    if (data == "run_table")
        run_table = true;
    else if (data.type == tMAP) {
        for (auto &kv: data.map) {
            if (kv.key == "next") {
                if (CHECKTYPE(kv.value, tSTR))
                    next = kv.value;
            } else if (kv.key == "run_table") {
                if (kv.value == "true")
                    run_table = true;
                else if (kv.value == "false")
                    run_table = false;
                else
                    error(kv.value.lineno, "Syntax error, expecting boolean");
            } else
                error(kv.key.lineno, "Syntax error, expecting gateway action description"); }
    } else
        error(data.lineno, "Syntax error, expecting gateway action description");
}

void GatewayTable::setup(VECTOR(pair_t) &data) {
    int bus = -1;
    payload = 0;
    gw_unit = -1;
    setup_logical_id();
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "row") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 7)
                error(kv.value.lineno, "row %d out of range", kv.value.i);
            layout.push_back(Layout{kv.value.lineno, kv.value.i, bus});
        } else if (kv.key == "bus") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "bus %d out of range", kv.value.i);
            bus = kv.value.i;
            if (!layout.empty()) layout[0].bus = bus;
        } else if (kv.key == "gateway_unit") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if (kv.value.i < 0 || kv.value.i > 1)
                error(kv.value.lineno, "gateway unit %d out of range", kv.value.i);
            gw_unit = kv.value.i;
        } else if (kv.key == "input_xbar") {
	    if (CHECKTYPE(kv.value, tMAP))
		input_xbar = new InputXbar(this, false, kv.value.map);
        } else if (kv.key == "miss") {
            match_t v = { 0, 0 };
            miss = Match(v, kv.value);
        } else if (kv.key == "payload") {
        } else if (kv.key == "match") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    match.emplace_back(gress, v);
            else
                match.emplace_back(gress, kv.value);
        } else if (kv.key == "xor") {
            if (kv.value.type == tVEC)
                for (auto &v : kv.value.vec)
                    xor_match.emplace_back(gress, v);
            else
                xor_match.emplace_back(gress, kv.value);
        } else if (kv.key.type == tINT) {
            match_t v = { ~(unsigned long)kv.key.i, (unsigned long)kv.key.i };
            table.emplace_back(v, kv.value);
        } else if (kv.key.type == tMATCH) {
            table.emplace_back(kv.key.m, kv.value);
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
}

unsigned width(const Phv::Ref &r) { return r->hi - r->lo + 1; }
unsigned width(const std::vector<Phv::Ref> &vec) {
    unsigned rv = 0;
    for (auto &f : vec)
        rv += width(f);
    return rv;
}

void GatewayTable::pass1() {
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    if (gw_unit < 0) gw_unit = layout[0].bus;
    if (input_xbar) input_xbar->pass1(stage->exact_ixbar, 128);
    for (auto &r : match) r.check();
    for (auto &r : xor_match) r.check();
    if (error_count > 0) return;
    if (width(xor_match) > 32)
        error(lineno, "Gateway can only xor 32 bits max");
    if (table.size() > 4)
        error(lineno, "Gateway can only have 4 match entries max");
    for (auto &line : table)
        if (line.next != "END")
            line.next.check();
    if (miss.next != "END")
        miss.next.check();
    for (auto &line : table) {
        unsigned long ignore = ~(line.val.word0 | line.val.word1);
        line.val.word0 |= ignore;
        line.val.word1 |= ignore; }
}
void GatewayTable::pass2() {
    if (input_xbar) input_xbar->pass2(stage->exact_ixbar, 128);
}
void GatewayTable::write_regs() {
    if (input_xbar) input_xbar->write_regs();
    auto &row = layout[0];
    auto &gw_reg = stage->regs.rams.array.row[row.row].gateway_table[gw_unit];
    auto &merge = stage->regs.rams.match.merge;
    if (row.bus == 0) {
        gw_reg.gateway_table_ctl.gateway_table_input_data0_select = 1;
        gw_reg.gateway_table_ctl.gateway_table_input_hash0_select = 1;
    } else {
        assert(row.bus == 1);
        gw_reg.gateway_table_ctl.gateway_table_input_data1_select = 1;
        gw_reg.gateway_table_ctl.gateway_table_input_hash1_select = 1; }
    gw_reg.gateway_table_ctl.gateway_table_logical_table = logical_id;
    gw_reg.gateway_table_ctl.gateway_table_thread = gress;
    gw_reg.gateway_table_matchdata_xor_en = ~(~0U << width(xor_match));
    unsigned lineno = 0;
    for (auto &line : table) {
        /* FIXME -- hardcoding version/valid to always */
        gw_reg.gateway_table_vv_entry[lineno].gateway_table_entry_versionvalid0 = 0x3;
        gw_reg.gateway_table_vv_entry[lineno].gateway_table_entry_versionvalid1 = 0x3;
        gw_reg.gateway_table_entry_matchdata[lineno][0] = line.val.word0 & 0xffffffff;
        gw_reg.gateway_table_entry_matchdata[lineno][1] = line.val.word1 & 0xffffffff;
        gw_reg.gateway_table_data_entry[lineno][0] = (line.val.word0 >> 32) & 0xffffff;
        gw_reg.gateway_table_data_entry[lineno][1] = (line.val.word1 >> 32) & 0xffffff;
        if (!line.run_table) {
            merge.gateway_next_table_lut[logical_id][lineno] =
                line.next ? line.next->table_id() : 0xff;
            merge.gateway_inhibit_lut[logical_id] |= 1 << lineno; }
        lineno++; }
    if (!miss.run_table) {
        merge.gateway_next_table_lut[logical_id][4] = miss.next ? miss.next->table_id() : 0xff;
        merge.gateway_inhibit_lut[logical_id] |= 1 << 4; }
    //bool ternary_match = false;
    if (auto *tm = dynamic_cast<TernaryMatchTable *>(match_table)) {
        //ternary_match = true;
        merge.gateway_inhibit_logical_to_tcam_xbar_ctl[tm->tcam_id]
            .enabled_4bit_muxctl_select = logical_id;
        merge.gateway_inhibit_logical_to_tcam_xbar_ctl[tm->tcam_id]
            .enabled_4bit_muxctl_enable = 1; }
    for (int v : VersionIter(config_version))
        merge.gateway_en[v] |= 1 << logical_id;
    merge.gateway_to_logicaltable_xbar_ctl[logical_id].enabled_4bit_muxctl_select =
        row.row*2 + gw_unit;
    merge.gateway_to_logicaltable_xbar_ctl[logical_id].enabled_4bit_muxctl_enable = 1;
    if (match_table) {
        for (auto &row : match_table->layout) {
            merge.gateway_to_pbus_xbar_ctl[row.row*2 + row.bus]
                .enabled_4bit_muxctl_select = logical_id;
            merge.gateway_to_pbus_xbar_ctl[row.row*2 + row.bus]
                .enabled_4bit_muxctl_enable = 1;
#if 0
            merge.gateway_payload_pbus[row.row][row.bus] |= 1 << (row.bus + ternary_match ? 2 : 0);
            merge.gateway_payload_data[row.row][row.bus][0] = ???;
            merge.gateway_payload_data[row.row][row.bus][1] = ???;
            merge.gateway_payload_match_adr[row.row][row.bus] = ???;
#endif
        }
    }
}
