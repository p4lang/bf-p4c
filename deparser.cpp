#include "deparser.h"
#include "phv.h"
#include "range.h"
#include "top_level.h"

Deparser Deparser::singleton_object;

Deparser::Deparser() : Section("deparser") {
    declare_registers(&inp_regs, sizeof(inp_regs),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.input_phase";
            inp_regs.emit_fieldname(out, addr, end); });
    declare_registers(&hdr_regs, sizeof(inp_regs),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.header_phase";
            hdr_regs.emit_fieldname(out, addr, end); });
}
Deparser::~Deparser() {
    undeclare_registers(&inp_regs);
    undeclare_registers(&hdr_regs);
}

struct Deparser::Intrinsic {
    gress_t     gress;
    std::string name;
    int         max;
    static std::map<std::string, Intrinsic *> all[2];
protected:
    Intrinsic(gress_t gr, const char *n, int m) : gress(gr), name(n), max(m) {
        assert(!all[gr].count(name));
        all[gress][name] = this; }
    ~Intrinsic() { all[gress].erase(name); }
public:
    virtual void setregs(Deparser *dep, std::vector<Phv::Ref> &vals) = 0;
};
std::map<std::string, Deparser::Intrinsic *> Deparser::Intrinsic::all[2];
#define INTRINSIC(GR, NAME, MAX, CODE) \
static struct INTRIN##GR##NAME : public Deparser::Intrinsic {           \
    INTRIN##GR##NAME() : Deparser::Intrinsic(GR, #NAME, MAX) {}         \
    void setregs(Deparser *dep, std::vector<Phv::Ref> &vals) { CODE; }  \
} INTRIN##GR##NAME##_singleton;
#define HIR_INTRINSIC(NAME) INTRINSIC(INGRESS, NAME, 1,                 \
    dep->hdr_regs.hir.ingr.NAME.phv = vals[0]->reg.index;               \
    dep->hdr_regs.hir.ingr.NAME.valid = 1; )
#define HER_INTRINSIC(NAME) INTRINSIC(EGRESS, NAME, 1,                  \
    dep->hdr_regs.her.egr.NAME.phv = vals[0]->reg.index;                \
    dep->hdr_regs.her.egr.NAME.valid = 1; )

INTRINSIC(INGRESS, egress_unicast_port, 1,
    dep->inp_regs.iir.main_i.egress_unicast_port.phv = vals[0]->reg.index;
    dep->inp_regs.iir.main_i.egress_unicast_port.valid = 1; )
INTRINSIC(INGRESS, copy_to_cpu, 1,
    dep->inp_regs.iir.ingr.copy_to_cpu.phv = vals[0]->reg.index;
    dep->inp_regs.iir.ingr.copy_to_cpu.valid = 1;)
INTRINSIC(INGRESS, egress_multicast_group, 2,
    int i = 0;
    for (auto &el : vals) {
        dep->hdr_regs.hir.ingr.egress_multicast_group[i].phv = el->reg.index;
        dep->hdr_regs.hir.ingr.egress_multicast_group[i++].valid = 1; } )
INTRINSIC(INGRESS, hash_lag_ecmp_mcast, 2,
    int i = 0;
    for (auto &el : vals) {
        dep->hdr_regs.hir.ingr.hash_lag_ecmp_mcast[i].phv = el->reg.index;
        dep->hdr_regs.hir.ingr.hash_lag_ecmp_mcast[i++].valid = 1; } )
HIR_INTRINSIC(copy_to_cpu_cos)
INTRINSIC(INGRESS, ingress_port_source, 1,
    dep->hdr_regs.hir.ingr.ingress_port.phv = vals[0]->reg.index;
    dep->hdr_regs.hir.ingr.ingress_port.sel = 0; )
HIR_INTRINSIC(deflect_on_drop)
HIR_INTRINSIC(meter_color)
HIR_INTRINSIC(icos)
HIR_INTRINSIC(qid)
HIR_INTRINSIC(xid)
HIR_INTRINSIC(yid)
HIR_INTRINSIC(rid)
HIR_INTRINSIC(warp)

INTRINSIC(EGRESS, egress_unicast_port, 1,
    dep->inp_regs.ier.main_e.egress_unicast_port.phv = vals[0]->reg.index;
    dep->inp_regs.ier.main_e.egress_unicast_port.valid = 1; )
HER_INTRINSIC(force_tx_err)
HER_INTRINSIC(tx_pkt_has_offsets)
HER_INTRINSIC(capture_tx_ts)
HER_INTRINSIC(coal)
HER_INTRINSIC(ecos)

void Deparser::start(int lineno, VECTOR(value_t) args) {
    if (args.size == 0) {
        this->lineno[INGRESS] = this->lineno[EGRESS] = lineno;
        return; }
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress"))
        error(lineno, "parser must specify ingress or egress");
    gress_t gress = args[0] == "egress" ? EGRESS : INGRESS;
    if (!this->lineno[gress]) this->lineno[gress] = lineno;
}
void Deparser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (args.size > 0) {
            if (args[0] == "ingress" && gress != INGRESS) continue;
            if (args[0] == "egress" && gress != EGRESS) continue;
        } else if (error_count > 0)
            break;
        for (auto &kv : MapIterChecked(data.map, true)) {
            if (kv.key == "dictionary") {
                if (!CHECKTYPE(kv.value, tMAP)) continue;
                for (auto &ent : kv.value.map)
                    dictionary[gress].emplace_back(RefOrChksum(gress, ent.key),
                                                   Phv::Ref(gress, ent.value));
            } else if (kv.key == "pov") {
                if (!CHECKTYPE(kv.value, tVEC)) continue;
                for (auto &ent : kv.value.vec)
                    pov_order[gress].emplace_back(gress, ent);
            } else if (kv.key == "learning" && (gress == INGRESS || args.size == 0)) {
                if (gress != INGRESS) continue;
                if (!CHECKTYPE(kv.value, tMAP)) continue;
                for (auto &l : kv.value.map) {
                    if (l.key == "select")
                        learn.select = Phv::Ref(gress, l.value);
                    else if (!CHECKTYPE(l.key, tINT))
                        continue;
                    else if (l.key.i < 0 || l.key.i >= DEPARSER_LEARN_GROUPS)
                        error(l.key.lineno, "Learning index %d out of range", l.key.i);
                    else if (l.value.type != tVEC)
                        learn.layout[l.key.i].emplace_back(gress, l.value);
                    else for (auto &v : l.value.vec)
                        learn.layout[l.key.i].emplace_back(gress, v); }
                if (!learn.select)
                    error(kv.value.lineno, "No select key in leanring spec");
            } else if (kv.key == "checksum") {
                if (kv.key.type != tCMD || kv.key.vec.size != 2 || kv.key[1].type != tINT ||
                    kv.key[1].i < 0 || kv.key[1].i >= DEPARSER_CHECKSUM_UNITS)
                    error(kv.key.lineno, "Invalid checksum unit number");
                else if (CHECKTYPE(kv.value, tVEC)) {
                    int unit = kv.key[1].i;
                    for (auto &ent : kv.value.vec)
                        checksum[gress][unit].emplace_back(gress, ent); }
            } else if (auto *intrin = ::get(Intrinsic::all[gress], value_desc(&kv.key))) {
                intrinsics.emplace_back(intrin, std::vector<Phv::Ref>());
                std::vector<Phv::Ref> &vec = intrinsics.back().second;
                if (kv.value.type == tVEC)
                    for (auto &val : kv.value.vec)
                        vec.emplace_back(gress, val);
                else
                    vec.emplace_back(gress, kv.value);
            } else
                error(kv.key.lineno, "Unknown deparser tag %s", value_desc(&kv.key));
        }
    }
}
void Deparser::process() {
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        for (auto &ent : pov_order[gress])
            if (ent.check())
                phv_use[gress][ent->reg.index] = 1;
        for (auto &ent : dictionary[gress]) {
            if (ent.first.check()) {
                phv_use[gress][ent.first->reg.index] = 1;
                if (ent.first->lo != 0 || ent.first->hi != ent.first->reg.size - 1)
                    error(ent.first.lineno, "Can only output full phv registers, not slices, "
                          "in deparser"); }
            if (ent.second.check()) {
                phv_use[gress][ent.second->reg.index] = 1;
                if (ent.second->lo != ent.second->hi)
                    error(ent.second.lineno, "POV bits should be single bits"); } }
        for (int i = 0; i < DEPARSER_CHECKSUM_UNITS; i++)
            for (auto &ent : checksum[gress][i])
                if (ent.check() && (ent->lo != 0 || ent->hi != ent->reg.size - 1))
                    error(ent.lineno, "Can only do checksums on full phv registers, not slices"); }
    for (auto &intrin : intrinsics) {
        for (auto &el : intrin.second)
            el.check();
        if (intrin.second.size() > (size_t)intrin.first->max)
            error(intrin.second[0].lineno, "Too many values for %s", intrin.first->name.c_str()); }
    if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
        error(lineno[INGRESS], "Registers used in both ingress and egress in deparser: %s",
              Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str());
    if (options.match_compiler) {
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
    if (learn.select) {
        learn.select.check();
        for (auto &set : learn.layout)
            for (auto &reg : set.second)
                reg.check(); }
}

static short phv2cksum[NUM_PHV_REGS][2] = {
    {287, 286}, {283, 282}, {279, 278}, {275, 274}, {271, 270}, {267, 266}, {263, 262}, {259, 258},
    {255, 254}, {251, 250}, {247, 246}, {243, 242}, {239, 238}, {235, 234}, {231, 230}, {227, 226},
    {223, 222}, {219, 218}, {215, 214}, {211, 210}, {207, 206}, {203, 202}, {199, 198}, {195, 194},
    {191, 190}, {187, 186}, {183, 182}, {179, 178}, {175, 174}, {171, 170}, {167, 166}, {163, 162},
    {285, 284}, {281, 280}, {277, 276}, {273, 272}, {269, 268}, {265, 264}, {261, 260}, {257, 256},
    {253, 252}, {249, 248}, {245, 244}, {241, 240}, {237, 236}, {233, 232}, {229, 228}, {225, 224},
    {221, 220}, {217, 216}, {213, 212}, {209, 208}, {205, 204}, {201, 200}, {197, 196}, {193, 192},
    {189, 188}, {185, 184}, {181, 180}, {177, 176}, {173, 172}, {169, 168}, {165, 164}, {161, 160},
    {147,  -1}, {145,  -1}, {143,  -1}, {141,  -1}, {127,  -1}, {125,  -1}, {123,  -1}, {121,  -1},
    {107,  -1}, {105,  -1}, {103,  -1}, {101,  -1}, { 87,  -1}, { 85,  -1}, { 83,  -1}, { 81,  -1},
    { 67,  -1}, { 65,  -1}, { 63,  -1}, { 61,  -1}, { 47,  -1}, { 45,  -1}, { 43,  -1}, { 41,  -1},
    { 27,  -1}, { 25,  -1}, { 23,  -1}, { 21,  -1}, {  7,  -1}, {  5,  -1}, {  3,  -1}, {  1,  -1},
    {146,  -1}, {144,  -1}, {142,  -1}, {140,  -1}, {126,  -1}, {124,  -1}, {122,  -1}, {120,  -1},
    {106,  -1}, {104,  -1}, {102,  -1}, {100,  -1}, { 86,  -1}, { 84,  -1}, { 82,  -1}, { 80,  -1},
    { 66,  -1}, { 64,  -1}, { 62,  -1}, { 60,  -1}, { 46,  -1}, { 44,  -1}, { 42,  -1}, { 40,  -1},
    { 26,  -1}, { 24,  -1}, { 22,  -1}, { 20,  -1}, {  6,  -1}, {  4,  -1}, {  2,  -1}, {  0,  -1},
    {159,  -1}, {157,  -1}, {155,  -1}, {153,  -1}, {151,  -1}, {149,  -1}, {139,  -1}, {137,  -1},
    {135,  -1}, {133,  -1}, {131,  -1}, {129,  -1}, {119,  -1}, {117,  -1}, {115,  -1}, {113,  -1},
    {111,  -1}, {109,  -1}, { 99,  -1}, { 97,  -1}, { 95,  -1}, { 93,  -1}, { 91,  -1}, { 89,  -1},
    { 79,  -1}, { 77,  -1}, { 75,  -1}, { 73,  -1}, { 71,  -1}, { 69,  -1}, { 59,  -1}, { 57,  -1},
    { 55,  -1}, { 53,  -1}, { 51,  -1}, { 49,  -1}, { 39,  -1}, { 37,  -1}, { 35,  -1}, { 33,  -1},
    { 31,  -1}, { 29,  -1}, { 19,  -1}, { 17,  -1}, { 15,  -1}, { 13,  -1}, { 11,  -1}, {  9,  -1},
    {158,  -1}, {156,  -1}, {154,  -1}, {152,  -1}, {150,  -1}, {148,  -1}, {138,  -1}, {136,  -1},
    {134,  -1}, {132,  -1}, {130,  -1}, {128,  -1}, {118,  -1}, {116,  -1}, {114,  -1}, {112,  -1},
    {110,  -1}, {108,  -1}, { 98,  -1}, { 96,  -1}, { 94,  -1}, { 92,  -1}, { 90,  -1}, { 88,  -1},
    { 78,  -1}, { 76,  -1}, { 74,  -1}, { 72,  -1}, { 70,  -1}, { 68,  -1}, { 58,  -1}, { 56,  -1},
    { 54,  -1}, { 52,  -1}, { 50,  -1}, { 48,  -1}, { 38,  -1}, { 36,  -1}, { 34,  -1}, { 32,  -1},
    { 30,  -1}, { 28,  -1}, { 18,  -1}, { 16,  -1}, { 14,  -1}, { 12,  -1}, { 10,  -1}, {  8,  -1},

    { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1},
    { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1},
    { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1},
    { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1}, { -1,  -1},

    /* TODO rewrite tagalong mappings once they're given to us by the HW team */
    {  0,   1}, {  2,   3}, {  4,   5}, {  6,   7}, {  8,   9}, { 10,  11}, { 12,  13}, { 14,  15},
    { 16,  17}, { 18,  19}, { 20,  21}, { 22,  23}, { 24,  25}, { 26,  27}, { 28,  29}, { 30,  31},
    { 32,  33}, { 34,  35}, { 36,  37}, { 38,  39}, { 40,  41}, { 42,  43}, { 44,  45}, { 46,  47},
    { 48,  49}, { 50,  51}, { 52,  53}, { 54,  55}, { 56,  57}, { 58,  59}, { 60,  61}, { 62,  63},
    { 64,  -1}, { 65,  -1}, { 66,  -1}, { 67,  -1}, { 68,  -1}, { 69,  -1}, { 70,  -1}, { 71,  -1},
    { 72,  -1}, { 73,  -1}, { 74,  -1}, { 75,  -1}, { 76,  -1}, { 77,  -1}, { 78,  -1}, { 79,  -1},
    { 80,  -1}, { 81,  -1}, { 82,  -1}, { 83,  -1}, { 84,  -1}, { 85,  -1}, { 86,  -1}, { 87,  -1},
    { 88,  -1}, { 89,  -1}, { 90,  -1}, { 91,  -1}, { 92,  -1}, { 93,  -1}, { 94,  -1}, { 95,  -1},
    { 96,  -1}, { 97,  -1}, { 98,  -1}, { 99,  -1}, {100,  -1}, {101,  -1}, {102,  -1}, {103,  -1},
    {104,  -1}, {105,  -1}, {106,  -1}, {107,  -1}, {108,  -1}, {109,  -1}, {110,  -1}, {111,  -1},
    {112,  -1}, {113,  -1}, {114,  -1}, {115,  -1}, {116,  -1}, {117,  -1}, {118,  -1}, {119,  -1},
    {120,  -1}, {121,  -1}, {122,  -1}, {123,  -1}, {124,  -1}, {125,  -1}, {126,  -1}, {127,  -1},
    {128,  -1}, {129,  -1}, {130,  -1}, {131,  -1}, {132,  -1}, {133,  -1}, {134,  -1}, {135,  -1},
    {136,  -1}, {137,  -1}, {138,  -1}, {139,  -1}, {140,  -1}, {141,  -1}, {142,  -1}, {143,  -1}
};

template<typename IPO, typename HPO> static
void dump_checksum_units(checked_array_base<IPO> &main_csum_units,
                         checked_array_base<HPO> &tagalong_csum_units,
                         std::vector<Phv::Ref> checksum[DEPARSER_CHECKSUM_UNITS])
{
    assert(phv2cksum[NUM_PHV_REGS-1][0] == 143);
    for (int i = 0; i < DEPARSER_CHECKSUM_UNITS; i++) {
        if (checksum[i].empty()) continue;
        auto &main_unit = main_csum_units[i].csum_cfg_entry;
        auto &tagalong_unit = tagalong_csum_units[i].csum_cfg_entry;
        for (auto &ent : main_unit) {
            ent.zero_l_s_b = 1;
            ent.zero_l_s_b.rewrite();
            ent.zero_m_s_b = 1;
            ent.zero_m_s_b.rewrite(); }
        for (auto &ent : tagalong_unit) {
            ent.zero_l_s_b = 1;
            ent.zero_l_s_b.rewrite();
            ent.zero_m_s_b = 1;
            ent.zero_m_s_b.rewrite(); }
        int polarity = 0;
        for (auto &reg : checksum[i]) {
            int idx = reg->reg.index;
            assert(phv2cksum[idx][0] >= 0);
            if (reg->reg.size == 8)
                polarity ^= 1;
            if (idx >= 256) {
                tagalong_unit[phv2cksum[idx][0]].zero_l_s_b = 0;
                tagalong_unit[phv2cksum[idx][0]].zero_m_s_b = 0;
                tagalong_unit[phv2cksum[idx][0]].swap = polarity;
                if (phv2cksum[idx][1] >= 0) {
                    tagalong_unit[phv2cksum[idx][1]].zero_l_s_b = 0;
                    tagalong_unit[phv2cksum[idx][1]].zero_m_s_b = 0;
                    tagalong_unit[phv2cksum[idx][1]].swap = polarity; }
            } else {
                main_unit[phv2cksum[idx][0]].zero_l_s_b = 0;
                main_unit[phv2cksum[idx][0]].zero_m_s_b = 0;
                main_unit[phv2cksum[idx][0]].swap = polarity;
                if (phv2cksum[idx][1] >= 0) {
                    main_unit[phv2cksum[idx][1]].zero_l_s_b = 0;
                    main_unit[phv2cksum[idx][1]].zero_m_s_b = 0;
                    main_unit[phv2cksum[idx][1]].swap = polarity; } } } }
}

void dump_field_dictionary(checked_array_base<fde_pov> &fde_control,
                           checked_array_base<fde_phv> &fde_data,
                           checked_array_base<ubits<8>> &pov_layout,
                           std::vector<Phv::Ref> &pov_order,
                           std::vector<std::pair<Deparser::RefOrChksum, Phv::Ref>> &dict)
{
    std::map<unsigned, unsigned>        pov;
    unsigned pov_byte = 0, pov_size = 0;
    for (auto &ent : pov_order)
        if (pov.count(ent->reg.index) == 0) {
            pov[ent->reg.index] = pov_size;
            pov_size += ent->reg.size;
            for (unsigned i = 0; i < ent->reg.size; i += 8) {
                if (pov_byte >= DEPARSER_MAX_POV_BYTES) {
                    error(ent.lineno, "Ran out of space in POV in deparser");
                    return; }
                pov_layout[pov_byte++] = ent->reg.index; } }
    for (auto &ent : dict)
        if (pov.count(ent.second->reg.index) == 0) {
            pov[ent.second->reg.index] = pov_size;
            pov_size += ent.second->reg.size;
            for (unsigned i = 0; i < ent.second->reg.size; i += 8) {
                if (pov_byte >= DEPARSER_MAX_POV_BYTES) {
                    error(ent.second.lineno, "Ran out of space in POV in deparser");
                    return; }
                pov_layout[pov_byte++] = ent.second->reg.index; } }
    while (pov_byte < DEPARSER_MAX_POV_BYTES)
        pov_layout[pov_byte++] = 0xff;

    int row = -1, prev_pov = -1;
    bool prev_is_checksum = false;
    unsigned pos = 0;
    for (auto &ent : dict) {
        unsigned size = ent.first->reg.size/8;
        int pov_bit = pov[ent.second->reg.index] + ent.second->lo;
        if (options.match_compiler) {
            if (ent.first->reg.index >= 224 && ent.first->reg.index < 236) {
                /* checksum unit -- make sure it gets its own dictionary line */
                prev_pov = -1;
                prev_is_checksum = true;
            } else {
                if (prev_is_checksum) prev_pov = -1;
                prev_is_checksum = false; } }
        while (size--) {
            if (pov_bit != prev_pov || pos >= 4 /*|| (pos & (size-1)) != 0*/) {
                if (row >= 0) {
                    fde_control[row].num_bytes = pos & 3;
                    fde_data[row].num_bytes = pos & 3; }
                if (row >= DEPARSER_MAX_FD_ENTRIES) {
                    error(ent.first.lineno, "Ran out of space in field dictionary");
                    return; }
                fde_control[++row].pov_sel = pov_bit;
                fde_control[row].version = 0xf;
                fde_control[row].valid = 1;
                pos = 0; }
            fde_data[row].phv[pos++] = ent.first->reg.index;
            prev_pov = pov_bit; } }
    if (pos) {
        fde_control[row].num_bytes = pos & 3;
        fde_data[row].num_bytes = pos & 3; }
}

void Deparser::output() {
    if (dictionary[INGRESS].empty() && dictionary[EGRESS].empty())
        return;
    inp_regs.icr.inp_cfg.disable();
    inp_regs.icr.intr.disable();
    hdr_regs.hem.he_edf_cfg.disable();
    hdr_regs.him.hi_edf_cfg.disable();
    dump_checksum_units(inp_regs.iim.ii_phv_csum.csum_cfg, hdr_regs.him.hi_tphv_csum.csum_cfg,
                        checksum[INGRESS]);
    dump_checksum_units(inp_regs.iem.ie_phv_csum.csum_cfg, hdr_regs.hem.he_tphv_csum.csum_cfg,
                        checksum[EGRESS]);
    dump_field_dictionary(inp_regs.iim.ii_fde_pov.fde_pov, hdr_regs.him.hi_fde_phv.fde_phv,
        inp_regs.iir.main_i.pov.phvs, pov_order[INGRESS], dictionary[INGRESS]);
    dump_field_dictionary(inp_regs.iem.ie_fde_pov.fde_pov, hdr_regs.hem.he_fde_phv.fde_phv,
        inp_regs.ier.main_e.pov.phvs, pov_order[EGRESS], dictionary[EGRESS]);

    if (options.match_compiler) {
        phv_use[INGRESS] |= Phv::use(INGRESS);
        phv_use[EGRESS] |= Phv::use(EGRESS);
        if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
            error(lineno[INGRESS], "Registers used in both ingress and egress in phv: %s",
                  Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str()); }
    for (unsigned i = 0; i < 7; i++) {
        /* FIXME -- should use the registers used by ingress here, but to match compiler
         * FIXME -- output we instead use registers not used by egress */
        inp_regs.iir.ingr.phv.in_ingress_thread[i] =
            phv_use[EGRESS].getrange(i*32, 32) ^ 0xffffffff;
        inp_regs.ier.egr.phv.in_egress_thread[i] = phv_use[EGRESS].getrange(i*32, 32); }
    for (unsigned i = 0; i < 8; i++) {
        if (phv_use[EGRESS].intersects(Phv::tagalong_groups[i])) {
            inp_regs.icr.tphv_cfg.i_e_assign |= 1 << i;
            if (phv_use[INGRESS].intersects(Phv::tagalong_groups[i])) {
                error(lineno[INGRESS], "tagalong group %d used in both ingress and "
                      "egress deparser", i); } } }

    for (auto &intrin : intrinsics)
        intrin.first->setregs(this, intrin.second);
    if (!hdr_regs.hir.ingr.ingress_port.sel.modified())
        hdr_regs.hir.ingr.ingress_port.sel = 1;

    if (learn.select) {
        inp_regs.iir.ingr.learn_cfg.phv = learn.select->reg.index;
        inp_regs.iir.ingr.learn_cfg.valid = 1;
        for (auto &set : learn.layout) {
            int idx = 0;
            for (auto &reg : set.second)
                for (int i = reg->reg.size/8; i > 0; i--)
                    inp_regs.iir.ingr.learn_tbl[set.first].phvs[idx++] = reg->reg.index;
            inp_regs.iir.ingr.learn_tbl[set.first].valid = 1;
            inp_regs.iir.ingr.learn_tbl[set.first].len = idx; } }

    inp_regs.emit_json(*open_output("regs.all.deparser.input_phase.cfg.json"));
    hdr_regs.emit_json(*open_output("regs.all.deparser.header_phase.cfg.json"));
    TopLevel::all.reg_pipe.deparser.hdr = "regs.all.deparser.header_phase";
    TopLevel::all.reg_pipe.deparser.inp = "regs.all.deparser.input_phase";
}

bool Deparser::RefOrChksum::check() const {
    if (name_ == "checksum") {
        if (lo != hi || lo < 0 || lo >= DEPARSER_CHECKSUM_UNITS) {
            error(lineno, "Invalid checksum unit number");
            return false; }
        return true; }
    return Phv::Ref::check();
}

Phv::Register Deparser::RefOrChksum::checksum_units[12] = {
    { 224, 16 }, { 225, 16 }, { 226, 16 }, { 227, 16 }, { 228, 16 }, { 229, 16 },
    { 230, 16 }, { 231, 16 }, { 232, 16 }, { 233, 16 }, { 234, 16 }, { 235, 16 } };

Phv::Slice Deparser::RefOrChksum::operator *() const {
    if (name_ == "checksum") {
        if (lo != hi || lo < 0 || lo >= DEPARSER_CHECKSUM_UNITS) {
            error(lineno, "Invalid checksum unit number");
            return Phv::Slice(); }
        return Phv::Slice(checksum_units[gress*DEPARSER_CHECKSUM_UNITS+lo], 0, 15); }
    return Phv::Ref::operator*();
}
