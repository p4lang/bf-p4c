#include <config.h>

#include "hashexpr.h"
#include "input_xbar.h"
#include "log.h"
#include "power_ctl.h"
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
    int errlo = -1;
    for (int col : Range(lo, hi))
        if (hash_table[col].data || hash_table[col].fn) {
            if (errlo < 0) errlo = col;
        } else {
            if (errlo >= 0) {
                if (errlo == col-1)
                    error(lineno, "Hash table %d column %d duplicated", id, errlo);
                else
                    error(lineno, "Hash table %d column %d..%d duplicated", id, errlo, col-1);
                errlo = -1; }
            hash_table[col].lineno = what.lineno;
            hash_table[col].fn = fn;
            hash_table[col].bit = bit++; }
    if (errlo >= 0)
        error(lineno, "Hash table %d column %d..%d duplicated", id, errlo, hi);
}

InputXbar::InputXbar(Table *t, bool tern, const VECTOR(pair_t) &data)
: table(t), lineno(data[0].key.lineno)
{
    for (auto &kv : data) {
        if ((kv.key.type == tSTR) && (kv.key == "random_seed")) {
          random_seed = kv.value.i;
          continue;
        }
        Group::type_t grtype = tern ? Group::TERNARY : Group::EXACT;
        if (!CHECKTYPEM(kv.key, tCMD, "group or hash descriptor"))
            continue;
        unsigned index = 1;
        if (kv.key[0] != "group" && (kv.key[1] == "group" || kv.key[1] == "table"))
            ++index;
        if (!PCHECKTYPE(kv.key.vec.size == int(index+1), kv.key[index], tINT))
            continue;
        index = kv.key[index].i;
        bool isgroup = false;

        if (kv.key[0] == "exact" && kv.key[1] == "group") {
            grtype = Group::EXACT;
            isgroup = true;
        } else if (kv.key[0] == "ternary" && kv.key[1] == "group") {
            grtype = Group::TERNARY;
            isgroup = true;
        } else if (kv.key[0] == "byte" && kv.key[1] == "group") {
            grtype = Group::BYTE;
            isgroup = true; }
        if (isgroup || kv.key[0] == "group") {
            if (index >= Group::max_index(grtype)) {
                error(kv.key.lineno, "invalid group descriptor");
                continue; }
            auto &group = groups[Group(grtype, index)];
            if (kv.value.type == tVEC) {
                for (auto &reg : kv.value.vec)
                    group.emplace_back(Phv::Ref(t->gress, reg));
            } else if (kv.value.type == tMAP) {
                for (auto &reg : kv.value.map) {
                    if (!CHECKTYPE2(reg.key, tINT, tRANGE)) continue;
                    int lo = -1, hi = -1;
                    if (reg.key.type == tINT)
                        lo = reg.key.i;
                    else {
                        lo = reg.key.lo;
                        hi = reg.key.hi; }
                    if (lo < 0 || lo >= Group::group_size(grtype)) {
                        error(reg.key.lineno, "Invalid offset for %s group",
                              Group::group_type(grtype));
                    } else if (grtype == Group::TERNARY && lo >= 40) {
                        if (hi >= lo) hi -= 40;
                        groups[Group(Group::BYTE, index/2)]
                            .emplace_back(Phv::Ref(t->gress, reg.value), lo-40, hi);
                    } else {
                        group.emplace_back(Phv::Ref(t->gress, reg.value), lo, hi); } }
            } else
                group.emplace_back(Phv::Ref(t->gress, kv.value));
        } else if (kv.key[0] == "hash") {
            if (kv.key[1] == "group") {
                if (index >= EXACT_HASH_GROUPS) {
                    error(kv.key.lineno, "invalid hash group descriptor");
                    continue; }
                hash_groups[index].lineno = kv.key.lineno;
                if (kv.value.type == tINT && (unsigned)kv.value.i < HASH_TABLES) {
                    hash_groups[index].tables |= 1U << kv.value.i;
                    continue; }
                if (!CHECKTYPE2(kv.value, tVEC, tMAP)) continue;
                VECTOR(value_t) *tbl = 0;
                if (kv.value.type == tMAP) {
                    for (auto &el : MapIterChecked(kv.value.map)) {
                        if (el.key == "seed") {
                            if (!CHECKTYPE2(el.value, tINT, tBIGINT)) continue;
                            if (el.value.type == tBIGINT) {
                                hash_groups[index].seed = el.value.bigi.data[0];
                            } else
                                hash_groups[index].seed = el.value.i & 0xFFFFFFFF;
                        } else if (el.key == "table") {
                            if (el.value.type == tINT) {
                                if (el.value.i < 0 || el.value.i >= HASH_TABLES)
                                    error(el.value.lineno, "invalid hash group descriptor");
                                else
                                    hash_groups[index].tables |= 1U << el.value.i;
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
                            hash_groups[index].tables |= 1U << v.i; } }
                continue; }
            if (index >= HASH_TABLES) {
                error(kv.key.lineno, "invalid hash descriptor");
                continue; }
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            for (auto &c : kv.value.map) {
                if (c.key.type == tINT) {
                    setup_hash(hash_tables[index], index, t->gress, c.value,
                               c.key.lineno, c.key.i, c.key.i);
                } else if (c.key.type == tRANGE) {
                    setup_hash(hash_tables[index], index, t->gress, c.value,
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
                    if (hash_tables[index][col].valid)
                        error(c.key.lineno, "Hash table %d column %d valid duplicated",
                              index, col);
                    else if (c.value.i >= 0x10000)
                        error(c.value.lineno, "Hash valid value out of range");
                    else
                        hash_tables[index][col].valid = c.value.i; } }
        } else {
            error(kv.key.lineno, "expecting a group or hash descriptor"); }
    }
}

unsigned InputXbar::tcam_width() {
    unsigned words = 0, bytes = 0;
    for (auto &group : groups) {
        if (group.first.type != Group::TERNARY) {
            if (group.first.type == Group::BYTE) ++bytes;
        continue; }
        unsigned in_word = 0, in_byte = 0;
        for (auto &input : group.second) {
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
    for (auto &group : groups) {
        if (group.first.type != Group::TERNARY) continue;
        for (auto &input : group.second)
            if (input.lo >= 40 || input.hi >= 40) {
                if (--idx < 0) return group.first.index/2;
                break; } }
    return -1;
}

int InputXbar::tcam_word_group(int idx) {
    for (auto &group : groups) {
        if (group.first.type != Group::TERNARY) continue;
        for (auto &input : group.second)
            if (input.lo < 40) {
                if (--idx < 0) return group.first.index;
                break; } }
    return -1;
}

bool InputXbar::conflict(const std::vector<Input> &a, const std::vector<Input> &b) {
    for (auto &i1 : a) {
        if (i1.lo < 0) continue;
        for (auto &i2 : b) {
            if (i2.lo < 0) continue;
            if (i2.lo > i1.hi || i1.lo > i2.hi) continue;
            if (i1.what->reg != i2.what->reg) return true;
            if (i1.lo - i1.what->lo != i2.lo - i2.what->lo)
                return true;
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
bool InputXbar::can_merge(HashGrp &a, HashGrp &b)
{
    unsigned both = a.tables & b.tables;
    uint64_t both_cols = 0, a_cols = 0, b_cols = 0;
    for (unsigned i = 0; i < 16; i++) {
        unsigned mask = 1U << i;
        if (!((a.tables|b.tables) & mask)) continue;
        for (InputXbar *other : table->stage->hash_table_use[i]) {
            if (both & mask) both_cols |= other->hash_columns_used(i);
            if (a.tables & mask) a_cols |= other->hash_columns_used(i);
            if (b.tables & mask) b_cols |= other->hash_columns_used(i); } }
    a_cols &= ~both_cols;
    b_cols &= ~both_cols;
    if (a_cols & b_cols)
        return false;
    if ((a_cols & b.seed & ~a.seed) || (b_cols & a.seed & ~b.seed))
        return false;
    if (a.tables && b.tables) {
        a.tables |= b.tables;
        b.tables |= a.tables; }
    if (a.seed && b.seed) {
        a.seed |= b.seed;
        b.seed |= a.seed; }
    return true;
}

static int tcam_swizzle_offset[4][4] = {
    {  0, +1, -2, -1 },
    { +3,  0, +1, -2 },
    { +2, -1,  0, -3 },
    { +1, +2, -1,  0 },
};

// FIXME -- when swizlling 16 bit PHVs, there are 2 places we could copy from, but
// FIXME -- we only consider the closest/easiest
static int tcam_swizzle_16[2][2] { { 0, -1 }, { +1, 0 } };

int InputXbar::tcam_input_use(int out_byte, int phv_byte, int phv_size) {
    int rv = out_byte;
    assert(phv_byte >= 0 && phv_byte < phv_size/8);
    switch(phv_size) {
    case 8:
        break;
    case 32:
        rv += tcam_swizzle_offset[out_byte & 3][phv_byte];
        break;
    case 16:
        rv += tcam_swizzle_16[out_byte & 1][phv_byte];
        break;
    default:
        assert(0); }
    return rv;
}

void InputXbar::tcam_update_use(TcamUseCache &use) {
    if (use.ixbars_added.count(this)) return;
    use.ixbars_added.insert(this);
    for (auto &group : groups) {
        if (group.first.type == Group::EXACT) continue;
        for (auto &input : group.second) {
            if (input.lo < 0) continue;
            int group_base = (group.first.index*11 + 1)/2U;
            int half_byte = 5 + 11*(group.first.index/2U);
            if (group.first.type == Group::BYTE) {
                group_base = 5 + 11*group.first.index;
                half_byte = -1; }
            int group_byte =input.lo/8;
            for (int phv_byte = input.what->lo/8; phv_byte <= input.what->hi/8;
                 phv_byte++, group_byte++)
            {
                assert(group_byte <= 5);
                int out_byte = group_byte == 5 ? half_byte : group_base + group_byte;
                int in_byte = tcam_input_use(out_byte, phv_byte, input.what->reg.size);
                use.tcam_use.emplace(in_byte, std::pair<const Input &, int>(input, phv_byte));
            }
        }
    }
}

void InputXbar::check_tcam_input_conflict(InputXbar::Group group, Input &input, TcamUseCache &use) {
    unsigned bit_align_mask = input.lo >= 40 ? 3 : 7;
    unsigned byte_align_mask = (input.what->reg.size-1) >> 3;
    int group_base = (group.index * 11 + 1)/2U;
    int half_byte = 5 + 11*(group.index/2U);
    if (group.type == Group::BYTE) {
        bit_align_mask = 3;
        group_base = 5 + 11*group.index;
        half_byte = -1; }
    int group_byte =input.lo/8;
    if ((input.lo ^ input.what->lo) & bit_align_mask) {
        error(input.what.lineno, "%s misaligned on input_xbar", input.what.name());
        return; }
    for (int phv_byte = input.what->lo/8; phv_byte <= input.what->hi/8; phv_byte++, group_byte++) {
        assert(group_byte <= 5);
        int out_byte = group_byte == 5 ? half_byte : group_base + group_byte;
        int in_byte = tcam_input_use(out_byte, phv_byte, input.what->reg.size);
        if (in_byte < 0 || in_byte >= TCAM_XBAR_INPUT_BYTES) {
            error(input.what.lineno, "%s misaligned on input_xbar", input.what.name());
            break; }
        auto *tbl = table->stage->tcam_ixbar_input[in_byte];
        if (tbl) tbl->input_xbar->tcam_update_use(use);
        if (use.tcam_use.count(in_byte)) {
            if (use.tcam_use.at(in_byte).first.what->reg != input.what->reg ||
                use.tcam_use.at(in_byte).second != phv_byte) {
                error(input.what.lineno, "Use of tcam ixbar for %s", input.what.name());
                error(use.tcam_use.at(in_byte).first.what.lineno, "...conflicts with %s",
                      use.tcam_use.at(in_byte).first.what.name());
                break; }
        } else {
            use.tcam_use.emplace(in_byte, std::pair<const Input &, int>(input, phv_byte));
            table->stage->tcam_ixbar_input[in_byte] = tbl; } }
}

bool InputXbar::copy_existing_hash(int group, std::pair<const int, HashCol> &col) {
    for (InputXbar *other : table->stage->hash_table_use[group]) {
        if (other == this) continue;
        if (other->hash_tables.count(group)) {
            auto &o = other->hash_tables.at(group);
            if (o.count(col.first)) {
                auto ocol = o.at(col.first);
                if (ocol.fn && *ocol.fn == *col.second.fn) {
                    col.second.data = ocol.data;
                    return true; } } } }
    return false;
}

void InputXbar::pass1() {
    TcamUseCache tcam_use;
    tcam_use.ixbars_added.insert(this);
    if (random_seed >= 0)
        srandom(random_seed);
    for (auto &group : groups) {
        for (auto &input : group.second) {
            if (!input.what.check()) continue;
            if (input.what->reg.ixbar_id() < 0)
                error(input.what.lineno, "%s not accessable in input xbar", input.what->reg.name);
            table->stage->match_use[table->gress][input.what->reg.uid] = 1;
            if (input.lo < 0 && group.first.type == Group::BYTE)
                input.lo = input.what->lo % 8U;
            if (input.lo >= 0) {
                if (input.hi >= 0) {
                    if (input.size() != input.what->size())
                        error(input.what.lineno, "Input xbar size doesn't match register size");
                } else
                    input.hi = input.lo + input.what->size() - 1;
                if (input.lo >= Group::group_size(group.first.type))
                    error(input.what.lineno, "placing %s off the top of the input xbar",
                          input.what.name()); }
                if (group.first.type != Group::EXACT)
                    check_tcam_input_conflict(group.first, input, tcam_use);
                else if (input.lo % input.what->reg.size != input.what->lo)
                    error(input.what.lineno, "%s misaligned on input_xbar", input.what.name()); }
        auto &use = table->stage->ixbar_use;
        for (InputXbar *other : use[group.first]) {
            if (other->groups.count(group.first) &&
                conflict(other->groups[group.first], group.second)) {
                error(lineno, "Input xbar group %d conflict in stage %d", group.first.index,
                      table->stage->stageno);
                warning(other->lineno, "conflicting group definition here"); } }
        use[group.first].push_back(this); }
    for (auto &hash : hash_tables) {
        bool ok = true;
        HashExpr *prev = 0;
        for (auto &col : hash.second) {
            if (col.second.fn && col.second.fn != prev)
                ok = (prev = col.second.fn)->check_ixbar(this, hash.first/2U);
            if (ok && col.second.fn && !copy_existing_hash(hash.first, col))
                col.second.fn->gen_data(col.second.data, col.second.bit, this, hash.first/2U); }
        bool add_to_use = true;
        for (InputXbar *other : table->stage->hash_table_use[hash.first]) {
            if (other == this) {
                add_to_use = false;
                continue; }
            if (other->hash_tables.count(hash.first) &&
                conflict(other->hash_tables[hash.first], hash.second)) {
                error(lineno, "Input xbar hash table %d conflict in stage %d", hash.first,
                      table->stage->stageno);
                warning(other->lineno, "conflicting hash definition here"); } }
        if (add_to_use)
            table->stage->hash_table_use[hash.first].push_back(this); }
    for (auto &group : hash_groups) {
        bool add_to_use = true;
        for (InputXbar *other : table->stage->hash_group_use[group.first]) {
            if (other == this) {
                add_to_use = false;
                break; }
            if (other->hash_groups.count(group.first) &&
                conflict(other->hash_groups[group.first], group.second)) {
                if (can_merge(other->hash_groups[group.first], group.second))
                    warning(group.second.lineno, "Input xbar hash group %d mergeable conflict "
                            "in stage %d", group.first, table->stage->stageno);
                else
                    error(group.second.lineno, "Input xbar hash group %d conflict in stage %d",
                          group.first, table->stage->stageno);
                warning(other->hash_groups[group.first].lineno,
                        "conflicting hash group definition here"); } }
        if (add_to_use)
            table->stage->hash_group_use[group.first].push_back(this); }
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

void InputXbar::pass2() {
    auto &use = table->stage->ixbar_use;
    for (auto &group : groups) {
        unsigned bytes_in_use = 0;
        for (auto &input : group.second) {
            if (input.lo >= 0) continue;
            if (auto *at = GroupSet(use, group.first).find(*input.what)) {
                input.lo = at->lo;
                input.hi = at->hi;
                LOG1(input.what << " found in bytes " << at->lo/8 << ".." << at->hi/8 <<
                     " of " << group.first << " in stage " << table->stage->stageno);
                continue; }
            if (bytes_in_use == 0)
                for (InputXbar *other : table->stage->ixbar_use[group.first])
                    if (other->groups.count(group.first))
                        add_use(bytes_in_use, other->groups[group.first]);
            int need = input.what->hi/8U - input.what->lo/8U + 1;
            unsigned mask = (1U << need)-1;
            int max = (Group::group_size(group.first.type)+7)/8 - need;
            for (int i = 0; i <= max; i++, mask <<= 1)
                if (!(bytes_in_use & mask)) {
                    input.lo = i*8 + input.what->lo%8U;
                    input.hi = (i+need-1)*8 + input.what->hi%8U;
                    bytes_in_use |= mask;
                    LOG1("Putting " << input.what << " in bytes " << i << ".." << i+need-1 <<
                         " of " << group.first << " in stage " << table->stage->stageno);
                    break; }
            if (input.lo < 0) {
                error(input.what.lineno, "No space in input xbar %s group %d for %s",
                      Group::group_type(group.first.type), group.first.index,
                      input.what.name());
                LOG1("Failed to put " << input.what << " into " << group.first <<
                     " in stage " << table->stage->stageno);
                LOG1("  inuse: " << GroupSet(use, group.first));
            }
        }
    }
    for (auto &hash : hash_tables)
        for (auto &col : hash.second)
            if (!col.second.data && col.second.fn)
                col.second.fn->gen_data(col.second.data, col.second.bit, this, hash.first/2U);
}

#include <tofino/input_xbar.cpp>        // tofino template specializations
#if HAVE_JBAY
#include <jbay/input_xbar.cpp>          // jbay template specializations
#endif // HAVE_JBAY

template<class REGS>
void InputXbar::write_regs(REGS &regs) {
    auto &xbar = regs.dp.xbar_hash.xbar;
    auto gress = timing_thread(table->gress);
    for (auto &group : groups) {
        if (group.second.empty()) continue;
        LOG1("  # Input xbar group " << group.first);
        unsigned group_base;
        unsigned half_byte = 0;
        unsigned bytes_used = 0;
        switch (group.first.type) {
        case Group::EXACT:
            group_base = group.first.index * 16U;
            break;
        case Group::TERNARY:
            group_base = 128 + (group.first.index*11 + 1)/2U;
            half_byte = 133 + 11*(group.first.index/2U);
            xbar.mau_match_input_xbar_ternary_match_enable[gress]
                |= 1 << (group.first.index)/2U;
            break;
        case Group::BYTE:
            group_base = 133 + 11*group.first.index;
            break;
        default:
            assert(0); }
        for (auto &input : group.second) {
            assert(input.lo >= 0);
            unsigned word_group, word_index, swizzle_mask;
            bool hi_enable = false;
            switch (input.what->reg.size) {
            case 8:
                word_group = (input.what->reg.ixbar_id() - 64) / 8U;
                word_index = (input.what->reg.ixbar_id() - 64) % 8U + (word_group & 4) * 2;
                swizzle_mask = 0;
                break;
            case 16:
                word_group = (input.what->reg.ixbar_id() - 128) / 12U;
                word_index = (input.what->reg.ixbar_id() - 128) % 12U + 16 + (word_group & 4) * 3;
                swizzle_mask = 1;
                break;
            case 32:
                word_group = input.what->reg.ixbar_id() / 8U;
                word_index = input.what->reg.ixbar_id() % 8U;
                hi_enable = word_group & 4;
                swizzle_mask = 3;
                break;
            default:
                assert(0); }
            word_group &= 3;
            unsigned phv_byte = input.what->lo/8U;
            unsigned phv_size = input.what->reg.size/8U;
            for (unsigned byte = input.lo/8U; byte <= input.hi/8U; byte++, phv_byte++) {
                bytes_used |= 1U << byte;
                unsigned i = group_base + byte;
                if (half_byte && byte == 5) i = half_byte;
                if (i%phv_size != phv_byte) {
                    if (group.first.type != Group::EXACT) {
                        int off;
                        if (phv_size == 2)
                            off = (i&2) ? -1 : 1;
                        else
                            off = tcam_swizzle_offset[i&3][phv_byte];
                        xbar.tswizzle.tcam_byte_swizzle_ctl[(i&0x7f)/4U].set_subfield(
                            off&3U, 2*(i%4U), 2);
                        i += off;
                    } else error(input.what.lineno, "misaligned phv access on input_xbar"); }
                if (input.what->reg.ixbar_id() < 64) {
                    assert(input.what->reg.size == 32);
                    xbar.match_input_xbar_32b_ctl[word_group][i]
                        .match_input_xbar_32b_ctl_address = word_index;
                    if (hi_enable)
                        xbar.match_input_xbar_32b_ctl[word_group][i]
                            .match_input_xbar_32b_ctl_hi_enable = 1;
                    else
                        xbar.match_input_xbar_32b_ctl[word_group][i]
                            .match_input_xbar_32b_ctl_lo_enable = 1;
                } else {
                    xbar.match_input_xbar_816b_ctl[word_group][i]
                        .match_input_xbar_816b_ctl_address = word_index;
                    xbar.match_input_xbar_816b_ctl[word_group][i]
                        .match_input_xbar_816b_ctl_enable = 1; }
                if ((i ^ phv_byte) & swizzle_mask)
                    LOG1("FIXME -- need swizzle for " << input.what); }
            auto &power_ctl = regs.dp.match_input_xbar_din_power_ctl;
            // we do in fact want mau_id, not ixbar_id here!
            set_power_ctl_reg(power_ctl, input.what->reg.mau_id()); }
        if (group.first.type == Group::EXACT) {
            unsigned enable = 0;
            if (bytes_used & 0xff) enable |= 1;
            if (bytes_used & 0xff00) enable |= 2;
            enable <<= group.first.index * 2;
            regs.dp.mau_match_input_xbar_exact_match_enable[gress].rewrite();
            regs.dp.mau_match_input_xbar_exact_match_enable[gress] |= enable; } }
    auto &hash = regs.dp.xbar_hash.hash;
    for (auto &ht : hash_tables) {
        if (ht.second.empty()) continue;
        LOG1("  # Input xbar hash table " << ht.first);
        write_galois_matrix(regs, ht.first, ht.second); }
    for (auto &hg : hash_groups) {
        LOG1("  # Input xbar hash group " << hg.first);
        int grp = hg.first;
        if (hg.second.tables) {
            hash.parity_group_mask[grp][0] = hg.second.tables & 0xff;
            hash.parity_group_mask[grp][1] = (hg.second.tables >> 8) & 0xff;
            regs.dp.mau_match_input_xbar_exact_match_enable[gress].rewrite();
            regs.dp.mau_match_input_xbar_exact_match_enable[gress] |= hg.second.tables; }
        if (hg.second.seed) {
            for (int bit = 0; bit < 52; ++bit)
                if ((hg.second.seed >> bit) & 1) 
                    hash.hash_seed[bit] |= 1U << grp; }
        if (gress == INGRESS)
            regs.dp.hashout_ctl.hash_group_ingress_enable |= 1 << grp;
        else
            regs.dp.hashout_ctl.hash_group_egress_enable |= 1 << grp;
    }
}

InputXbar::Input *InputXbar::find(Phv::Slice sl, Group grp) {
    InputXbar::Input *rv = nullptr;
    if (groups.count(grp))
        for (auto &in : groups[grp]) {
            if (in.lo < 0) continue;
            if (in.what->reg.uid != sl.reg.uid) continue;
            if (in.what->lo/8U > sl.lo/8U) continue;
            if (in.what->hi/8U < sl.hi/8U) continue;
            rv = &in;
            if (in.what->lo > sl.lo) continue;
            if (in.what->hi < sl.hi) continue;
            return &in; }
    return rv;
}

bitvec InputXbar::hash_group_bituse(int grp) const {
    bitvec rv;
    unsigned tables = 0;
    for (auto &g : hash_groups) {
        if (grp == -1 || (int)g.first == grp) {
            tables |= g.second.tables;
            rv |= g.second.seed; } }
    for (auto &tbl : hash_tables) {
        if (!((tables >> tbl.first) & 1)) continue;
        for (auto &col : tbl.second)
            rv[col.first] = 1; }
    return rv;
}

// Used by LPF/WRED meters to determine the bytemask input
bitvec InputXbar::bytemask() {
    bitvec bytemask;
    // Only one ixbar group allowed for a meter input
    if (match_group() == -1)
        return bytemask;
    for (auto group : groups) {
        auto &inputs = group.second;
        for (auto &input : inputs) {
            int byte_lo = input.lo / 8;
            int byte_hi = input.hi / 8;
            int byte_size = byte_hi - byte_lo + 1;
            bytemask.setrange(byte_lo, byte_size);
        }
    }
    return bytemask;
}

std::vector<const HashCol *> InputXbar::hash_column(int col, int grp) const {
    unsigned tables = 0;
    std::vector<const HashCol *> rv;
    for (auto &g : hash_groups)
        if (grp == -1 || (int)g.first == grp)
            tables |= g.second.tables;
    for (auto &tbl : hash_tables) {
        if (!((tables >> tbl.first) & 1)) continue;
        if (const HashCol *c = getref(tbl.second, col))
            rv.push_back(c); }
    return rv;
}
