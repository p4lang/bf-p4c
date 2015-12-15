#include "hashexpr.h"
#include "input_xbar.h"
#include "log.h"
#include "stage.h"
#include "range.h"
#include <stdlib.h>

void InputXbar::setup_hash(std::map<int, HashCol> &hash_table, int id,
                           gress_t gress, value_t &what, int lineno, int lo, int hi)
{
    if (lo < 0 || lo >= 52 || hi < 0 || hi >= 52) {
        error(lineno, "Hash column out of range");
        return; }
    if (lo == hi) {
        if (what.type == tINT) {
            hash_table[lo].data.setraw(what.i);
            return;
        } else if (what.type == tBIGINT) {
            hash_table[lo].data.setraw(what.bigi.data, what.bigi.size);
            if (hash_table[lo].data.max().index() >= 64)
                error(what.lineno, "Hash column value out of range");
            return; } }
    HashExpr *fn = HashExpr::create(gress, what);
    if (!fn) return;
    int width = fn->width();
    if (width && width != abs(hi - lo) + 1)
        error(what.lineno, "hash expression width mismatch (%d != %d)", width, abs(hi-lo)+1);
    int bit = 0;
    for (int col : Range(lo, hi))
        if (hash_table[col].data || hash_table[col].fn)
            error(lineno, "Hash table %d column %d duplicated", id, col);
        else {
            hash_table[col].lineno = what.lineno;
            hash_table[col].fn = fn;
            hash_table[col].bit = bit++; }
}

InputXbar::InputXbar(Table *t, bool tern, VECTOR(pair_t) &data)
: table(t), ternary(tern), lineno(data[0].key.lineno)
{
    int numgroups = ternary ? TCAM_XBAR_GROUPS : EXACT_XBAR_GROUPS;
    for (auto &kv : data) {
	if (!CHECKTYPEM(kv.key, tCMD, "group or hash descriptor"))
	    continue;
	if (kv.key[0] == "group") {
	    if (kv.key.vec.size != 2 || kv.key[1].type != tINT || kv.key[1].i >= numgroups) {
		error(kv.key.lineno, "invalid group descriptor");
		continue; }
            if (groups.count(kv.key[1].i)) {
                error(kv.key[1].lineno, "group %d duplicated", kv.key[1].i);
                continue; }
            auto &group = groups[kv.key[1].i];
            group_order.push_back(groups.find(kv.key[1].i));
            if (kv.value.type == tVEC) {
                for (auto &reg : kv.value.vec)
                    group.emplace_back(Phv::Ref(t->gress, reg));
            } else if (kv.value.type == tMAP) {
                for (auto &reg : kv.value.map) {
                    if (!CHECKTYPE2(reg.key, tINT, tRANGE)) continue;
                    if (reg.key.type == tINT)
                        group.emplace_back(Phv::Ref(t->gress, reg.value), reg.key.i);
                    else
                        group.emplace_back(Phv::Ref(t->gress, reg.value),
                                           reg.key.lo, reg.key.hi); }
            } else
                group.emplace_back(Phv::Ref(t->gress, kv.value));
	} else if (!ternary && kv.key[0] == "hash") {
            if (kv.key.vec.size == 3 && kv.key[1] == "group") {
                if (kv.key[2].type != tINT || kv.key[2].i >= EXACT_HASH_GROUPS) {
                    error(kv.key.lineno, "invalid hash group descriptor");
                    continue; }
                int id = kv.key[2].i;
                hash_groups[id].lineno = kv.key.lineno;
                if (kv.value.type == tINT && (unsigned)kv.value.i < HASH_TABLES) {
                    hash_groups[id].tables |= 1U << kv.value.i;
                    continue; }
                if (!CHECKTYPE2(kv.value, tVEC, tMAP)) continue;
                VECTOR(value_t) *tbl = 0;
                if (kv.value.type == tMAP) {
                    for (auto &el : MapIterChecked(kv.value.map)) {
                        if (el.key == "seed") {
                            if (!CHECKTYPE2(el.value, tINT, tBIGINT)) continue;
                            if (el.value.type == tBIGINT) {
                                hash_groups[id].seed = el.value.bigi.data[0];
                            } else
                                hash_groups[id].seed = el.value.i;
                        } else if (el.key == "table") {
                            if (el.value.type == tINT) {
                                if (el.value.i < 0 || el.value.i >= HASH_TABLES)
                                    error(el.value.lineno, "invalid hash group descriptor");
                                else
                                    hash_groups[id].tables |= 1U << el.value.i;
                            } else if (CHECKTYPE(el.value, tVEC))
                                tbl = &el.value.vec;
                        } else
                            error(el.key.lineno, "invalid hash group descriptor"); }
                } else
                    tbl = &kv.value.vec;
                if (tbl) {
                    for (auto &v : *tbl) {
                        if (!CHECKTYPE(v, tINT)) continue;
                        if (v.i < 0 || v.i >= HASH_TABLES)
                            error(v.lineno, "invalid hash group descriptor");
                        else
                            hash_groups[id].tables |= 1U << v.i; } }
                continue; }
            if (kv.key.vec.size == 3 && kv.key[1] == "table") {
                free_value(&kv.key[1]);
                kv.key[1] = kv.key[2];
                kv.key.vec.size = 2; }
	    if (kv.key.vec.size != 2 || kv.key[1].type != tINT || kv.key[1].i >= HASH_TABLES) {
		error(kv.key.lineno, "invalid hash descriptor");
		continue; }
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            int id = kv.key[1].i;
            for (auto &c : kv.value.map) {
                if (c.key.type == tINT) {
                    setup_hash(hash_tables[id], id, t->gress, c.value,
                               c.key.lineno, c.key.i, c.key.i);
                } else if (c.key.type == tRANGE) {
                    setup_hash(hash_tables[id], id, t->gress, c.value,
                               c.key.lineno, c.key.lo, c.key.hi);
                } else if (CHECKTYPEM(c.key, tCMD, "hash column decriptor")) {
                    if (c.key.vec.size != 2 || c.key[0] != "valid" || c.key[1].type != tINT) {
                        error(c.key.lineno, "Invalid hash column descriptor");
                        continue; }
                    int col = c.key[1].i;
                    if (col < 0 || col >= 52) {
                        error(c.key.lineno, "Hash column out of range");
                        continue; }
                    if (!CHECKTYPE(c.value, tINT)) continue;
                    if (hash_tables[id][col].valid)
                        error(c.key.lineno, "Hash table %d column %d valid duplicated", id, col);
                    else if (c.value.i >= 0x10000)
                        error(c.value.lineno, "Hash valid value out of range");
                    else
                        hash_tables[id][col].valid = c.value.i; } }
	} else {
	    error(kv.key.lineno, "expecting a group %sdescriptor",
		  ternary ? "" : "or hash "); }
    }
}

unsigned InputXbar::tcam_width() {
    unsigned words = 0, bytes = 0;
    for (auto group : group_order) {
        unsigned in_word = 0, in_byte = 0;
        for (auto &input : group->second) {
            if (input.lo < 40)
                in_word = 1;
            if (input.lo >= 40 || input.hi >= 40)
                in_byte = 1; }
        words += in_word;
        bytes += in_byte; }
    if (bytes*2 > words)
        error(lineno, "Too many byte groups in tcam input xbar");
    return words;
}

int InputXbar::tcam_byte_group(int idx) {
    for (auto group : group_order)
        for (auto &input : group->second)
            if (input.lo >= 40 || input.hi >= 40) {
                if (--idx < 0) return group->first/2;
                break; }
    return -1;
}

int InputXbar::tcam_word_group(int idx) {
    for (auto group : group_order)
        for (auto &input : group->second)
            if (input.lo < 40) {
                if (--idx < 0) return group->first;
                break; }
    return -1;
}

bool InputXbar::conflict(const std::vector<Input> &a, const std::vector<Input> &b) {
    for (auto &i1 : a) {
        if (i1.lo < 0) continue;
        for (auto &i2 : b) {
            if (i2.lo < 0) continue;
            if (i1.lo < i2.lo) {
                if (i1.hi >= i2.lo) return true;
            } else if (i2.hi >= i1.lo) {
                if (i1.lo != i2.lo || i1.hi != i2.hi || i1.what != i2.what)
                    return true;
            }
        }
    }
    return false;
}

bool InputXbar::conflict(const std::map<int, HashCol> &a, const std::map<int, HashCol> &b) {
    for (auto &acol : a)
        if (auto bcol = ::getref(b, acol.first))
            if (acol.second.data != bcol->data || acol.second.valid != bcol->valid)
                return true;
    return false;
}

bool InputXbar::conflict(const HashGrp &a, const HashGrp &b) {
    if (a.tables != b.tables) return true;
    if (a.seed && b.seed && a.seed != b.seed) return true;
    return false;
}

uint64_t InputXbar::hash_columns_used(unsigned hash) {
    uint64_t rv = 0;
    if (hash_tables.count(hash))
	for (auto &col : hash_tables[hash])
	    rv |= 1UL << col.first;
    return rv;
}

/* FIXME -- this is questionable, but the compiler produces hash groups that conflict
 * FIXME -- so we try to tag ones that may be ok as merely warnings */
bool InputXbar::can_merge(HashGrp &a, HashGrp &b,
			  Alloc1Dbase<std::vector<InputXbar *>> &use)
{
    unsigned both = a.tables & b.tables;
    uint64_t both_cols = 0, a_cols = 0, b_cols = 0;
    for (unsigned i = 0; i < 16; i++) {
	unsigned mask = 1U << i;
	if (!((a.tables|b.tables) & mask)) continue;
	for (InputXbar *other : use[i]) {
	    if (both & mask) both_cols |= other->hash_columns_used(i);
	    if (a.tables & mask) a_cols |= other->hash_columns_used(i);
	    if (b.tables & mask) b_cols |= other->hash_columns_used(i); } }
    a_cols &= ~both_cols;
    b_cols &= ~both_cols;
    if (a_cols & b_cols)
	return false;
    if ((a_cols & b.seed & ~a.seed) || (b_cols & a.seed & ~b.seed))
	return false;
    a.tables |= b.tables;
    b.tables |= a.tables;
    a.seed |= b.seed;
    b.seed |= a.seed;
    return true;
}

void InputXbar::pass1(Alloc1Dbase<std::vector<InputXbar *>> &use, int size) {
    for (auto &group : groups) {
        for (auto &input : group.second) {
            if (!input.what.check()) continue;
            if (ternary && (input.lo == 40 || input.lo < 0)) {
                // can do a single nybble in a ternary group, so different error message?
                if (input.what->lo % 4U != 0 || input.what->hi % 4U != 3)
                    error(input.what.lineno, "input_xbar can only manipulate whole bytes");
            } else if (input.what->lo % 8U != 0 || input.what->hi % 8U != 7)
                error(input.what.lineno, "input_xbar can only manipulate whole bytes");
            table->stage->match_use[table->gress][input.what->reg.index] = 1;
            if (input.lo >= 0) {
                if (input.lo % 8U != 0)
                    error(input.what.lineno, "input_xbar can only manipulate whole bytes");
                if (input.hi >= 0) {
                    if (input.hi - input.lo != input.what->hi - input.what->lo)
                        error(input.what.lineno, "Input xbar size doesn't match register size");
                } else
                    input.hi = input.lo - input.what->lo + input.what->hi;
                if (input.lo >= size)
                    error(input.what.lineno, "placing %s off the top of the input xbar",
                          input.what.name()); }
                if (!ternary && (input.lo % input.what->reg.size != input.what->lo))
                    error(input.what.lineno, "%s misaligned on input_xbar", input.what.name()); }
        for (InputXbar *other : use[group.first]) {
            if (other->groups.count(group.first) &&
                conflict(other->groups[group.first], group.second)) {
                error(lineno, "Input xbar group %d conflict in stage %d", group.first,
                      table->stage->stageno);
                warning(other->lineno, "conflicting group definition here"); } }
        use[group.first].push_back(this); }
    for (auto &hash : hash_tables) {
        bool ok = true;
        HashExpr *prev = 0;
        for (auto &col : hash.second) {
            if (col.second.fn && col.second.fn != prev)
                ok = (prev = col.second.fn)->check_ixbar(this, hash.first/2U);
            if (ok && col.second.fn)
                col.second.fn->gen_data(col.second.data, col.second.bit, this, hash.first/2U); }
        bool add_to_use = true;
        for (InputXbar *other : use[hash.first]) {
            if (other == this) {
                add_to_use = false;
                break; }
            if (other->hash_tables.count(hash.first) &&
                conflict(other->hash_tables[hash.first], hash.second)) {
                error(lineno, "Input xbar hash table %d conflict in stage %d", hash.first,
                      table->stage->stageno);
                warning(other->lineno, "conflicting hash definition here"); } }
        if (add_to_use)
            use[hash.first].push_back(this); }
    for (auto &group : hash_groups) {
        bool add_to_use = true;
        for (InputXbar *other : use[group.first]) {
            if (other == this) {
                add_to_use = false;
                break; }
            if (other->hash_groups.count(group.first) &&
                conflict(other->hash_groups[group.first], group.second)) {
                if (can_merge(other->hash_groups[group.first], group.second, use))
                    warning(group.second.lineno, "Input xbar hash group %d mergeable conflict "
			    "in stage %d", group.first, table->stage->stageno);
                else 
                    error(group.second.lineno, "Input xbar hash group %d conflict in stage %d",
                          group.first, table->stage->stageno);
                warning(other->hash_groups[group.first].lineno,
                        "conflicting hash group definition here"); } }
        if (add_to_use)
            use[group.first].push_back(this); }
}

void InputXbar::add_use(unsigned &byte_use, std::vector<Input> &inputs) {
    for (auto &i : inputs) {
        if (i.lo < 0) continue;
        for (int byte = i.lo/8; byte <= i.hi/8; byte++)
            byte_use |= 1 << byte;;
    }
}

InputXbar::Input *InputXbar::GroupSet::find(Phv::Slice sl) const {
    for (InputXbar *i : use)
        if (auto rv = i->find(sl, group))
            return rv;
    return 0;
}

void InputXbar::GroupSet::dbprint(std::ostream &out) const {
    std::map<unsigned, InputXbar::Input *> byte_use;
    for (InputXbar *ixbar : use)
        if (ixbar->groups.count(group))
            for (auto &i : ixbar->groups[group]) {
                if (i.lo < 0) continue;
                for (int byte = i.lo/8; byte <= i.hi/8; byte++)
                    byte_use[byte] = &i; }
    InputXbar::Input *prev = 0;
    for (auto &in : byte_use) {
        if (prev == in.second) continue;
        if (prev) out << ", ";
        prev = in.second;
        out << prev->what << ':' << prev->lo << ".." << prev->hi; }
}

void InputXbar::pass2(Alloc1Dbase<std::vector<InputXbar *>> &use, int size) {
    for (auto &group : groups) {
        unsigned bytes_in_use = 0;
        for (auto &input : group.second) {
            if (input.lo >= 0) continue;
            if (auto *at = GroupSet(use, group.first).find(*input.what)) {
                input.lo = at->lo;
                input.hi = at->hi;
                LOG1(input.what << " found in bytes " << at->lo/8 << ".."
                     << at->hi/8 << " of " << (ternary ? "tcam" : "exact")
                     << " ixbar group " << group.first << " in stage "
                     << table->stage->stageno);
                continue; }
            if (bytes_in_use == 0)
                for (InputXbar *other : use[group.first])
                    if (other->groups.count(group.first))
                        add_use(bytes_in_use, other->groups[group.first]);
            int need = input.what->hi/8U - input.what->lo/8U + 1;
            unsigned mask = (1U << need)-1;
            int max = (size+7)/8 - need;
            for (int i = 0; i <= max; i++, mask <<= 1)
                if (!(bytes_in_use & mask)) {
                    input.lo = i*8 + input.what->lo%8U;
                    input.hi = (i+need-1)*8 + input.what->hi%8U;
                    bytes_in_use |= mask;
                    LOG1("Putting " << input.what << " in bytes " << i << ".."
                         << i+need-1 << " of " << (ternary ? "tcam" : "exact")
                         << " ixbar group " << group.first << " in stage "
                         << table->stage->stageno);
                    break; }
            if (input.lo < 0) {
                error(input.what.lineno, "No space in input xbar group %d for %s",
                      group.first, input.what.name());
                LOG1("Failed to put " << input.what << " into " << (ternary ? "tcam" : "exact")
                     << " ixbar group " << group.first << " in stage " << table->stage->stageno);
                LOG1("  inuse: " << GroupSet(use, group.first));
            }
        }
    }
    for (auto &hash : hash_tables)
        for (auto &col : hash.second)
            if (!col.second.data && col.second.fn)
                col.second.fn->gen_data(col.second.data, col.second.bit, this, hash.first/2U);
}

static int tcam_swizzle_offset[4][4] = {
    {  0, +1, -2, -1 },
    { +3,  0, +1, -2 },
    { +2, -1,  0, -3 },
    { +1, +2, -1,  0 },
};

void InputXbar::write_regs() {
    auto &xbar = table->stage->regs.dp.xbar_hash.xbar;
    for (auto &group : groups) {
        if (group.second.empty()) continue;
        LOG1("  # Input xbar group " << group.first);
        unsigned group_base;
        unsigned half_byte = 0;
        if (ternary) {
            group_base = 128 + (group.first*11 + 1)/2U;
            half_byte = 133 + 11*(group.first/2U);
            xbar.mau_match_input_xbar_ternary_match_enable[table->gress] |= 1 << (group.first)/2U;
        } else
            group_base = group.first * 16U;
        for (auto &input : group.second) {
            assert(input.lo >= 0);
            unsigned word_group = input.what->reg.index / 16U;
            unsigned word_index = input.what->reg.index % 16U;
            unsigned swizzle_mask = 3;
            if (input.what->reg.index >= 128) {
                assert(input.what->reg.size == 16);
                word_group = (input.what->reg.index-128) / 24U;
                word_index = (input.what->reg.index-128) % 24U + 16;
                swizzle_mask = 1;
            } else if (input.what->reg.index >= 64) {
                word_group -= 4;
                swizzle_mask = 0; }
            unsigned phv_byte = input.what->lo/8U;
            unsigned phv_size = input.what->reg.size/8U;
            for (unsigned byte = input.lo/8U; byte <= input.hi/8U; byte++, phv_byte++) {
                unsigned i = group_base + byte;
                if (half_byte && byte == 5) i = half_byte;
                if (i%phv_size != phv_byte) {
                    if (ternary) {
                        int off;
                        if (phv_size == 2)
                            off = (i&2) ? -1 : 1;
                        else
                            off = tcam_swizzle_offset[i&3][phv_byte];
                        xbar.tswizzle.tcam_byte_swizzle_ctl[i&0x7f] = off&3U;
                        i += off;
                    } else error(input.what.lineno, "misaligned phv access on input_xbar"); }
                if (input.what->reg.index < 64) {
                    assert(input.what->reg.size == 32);
                    xbar.match_input_xbar_32b_ctl[word_group][i]
                        .match_input_xbar_32b_ctl_address = word_index;
                    xbar.match_input_xbar_32b_ctl[word_group][i]
                        .match_input_xbar_32b_ctl_enable = 1;
                } else {
                    xbar.match_input_xbar_816b_ctl[word_group][i]
                        .match_input_xbar_816b_ctl_address = word_index;
                    xbar.match_input_xbar_816b_ctl[word_group][i]
                        .match_input_xbar_816b_ctl_enable = 1; }
                if ((i ^ phv_byte) & swizzle_mask)
                    LOG1("FIXME -- need swizzle for " << input.what); }
            auto &power_ctl = table->stage->regs.dp.match_input_xbar_din_power_ctl;
            int phv = input.what->reg.index;
            power_ctl[phv/112U][phv%112U/8U] |= 1 << phv%8U; } }
    auto &hash = table->stage->regs.dp.xbar_hash.hash;
    for (auto &ht : hash_tables) {
        if (ht.second.empty()) continue;
        LOG1("  # Input xbar hash table " << ht.first);
        int id = ht.first;
        for (auto &col : ht.second) {
            int c = col.first;
            HashCol &h = col.second;
            for (int word = 0; word < 4; word++) {
                unsigned data = h.data.getrange(word*16, 16);
                unsigned valid = (h.valid >> word*2) & 3;
                if (data == 0 && valid == 0) continue;
                auto &w = hash.galois_field_matrix[id*4 + word][c];
                w.byte0 = data & 0xff;
                w.byte1 = (data >> 8) & 0xff;
                w.valid0 = valid & 1;
                w.valid1 = (valid >> 1) & 1; } } }
    for (auto &hg : hash_groups) {
        LOG1("  # Input xbar hash group " << hg.first);
        int grp = hg.first;
        if (hg.second.tables) {
            hash.parity_group_mask[grp] = hg.second.tables;
            xbar.mau_match_input_xbar_exact_match_enable[table->gress] |= hg.second.tables; }
        if (hg.second.seed) {
            hash.hash_seed[grp][0] = hg.second.seed & 0x3ffffff;
            hash.hash_seed[grp][1] = (hg.second.seed >> 26) & 0x3ffffff; }
        if (table->gress == INGRESS)
            hash.hashout_ctl.hash_group_ingress_enable |= 1 << grp;
        else
            hash.hashout_ctl.hash_group_egress_enable |= 1 << grp; }
}

InputXbar::Input *InputXbar::find(Phv::Slice sl, int grp) {
    if (groups.count(grp))
        for (auto &in : groups[grp]) {
            if (in.lo < 0) continue;
            if (in.what->reg.index != sl.reg.index) continue;
            if (in.what->lo > sl.lo) continue;
            if (in.what->hi < sl.hi) continue;
            return &in; }
    return 0;
}

bitvec InputXbar::hash_group_bituse() {
    bitvec rv;
    unsigned tables;
    for (auto &grp : hash_groups) {
        tables |= grp.second.tables;
        rv |= grp.second.seed; }
    for (auto &tbl : hash_tables) {
        if (!((tables >> tbl.first) & 1)) continue;
        for (auto &col : tbl.second)
            rv[col.first] = 1; }
    return rv;
}
