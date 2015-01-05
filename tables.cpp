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
                CHECKTYPE(val[i], tSTR);
                action_args.push_back(val[1].s); }
        }
        action.lineno = val.lineno; }
}

static int add_row(int lineno, Table *t, int row) {
    if (contains_if(t->layout, [row](Table::Layout &p)->bool { return p.row == row; })) {
        error(lineno, "row %d duplicated in table %s", row, t->name());
        return 1; }
    t->layout.push_back(Table::Layout{row, -1});
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
		     Alloc1Dbase<Table *> &use)
{
    if (id >= 0) {
        next_id = id;
        return; }
    while (++next_id < max_id && use[next_id]);
    if (next_id >= max_id) {
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
        auto it = fmt[idx].emplace(name.s, Field{ nextbit, 0, idx }).first;
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
            error(data[0].key.lineno, "Format group %d doesn't match group 0", i);
    /* FIXME -- need to figure out which fields are immediates, and set immed_size */
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
                ins.first = i.i;
                continue; }
            if (!CHECKTYPE(i, tCMD)) continue;
            if (auto *p = Instruction::decode(tbl, i.vec))
                ins.second.push_back(p);
        }
    }
}

Table::ActionBus::ActionBus(Table *tbl, VECTOR(pair_t) &data) {
    for (auto &kv : data) {
	if (!CHECKTYPE2(kv.key, tINT, tRANGE)) continue;
	if (!CHECKTYPE(kv.value, tSTR)) continue;
	Format::Field *f = tbl->format->field(kv.value.s);
	if (!f) {
	    error(kv.value.lineno, "No field %s in format", kv.value.s);
	    continue; }
	int idx = kv.key.i;
	if (kv.key.type == tRANGE) {
	    idx = kv.key.lo;
	    unsigned size = (kv.key.hi-idx+1) * 8;
	    if (size != f->size) {
		error(kv.key.lineno, "Byte range doesn't match size %d of %s",
		      f->size, kv.key.s);
		continue; } }
	bus[kv.value.s].first.push_back(idx);
	bus[kv.value.s].second = f; }
}

class MatchTable : public Table {
protected:
    MatchTable(int l, std::string &&n, gress_t g, Stage *s, int lid)
        : Table(l, std::move(n), g, s, lid) {}
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

static int get_address_mau_actiondata_adr_default(unsigned width) {
    int huffman_size = 0;
    width >>= 3; /* min size 8 bits */
    while (width) {
        huffman_size++;
        width >>= 1; }
    assert(huffman_size < 8);
    int rv = (1 << huffman_size) - 1;
    rv = ((rv << 10) & 0xf8000) | ( rv & 0x1f);
    return rv;
}

void MatchTable::write_regs(int type, Table *result) {
    /* this follows the order an behavior in stage_match_entry_table.py
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
        auto iaddr = result->format->field("iaddr");
        if (iaddr)
            merge.mau_action_instruction_adr_mask[type][bus] = (1U << iaddr->size) - 1;
        else
            warning(result->format->lineno, "No iaddr in format");
        if (result->action) {
            merge.mau_actiondata_adr_default[type][bus] =
                get_address_mau_actiondata_adr_default(result->action->format->size);
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
            if (Format::Field *iaddr = result->format->field(result->action_args[0])) {
                if ((1U << iaddr->size) <= ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH) {
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
            } else
                error(action.lineno, "No %s in table format", result->action_args[0].c_str());
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
        } else if (kv.key == "vpn") {
            if (CHECKTYPE(kv.value, tINT))
		if ((vpn = kv.value.i) < 0 || vpn >= MAX_VPN)
		    error(kv.key.lineno, "Invalid vpn %d", vpn);
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
    if (action && actions)
	error(lineno, "Table %s has both action table and immedaite actions", name());
}
void ExactMatchTable::pass1() {
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, stage->logical_id_use);
    alloc_busses(stage->sram_match_bus_use);
    check_next();
    input_xbar->pass1(stage->exact_ixbar, 128);
}
void ExactMatchTable::pass2() {
    input_xbar->pass2(stage->exact_ixbar, 128);
}
void ExactMatchTable::write_regs() {
    MatchTable::write_regs(0, this);
}

DEFINE_TABLE_TYPE(TernaryMatchTable, MatchTable, "ternary_match",
    int tcam_id;
    Table::Ref indirect;
)
void TernaryMatchTable::setup(VECTOR(pair_t) &data) {
    tcam_id = -1;
    setup_layout(get(data, "row"), get(data, "column"), get(data, "bus"));
    setup_logical_id();
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "input_xbar") {
	    if (CHECKTYPE(kv.value, tMAP))
		input_xbar = new InputXbar(this, true, kv.value.map);
        } else if (kv.key == "gateway") {
        } else if (kv.key == "vpn") {
            if (CHECKTYPE(kv.value, tINT))
		if ((vpn = kv.value.i) < 0 || vpn >= MAX_VPN)
		    error(kv.key.lineno, "Invalid vpn %d", vpn);
        } else if (kv.key == "indirect") {
            if (CHECKTYPE(kv.value, tSTR))
                indirect = kv.value;
        } else if (kv.key == "tcam_id") {
            if (CHECKTYPE(kv.value, tINT))
		if ((tcam_id = kv.value.i) < 0 || tcam_id >= TCAM_TABLES_PER_STAGE)
		    error(kv.key.lineno, "Invalid tcam_id %d", tcam_id);
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
    alloc_id("logical", logical_id, stage->pass1_logical_id,
	     LOGICAL_TABLES_PER_STAGE, stage->logical_id_use);
    alloc_id("tcam", tcam_id, stage->pass1_tcam_id,
	     TCAM_TABLES_PER_STAGE, stage->tcam_id_use);
    alloc_busses(stage->tcam_match_bus_use);
    check_next();
    indirect.check();
    if (hit_next.size() > 2)
        error(hit_next[0].lineno, "Ternary Match tables cannot directly specify more"
              "than 2 hit next tables");
    if (indirect && hit_next.size() > 0 && indirect->hit_next.size() > 0)
        error(hit_next[0].lineno, "Ternary Match table with both direct and indirect next tables");
    input_xbar->pass1(stage->tcam_ixbar, 44);
}
void TernaryMatchTable::pass2() {
    input_xbar->pass2(stage->tcam_ixbar, 44);
}
void TernaryMatchTable::write_regs() {
    MatchTable::write_regs(1, indirect);
    int idx = 0;
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
	    tcam_mode.tcam_vpn = vpn + idx++;
	    tcam_mode.tcam_logical_table = tcam_id;
	    /* TODO -- always disable tcam_validbit_xbar */
	    auto tcam_vh_xbar = stage->regs.tcams.vh_data_xbar;
	    for (int i = 0; i < 8; i++)
		tcam_vh_xbar.tcam_validbit_xbar_ctl[row.bus][row.row/2][i] = 15;
	    /* TODO -- don't support wide tcam matches yet. */
	    if (input_xbar->width() != 1)
		error(input_xbar->lineno, "FIXME -- no support for wide TCAM matches");
	    tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row]
		.tcam_row_halfbyte_mux_ctl_select = 3;
	    tcam_vh_xbar.tcam_row_halfbyte_mux_ctl[row.bus][row.row]
		.tcam_row_halfbyte_mux_ctl_enable = 1;
	    tcam_vh_xbar.tcam_row_output_ctl[row.bus][row.row]
		.enabled_4bit_muxctl_select = *input_xbar->begin();
	    tcam_vh_xbar.tcam_row_output_ctl[row.bus][row.row]
		.enabled_4bit_muxctl_enable = 1;
	}
    }
}

DEFINE_TABLE_TYPE(TernaryIndirectTable, Table, "ternary_indirect", )
void TernaryIndirectTable::setup(VECTOR(pair_t) &data) {
    setup_layout(get(data, "row"), get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
	if (CHECKTYPE(*fmt, tMAP))
	    format = new Format(fmt->map);
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
    if (action && actions)
	error(lineno, "Table %s has both action table and immedaite actions", name());
}
void TernaryIndirectTable::pass1() {
    alloc_busses(stage->tcam_indirect_bus_use);
    check_next();
}
void TernaryIndirectTable::pass2() {
}
void TernaryIndirectTable::write_regs() {
}

DEFINE_TABLE_TYPE(ActionTable, Table, "action",)


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
}
void ActionTable::pass2() {
}
void ActionTable::write_regs() {
}

DEFINE_TABLE_TYPE(GatewayTable, Table, "gateway", )
void GatewayTable::setup(VECTOR(pair_t) &data) {
    int bus = -1;
    for (auto &kv : MapIterChecked(data)) {
        if (kv.key == "row") {
            if (!CHECKTYPE(kv.value, tINT)) continue;
            layout.push_back(Layout{kv.value.i, bus});
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
