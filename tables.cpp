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
                    !(arg = format->field(val[i].s)))
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
            if ((err |= add_cols(row, *col)))
                break;
    }
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
                row.bus = bus->i;
    }
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

Table::Format::Format(VECTOR(pair_t) &data) : lineno(data[0].key.lineno), size(0), immed_size(0) {
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
        auto it = fmt[idx].emplace(name.s, Field{ nextbit, 0, idx, -1 }).first;
        if (kv.value.type == tINT) {
            it->second.size  = kv.value.i;
        } else {
            it->second.bit = kv.value.lo;
            it->second.size = kv.value.hi - kv.value.lo + 1; }
        nextbit = it->second.bit + it->second.size;
        if (byindex.empty())
            byindex[it->second.bit] = it;
        else {
            auto p = byindex.upper_bound(it->second.bit);
            if (p != byindex.end())
                overlap_test(kv.value.lineno, it, p->second);
            p--;
            overlap_test(kv.value.lineno, p->second, it);
            if (nextbit > p->second->second.bit + p->second->second.size)
                byindex[it->second.bit] = it; }
        if (nextbit > size) size = nextbit; }
    for (size_t i = 1; i < fmt.size(); i++)
        if (fmt[0] != fmt[i])
            error(data[0].key.lineno, "Format group %zu doesn't match group 0", i);
    /* FIXME -- need to figure out which fields are immediates, and set immed_size */
    for (log2size = 0; (1U << log2size) < size; log2size++);
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
            if (auto *p = Instruction::decode(tbl, i.vec))
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
            inst->encode(tbl);
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
            assert(inst->slot >= 0);
            switch (inst->slot/32) {
            case 0: case 1: /* 32 bit */
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_instr = inst->bits;
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_color = color;
                imem.imem_subword32[inst->slot][iaddr].imem_subword32_parity =
                    parity(inst->bits) ^ color;
                break;
            case 2: case 3: /* 8 bit */
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_instr = inst->bits;
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_color = color;
                imem.imem_subword8[inst->slot-64][iaddr].imem_subword8_parity =
                    parity(inst->bits) ^ color;
                break;
            case 4: case 5: case 6: /* 16 bit */
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_instr = inst->bits;
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_color = color;
                imem.imem_subword16[inst->slot-128][iaddr].imem_subword16_parity =
                    parity(inst->bits) ^ color;
                break;
            default:
                assert(0); } } }
}

Table::ActionBus::ActionBus(Table *tbl, VECTOR(pair_t) &data) {
    lineno = data[0].key.lineno;
    for (auto &kv : data) {
	if (!CHECKTYPE2(kv.key, tINT, tRANGE)) continue;
	if (!CHECKTYPE(kv.value, tSTR)) continue;
	Format::Field *f = tbl->format->field(kv.value.s);
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
        if (idx >= 160) {
            error(kv.key.lineno, "Action bus index out of range");
            continue; }
        f->action_xbar = idx;
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
        Table *create(int lineno, const char *name, gress_t gress,      \
                      Stage *stage, int lid, VECTOR(pair_t) &data);     \
    } table_type;                                                       \
    friend struct Type;                                                 \
    TYPE(int l, const char *n, gress_t g, Stage *s, int lid)            \
        : PARENT(l, n, g, s, lid) {}                                    \
    void setup(VECTOR(pair_t) &data);                                   \
    void pass1();                                                       \
    void pass2();                                                       \
    void write_regs();                                                  \
    __VA_ARGS__                                                         \
};                                                                      \
TYPE::Type TYPE::table_type;                                            \
Table *TYPE::Type::create(int lineno, const char *name, gress_t gress,  \
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
            merge.mau_actiondata_adr_default[type][bus] =
                get_address_mau_actiondata_adr_default(result->action->format->log2size);
        } else {
            /* FIXME */
            assert(0);
        }
    }
    /*------------------------
     * Action instruction Address
     *-----------------------*/
    if (result->action) {
        if (result->action_args.size() != 1) {
            error(action.lineno, "Expecting single instruction address argument to "
                  "action table");
        } else {
            assert(result->action_args[0]);
            if ((1U << result->action_args[0]->size) <= ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH) {
                merge.mau_action_instruction_adr_map_en[type] |= (1U << logical_id);
                int idx = 0;
                int shift = 0;
                for (auto act : *result->action->actions) {
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
        }
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
	merge.mau_immediate_data_mask[type][bus] = (1U << result->format->immed_size)-1; }

    input_xbar->write_regs();
}

DEFINE_TABLE_TYPE(ExactMatchTable, MatchTable, "exact_match", )
DEFINE_TABLE_TYPE(TernaryMatchTable, MatchTable, "ternary_match",
public:
    int tcam_id;
    Table::Ref indirect;
)
DEFINE_TABLE_TYPE(TernaryIndirectTable, Table, "ternary_indirect",)
DEFINE_TABLE_TYPE(ActionTable, Table, "action",)
DEFINE_TABLE_TYPE(GatewayTable, Table, "gateway", )

void MatchTable::link_action(Table::Ref &ref) {
    if (ref) {
        if (!dynamic_cast<ActionTable *>((Table *)ref))
            error(ref.lineno, "%s is not an action table", ref->name());
        if (ref->match)
            error(ref->lineno, "Multiple references to action table %s",
                  ref->name());
        ref->match = this;
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
        } else if (kv.key == "format") {
	    /* done above so it's always before 'actions' */
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
    alloc_rams(false, stage->sram_use, &stage->sram_match_bus_use);
    if (action.set() && actions)
	error(lineno, "Table %s has both action table and immediate actions", name());
    if (!action.set() && !actions)
	error(lineno, "Table %s has neither action table nor immediate actions", name());
    if (action.set() && (action_args.size() < 1 || action_args.size() > 2))
        error(lineno, "Unexpected number of action table arguments %zu", action_args.size());
}
void ExactMatchTable::pass1() {
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, true, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    check_next();
    link_action(action);
    if (actions) {
        assert(action_args.size() == 0);
        if (auto *sel = format->field("action"))
            action_args.push_back(sel);
        else
            error(lineno, "No field 'action' in table %s format", name());
        actions->pass1(this); }
    input_xbar->pass1(stage->exact_ixbar, 128);
}
void ExactMatchTable::pass2() {
    input_xbar->pass2(stage->exact_ixbar, 128);
    if (actions) actions->pass2(this);
}
void ExactMatchTable::write_regs() {
    MatchTable::write_regs(0, this);
    if (actions) actions->write_regs(this);
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
        if (indirect->match)
            error(indirect->lineno, "Multiple references to ternary indirect table %s",
                  indirect->name());
        indirect->match = this;
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
}
void TernaryMatchTable::pass2() {
    input_xbar->pass2(stage->tcam_ixbar, 44);
}
void TernaryMatchTable::write_regs() {
    MatchTable::write_regs(1, indirect);
    int vpn = 0;
    auto &merge = stage->regs.rams.match.merge;
    for (Layout &row : layout) {
	for (int col : row.cols) {
	    auto &tcam_mode = stage->regs.tcams.col[col].tcam_mode[row.row];
	    /* TODO -- always setting dirtcam mode to 0 */
	    tcam_mode.tcam_data_dirtcam_mode = 0;
	    tcam_mode.tcam_data1_select = row.bus;
	    tcam_mode.tcam_chain_out_enable = 0 /*???*/;
	    if (gress == INGRESS)
		tcam_mode.tcam_ingress = 1;
	    else
		tcam_mode.tcam_egress = 1;
	    tcam_mode.tcam_match_output_enable = 1;
	    tcam_mode.tcam_vpn = vpn++;
	    tcam_mode.tcam_logical_table = tcam_id;
	    /* TODO -- always disable tcam_validbit_xbar */
	    auto &tcam_vh_xbar = stage->regs.tcams.vh_data_xbar;
            int off = (row.row&1) * 4;
	    for (int i = 0; i < 4; i++)
		tcam_vh_xbar.tcam_validbit_xbar_ctl[row.bus][row.row/2][i+off] = 15;
	    /* TODO -- don't support wide tcam matches yet. */
	    if (input_xbar->width() != 1)
		error(input_xbar->lineno, "FIXME -- no support for wide TCAM matches");
	    tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row]
		.tcam_row_halfbyte_mux_ctl_select = 3;
	    tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row]
		.tcam_row_halfbyte_mux_ctl_enable = 1;
	    tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row]
                .tcam_row_search_thread = gress;
            /* FIXME:
            tcam_vh_xbar.tcam_extra_byte_ctl[row.bus][row.row/2]
                .enabled_3bit_muxctl_select = byte_match_group_number;
            tcam_vh_xbar.tcam_extra_byte_ctl[row.bus][row.row/2]
                .enabled_3bit_muxctl_enable = 1; */
	    tcam_vh_xbar.tcam_row_output_ctl[row.bus][row.row]
		.enabled_4bit_muxctl_select = *input_xbar->begin();
	    tcam_vh_xbar.tcam_row_output_ctl[row.bus][row.row]
		.enabled_4bit_muxctl_enable = 1;
            stage->regs.tcams.col[col].tcam_table_map[tcam_id] |= 1U << row.row;
	}
    }
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
}

void TernaryIndirectTable::setup(VECTOR(pair_t) &data) {
    match = 0;
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
	    /* done above so it's always before 'actions' */
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
}
void TernaryIndirectTable::pass1() {
    alloc_busses(stage->tcam_indirect_bus_use);
    check_next();
    if (actions) {
        assert(action_args.size() == 0);
        if (auto *sel = format->field("action"))
            action_args.push_back(sel);
        else
            error(lineno, "No field 'action' in table %s format", name());
        actions->pass1(this); }
}
void TernaryIndirectTable::pass2() {
    if (!match)
        error(lineno, "No match table for ternary indirect table %s", name());
    if (actions) actions->pass2(this);
}
void TernaryIndirectTable::write_regs() {
    int tcam_id = dynamic_cast<TernaryMatchTable *>(match)->tcam_id;
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
            error(lineno, "TODO -- ternary indirect with no action data table");
        }
    }
    if (actions) actions->write_regs(this);
}


void ActionTable::setup(VECTOR(pair_t) &data) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(row, get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
	if (CHECKTYPE(*fmt, tMAP))
	    format = new Format(fmt->map);
    } else
        error(lineno, "No format specified in table %s", name());
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "format") {
	    /* done above so it's always before 'actions' and 'action_bus' */
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
                    kv.key.s, name()); }
    alloc_rams(true, stage->sram_use, 0);
}
void ActionTable::pass1() {
    for (Layout &row : layout) {
        if (row.row > layout[0].row)
            error(row.lineno, "Action table %s home row must be first", name());
    }
    if (actions) actions->pass1(this);
}
void ActionTable::pass2() {
    if (!match)
        error(lineno, "No match table for action table %s", name());
    if (actions) actions->pass2(this);
}
void Table::ActionBus::write_action_regs(Table *tbl, unsigned home_row, unsigned action_slice) {
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
        if (byte < 16) {
            for (unsigned sbyte = bit/8; sbyte <= (bit+f->size-1)/8; sbyte++, byte++) {
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
                action_hv_xbar.action_hv_xbar_ctl_byte[side].set_subfield(code, byte*2, 2);
                action_hv_xbar.action_hv_xbar_ctl_byte_enable[side] |= 1 << byte; }
        } else if (byte < 72) {
            for (unsigned word = bit/16; word <= (bit+f->size-1)/16; word++, byte+=2) {
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
                action_hv_xbar.action_hv_xbar_ctl_half[side][(byte-16)/8]
                        .set_subfield(code, byte%8, 2); }
        } else if (byte < 160) {
            unsigned word = bit/32;
            unsigned code = 1 + word/2;
            if (((word << 2)^byte) & 7)
                error(lineno, "Can't put field %s into byte %d on action xbar",
                      el.second.first.c_str(), byte);
            else
                action_hv_xbar.action_hv_xbar_ctl_word[side][(byte-72)/8]
                        .set_subfield(code, (byte%8)/2, 2);
        } else assert(0);
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

void GatewayTable::setup(VECTOR(pair_t) &data) {
    int bus = -1;
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "row") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            layout.push_back(Layout{kv.value.lineno, kv.value.i, bus});
        } else if (kv.key == "bus") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            bus = kv.value.i;
            if (!layout.empty()) layout[0].bus = bus;
        } else if (kv.key == "input_xbar") {
        } else if (kv.key == "match") {
        } else if (kv.key == "miss") {
        } else if (kv.key == "payload") {
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    kv.key.s, name()); }
}
void GatewayTable::pass1() {
}
void GatewayTable::pass2() {
}
void GatewayTable::write_regs() {
}
