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
            return Group(Group::TERNARY, key[1].i); } }
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

bool Flatrock::InputXbar::parse_unit(Table *t, const pair_t &kv) {
    if (kv.key[0] == "output") {
        if (CHECKTYPE(kv.value, tINT)) {
            if (kv.value.i < 0 || kv.value.i >= XMU_UNITS)
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

void Flatrock::InputXbar::pass2() {
    ::InputXbar::pass2();
    // Find the range (min/max) of units used in the exact byte and word xbars.  This
    // will only be needed if this ixbar is for an exact match table, but that is ok.
    int lo[2] = { INT_MAX, INT_MAX }, hi[2] = { -1, -1 };
    for (auto &group : groups) {
        if (group.first.type != Group::EXACT) continue;
        BUG_CHECK(group.first.index < 2, "invalid exact group %d", group.first.index);
        for (auto &input : group.second) {
            if (input.lo < lo[group.first.index]) lo[group.first.index] = input.lo;
            if (input.hi > hi[group.first.index]) hi[group.first.index] = input.hi; } }
    if (hi[0] >= lo[0]) {
        first8 = lo[0]/8U;
        num8 = hi[0]/8U - first8 + 1;
    } else {
        first8 = num8 = 0; }
    if (hi[1] >= lo[1]) {
        first32 = lo[1]/32U;
        num32 = hi[1]/32U - first32 + 1;
    } else {
        first32 = num32 = 0; }
}

// tables mapping PHEs to the bit indexes used for their power gating.
static unsigned short minput_byte_pwr_transpose[] = {
/*B0*/     4,   5,   6,   7,   8,   9,  10,  11,  26,  27,  28,  29,  30,  31,  32,  33,
/*B16*/   48,  49,  50,  51,  52,  53,  54,  55,  70,  71,  72,  73,  74,  75,  76,  77,
/*B32*/   92,  93,  94,  95,  96,  97,  98,  99, 114, 115, 116, 117, 118, 119, 120, 121,
/*B48*/  136, 137, 138, 139, 140, 141, 142, 143, 158, 159, 160, 161, 162, 163, 164, 165,
/*B64*/  180, 181, 182, 183, 184, 185, 186, 187, 202, 203, 204, 205, 206, 207, 208, 209,
/*B80*/   12,  13,  14,  15,  16,  17,  18,  19,  34,  35,  36,  37,  38,  39,  40,  41,
/*B96*/   56,  57,  58,  59,  60,  61,  62,  63,  78,  79,  80,  81,  82,  83,  84,  85,
/*B112*/ 100, 101, 102, 103, 104, 105, 106, 107, 122, 123, 124, 125, 136, 127, 128, 129,
/*B128*/ 144, 145, 146, 147, 148, 149, 150, 151, 166, 167, 168, 169, 170, 171, 172, 173,
/*B144*/ 188, 189, 190, 191, 192, 193, 194, 195, 210, 211, 212, 213, 214, 215, 216, 217,
/*H0*/    20,  21,  22,  23,  42,  43,  44,  45,  64,  65,  66,  67,  86,  87,  88,  89,
/*H16*/  108, 109, 110, 111, 130, 131, 132, 133, 152, 153, 154, 155, 174, 175, 176, 177,
/*H32*/  196, 197, 198, 199, 218, 219, 220, 221,
/*W0*/    24,  25,  46,  47,  68,  69,  90,  91, 112, 113, 134, 135, 156, 157, 178, 179,
/*W16*/  200, 201, 222, 223 };
static unsigned short minput_word_pwr_transpose[] = {
/*B0*/    16,  16,  16,  16,  17,  17,  17,  17,  24,  24,  24,  24,  25,  25,  25,  25,
/*B16*/   32,  32,  32,  32,  33,  33,  33,  33,  40,  40,  40,  40,  41,  41,  41,  41,
/*B32*/   48,  48,  48,  48,  49,  49,  49,  49,  56,  56,  56,  56,  57,  57,  57,  57,
/*B48*/   64,  64,  64,  64,  65,  65,  65,  65,  72,  72,  72,  72,  73,  73,  73,  73,
/*B64*/   80,  80,  80,  80,  81,  81,  81,  81,  88,  88,  88,  88,  89,  89,  89,  89,
/*B80*/   18,  18,  18,  18,  19,  19,  19,  19,  26,  26,  26,  26,  27,  27,  27,  27,
/*B96*/   34,  34,  34,  34,  35,  35,  35,  35,  42,  42,  42,  42,  43,  43,  43,  43,
/*B112*/  50,  50,  50,  50,  51,  51,  51,  51,  58,  58,  58,  58,  59,  59,  59,  59,
/*B128*/  66,  66,  66,  66,  67,  67,  67,  67,  74,  74,  74,  74,  75,  75,  75,  75,
/*B144*/  82,  82,  82,  82,  83,  83,  83,  83,  90,  90,  90,  90,  91,  91,  91,  91,
/*H0*/    20,  20,  21,  21,  28,  28,  29,  29,  36,  36,  37,  37,  44,  44,  45,  45,
/*H16*/   52,  52,  53,  53,  60,  60,  61,  61,  68,  68,  69,  69,  76,  76,  77,  77,
/*H32*/   84,  84,  85,  85,  92,  92,  93,  93,
/*W0*/    22,  23,  30,  31,  38,  39,  46,  47,  54,  55,  62,  63,  70,  71,  78,  79,
/*W16*/   86,  87,  94,  95 };
template<class REG> static void set_bit(REG &reg, unsigned bit) {
    reg[bit/reg[0].size()] |= 1UL << (bit % reg[0].size());
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
                    set_bit(minput.minput_word_pwr[0],
                            minput_word_pwr_transpose[input.what->reg.uid]);
                    for (int x : xme_units) {
                        if (x < FIRST_STM_XME) continue;
                        minput.rf.minput_em_xb_stm_tab[(x-FIRST_STM_XME)/2].key32_used
                            |= 1U << input.lo/32U; } }
            } else {
                auto &key8 = em_key_cfg.minput_em_xb_key8;
                for (auto &input : group.second) {
                    for (int d : dconfig)
                        key8[input.lo/8U][d].key8 = input.what->reg.ixbar_id();
                    set_bit(minput.minput_byte_pwr[0],
                            minput_byte_pwr_transpose[input.what->reg.uid]);
                    for (int x : xme_units)
                        minput.rf.minput_em_xb_tab[x/2].key8_used |= 1U << input.lo/8U; } }
            break; }
        case Group::TERNARY: {
            auto &scm_key_cfg = minput.minput_scm_xb_key_erf;
            auto &key8 = scm_key_cfg.minput_scm_xb_key8;
            int base = group.first.index * 5;  // first byte for the group
            for (auto &input : group.second) {
                for (int d : dconfig)
                    key8[base + input.lo/8U][d].key8 = input.what->reg.ixbar_id();
                set_bit(minput.minput_byte_pwr[4 + group.first.index/4],
                        minput_byte_pwr_transpose[input.what->reg.uid]); }
            minput.rf.minput_scm_xb_tab[table->get_tcam_id()].key40_used |= 1U << group.first.index;
            break; }
        case Group::GATEWAY: {
            auto &gw_key_cfg = minput.rf.minput_gw_xb_vgd;
            for (auto &input : group.second) {
                gw_key_cfg[input.lo/8U].vgd = input.what->reg.ixbar_id();
                set_bit(minput.minput_byte_pwr[3],
                        minput_byte_pwr_transpose[input.what->reg.uid]); }
            break; }
        case Group::XCMP: {
            auto &xcmp_key_cfg = minput.minput_xcmp_xb_key_erf;
            if (group.first.index) {
                auto &key32 = xcmp_key_cfg.minput_xcmp_xb_key32;
                for (auto &input : group.second) {
                    for (int d : dconfig)
                        key32[input.lo/32U][d].key32 = input.what->reg.ixbar_id()/4U;
                    set_bit(minput.minput_word_pwr[1],
                            minput_word_pwr_transpose[input.what->reg.uid]); }
            } else {
                auto &key8 = xcmp_key_cfg.minput_xcmp_xb_key8;
                for (auto &input : group.second) {
                    for (int d : dconfig)
                        key8[input.lo/8U][d].key8 = input.what->reg.ixbar_id();
                    set_bit(minput.minput_byte_pwr[1],
                            minput_byte_pwr_transpose[input.what->reg.uid]); } }
            break; }
        default:
            BUG("invalid InputXbar::Group::Type(%d)", group.first.type);
        }
    }
    for (auto &hash : hash_tables) {
        switch (hash.first) {
        case 0: {  // exact byte hash
            unsigned byte = 0;
            for (auto &col : hash.second) {
                for (unsigned bit : col.second.data) {
                    unsigned b = bit % 32U;
                    auto &row = minput.minput_em_bhash1_erf.minput_em_bhash1[bit/32U];
                    byte |= 1U << (bit/8U);
                    if (!(row[col.first].gf & b)) {
                        row[45].gf ^= b;  // parity;
                        row[col.first].gf |= b; } } }
            int prev_xmu = -1;
            for (int xme : xme_units) {
                int xmu = xme/2;
                if (prev_xmu == xmu) continue;
                unsigned shift = xmu * 20;
                auto &bhash2 = minput.minput_em_bhash2_erf.minput_em_bhash2;
                bhash2[shift/32] |= (byte << (shift%32)) & 0xffffffff;
                if (shift%32 != 0)
                    bhash2[shift/32 + 1] |= byte >> (32 - shift%32);
                prev_xmu = xmu; }
            break; }
        case 1: {  // exact word hash
            unsigned word = 0;
            for (auto &col : hash.second) {
                for (unsigned bit : col.second.data) {
                    unsigned b = bit % 32U;
                    auto &row = minput.minput_em_whash1_erf.minput_em_whash1[bit/32U];
                    word |= 1U << (bit/32U);
                    if (!(row[col.first].gf & b)) {
                        row[45].gf ^= b;  // parity;
                        row[col.first].gf |= b; } } }
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
            BUG("invalid hash table %d", hash.first);
        }
    }
}

template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs) { write_regs_v(regs); }

void Flatrock::InputXbar::write_xmu_key_mux(Target::Flatrock::mau_regs::_ppu_eml &xmu) {
    for (int d : dconfig) {
        xmu.eml_key_cfg[d].first8 = first8;
        xmu.eml_key_cfg[d].num8 = num8; }
}

void Flatrock::InputXbar::write_xmu_key_mux(Target::Flatrock::mau_regs::_ppu_ems &xmu) {
    for (int d : dconfig) {
        xmu.ems_key_cfg[d].first8 = first8;
        xmu.ems_key_cfg[d].num8 = num8;
        xmu.ems_key_cfg[d].first32 = first32;
        xmu.ems_key_cfg[d].num32 = num32; }
}

void Flatrock::InputXbar::write_xme_regs(Target::Flatrock::mau_regs::_ppu_eml &xmu, int xme) {
    auto *mt = table->to<SRamMatchTable>();
    BUG_CHECK(mt, "%s is not an sram table", table->name());
    SRamMatchTable::Ram unit(xme);
    auto *way = mt->way_for_ram(unit);
    int idx = std::find(way->rams.begin(), way->rams.end(), unit) - way->rams.begin();
    int subword_bits = 0;
    int bank_bits = ceil_log2(way->rams.size());
    int set_size = 1;
    bitvec key_mask;
    int key_size = 0;
    if (auto *match = table->format->field("match")) {
        // cuckoo hash (or BPH?)
        set_size = table->format->groups();
        while (set_size > 4) {
            BUG_CHECK((set_size & 1) == 0, "cuckoo table %s match groups not valid", table->name());
            set_size >>= 1;
            ++subword_bits; }
        // FIXME -- figure out key_mask and key_size
    } else {
        // direct match
        subword_bits = ceil_log2(table->format->groups());
        BUG_CHECK(table->format->groups() == 1 << subword_bits, "direct table %s match "
                  "groups not a power of 2", table->name());
    }
    int addr_size = bank_bits + 6 + subword_bits;  // 6 is the whole lamb, but we could use less?
    int hash_base = way->group + way->subgroup*addr_size;
    for (int d : dconfig) {
        auto &addr = xmu.eml_addr_cfg[xme%2U][d];
        addr.banknum = idx;
        addr.banknum_size = bank_bits;
        addr.banknum_start = hash_base + addr_size - bank_bits;
        addr.base_addr = 0;   // does not seem useful?
        addr.idx_size = 6;
        addr.idx_start = hash_base + subword_bits;
        xmu.eml_en_sel[xme%2U][d].en = 1;
        xmu.eml_lamb_map[xme%2U][d].sel = output_unit;
        auto &match = xmu.eml_match_cfg[xme%2U][d];
        match.bph_l1_en = 0;  // FIXME -- support BPH
        match.entries_per_set = set_size;
        for (int i = 0; i < 16; ++i)
            match.key_mask[i] = key_mask.getrange(i*8, 8);
        match.key_size = key_size;
        match.sets_per_word = subword_bits;
        match.valid_en = 0;  // FIXME -- one bit valid field
        auto &payload = xmu.eml_payload_cfg[xme%2U][d];
        payload.addon = 0;      // not clear what it is used for?
        payload.base_mask = 0;  // pass ram data (can pass key bytes, useful for?)
        payload.cuckoo_start = 0;
        payload.idx_hi = 63;    // can rotate and chop the the payload if
        payload.idx_lo = 0;     // that can be useful?  align things?
        payload.idx_rot = 0;
        payload.mres_en = 1;
    }
}

void Flatrock::InputXbar::write_xme_regs(Target::Flatrock::mau_regs::_ppu_ems &xmu, int xme) {
    BUG("STM XME setup not done yet");
}

void Flatrock::InputXbar::write_xmu_regs_v(Target::Flatrock::mau_regs &regs) {
    int prev_xme = -1;
    for (auto xme : xme_units) {
        bool lamb = xme < FIRST_STM_XME;
        int xmu = (xme/2U)%4U;
        if (xme%2U != prev_xme%2U) {
            if (lamb)
                write_xmu_key_mux(regs.ppu_eml[xmu]);
            else
                write_xmu_key_mux(regs.ppu_ems[xmu]); }
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
    for (auto reg : Phv::use(gress))
        set_bit(minput.minput_byte_pwr[2], minput_byte_pwr_transpose[reg]);
    // need all of bytes 0-4 to make gatewats work, if if they are unusued
    for (unsigned i = 0; i < 5; ++i) {
        set_bit(minput.minput_byte_pwr[2], minput_byte_pwr_transpose[i]);
        set_bit(minput.minput_byte_pwr[3], minput_byte_pwr_transpose[i]); }
}
