#include "input_xbar.h"
#include "tables.h"

int Flatrock::InputXbar::group_max_index(Group::type_t t) const {
    switch (t) {
    case Group::EXACT:   return 2;
    case Group::TERNARY: return 16;
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
    if (kv.key[0] != "exact") return false;
    if (CHECKTYPE2(kv.value, tINT, tVEC)) {
        if (kv.value.type == tINT) {
            if (kv.value.i < 0 || kv.value.i >= XMU_UNITS)
                error(kv.value.lineno, "Invalid exact unit %" PRId64, kv.value.i);
            else
                xmu_units[kv.value.i] = 1;
        } else {
            for (auto &v : kv.value.vec) {
                if (CHECKTYPE(v, tINT)) {
                    if (v.i < 0 || v.i >= XMU_UNITS)
                        error(v.lineno, "Invalid exact unit %" PRId64, v.i);
                    else
                        xmu_units[v.i] = 1; } } } }
    return true;
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
    bitvec dconfig(0, 4);  // default dconfig -- program all 4
    auto &minput = regs.ppu_minput_rspec;
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
                    for (int x : xmu_units)
                        minput.rf.minput_em_xb_stm_tab[x].key32_used |= 1U << input.lo/32U; }
            } else {
                auto &key8 = em_key_cfg.minput_em_xb_key8;
                for (auto &input : group.second) {
                    for (int d : dconfig)
                        key8[input.lo/8U][d].key8 = input.what->reg.ixbar_id();
                    set_bit(minput.minput_byte_pwr[0],
                            minput_byte_pwr_transpose[input.what->reg.uid]);
                    for (int x : xmu_units)
                        minput.rf.minput_em_xb_tab[x].key8_used |= 1U << input.lo/8U; } }
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
            auto &gw_key_cfg = minput.rf.minput_gw_xb_vdg;
            for (auto &input : group.second) {
                gw_key_cfg.vgd[input.lo/8U] = input.what->reg.ixbar_id();
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
}

template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs) { write_regs_v(regs); }
