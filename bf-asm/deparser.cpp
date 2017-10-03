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
#define VIRTUAL_TARGET_METHODS(TARGET) \
    virtual void setregs(Target::TARGET::deparser_regs &regs, std::vector<Phv::Ref> &vals) = 0;
    FOR_ALL_TARGETS(VIRTUAL_TARGET_METHODS)
#undef VIRTUAL_TARGET_METHODS
};

#define ALL_DEPARSER_INTRINSICS(M, ...) \
    M(INGRESS, egress_unicast_port, 1, ##__VA_ARGS__) \
    M(INGRESS, drop_ctl, 1, ##__VA_ARGS__) \
    M(INGRESS, copy_to_cpu, 1, ##__VA_ARGS__) \
    M(INGRESS, egress_multicast_group, 2, ##__VA_ARGS__) \
    M(INGRESS, hash_lag_ecmp_mcast, 2, ##__VA_ARGS__) \
    M(INGRESS, copy_to_cpu_cos, 1, ##__VA_ARGS__) \
    M(INGRESS, ingress_port_source, 1, ##__VA_ARGS__) \
    M(INGRESS, deflect_on_drop, 1, ##__VA_ARGS__) \
    M(INGRESS, meter_color, 1, ##__VA_ARGS__) \
    M(INGRESS, icos, 1, ##__VA_ARGS__) \
    M(INGRESS, qid, 1, ##__VA_ARGS__) \
    M(INGRESS, xid, 1, ##__VA_ARGS__) \
    M(INGRESS, yid, 1, ##__VA_ARGS__) \
    M(INGRESS, rid, 1, ##__VA_ARGS__) \
    M(INGRESS, bypss_egr, 1, ##__VA_ARGS__) \
    M(INGRESS, ct_disable, 1, ##__VA_ARGS__) \
    M(INGRESS, ct_mcast, 1, ##__VA_ARGS__) \
    M(EGRESS, egress_unicast_port, 1, ##__VA_ARGS__) \
    M(EGRESS, drop_ctl, 1, ##__VA_ARGS__) \
    M(EGRESS, force_tx_err, 1, ##__VA_ARGS__) \
    M(EGRESS, tx_pkt_has_offsets, 1, ##__VA_ARGS__) \
    M(EGRESS, capture_tx_ts, 1, ##__VA_ARGS__) \
    M(EGRESS, coal, 1, ##__VA_ARGS__) \
    M(EGRESS, ecos, 1, ##__VA_ARGS__)

#define DECLARE_DEPARSER_INTRINSIC(GR, NAME, MAX) \
struct INTRIN##GR##NAME : public Deparser::Intrinsic {           \
    INTRIN##GR##NAME() : Deparser::Intrinsic(GR, #NAME, MAX) {}         \
    template<class REGS> void setregs(REGS &regs, std::vector<Phv::Ref> &vals); \
    FOR_ALL_TARGETS(DECLARE_INTRINSIC_SETREGS_FORWARD) \
};
#define DECLARE_INTRINSIC_SETREGS_FORWARD(TARGET) \
    void setregs(Target::TARGET::deparser_regs &regs, std::vector<Phv::Ref> &vals);
#define DEFINE_INTRINSIC_SETREGS_FORWARD(TARGET, CLASS) \
void CLASS::setregs(Target::TARGET::deparser_regs &regs, std::vector<Phv::Ref> &vals) { \
    setregs<Target::TARGET::deparser_regs>(regs, vals); }
#define DEFINE_DEPARSER_INTRINSIC(GR, NAME, MAX) \
FOR_ALL_TARGETS(DEFINE_INTRINSIC_SETREGS_FORWARD, INTRIN##GR##NAME) \
static struct INTRIN##GR##NAME INTRIN##GR##NAME##_singleton;

std::map<std::string, Deparser::Intrinsic *> Deparser::Intrinsic::all[2];

ALL_DEPARSER_INTRINSICS(DECLARE_DEPARSER_INTRINSIC)

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
#define VIRTUAL_TARGET_METHODS(TARGET) \
    virtual void setregs(Target::TARGET::deparser_regs &regs, Deparser::Digest &data) = 0; \
    virtual void init(Target::TARGET) = 0;
    FOR_ALL_TARGETS(VIRTUAL_TARGET_METHODS)
#undef VIRTUAL_TARGET_METHODS
    static void init(target_t target) {
        for (auto &m : all) {
            for (auto d : Values(m)) {
                switch(target) {
#define SWITCH_FOR_TARGET(TARGET) case Target::TARGET::tag: d->init(Target::TARGET()); break;
                FOR_ALL_TARGETS(SWITCH_FOR_TARGET)
#undef SWITCH_FOR_TARGET
                default: assert(0); } } } }
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

#define ALL_DEPARSER_DIGESTS(M, ...)    \
    M(INGRESS, learning, 8)             \
    M(INGRESS, mirror, 8)               \
    M(EGRESS, mirror, 8)                \
    M(INGRESS, resubmit, 8)

#define DECLARE_DEPARSER_DIGEST(GRESS, NAME, CNT)                       \
struct GRESS##NAME##Digest : public Deparser::Digest::Type {                    \
    GRESS##NAME##Digest() : Deparser::Digest::Type(GRESS, #NAME, CNT) {}        \
    template<class REGS> void setregs(REGS &regs, Deparser::Digest &data);      \
    FOR_ALL_TARGETS(DECLARE_INIT_OVERRIDE)                                      \
    FOR_ALL_TARGETS(DECLARE_DIGEST_SETREGS_FORWARD)                             \
};
#define DECLARE_INIT_OVERRIDE(TARGET) void init(Target::TARGET) override;
#define DECLARE_DIGEST_SETREGS_FORWARD(TARGET) \
    void setregs(Target::TARGET::deparser_regs &regs, Deparser::Digest &data) override;
#define DEFINE_DIGEST_SETREGS_FORWARD(TARGET, CLASS) \
void CLASS::setregs(Target::TARGET::deparser_regs &regs, Deparser::Digest &data) { \
    setregs<Target::TARGET::deparser_regs>(regs, data); }
#define DEFINE_DEPARSER_DIGEST(GRESS, NAME, CNT) \
FOR_ALL_TARGETS(DEFINE_DIGEST_SETREGS_FORWARD, GRESS##NAME##Digest) \
static struct GRESS##NAME##Digest GRESS##NAME##Digest##_singleton;

std::map<std::string, Deparser::Digest::Type *> Deparser::Digest::Type::all[2];

ALL_DEPARSER_DIGESTS(DECLARE_DEPARSER_DIGEST)

void Deparser::start(int lineno, VECTOR(value_t) args) {
    Digest::Type::init(options.target);
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
                phv_use[gress][ent->reg.uid] = 1;
        for (auto &ent : dictionary[gress]) {
            if (ent.first.check()) {
                phv_use[gress][ent.first->reg.uid] = 1;
                if (ent.first->lo != 0 || ent.first->hi != ent.first->reg.size - 1)
                    error(ent.first.lineno, "Can only output full phv registers, not slices, "
                          "in deparser"); }
            if (ent.second.check()) {
                phv_use[gress][ent.second->reg.uid] = 1;
                if (ent.second->lo != ent.second->hi)
                    error(ent.second.lineno, "POV bits should be single bits"); } }
        for (int i = 0; i < DEPARSER_CHECKSUM_UNITS; i++)
            for (auto &ent : checksum[gress][i])
                if (ent.check() && (ent->lo != 0 || ent->hi != ent->reg.size - 1))
                    error(ent.lineno, "Can only do checksums on full phv registers, not slices"); }
    for (auto &intrin : intrinsics) {
        for (auto &el : intrin.second)
            if (el.check())
                phv_use[intrin.first->gress][el->reg.uid] = 1;
        if (intrin.second.size() > (size_t)intrin.first->max)
            error(intrin.second[0].lineno, "Too many values for %s", intrin.first->name.c_str()); }
    if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
        error(lineno[INGRESS], "Registers used in both ingress and egress in deparser: %s",
              Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str());
    for (auto &digest : digests) {
        if (digest.select.check()) {
            phv_use[digest.type->gress][digest.select->reg.uid] = 1;
            if (digest.select->lo > 0 && !digest.type->can_shift)
                error(digest.select.lineno, "%s digest selector must be in bottom bits of phv",
                      digest.type->name.c_str()); }
        for (auto &set : digest.layout)
            for (auto &reg : set.second)
                if (reg.check())
                    phv_use[digest.type->gress][reg->reg.uid] = 1; }
    if (options.match_compiler || 1) {  /* FIXME -- need proper liveness analysis */
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
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
        if (pov.count(ent->reg.deparser_id()) == 0) {
            pov[ent->reg.deparser_id()] = pov_size;
            pov_size += ent->reg.size;
            for (unsigned i = 0; i < ent->reg.size; i += 8) {
                if (pov_byte >= DEPARSER_MAX_POV_BYTES) {
                    error(ent.lineno, "Ran out of space in POV in deparser");
                    return; }
                pov_layout[pov_byte++] = ent->reg.deparser_id(); } }
    for (auto &ent : dict)
        if (pov.count(ent.second->reg.deparser_id()) == 0) {
            pov[ent.second->reg.deparser_id()] = pov_size;
            pov_size += ent.second->reg.size;
            for (unsigned i = 0; i < ent.second->reg.size; i += 8) {
                if (pov_byte >= DEPARSER_MAX_POV_BYTES) {
                    error(ent.second.lineno, "Ran out of space in POV in deparser");
                    return; }
                pov_layout[pov_byte++] = ent.second->reg.deparser_id(); } }
    while (pov_byte < DEPARSER_MAX_POV_BYTES)
        pov_layout[pov_byte++] = 0xff;

    int row = -1, prev_pov = -1;
    bool prev_is_checksum = false;
    unsigned pos = 0;
    for (auto &ent : dict) {
        unsigned size = ent.first->reg.size/8;
        int pov_bit = pov[ent.second->reg.deparser_id()] + ent.second->lo;
        if (options.match_compiler) {
            if (ent.first->reg.deparser_id() >= 224 && ent.first->reg.deparser_id() < 236) {
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
            fde_data[row].phv[pos++] = ent.first->reg.deparser_id();
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
    // FIXME -- this only works because tofino Phv::Register uids happend to match
    // FIXME -- the deparser encoding of phv containers. (FIXME-PHV)
    unsigned reg = first;
    for (unsigned i = 0; i < in_grp.val.size(); i++, reg += group_size) {
        int count = 0;
        if (phv_use[INGRESS].getrange(reg, group_size)) {
            in_grp.val |= 1U << i;
            if (i * group_size >= 16 && i * group_size < 32)
                error(0, "%s..%s(R%d..R%d) used by ingress deparser but only available to egress",
                      Phv::reg(reg)->name, Phv::reg(reg+group_size-1)->name, reg, reg+group_size-1);
            else
                count++; }
        if (phv_use[EGRESS].getrange(reg, group_size)) {
            eg_grp.val |= 1U << i;
            if (i * group_size < 16)
                error(0, "%s..%s(R%d..R%d) used by egress deparser but only available to ingress",
                      Phv::reg(reg)->name, Phv::reg(reg+group_size-1)->name, reg, reg+group_size-1);
            else
                count++; }
        if (count > 1)
            error(0, "%s..%s(R%d..R%d) used by both ingress and egress deparser",
                  Phv::reg(reg)->name, Phv::reg(reg+group_size-1)->name, reg, reg+group_size-1); }
    in_split.val = phv_use[INGRESS].getrange(reg, group_size);
    eg_split.val = phv_use[EGRESS].getrange(reg, group_size);
}

#include "tofino/deparser.cpp"    // tofino template specializations
#if HAVE_JBAY
#include "jbay/deparser.cpp"      // jbay template specializations
#endif // HAVE_JBAY

// These defintions must be after the template specializations
ALL_DEPARSER_INTRINSICS(DEFINE_DEPARSER_INTRINSIC)
ALL_DEPARSER_DIGESTS(DEFINE_DEPARSER_DIGEST)

void Deparser::output(json::map &) {
    switch(options.target) {
#define SWITCH_FOR_TARGET(TARGET)                                       \
    case Target::TARGET::tag: {                                         \
        Target::TARGET::deparser_regs    regs;                          \
        declare_registers(&regs);                                       \
        write_config(regs);                                             \
        undeclare_registers(&regs);                                     \
        break; }
    FOR_ALL_TARGETS(SWITCH_FOR_TARGET)
#undef SWITCH_FOR_TARGET
    default: assert(0); }
}

bool Deparser::RefOrChksum::check() const {
    if (name_ == "checksum") {
        if (lo != hi || lo < 0 || lo >= DEPARSER_CHECKSUM_UNITS) {
            error(lineno, "Invalid checksum unit number");
            return false; }
        return true; }
    return Phv::Ref::check();
}

// FIXME -- we need to set the uid explicitly here so it matches the encoding of the
// FIXME -- checksums.  This works for tofino, but will fail for jbay as they won't be
// FIXME -- unique.  They also don't get installed properly in Phv::regs, but that is
// FIXME -- ok as we never ask for them (FIXME-PHV)
namespace {
static struct ChecksumReg : public Phv::Register {
    ChecksumReg(int unit) : Phv::Register("", Phv::Register::CHECKSUM, unit, unit+224, 16) {
        sprintf(name, "csum%d", unit); }
    int deparser_id() const override { return uid; }
} checksum_units[12] = { {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11} };
}

Phv::Slice Deparser::RefOrChksum::operator *() const {
    if (name_ == "checksum") {
        if (lo != hi || lo < 0 || lo >= DEPARSER_CHECKSUM_UNITS) {
            error(lineno, "Invalid checksum unit number");
            return Phv::Slice(); }
        return Phv::Slice(checksum_units[gress*DEPARSER_CHECKSUM_UNITS+lo], 0, 15); }
    return Phv::Ref::operator*();
}

