#include "input_xbar.h"
#include "tables.h"

Flatrock::InputXbar::InputXbar(Table *table, const value_t *key)
: ::InputXbar(table, key ? key->lineno : -1) {
    uint64_t limit = 1ULL << Target::DYNAMIC_CONFIG();
    if (!key || key->type != tCMD || key->vec.size <= 1) {
        dconfig.setrange(0, limit);  // default dconfig -- program all 4
    } else if (CHECKTYPE2(key->vec[1], tINT, tMATCH)) {
        if (key->vec[1].type == tINT) {
            if (key->vec[1].i < 0 || key->vec[1].i >= limit)
                error(key->vec[1].lineno, "%" PRId64 " invalid dynamic config mask", key->vec[1].i);
            else
                dconfig[key->vec[1].i] = 1;
        } else {
            for (uint64_t i = 0; i < limit; ++i)
                if (key->vec[1].m.matches(i)) dconfig[i] = 1;
        }
    }
}

int Flatrock::InputXbar::group_max_index(Group::type_t t) const {
    switch (t) {
    case Group::EXACT:   return 2;
    case Group::TERNARY: return 20;
    case Group::GATEWAY: return 1;
    case Group::XCMP:    return 4;
    default:
       BUG("invalid group type for %s: %s", Target::name(), group_type(t)); }
    return 0;
}

InputXbar::Group Flatrock::InputXbar::group_name(bool tern, const value_t &key) const {
    if (key.type == tSTR) {
        if (key == "gateway") return Group(Group::GATEWAY, 0);
    } else if (key.type == tCMD && key.vec.size == 2) {
        if (key[0] == "exact") {
            if (key[1] == "byte") return Group(Group::EXACT, 0);
            if (key[1] == "word") return Group(Group::EXACT, 1);
        } else if (key[0] == "xcmp") {
            if (key[1] == "byte") return Group(Group::XCMP, 0);
            if (key[1] == "word") return Group(Group::XCMP, 1);
        } else if (key[0] == "ternary" && CHECKTYPE(key[1], tINT)) {
            return Group(Group::TERNARY, key[1].i); }
    } else if (key.type == tCMD && key.vec.size == 3 && key[0] == "xcmp" && key[1] == "word") {
        if (CHECKTYPE(key[2], tINT) && key[2].i >= 0 && key[2].i < 4)
            return Group(Group::XCMP, key[2].i + 1); }
    return Group(Group::INVALID, 0);
}

int Flatrock::InputXbar::group_size(Group::type_t t) const {
    switch (t) {
    case Group::EXACT:   return 20*8;
    case Group::TERNARY: return 5*8;
    case Group::GATEWAY: return 8*8;
    case Group::XCMP:    return 16*8;
    default:
        BUG("invalid group type for %s: %s", Target::name(), group_type(t)); }
    return 0;
}

void Flatrock::InputXbar::check_input(Group group, Input &input, TcamUseCache &tcam_use) {
    if (group.type == Group::TERNARY) {
        // all ternary are byte organized, but concatenated in groups of 5 bytes
        unsigned align = input.what->reg.size == 8 ? 8 : 16;
        unsigned bit = input.lo + 40 * group.index;
        if (bit % align != input.what->lo % align)
            error(input.what.lineno, "%s misaligned on input_xbar", input.what.name());
    } else if (group.index == 0) {
        // a byte organized group -- 8 bit alignment for 8 bit PHEs, 16 bit for 16/32 PHEs
        unsigned align = input.what->reg.size == 8 ? 8 : 16;
        if (input.lo % align != input.what->lo % align)
            error(input.what.lineno, "%s misaligned on input_xbar", input.what.name());
    } else if (group.index == 1) {
        // a word group -- needs 32-bit alignment
        unsigned bit = input.what->reg.index * input.what->reg.size + input.what->lo;
        if (input.lo % 32U != bit % 32U)
            error(input.what.lineno, "%s misaligned on input_xbar", input.what.name());
    } else {
        BUG("unexpected group %s %d for %s", group_type(group.type), group.index, Target::name());
    }
}

/**
 * parse flatrock "combined" hashtable/groups
 *
 * flatrock has level1 and level2 hashes, rather than "tables" and "groups" so we kind
 * of shoe-horn them into things.
 * HashTable EXACT:0 is the em bytehash (level1) table
 * HashTable EXACT:1 is the em wordhash (level1) table
 * HashTable XCMP:0..3 are the 4 XCMP hash subsets.
 *
 * HashGrp 0-3 are the STM hashes, 4-7 are the lamb hashes, and 8-11 are the XCMP hashes
 * in the HashGrp object, the `tables` corresponds to the bits in the level2 tables
 * - for EXACT hashes there are 20 (lamb) or 25 (stm) bits for the 20 bytes + 5 words
 * - for XCMP hashes there are 4 bits for the 4 subsets
 */
bool Flatrock::InputXbar::parse_hash(Table *t, const pair_t &kv) {
    if (kv.key.vec.size == 2 && kv.key[0] == "byte") {
        parse_hash_table(t, HashTable(HashTable::EXACT, 0), kv.value);
    } else if (kv.key.vec.size == 2 && kv.key[0] == "word") {
        parse_hash_table(t, HashTable(HashTable::EXACT, 1), kv.value);
#if 0
    } else if (kv.key.vec.size == 3 && (kv.key[0] == "lamb" || kv.key[0] == "stm")) {
        // FIXME -- do we need to specify the HashGrp or can we always figure it out
        // in the end? (we currently do this in Flatrock::InputXbar::write_regs_v)
        if (!CHECKTYPE(kv.key[2], tINT) || kv.key[2].i < 0 || kv.key[2].i > 3) return false;
        parse_hash_table(t, HashTable(HashTable::EXACT, 0), kv.value);
        if (kv.key[0] == "stm")
            // FIXME -- need to filter this to have the byte part and word part
            parse_hash_table(t, HashTable(HashTable::EXACT, 1), kv.value);
#endif
    } else if (kv.key.vec.size == 3 && kv.key[0] == "xcmp") {
        if (!CHECKTYPE(kv.key[2], tINT) || kv.key[2].i < 0 || kv.key[2].i > 3) return false;
        parse_hash_table(t, HashTable(HashTable::XCMP, kv.key[2].i), kv.value);
    } else {
        return false; }
    return true;
}

bool Flatrock::InputXbar::parse_unit(Table *t, const pair_t &kv) {
    if (kv.key[0] == "output") {
        if (CHECKTYPE(kv.value, tINT)) {
            if (kv.value.i < 0 || kv.value.i >= FIRST_STM_XMU)
                error(kv.value.lineno, "Invalid output unit %" PRId64, kv.value.i);
            output_unit = kv.value.i; }
    } else if (kv.key[0] == "exact") {
        if (CHECKTYPE2(kv.value, tINT, tVEC)) {
            if (kv.value.type == tINT) {
                if (kv.value.i < 0 || kv.value.i >= XME_UNITS)
                    error(kv.value.lineno, "Invalid exact unit %" PRId64, kv.value.i);
                else
                    xme_units[kv.value.i] = 1;
            } else {
                for (auto &v : kv.value.vec) {
                    if (CHECKTYPE(v, tINT)) {
                        if (v.i < 0 || v.i >= XME_UNITS)
                            error(v.lineno, "Invalid exact unit %" PRId64, v.i);
                        else
                            xme_units[v.i] = 1; } } } }
    } else {
        return false; }
    return true;
}

unsigned Flatrock::InputXbar::exact_physical_ids() const {
    if (xme_units.getrange(8,8)) return 0xf000;
    if (xme_units.getrange(0,8)) return 0x0f00;
    return 0xff00;
}

unsigned Flatrock::InputXbar::xmu_units() const {
    unsigned rv = 0;
    for (int i : xme_units)
        rv |= 1U << (i/2);
    return rv;
}

void Flatrock::InputXbar::pass2() {
    ::InputXbar::pass2();
}

void Flatrock::InputXbar::setup_match_key_cfg(const MatchSource *match) {
    // extend the ranges of the keys in the key_cfg to cover the specified MatchSource
    if (auto *phv = dynamic_cast<const Phv::Ref *>(match)) {
        auto sl = **phv;
        Group group(Group::EXACT, -1);
        if (auto *in = find(sl, group, &group)) {
            BUG_CHECK(group.type == Group::EXACT, "find corrupted group.type?");
            size_t lo = in->lo + sl.lo - in->what->lo;
            size_t hi = lo + sl.size() - 1;
            switch (group.index) {
            case 0:  // byte ixbar
                if (num8 == 0) {
                    first8 = lo/8;
                    num8 = hi/8 + 1 - first8;
                } else {
                    if (first8 > lo/8) {
                        num8 += first8 - lo/8;
                        first8 = lo/8; }
                    if (num8 < hi/8 + 1 - first8)
                        num8 = hi/8 + 1 - first8; }
                break;
            case 1:  // word ixbar
                if (num32 == 0) {
                    first32 = lo/32;
                    num32 = hi/32 + 1 - first32;
                } else {
                    if (first32 > lo/32) {
                        num32 += first32 - lo/32;
                        first32 = lo/32; }
                    if (num32 < hi/32 + 1 - first32)
                        num32 = hi/32 + 1 - first32; }
                break;
            default:
                BUG("invalid exact group %d", group.index); }
        } else {
            error(match->get_lineno(), "%s not available on exact ixbar in table %s",
                  match->toString().c_str(), table->name()); }
    } else if (auto *hash = dynamic_cast<const HashMatchSource *>(match)) {
        error(match->get_lineno(), "HashMatchSource not supported on flatrock");
        // up to 24 hash bits are included, so we can support it
    } else {
        BUG();
    }
}

InputXbar::Group Flatrock::InputXbar::hashtable_input_group(HashTable ht) const {
    BUG_CHECK(ht.type == HashTable::EXACT || ht.type == HashTable::XCMP,
              "invalid ht.type: %s", ht.toString().c_str());
    return Group(ht.type == HashTable::EXACT ? Group::EXACT : Group::XCMP, ht.index);
}

int Flatrock::InputXbar::find_offset(const MatchSource *ms, Group group, int off) const {
    if (auto *phv = dynamic_cast<const Phv::Ref *>(ms)) {
        auto sl = **phv;
        const Input *in = nullptr;
        if (off >= 0) {
            for (auto i : find_all(sl, group)) {
                if (i->lo + sl.lo - i->what->lo == off) {
                    in = i;
                    break; } }
        } else {
            in = find(sl, group, &group);
        }
        if (in) {
            BUG_CHECK(in->lo + sl.lo >= in->what->lo,
                      "computed invalid offset in InputXbar::find_offset");
            unsigned offset = in->lo + sl.lo - in->what->lo;
            if (group.type == Group::EXACT) {
                switch (group.index) {
                case 0:  // byte ixbar
                    BUG_CHECK(offset >= first8 * 8 && offset + sl.size() - 1 < (first8 + num8) * 8,
                              "%s not in the key_cfg", ms->toString().c_str());
                    offset += num32 * 32;
                    offset -= first8 * 8;
                    break;
                case 1:  // word ixbar
                    BUG_CHECK(offset >= first32 * 32 &&
                              offset + sl.size() - 1 < (first32 + num32) * 32,
                              "%s not in the key_cfg", ms->toString().c_str());
                    offset -= first32 * 32;
                    break;
                default:
                    BUG("invalid exact group %d", group.index); } }
            return offset; }
    } else if (auto *hash = dynamic_cast<const HashMatchSource *>(ms)) {
        error(ms->get_lineno(), "HashMatchSource not supported on flatrock");
        // up to 24 hash bits are included starting at num32*32 + num8*8, so we can support it
    } else {
        BUG();
    }
    return -1;
}

/* DANGER -- messy problem -- the dynhash code in bfnutils assumes a Tofino1 style
 * hash matrix of 16*64*52 bits, which is stored in matrix[16][52] with 64 bits in
 * each element.  We only care about column 0 (since we always map stuff there), but
 * flatrock hash functions are more than 64 bits.  So we assemble the entire 1024
 * bit column and then extract from that */
bitvec Flatrock::InputXbar::global_column0_extract(HashTable ht,
        const hash_column_t matrix[PARITY_GROUPS_DYN][HASH_MATRIX_WIDTH_DYN]) const {
    BUG_CHECK(ht.type == HashTable::EXACT, "not an exact hash table");
    bitvec column0;
    for (int i = PARITY_GROUPS_DYN-1; i >= 0; --i)
        column0.putrange(i*64, 64, matrix[i][0].column_value);
    return column0.getslice(ht.index*EXACT_HASH_SIZE, EXACT_HASH_SIZE);
}

// tables mapping PHEs to the bit indexes used for their power gating.
static unsigned short minput_byte_pwr_transpose[] = {
/*B0*/     0,   1,   2,   3,   4,   5,   6,   7,  22,  23,  24,  25,  26,  27,  28,  29,
/*B16*/   44,  45,  46,  47,  48,  49,  50,  51,  66,  67,  68,  69,  70,  71,  72,  73,
/*B32*/   88,  89,  90,  91,  92,  93,  94,  95, 110, 111, 112, 113, 114, 115, 116, 117,
/*B48*/  132, 133, 134, 135, 136, 137, 138, 139, 154, 155, 156, 157, 158, 159, 160, 161,
/*B64*/  176, 177, 178, 179, 180, 181, 182, 183, 198, 199, 200, 201, 202, 203, 204, 205,
/*B80*/    8,   9,  10,  11,  12,  13,  14,  15,  30,  31,  32,  33,  34,  35,  36,  37,
/*B96*/   52,  53,  54,  55,  56,  57,  58,  59,  74,  75,  76,  77,  78,  79,  80,  81,
/*B112*/  96,  97,  98,  99, 100, 101, 102, 103, 118, 119, 120, 121, 132, 123, 124, 125,
/*B128*/ 140, 141, 142, 143, 144, 145, 146, 147, 162, 163, 164, 165, 166, 167, 168, 169,
/*B144*/ 184, 185, 186, 187, 188, 189, 190, 191, 206, 207, 208, 209, 210, 211, 212, 213,
/*H0*/    16,  17,  18,  19,  38,  39,  40,  41,  60,  61,  62,  63,  82,  83,  84,  85,
/*H16*/  104, 105, 106, 107, 126, 127, 128, 129, 148, 149, 150, 151, 170, 171, 172, 173,
/*H32*/  192, 193, 194, 195, 214, 215, 216, 217,
/*W0*/    20,  21,  42,  43,  64,  65,  86,  87, 108, 109, 130, 131, 152, 153, 174, 175,
/*W16*/  196, 197, 218, 219 };
static unsigned short minput_word_pwr_transpose[] = {
/*B0*/     0,   0,   0,   0,   1,   1,   1,   1,   8,   8,   8,   8,   9,   9,   9,   9,
/*B16*/   16,  16,  16,  16,  17,  17,  17,  17,  24,  24,  24,  24,  25,  25,  25,  25,
/*B32*/   32,  32,  32,  32,  33,  33,  33,  33,  40,  40,  40,  40,  41,  41,  41,  41,
/*B48*/   48,  48,  48,  48,  49,  49,  49,  49,  56,  56,  56,  56,  57,  57,  57,  57,
/*B64*/   64,  64,  64,  64,  65,  65,  65,  65,  72,  72,  72,  72,  73,  73,  73,  73,
/*B80*/    2,   2,   2,   2,   3,   3,   3,   3,  10,  10,  10,  10,  11,  11,  11,  11,
/*B96*/   18,  18,  18,  18,  19,  19,  19,  19,  26,  26,  26,  26,  27,  27,  27,  27,
/*B112*/  34,  34,  34,  34,  35,  35,  35,  35,  42,  42,  42,  42,  43,  43,  43,  43,
/*B128*/  50,  50,  50,  50,  51,  51,  51,  51,  58,  58,  58,  58,  59,  59,  59,  59,
/*B144*/  66,  66,  66,  66,  67,  67,  67,  67,  74,  74,  74,  74,  75,  75,  75,  75,
/*H0*/     4,   4,   5,   5,  12,  12,  13,  13,  20,  20,  21,  21,  28,  28,  29,  29,
/*H16*/   36,  36,  37,  37,  44,  44,  45,  45,  52,  52,  53,  53,  60,  60,  61,  61,
/*H32*/   68,  68,  69,  69,  76,  76,  77,  77,
/*W0*/     6,   7,  14,  15,  22,  23,  30,  31,  38,  39,  46,  47,  54,  55,  62,  63,
/*W16*/   70,  71,  78,  79, };

template<class REG>
void Flatrock::InputXbar::setup_byte_ixbar(REG &reg, const Input &input, int offset) {
    for (int d : dconfig) {
        unsigned byte = input.lo/8U + offset;
        Phv::Slice slice = *input.what;
        for (auto i = slice.lo/8U; i <= slice.hi/8U; ++i, ++byte) {
            BUG_CHECK(slice.reg.size == 8 || ((i ^ byte) & 1) == 0,
                      "%s needs 16-bit alignment on ixbar", slice.reg.name);
            reg[byte][d].key8 = slice.reg.ixbar_id() + (i&2);
        }
    }
}

template<class REG> void Flatrock::InputXbar::setup_byte_ixbar_gw(REG &reg, const Input &input) {
    unsigned byte = input.lo/8U;
    Phv::Slice slice = *input.what;
    for (auto i = slice.lo/8U; i <= slice.hi/8U; ++i, ++byte) {
        BUG_CHECK(slice.reg.size == 8 || ((i ^ byte) & 1) == 0,
                  "%s needs 16-bit alignment on ixbar", slice.reg.name);
        reg[byte].used = 1;
        reg[byte].vgd = slice.reg.ixbar_id() + (i&2);
    }
}

void Flatrock::InputXbar::write_regs_v(Target::Flatrock::mau_regs &regs) {
    LOG1("### Input xbar " << table->name() << " write_regs " << table->loc());
    auto &minput = regs.ppu_minput;
    for (auto &group : groups) {
        switch (group.first.type) {
        case Group::EXACT: {
            auto &em_key_cfg = minput.minput_em_xb_key_erf;
            if (group.first.index) {
                auto &key32 = em_key_cfg.minput_em_xb_key32;
                for (auto &input : group.second) {
                    for (int d : dconfig)
                        key32[input.lo/32U][d].key32 = input.what->reg.ixbar_id()/4U;
                    unsigned bit = minput_word_pwr_transpose[input.what->reg.uid];
                    minput.minput_word_pwr_erf.minput_word_pwr[bit/4].data_chain1 |= 1U << (bit%4);
                    for (int x : xme_units) {
                        if (x < FIRST_STM_XME) continue;
                        minput.rf.minput_em_xb_stm_tab[(x-FIRST_STM_XME)/2].key32_used
                            |= bitRange(input.lo/32U, input.hi/32U); } }
            } else {
                auto &key8 = em_key_cfg.minput_em_xb_key8;
                for (auto &input : group.second) {
                    setup_byte_ixbar(key8, input, 0);
                    unsigned bit = minput_byte_pwr_transpose[input.what->reg.uid];
                    minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain7 |= 1U << (bit%4);
                    for (int x : xme_units)
                        minput.rf.minput_em_xb_tab[x/2].key8_used |=
                            bitRange(input.lo/8U, input.hi/8U); } }
            break; }
        case Group::TERNARY: {
            auto &scm_key_cfg = minput.minput_scm_xb_key_erf;
            auto &key8 = scm_key_cfg.minput_scm_xb_key8;
            int base = group.first.index * 5;  // first byte for the group
            for (auto &input : group.second) {
                setup_byte_ixbar(key8, input, base);
                unsigned bit = minput_byte_pwr_transpose[input.what->reg.uid];
                switch (group.first.index/4U) {
                case 0:
                    minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain2 |= 1U << (bit%4);
                    break;
                case 1:
                    minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain3 |= 1U << (bit%4);
                    break;
                case 2:
                    minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain4 |= 1U << (bit%4);
                    break;
                case 3:
                    minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain5 |= 1U << (bit%4);
                    break;
                case 4:
                    minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain6 |= 1U << (bit%4);
                    break;
                default:
                    BUG("invalid ternary group %d", group.first.index); } }
            minput.rf.minput_scm_xb_tab[table->get_tcam_id()].key40_used |= 1U << group.first.index;
            break; }
        case Group::GATEWAY: {
            auto &gw_key_cfg = minput.rf.minput_gw_xb_vgd;
            for (auto &input : group.second) {
                setup_byte_ixbar_gw(gw_key_cfg, input);
                unsigned bit = minput_byte_pwr_transpose[input.what->reg.uid];
                minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain0 |= 1U << (bit%4); }
            break; }
        case Group::XCMP: {
            auto &xcmp_key_cfg = minput.minput_xcmp_xb_key_erf;
            if (group.first.index) {
                int wgroup = group.first.index - 1;
                auto &key32 = xcmp_key_cfg.minput_xcmp_xb_key32;
                for (auto &input : group.second) {
                    for (int d : dconfig)
                        key32[wgroup*4 + input.lo/32U][d].key32 = input.what->reg.ixbar_id()/4U;
                    unsigned bit = minput_word_pwr_transpose[input.what->reg.uid];
                    minput.minput_word_pwr_erf.minput_word_pwr[bit/4].data_chain0 |= 1U << (bit%4);
                    for (auto physid : table->physical_ids) {
                        minput.rf.minput_xcmp_xb_tab[physid].key32_used |=
                            bitRange(wgroup*4 + input.lo/32U, input.hi/32U); } }
            } else {
                auto &key8 = xcmp_key_cfg.minput_xcmp_xb_key8;
                for (auto &input : group.second) {
                    setup_byte_ixbar(key8, input, 0);
                    unsigned bit = minput_byte_pwr_transpose[input.what->reg.uid];
                    minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain1 |= 1U << (bit%4);
                    for (auto physid : table->physical_ids) {
                        minput.rf.minput_xcmp_xb_tab[physid].key8_used |=
                            bitRange(input.lo/8U, input.hi/8U); } } }
            break; }
        default:
            BUG("invalid InputXbar::Group::Type(%d)", group.first.type);
        }
    }
    for (auto &hash : hash_tables) {
        switch (hash.first.type) {
        case InputXbar::HashTable::EXACT:
            switch (hash.first.index) {
            case 0: {  // exact byte hash
                unsigned byte = 0;
                for (auto &col : hash.second) {
                    for (int i = 0; i < EXACT_HASH_SIZE/32; ++i) {
                        uint32_t bits = col.second.data.getrange(i*32, 32);
                        if (!bits) continue;
                        auto &row = minput.minput_em_bhash1_erf.minput_em_bhash1[i];
                        for (auto b = 0; b < 4; ++b) {
                            if ((bits >> (b*8)) & 0xff)
                                byte |= 1 << (i*4 + b); }
                        uint32_t delta = bits & ~row[col.first].gf;
                        row[col.first].gf |= bits;
                        row[45].gf ^= delta; } }  // parity;
                int prev_xmu = -1;
                for (int xme : xme_units) {
                    int xmu = xme/2;
                    if (prev_xmu == xmu) continue;
                    auto &bhash2 = minput.minput_em_bhash2_erf.minput_em_bhash2;
                    for (unsigned shift = 0; shift < 20; shift += 4) {
                        switch (xmu) {
                        // DANGER -- for this config lambs/stms are SWAPPED (0-3 are stms
                        // and 4-7 are lambs)
                        case 0: bhash2[shift/4].data_chain4 |= (byte >> shift) & 0xf; break;
                        case 1: bhash2[shift/4].data_chain5 |= (byte >> shift) & 0xf; break;
                        case 2: bhash2[shift/4].data_chain6 |= (byte >> shift) & 0xf; break;
                        case 3: bhash2[shift/4].data_chain7 |= (byte >> shift) & 0xf; break;
                        case 4: bhash2[shift/4].data_chain0 |= (byte >> shift) & 0xf; break;
                        case 5: bhash2[shift/4].data_chain1 |= (byte >> shift) & 0xf; break;
                        case 6: bhash2[shift/4].data_chain2 |= (byte >> shift) & 0xf; break;
                        case 7: bhash2[shift/4].data_chain3 |= (byte >> shift) & 0xf; break;
                        default: BUG("invalid xmu %d", xmu); } }
                    prev_xmu = xmu; }
                break; }
            case 1: {  // exact word hash
                unsigned word = 0;
                for (auto &col : hash.second) {
                    for (int i = 0; i < EXACT_HASH_SIZE/32; ++i) {
                        uint32_t bits = col.second.data.getrange(i*32, 32);
                        if (!bits) continue;
                        auto &row = minput.minput_em_whash1_erf.minput_em_whash1[i];
                        word |= 1 << i;
                        uint32_t delta = bits & ~row[col.first].gf;
                        row[col.first].gf |= bits;
                        row[45].gf ^= delta; } }  // parity;
                int prev_xmu = -1;
                for (int xme : xme_units) {
                    if (xme < FIRST_STM_XME) continue;
                    int xmu = xme/2;
                    if (prev_xmu == xmu) continue;
                    minput.rf.minput_em_whash2[xmu-4].enable_ |= word;
                    prev_xmu = xmu; }
                break; }
            // FIXME -- xcmp hashes here?
            default:
                BUG("invalid hash table %s", hash.first.toString().c_str());
            }
            break;
        default:
            BUG("invalid hash table %s", hash.first.toString().c_str());
        }
    }
}

template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs) { write_regs_v(regs); }

void Flatrock::InputXbar::write_xmu_key_mux(Target::Flatrock::mau_regs::_ppu_eml &xmu) {
    for (int d : dconfig) {
        xmu.rf.eml_key_cfg[d].first8 = first8;
        xmu.rf.eml_key_cfg[d].num8 = num8; }
}

void Flatrock::InputXbar::write_xmu_key_mux(Target::Flatrock::mau_regs::_ppu_ems &xmu) {
    for (int d : dconfig) {
        xmu.rf.ems_key_cfg[d].first8 = first8;
        xmu.rf.ems_key_cfg[d].num8 = num8;
        xmu.rf.ems_key_cfg[d].first32 = first32;
        xmu.rf.ems_key_cfg[d].num32 = num32; }
}

// Info we need for both LAMB and STM xme config
struct Flatrock::InputXbar::xme_cfg_info_t {
    int log2_way_depth = 0;
    int subword_bits = 0;
    int set_size = 0;
    bitvec key_mask;
    int key_size = 0;
    int valid_en = 0;
    int hash_base = 0;
    bool has_direct = false;
    unsigned index_size = 0;
};

/* common code needed to gather info about a cuckoo table for both LAMB and STM */
void Flatrock::InputXbar::find_xme_info(xme_cfg_info_t &info, const SRamMatchTable::Way *way) {
    info.subword_bits = std::max(0, 7 - static_cast<int>(table->format->log2size));
    info.log2_way_depth = ceil_log2(way->rams.size());
    info.set_size = 1;
    if (auto *match = table->format->field("match")) {
        // cuckoo hash (or BPH?)
        info.set_size = table->format->groups();
        while (info.set_size > 4) {
            BUG_CHECK((info.set_size & 1) == 0,
                      "cuckoo table %s match groups not valid", table->name());
            info.set_size >>= 1;
            ++info.subword_bits; }
        for (int i = 0; i < info.set_size; ++i) {
            for (auto &br : match->by_group[i]->bits) {
                info.key_mask.setrange(br.lo, br.size());
                if (i == 0 && br.hi >= info.key_size)
                    info.key_size = br.hi+1; } }
        int shift = 64;
        for (int i = 0; i < info.subword_bits; ++i, shift >>= 1)
            info.key_mask |= info.key_mask << shift;
    } else {
        // direct match
        BUG_CHECK((table->format->groups() & (table->format->groups() - 1)) == 0,
                  "direct table %s match groups not a power of 2", table->name());
        info.subword_bits += ceil_log2(table->format->groups());
    }
    if (auto *valid = table->format->field("valid")) {
        BUG_CHECK(valid->bits.size() == 1 && valid->bits.front().size() == 1,
                  "valid is not one bit");
        BUG_CHECK(valid->bits.front().lo >= info.key_size, "valid is not after match");
        info.key_size = valid->bits.front().lo + 1;
        info.valid_en = 1; }
    BUG_CHECK(info.subword_bits == way->subword_bits, "subword bit size mismatch");
    info.hash_base = way->index;
    info.index_size = info.log2_way_depth + info.subword_bits;
    for (auto &c : table->get_calls()) {
        if (c.is_direct_call()) {
            info.has_direct = true;
            break; } }
}

void Flatrock::InputXbar::write_xme_regs(Target::Flatrock::mau_regs::_ppu_eml &xmu, int xme) {
    xme_cfg_info_t info;
    auto *mt = table->to<SRamMatchTable>();
    BUG_CHECK(mt, "%s is not an sram table", table->name());
    SRamMatchTable::Ram unit(xme);
    auto *way = mt->way_for_ram(unit);
    find_xme_info(info, way);
    int banknum = std::find(way->rams.begin(), way->rams.end(), unit) - way->rams.begin();
    for (int d : dconfig) {
        auto &addr = xmu.rf.eml_addr_cfg[xme%2U][d];
        addr.banknum = banknum;
        addr.banknum_size = info.log2_way_depth;
        addr.banknum_start = info.hash_base + LAMB_DEPTH_BITS + info.subword_bits;
        addr.base_addr = 0;   // does not seem useful?
        addr.idx_size = LAMB_DEPTH_BITS;
        addr.idx_start = info.hash_base + info.subword_bits;
        xmu.rf.eml_en_sel[xme%2U][d].en = 1;
        xmu.rf.eml_en_sel[xme%2U][d].sel = xme/2U;
        xmu.rf.eml_lamb_map[xme%2U][d].sel = output_unit;
        auto &match = xmu.rf.eml_match_cfg[xme%2U][d];
        match.bph_l1_en = 0;  // FIXME -- support BPH
        match.entries_per_set = info.set_size;
        for (int i = 0; i < 16; ++i)
            match.key_mask[i] = info.key_mask.getrange(i*8, 8);
        match.key_and_v_size = info.key_size;
        match.sets_per_word = info.subword_bits;
        match.valid_en = info.valid_en;
        auto &payload = xmu.rf.eml_payload_cfg[xme%2U][d];
        payload.action_size = table->format->overhead_size;
        payload.addon = 0;      // not clear what it is used for?
        payload.base_mask = 0;  // pass ram data (can pass key bytes, useful for?)
        payload.cuckoo_start = 0;
        if (info.has_direct) {
            payload.idx_hi = table->format->overhead_size + info.index_size - 1;
            payload.idx_lo = table->format->overhead_size;
            payload.idx_rot = table->format->overhead_size;
        } else {
            payload.idx_hi = 0;
            payload.idx_lo = 1;
            payload.idx_rot = 0;
        }
        payload.mres_en = 1;
    }
}

void Flatrock::InputXbar::write_xme_regs(Target::Flatrock::mau_regs::_ppu_ems &xmu, int xme) {
    xme_cfg_info_t info;
    auto *mt = table->to<SRamMatchTable>();
    BUG_CHECK(mt, "%s is not an sram table", table->name());
    find_xme_info(info, mt->way_for_xme(xme | FIRST_STM_XME));
    if (output_unit >= 0)
        warning(lineno, "output_unit not relevant for STM XME, will be ignored");
    for (int d : dconfig) {
        auto &addr = xmu.rf.ems_addr_cfg[xme%2U][d];
        // FIXME -- are banks useful for STM tables?  One xme can access all the rams
        addr.banknum = 0;
        addr.banknum_size = 0;
        addr.banknum_start = 0;
        addr.base_addr = 0;   // does not seem useful?
        addr.idx_sel = 0;   // not BPH -- revisit when BFH support
        addr.idx_size = SRAM_DEPTH_BITS + info.log2_way_depth;
        addr.idx_start = info.hash_base + info.subword_bits;
        addr.alt_match_type = 0;   // FIXME -- what is this for? CSR comment not clear
        addr.limit = 0xfffff;   // for non-power-2 size, ignore for now
        xmu.rf.ems_en_sel[xme%2U][d].en = 1;
        xmu.rf.ems_en_sel[xme%2U][d].sel = xme/2U;
        auto &match = xmu.rf.ems_match_cfg[xme%2U][d];
        match.bph_l1_en = 0;  // FIXME -- support BPH
        if (xme%2) {
            match.cascade_start = 1;  // per Carsten, this should be 1 for cuckoo matches?
            // FIXME -- support BPH (wide vs narrow>?)
        }
        match.entries_per_set = info.set_size;
        for (int i = 0; i < 16; ++i)
            match.key_mask[i] = info.key_mask.getrange(i*8, 8);
        match.key_and_v_size = info.key_size;
        match.l1_passthru = 0;  // FIXME -- support BPH
        match.sets_per_word = info.subword_bits;
        match.valid_en = info.valid_en;
        // FIXME -- one payload config for both XMEs in XMU -- only config once?
        auto &payload = xmu.rf.ems_payload_cfg[d];
        payload.action_size = table->format->overhead_size;
        payload.addon = 0;      // not clear what it is used for?
        payload.base_mask = 0;  // pass ram data (can pass key bytes, useful for?)
        payload.cuckoo_start = 0;
        if (info.has_direct) {
            payload.idx_hi = table->format->overhead_size + info.index_size - 1;
            payload.idx_lo = table->format->overhead_size;
            payload.idx_rot[0] = table->format->overhead_size;
        } else {
            payload.idx_hi = 0;     // insert the 'index' into the payload.
            payload.idx_lo = 1;
            payload.idx_rot[0] = 0;
        }
        payload.idx_rot[1] = 0;
        payload.idx_rot[2] = 0;
        payload.idx_sel = 0;  // FIXME -- support BPH
        payload.mres_en = 1;
        payload.way_en = 1;
    }
    // FIXME -- one ems_cfg for both XMEs in XMU -- only config once?
    auto &cfg = xmu.rf.ems_cfg;
    cfg.l1_addr_delay = 3;  // FIXME -- delay config
    cfg.l1_key_delay = 3;   // FIXME -- delay config
    cfg.l2_delay = 3;       // FIXME -- delay config
    cfg.stm_miss_allow = 0;
    cfg.xmu_delay = 0;      // FIXME -- delay config
}

void Flatrock::InputXbar::write_xmu_regs_v(Target::Flatrock::mau_regs &regs) {
    int prev_xme = -1;
    for (auto xme : xme_units) {
        bool lamb = xme < FIRST_STM_XME;
        int xmu = (xme/2U)%4U;
        if (xme/2U != prev_xme/2U) {
            if (lamb) {
                regs.ppu_minput.rf.minput_em.lamb_used |= 1U << xmu;
                write_xmu_key_mux(regs.ppu_eml[xmu]);
            } else {
                regs.ppu_minput.rf.minput_em.stm_used |= 1U << xmu;
                write_xmu_key_mux(regs.ppu_ems[xmu]); } }
        if (lamb)
            write_xme_regs(regs.ppu_eml[xmu], xme);
        else
            write_xme_regs(regs.ppu_ems[xmu], xme - FIRST_STM_XME);
        prev_xme = xme; }
}

template<>
void InputXbar::write_xmu_regs(Target::Flatrock::mau_regs &regs) { write_xmu_regs_v(regs); }

/* registers that are needed in the minput block even when the stage is being bypassed and
 * doing nothing */
void Flatrock::InputXbar::write_global_regs(Target::Flatrock::mau_regs &regs, gress_t gress) {
    auto &minput = regs.ppu_minput;
    for (auto reg : Phv::use(gress)) {
        unsigned bit = minput_byte_pwr_transpose[reg];
        minput.minput_dpreg_pwr_erf.minput_dpreg_pwr[bit/4].data_chain0 |= 1U << (bit%4); }
    // need all of bytes 0-4 to make gateways work, if if they are unusued
    for (unsigned i = 0; i < 5; ++i) {
        unsigned bit = minput_byte_pwr_transpose[i];
        minput.minput_dpreg_pwr_erf.minput_dpreg_pwr[bit/4].data_chain0 |= 1U << (bit%4);
        minput.minput_byte_pwr_erf.minput_byte_pwr[bit/4].data_chain0 |= 1U << (bit%4); }
}
