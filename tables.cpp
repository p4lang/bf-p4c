#include "action_bus.h"
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
                if (arg) {
                    if (arg->bits.size() != 1)
                        error(val[i].lineno, "Action arg fields can't be split in format");
                    action_args.push_back(arg); } } }
        action.lineno = val.lineno; }
}

static void add_row(int lineno, Table *t, int row) {
    t->layout.push_back(Table::Layout{lineno, row, -1});
}

static int add_rows(Table *t, value_t &rows) {
    if (!CHECKTYPE2(rows, tINT, tRANGE)) return 1;
    if (rows.type == tINT)
        add_row(rows.lineno, t, rows.i);
    else {
        int step = rows.lo > rows.hi ? -1 : 1;
        for (int i = rows.lo; i != rows.hi; i += step)
            add_row(rows.lineno, t, i);
        add_row(rows.lineno, t, rows.hi); }
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
                error(i->lineno, "row %d%s duplicated in table %s", i->row, bus, name()); }
}

void Table::setup_logical_id() {
    if (logical_id >= 0) {
        if (Table *old = stage->logical_id_use[logical_id]) {
            error(lineno, "table %s wants logical id %d:%d", name(),
                  stage->stageno, logical_id);
            error(old->lineno, "already in use by %s", old->name()); }
        stage->logical_id_use[logical_id] = this; }
}

void Table::setup_vpns(VECTOR(value_t) *vpn) {
    int period, width;
    const char *period_name;
    vpn_params(width, period, period_name);
    if (vpn && (unsigned)vpn->size != layout_size()/width) {
        error(lineno, "Vpn list length doesn't match layout (is %d, should be %d)",
              vpn->size, layout_size()/width);
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
                vpn_ctr += period; } } }
    if (vpn && error_count == 0) {
        for (int i = 0; i < vpn->size; i++)
            if (!used_vpns[i]) {
                error((*vpn)[0].lineno, "Hole in vpn list (%d) for table %s", i*period, name());
                break; } }
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

void Table::alloc_vpns() {
    if (layout.size() == 0 || layout[0].vpns.size() > 0) return;
    setup_vpns(0);
}

void Table::check_next() {
    for (auto &n : hit_next)
        if (n != "END") n.check();
    if (miss_next != "END")
        miss_next.check();
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

Table::Format::Format(VECTOR(pair_t) &data, bool may_overlap) :
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
            f->bits.emplace_back(nextbit, nextbit+f->size-1);
        } else if (kv.value.type == tRANGE) {
            if (kv.value.lo > kv.value.hi)
                error(kv.value.lineno, "invalid range %d..%d", kv.value.lo, kv.value.hi);
            f->bits.emplace_back(kv.value.lo, kv.value.hi);
            f->size = kv.value.hi - kv.value.lo + 1;
        } else if (kv.value.type == tVEC) {
            f->size = 0;
            for (auto &c : kv.value.vec)
                if (CHECKTYPE(c, tRANGE) && VALIDATE_RANGE(c)) {
                    f->bits.emplace_back(c.lo, c.hi);
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

Table::Actions::Actions(Table *tbl, VECTOR(pair_t) &data) : lineno(data.size > 0 ? data[0].key.lineno : -1) {
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
    merge.predication_ctl[gress].table_thread |= 1 << logical_id;
    if (result) {
        for (auto &row : result->layout) {
            int bus = row.row*2 | row.bus;
            merge.match_to_logical_table_ixbar_outputmap[type][bus].enabled_4bit_muxctl_select =
                logical_id;
            merge.match_to_logical_table_ixbar_outputmap[type][bus].enabled_4bit_muxctl_enable = 1;
            if (result->action_args.size() >= 1) {
                assert(result->action_args[0]);
                merge.mau_action_instruction_adr_mask[type][bus] =
                    (1U << result->action_args[0]->size) - 1;
            } else
                merge.mau_action_instruction_adr_mask[type][bus] = 0;
            if (result->action) {
                /* FIXME -- deal with variable-sized actions */
                merge.mau_actiondata_adr_default[type][bus] =
                    get_address_mau_actiondata_adr_default(result->action->format->log2size);
            }
        }
    } else result = this;

    /*------------------------
     * Action instruction Address
     *-----------------------*/
    Actions *actions = result->actions;
    if (result->action) {
        assert(!actions);
        actions = result->action->actions; }
    assert(actions);

    //assert(result->action_args[0]);
    if (result->action_args.empty() ||
        (1U << result->action_args[0]->size) <= ACTION_INSTRUCTION_SUCCESSOR_TABLE_DEPTH) {
        merge.mau_action_instruction_adr_map_en[type] |= (1U << logical_id);
        int idx = 0;
        int shift = gateway ? 6 : 0; // skip slot 0 if there's a gateway (reserved for NOP)
        for (auto act : *actions) {
            assert(idx < 2);
            merge.mau_action_instruction_adr_map_data[type][logical_id][idx]
                |= act->second.first << shift;
            if ((shift += 6) >= 24) { shift = 0; idx++; } } }

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
    if (next->hit_next.size() > 0) {
        assert(((next->hit_next.size()-1) & next->hit_next.size()) == 0);
        merge.next_table_format_data[logical_id].match_next_table_adr_mask = next->hit_next.size()-1; }

    /*------------------------
     * Immediate data found in overhead
     *-----------------------*/
    if (result->format) {
        for (auto &row : result->layout) {
            int bus = row.row*2 | row.bus;
            merge.mau_immediate_data_mask[type][bus] = (1UL << result->format->immed_size)-1; }
        if (result->action_bus)
            result->action_bus->write_immed_regs(result); }

    input_xbar->write_regs();
}

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

int Table::find_on_actionbus(Format::Field *f, int off) {
    return action_bus ? action_bus->find(f, off) : -1;
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

