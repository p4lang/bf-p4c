#include <config.h>

#include "deparser.h"
#include "phv.h"
#include "range.h"
#include "target.h"
#include "top_level.h"

Deparser Deparser::singleton_object;

Deparser::Deparser() : Section("deparser") { }
Deparser::~Deparser() { }

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
#define VIRTUAL_TARGET_METHODS(ETAG, TTYPE) \
    virtual void setregs(TTYPE::deparser_regs &regs, std::vector<Phv::Ref> &vals) = 0;
    FOR_ALL_TARGETS(VIRTUAL_TARGET_METHODS)
#undef VIRTUAL_TARGET_METHODS
};

#if HAVE_JBAY
#define INTRINSIC_SET_REGS \
    void setregs(Target::Tofino::deparser_regs &regs, std::vector<Phv::Ref> &vals) {    \
        setregs<Target::Tofino::deparser_regs>(regs, vals); }                           \
    void setregs(Target::JBay::deparser_regs &regs, std::vector<Phv::Ref> &vals) {      \
        /*setregs<Target::JBay::deparser_regs>(regs, vals);*/ assert(0); }
#else
#define INTRINSIC_SET_REGS \
    void setregs(Target::Tofino::deparser_regs &regs, std::vector<Phv::Ref> &vals) {    \
        setregs<Target::Tofino::deparser_regs>(regs, vals); }
#endif // HAVE_JBAY

std::map<std::string, Deparser::Intrinsic *> Deparser::Intrinsic::all[2];
#define INTRINSIC(GR, NAME, MAX, CODE) \
static struct INTRIN##GR##NAME : public Deparser::Intrinsic {           \
    INTRIN##GR##NAME() : Deparser::Intrinsic(GR, #NAME, MAX) {}         \
    template<class REGS> void setregs(REGS &regs, std::vector<Phv::Ref> &vals) { CODE; }  \
    INTRINSIC_SET_REGS                                                  \
} INTRIN##GR##NAME##_singleton;
#define YES(X)  X
#define NO(X)
#define SIMPLE_INTRINSIC(GR, PFX, NAME, IF_SHIFT) INTRINSIC(GR, NAME, 1,\
    PFX.NAME.phv = vals[0]->reg.index;                                  \
    IF_SHIFT( PFX.NAME.shft = vals[0]->lo; )                            \
    PFX.NAME.valid = 1; )
#define IIR_MAIN_INTRINSIC(NAME, SHFT) SIMPLE_INTRINSIC(INGRESS, regs.input.iir.main_i, NAME, SHFT)
#define IIR_INTRINSIC(NAME, SHFT)      SIMPLE_INTRINSIC(INGRESS, regs.input.iir.ingr, NAME, SHFT)
#define HIR_INTRINSIC(NAME, SHFT)      SIMPLE_INTRINSIC(INGRESS, regs.header.hir.ingr, NAME, SHFT)
#define IER_MAIN_INTRINSIC(NAME, SHFT) SIMPLE_INTRINSIC(EGRESS, regs.input.ier.main_e, NAME, SHFT)
#define HER_INTRINSIC(NAME, SHFT)      SIMPLE_INTRINSIC(EGRESS, regs.header.her.egr, NAME, SHFT)

IIR_MAIN_INTRINSIC(egress_unicast_port, NO)
IIR_MAIN_INTRINSIC(drop_ctl, YES)
IIR_INTRINSIC(copy_to_cpu, YES)
INTRINSIC(INGRESS, egress_multicast_group, 2,
    int i = 0;
    for (auto &el : vals) {
        regs.header.hir.ingr.egress_multicast_group[i].phv = el->reg.index;
        regs.header.hir.ingr.egress_multicast_group[i++].valid = 1; } )
INTRINSIC(INGRESS, hash_lag_ecmp_mcast, 2,
    int i = 0;
    for (auto &el : vals) {
        regs.header.hir.ingr.hash_lag_ecmp_mcast[i].phv = el->reg.index;
        regs.header.hir.ingr.hash_lag_ecmp_mcast[i++].valid = 1; } )
HIR_INTRINSIC(copy_to_cpu_cos, YES)
INTRINSIC(INGRESS, ingress_port_source, 1,
    regs.header.hir.ingr.ingress_port.phv = vals[0]->reg.index;
    regs.header.hir.ingr.ingress_port.sel = 0; )
HIR_INTRINSIC(deflect_on_drop, YES)
HIR_INTRINSIC(meter_color, YES)
HIR_INTRINSIC(icos, YES)
HIR_INTRINSIC(qid, YES)
HIR_INTRINSIC(xid, NO)
HIR_INTRINSIC(yid, NO)
HIR_INTRINSIC(rid, NO)
HIR_INTRINSIC(bypss_egr, YES)
HIR_INTRINSIC(ct_disable, YES)
HIR_INTRINSIC(ct_mcast, YES)

IER_MAIN_INTRINSIC(egress_unicast_port, NO)
IER_MAIN_INTRINSIC(drop_ctl, YES)
HER_INTRINSIC(force_tx_err, YES)
HER_INTRINSIC(tx_pkt_has_offsets, YES)
HER_INTRINSIC(capture_tx_ts, YES)
HER_INTRINSIC(coal, NO)
HER_INTRINSIC(ecos, YES)

struct Deparser::Digest::Type {
    gress_t     gress;
    std::string name;
    int         count;
    bool        can_shift = false;
    static std::map<std::string, Type *> all[2];
protected:
    Type(gress_t gr, const char *n, int cnt) : gress(gr), name(n), count(cnt) {
        assert(!all[gress].count(name)); all[gress][name] = this; }
    ~Type() { all[gress].erase(name); }
public:
#define VIRTUAL_TARGET_METHODS(ETAG, TTYPE) \
    virtual void setregs(TTYPE::deparser_regs &regs, Deparser::Digest &data) = 0;
    FOR_ALL_TARGETS(VIRTUAL_TARGET_METHODS)
#undef VIRTUAL_TARGET_METHODS
};
Deparser::Digest::Digest(Deparser::Digest::Type *t, int lineno, VECTOR(pair_t) &data) {
    type = t;
    for (auto &l : data) {
        if (l.key == "select")
            select = Phv::Ref(t->gress, l.value);
        else if (t->can_shift && l.key == "shift") {
            if (CHECKTYPE(l.value, tINT))
                shift = l.value.i;
        } else if (!CHECKTYPE(l.key, tINT))
            continue;
        else if (l.key.i < 0 || l.key.i >= t->count)
            error(l.key.lineno, "%s index %d out of range", t->name.c_str(), l.key.i);
        else if (l.value.type != tVEC)
            layout[l.key.i].emplace_back(t->gress, l.value);
        else for (auto &v : l.value.vec)
            layout[l.key.i].emplace_back(t->gress, v); }
    if (!select)
        error(lineno, "No select key in %s spec", t->name.c_str());
}

#if HAVE_JBAY
#define DIGEST_SET_REGS \
    void setregs(Target::Tofino::deparser_regs &regs, Deparser::Digest &data) { \
        setregs<Target::Tofino::deparser_regs>(regs, data); }                   \
    void setregs(Target::JBay::deparser_regs &regs, Deparser::Digest &data) {   \
        /*setregs<Target::JBay::deparser_regs>(regs, data);*/ assert(0); }
#else
#define DIGEST_SET_REGS \
    void setregs(Target::Tofino::deparser_regs &regs, Deparser::Digest &data) { \
        setregs<Target::Tofino::deparser_regs>(regs, data); }
#endif // HAVE_JBAY

std::map<std::string, Deparser::Digest::Type *> Deparser::Digest::Type::all[2];
#define DIGEST(GRESS, NAME, CFG, TBL, IFSHIFT, IFID, CNT)                       \
struct GRESS##NAME##Digest : public Deparser::Digest::Type {                    \
    GRESS##NAME##Digest() : Deparser::Digest::Type(GRESS, #NAME, CNT) {         \
        IFSHIFT( can_shift = true; ) }                                          \
    template<class REGS> void setregs(REGS &regs, Deparser::Digest &data) {     \
        CFG.phv = data.select->reg.index;                                       \
        IFSHIFT( CFG.shft = data.shift + data.select->lo; )                     \
        CFG.valid = 1;                                                          \
        for (auto &set : data.layout) {                                         \
            int id = set.first >> data.shift;                                   \
            int idx = 0;                                                        \
            bool first = true;                                                  \
            for (auto &reg : set.second) {                                      \
                if (first) {                                                    \
                    first = false;                                              \
                    IFID( TBL[id].id_phv = reg->reg.index; continue; ) }        \
                for (int i = reg->reg.size/8; i > 0; i--)                       \
                    TBL[id].phvs[idx++] = reg->reg.index; }                     \
            TBL[id].valid = 1;                                                  \
            TBL[id].len = idx; } }                                              \
         DIGEST_SET_REGS                                                        \
} GRESS##NAME##Digest_singleton;
#define YES(X)        X
#define NO(X)

DIGEST(INGRESS, learning, regs.input.iir.ingr.learn_cfg, regs.input.iir.ingr.learn_tbl, NO, NO, 8)
DIGEST(INGRESS, mirror, regs.header.hir.main_i.mirror_cfg, regs.header.hir.main_i.mirror_tbl, YES, YES, 8)
DIGEST(EGRESS, mirror, regs.header.her.main_e.mirror_cfg, regs.header.her.main_e.mirror_tbl, YES, YES, 8)
DIGEST(INGRESS, resubmit, regs.input.iir.ingr.resub_cfg, regs.input.iir.ingr.resub_tbl, YES, NO, 8)

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
                if (kv.value.type == tVEC && kv.value.vec.size == 0) continue;
                collapse_list_of_maps(kv.value);
                if (!CHECKTYPE(kv.value, tMAP)) continue;
                for (auto &ent : kv.value.map)
                    dictionary[gress].emplace_back(RefOrChksum(gress, ent.key),
                                                   Phv::Ref(gress, ent.value));
            } else if (kv.key == "pov") {
                if (!CHECKTYPE(kv.value, tVEC)) continue;
                for (auto &ent : kv.value.vec)
                    pov_order[gress].emplace_back(gress, ent);
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
            } else if (auto *digest = ::get(Digest::Type::all[gress], value_desc(&kv.key))) {
                if (CHECKTYPE(kv.value, tMAP))
                    digests.emplace_back(digest, kv.value.lineno, kv.value.map);
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
            if (el.check())
                phv_use[intrin.first->gress][el->reg.index] = 1;
        if (intrin.second.size() > (size_t)intrin.first->max)
            error(intrin.second[0].lineno, "Too many values for %s", intrin.first->name.c_str()); }
    if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
        error(lineno[INGRESS], "Registers used in both ingress and egress in deparser: %s",
              Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str());
    for (auto &digest : digests) {
        if (digest.select.check()) {
            phv_use[digest.type->gress][digest.select->reg.index] = 1;
            if (digest.select->lo > 0 && !digest.type->can_shift)
                error(digest.select.lineno, "%s digest selector must be in bottom bits of phv",
                      digest.type->name.c_str()); }
        for (auto &set : digest.layout)
            for (auto &reg : set.second)
                if (reg.check())
                    phv_use[digest.type->gress][reg->reg.index] = 1; }
    if (options.match_compiler || 1) {  /* FIXME -- need proper liveness analysis */
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
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

    /* TODO: rewrite tagalong mappings once they're given to us by the HW team */
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

#define TAGALONG_THREAD_BASE    (COUNT_8BIT_TPHV + COUNT_16BIT_TPHV + 2*COUNT_32BIT_TPHV)

template<typename IPO, typename HPO> static
void dump_checksum_units(checked_array_base<IPO> &main_csum_units,
                         checked_array_base<HPO> &tagalong_csum_units,
                         gress_t gress,
                         std::vector<Phv::Ref> checksum[DEPARSER_CHECKSUM_UNITS])
{
    assert(phv2cksum[NUM_PHV_REGS-1][0] == 143);
    for (int i = 0; i < DEPARSER_CHECKSUM_UNITS; i++) {
        if (checksum[i].empty()) {
            if (!options.match_compiler || gress == EGRESS || i > 1)
                continue; }
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
        if (checksum[i].empty())
            continue;
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
                    main_unit[phv2cksum[idx][1]].swap = polarity; } } }
        // Thread non-tagalong checksum results through the tagalong unit
        int idx = i + TAGALONG_THREAD_BASE + gress * DEPARSER_CHECKSUM_UNITS;
        tagalong_unit[idx].zero_l_s_b = 0;
        tagalong_unit[idx].zero_m_s_b = 0;
        tagalong_unit[idx].swap = 0; }
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

template <typename IN_GRP, typename IN_SPLIT, typename EG_GRP, typename EG_SPLIT>
void output_phv_ownership(bitvec phv_use[2],
                          IN_GRP &in_grp, IN_SPLIT &in_split,
                          EG_GRP &eg_grp, EG_SPLIT &eg_split,
                          unsigned first, unsigned count)
{
    assert(in_grp.val.size() == eg_grp.val.size());
    assert(in_split.val.size() == eg_split.val.size());
    assert((in_grp.val.size() + 1) * in_split.val.size() == count);
    unsigned group_size = in_split.val.size();
    unsigned reg = first;
    for (unsigned i = 0; i < in_grp.val.size(); i++, reg += group_size) {
        int count = 0;
        if (phv_use[INGRESS].getrange(reg, group_size)) {
            in_grp.val |= 1U << i;
            if (i * group_size >= 16 && i * group_size < 32)
                error(0, "%s..%s(R%d..R%d) used by ingress deparser but only available to egress",
                      Phv::reg(reg).name, Phv::reg(reg+group_size-1).name, reg, reg+group_size-1);
            else
                count++; }
        if (phv_use[EGRESS].getrange(reg, group_size)) {
            eg_grp.val |= 1U << i;
            if (i * group_size < 16)
                error(0, "%s..%s(R%d..R%d) used by egress deparser but only available to ingress",
                      Phv::reg(reg).name, Phv::reg(reg+group_size-1).name, reg, reg+group_size-1);
            else
                count++; }
        if (count > 1)
            error(0, "%s..%s(R%d..R%d) used by both ingress and egress deparser",
                  Phv::reg(reg).name, Phv::reg(reg+group_size-1).name, reg, reg+group_size-1); }
    in_split.val = phv_use[INGRESS].getrange(reg, group_size);
    eg_split.val = phv_use[EGRESS].getrange(reg, group_size);
}

void Deparser::output() {
    if (dictionary[INGRESS].empty() && dictionary[EGRESS].empty())
        return;
    Target::Tofino::deparser_regs regs;
    declare_registers(&regs);
    write_config(regs);
    undeclare_registers(&regs);
}

template<class REGS> void Deparser::write_config(REGS &regs) {
    regs.input.icr.inp_cfg.disable();
    regs.input.icr.intr.disable();
    regs.header.hem.he_edf_cfg.disable();
    regs.header.him.hi_edf_cfg.disable();
    dump_checksum_units(regs.input.iim.ii_phv_csum.csum_cfg, regs.header.him.hi_tphv_csum.csum_cfg,
                        INGRESS, checksum[INGRESS]);
    dump_checksum_units(regs.input.iem.ie_phv_csum.csum_cfg, regs.header.hem.he_tphv_csum.csum_cfg,
                        EGRESS, checksum[EGRESS]);
    dump_field_dictionary(regs.input.iim.ii_fde_pov.fde_pov, regs.header.him.hi_fde_phv.fde_phv,
        regs.input.iir.main_i.pov.phvs, pov_order[INGRESS], dictionary[INGRESS]);
    dump_field_dictionary(regs.input.iem.ie_fde_pov.fde_pov, regs.header.hem.he_fde_phv.fde_phv,
        regs.input.ier.main_e.pov.phvs, pov_order[EGRESS], dictionary[EGRESS]);

    if (Phv::use(INGRESS).intersects(Phv::use(EGRESS))) {
        warning(lineno[INGRESS], "Registers used in both ingress and egress in pipeline: %s",
                Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str());
        /* FIXME -- this only (sort-of) works because 'deparser' comes first in the alphabet,
         * FIXME -- so is the first section to have its 'output' method run.  Its a hack
         * FIXME -- anyways to attempt to correct broken asm that should be an error */
        Phv::unsetuse(INGRESS, phv_use[EGRESS]);
        Phv::unsetuse(EGRESS, phv_use[INGRESS]);
    }

    output_phv_ownership(phv_use, regs.input.iir.ingr.phv8_grp, regs.input.iir.ingr.phv8_split,
                         regs.input.ier.egr.phv8_grp, regs.input.ier.egr.phv8_split,
                         FIRST_8BIT_PHV, COUNT_8BIT_PHV);
    output_phv_ownership(phv_use, regs.input.iir.ingr.phv16_grp, regs.input.iir.ingr.phv16_split,
                         regs.input.ier.egr.phv16_grp, regs.input.ier.egr.phv16_split,
                         FIRST_16BIT_PHV, COUNT_16BIT_PHV);
    output_phv_ownership(phv_use, regs.input.iir.ingr.phv32_grp, regs.input.iir.ingr.phv32_split,
                         regs.input.ier.egr.phv32_grp, regs.input.ier.egr.phv32_split,
                         FIRST_32BIT_PHV, COUNT_32BIT_PHV);

    for (unsigned i = 0; i < 8; i++) {
        if (phv_use[EGRESS].intersects(Phv::tagalong_groups[i])) {
            regs.input.icr.tphv_cfg.i_e_assign |= 1 << i;
            if (phv_use[INGRESS].intersects(Phv::tagalong_groups[i])) {
                error(lineno[INGRESS], "tagalong group %d used in both ingress and "
                      "egress deparser", i); } } }

    for (auto &intrin : intrinsics)
        intrin.first->setregs(regs, intrin.second);
    if (!regs.header.hir.ingr.ingress_port.sel.modified())
        regs.header.hir.ingr.ingress_port.sel = 1;

    for (auto &digest : digests)
        digest.type->setregs(regs, digest);

    if (!options.match_compiler) {
        regs.input.disable_if_zero();
        regs.header.disable_if_zero(); }
    regs.input.emit_json(*open_output("regs.all.deparser.input_phase.cfg.json"));
    regs.header.emit_json(*open_output("regs.all.deparser.header_phase.cfg.json"));
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
    { "csum0", 224, 16 }, { "csum1", 225, 16 }, { "csum2", 226, 16 }, { "csum3", 227, 16 },
    { "csum4", 228, 16 }, { "csum5", 229, 16 }, { "csum6", 230, 16 }, { "csum7", 231, 16 },
    { "csum8", 232, 16 }, { "csum9", 233, 16 }, { "csum10", 234, 16 }, { "csum11", 235, 16 } };

Phv::Slice Deparser::RefOrChksum::operator *() const {
    if (name_ == "checksum") {
        if (lo != hi || lo < 0 || lo >= DEPARSER_CHECKSUM_UNITS) {
            error(lineno, "Invalid checksum unit number");
            return Phv::Slice(); }
        return Phv::Slice(checksum_units[gress*DEPARSER_CHECKSUM_UNITS+lo], 0, 15); }
    return Phv::Ref::operator*();
}
