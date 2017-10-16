#include <config.h>

#include "deparser.h"
#include "phv.h"
#include "range.h"
#include "target.h"
#include "top_level.h"

Deparser Deparser::singleton_object;

Deparser::Deparser() : Section("deparser") { }
Deparser::~Deparser() { }

struct Deparser::Intrinsic::Type {
    target_t    target;
    gress_t     gress;
    std::string name;
    int         max;
    static std::map<std::string, Type *> all[TARGET_INDEX_LIMIT][2];
protected:
    Type(target_t t, gress_t gr, const char *n, int m) : target(t), gress(gr), name(n), max(m) {
        assert(!all[t][gr].count(name));
        all[target][gress][name] = this; }
    ~Type() { all[target][gress].erase(name); }
public:
#define VIRTUAL_TARGET_METHODS(TARGET) \
    virtual void setregs(Target::TARGET::deparser_regs &regs, Deparser &deparser,       \
                         Intrinsic &vals) { assert(!"target mismatch"); }
    FOR_ALL_TARGETS(VIRTUAL_TARGET_METHODS)
#undef VIRTUAL_TARGET_METHODS
};

#define DEPARSER_INTRINSIC(TARGET, GR, NAME, MAX)                                               \
static struct TARGET##INTRIN##GR##NAME : public Deparser::Intrinsic::Type {                     \
    TARGET##INTRIN##GR##NAME()                                                                  \
    : Deparser::Intrinsic::Type(Target::TARGET::tag, GR, #NAME, MAX) {}                         \
    void setregs(Target::TARGET::deparser_regs &, Deparser &, Deparser::Intrinsic &) override;  \
} TARGET##INTRIN##GR##NAME##_singleton;                                                         \
void TARGET##INTRIN##GR##NAME::setregs(Target::TARGET::deparser_regs &regs,                     \
                                       Deparser &deparser, Deparser::Intrinsic &intrin)

std::map<std::string, Deparser::Intrinsic::Type *>
    Deparser::Intrinsic::Type::all[TARGET_INDEX_LIMIT][2];

struct Deparser::Digest::Type {
    target_t    target;
    gress_t     gress;
    std::string name;
    int         count;
    bool        can_shift = false;
    static std::map<std::string, Type *> all[TARGET_INDEX_LIMIT][2];
protected:
    Type(target_t t, gress_t gr, const char *n, int cnt)
    : target(t), gress(gr), name(n), count(cnt) {
        assert(!all[target][gress].count(name));
        all[target][gress][name] = this; }
    ~Type() { all[target][gress].erase(name); }
public:
#define VIRTUAL_TARGET_METHODS(TARGET)                                                  \
    virtual void setregs(Target::TARGET::deparser_regs &regs, Deparser &deparser,       \
                         Deparser::Digest &data) { assert(!"target mismatch"); }
    FOR_ALL_TARGETS(VIRTUAL_TARGET_METHODS)
#undef VIRTUAL_TARGET_METHODS
};
Deparser::Digest::Digest(Deparser::Digest::Type *t, int l, VECTOR(pair_t) &data) {
    type = t;
    lineno = l;
    for (auto &l : data) {
        if (l.key == "select") {
            if (l.value.type == tMAP && l.value.map.size == 1) {
                select = Val(t->gress, l.value.map[0].key, l.value.map[0].value);
            } else {
                select = Val(t->gress, l.value); }
        } else if (t->can_shift && l.key == "shift") {
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

#define DEPARSER_DIGEST(TARGET, GRESS, NAME, CNT, ...)                                          \
static struct TARGET##GRESS##NAME##Digest : public Deparser::Digest::Type {                     \
    TARGET##GRESS##NAME##Digest()                                                               \
    : Deparser::Digest::Type(Target::TARGET::tag, GRESS, #NAME, CNT) { __VA_ARGS__ }            \
    void setregs(Target::TARGET::deparser_regs &, Deparser &, Deparser::Digest &) override;     \
} TARGET##GRESS##NAME##Digest##_singleton;                                                      \
void TARGET##GRESS##NAME##Digest::setregs(Target::TARGET::deparser_regs &regs,                  \
                                          Deparser &deparser, Deparser::Digest &data)

std::map<std::string, Deparser::Digest::Type *> Deparser::Digest::Type::all[TARGET_INDEX_LIMIT][2];

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
                    kv.key[1].i < 0 || kv.key[1].i >= Target::DEPARSER_CHECKSUM_UNITS())
                    error(kv.key.lineno, "Invalid checksum unit number");
                else if (CHECKTYPE2(kv.value, tVEC, tMAP)) {
                    int unit = kv.key[1].i;
                    if (kv.value.type == tVEC) {
                        for (auto &ent : kv.value.vec)
                            checksum[gress][unit].emplace_back(gress, ent);
                    } else {
                        for (auto &ent : kv.value.map)
                            checksum[gress][unit].emplace_back(gress, ent.key, ent.value); } }
            } else if (auto *itype = ::get(Intrinsic::Type::all[options.target][gress],
                                           value_desc(&kv.key))) {
                intrinsics.emplace_back(itype, kv.key.lineno);
                auto &intrin = intrinsics.back();
                if (kv.value.type == tVEC) {
                    for (auto &val : kv.value.vec)
                        intrin.vals.emplace_back(gress, val);
                } else if (kv.value.type == tMAP) {
                    for (auto &el : kv.value.map)
                        intrin.vals.emplace_back(gress, el.key, el.value);
                } else {
                    intrin.vals.emplace_back(gress, kv.value); }
            } else if (auto *digest = ::get(Digest::Type::all[options.target][gress],
                                            value_desc(&kv.key))) {
                if (CHECKTYPE(kv.value, tMAP))
                    digests.emplace_back(digest, kv.value.lineno, kv.value.map);
            } else
                error(kv.key.lineno, "Unknown deparser tag %s", value_desc(&kv.key));
        }
    }
}
void Deparser::process() {
    bitvec pov_use[2];
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        for (auto &ent : pov_order[gress])
            if (ent.check()) {
                pov_use[gress][ent->reg.uid] = 1;
                phv_use[gress][ent->reg.uid] = 1; }
        for (auto &ent : dictionary[gress]) {
            if (ent.first.check()) {
                phv_use[gress][ent.first->reg.uid] = 1;
                if (ent.first->lo != 0 || ent.first->hi != ent.first->reg.size - 1)
                    error(ent.first.lineno, "Can only output full phv registers, not slices, "
                          "in deparser"); }
            if (ent.second.check()) {
                phv_use[gress][ent.second->reg.uid] = 1;
                if (ent.second->lo != ent.second->hi)
                    error(ent.second.lineno, "POV bits should be single bits");
                if (!pov_use[gress][ent.second->reg.uid]) {
                    pov_order[gress].emplace_back(ent.second->reg);
                    pov_use[gress][ent.second->reg.uid] = 1; } } }
        for (int i = 0; i < MAX_DEPARSER_CHECKSUM_UNITS; i++)
            for (auto &ent : checksum[gress][i])
                if (ent.check() && (ent->lo != 0 || ent->hi != ent->reg.size - 1))
                    error(ent.lineno, "Can only do checksums on full phv registers, not slices"); }
    for (auto &intrin : intrinsics) {
        for (auto &el : intrin.vals) {
            if (el.check())
                phv_use[intrin.type->gress][el->reg.uid] = 1;
            if (el.pov.check()) {
                phv_use[intrin.type->gress][el.pov->reg.uid] = 1;
                if (el.pov->lo != el.pov->hi)
                    error(el.pov.lineno, "POV bits should be single bits");
                if (!pov_use[intrin.type->gress][el.pov->reg.uid]) {
                    pov_order[intrin.type->gress].emplace_back(el.pov->reg);
                    pov_use[intrin.type->gress][el.pov->reg.uid] = 1; } } }
        if (intrin.vals.size() > (size_t)intrin.type->max)
            error(intrin.lineno, "Too many values for %s", intrin.type->name.c_str()); }
    if (phv_use[INGRESS].intersects(phv_use[EGRESS]))
        error(lineno[INGRESS], "Registers used in both ingress and egress in deparser: %s",
              Phv::db_regset(phv_use[INGRESS] & phv_use[EGRESS]).c_str());
    for (auto &digest : digests) {
        if (digest.select.check()) {
            phv_use[digest.type->gress][digest.select->reg.uid] = 1;
            if (digest.select->lo > 0 && !digest.type->can_shift)
                error(digest.select.lineno, "%s digest selector must be in bottom bits of phv",
                      digest.type->name.c_str()); }
        if (digest.select.pov.check()) {
            phv_use[digest.type->gress][digest.select.pov->reg.uid] = 1;
            if (digest.select.pov->lo != digest.select.pov->hi)
                error(digest.select.pov.lineno, "POV bits should be single bits");
            if (!pov_use[digest.type->gress][digest.select.pov->reg.uid]) {
                pov_order[digest.type->gress].emplace_back(digest.select.pov->reg);
                pov_use[digest.type->gress][digest.select.pov->reg.uid] = 1; } }
        for (auto &set : digest.layout)
            for (auto &reg : set.second)
                if (reg.check())
                    phv_use[digest.type->gress][reg->reg.uid] = 1; }
    if (options.match_compiler || 1) {  /* FIXME -- need proper liveness analysis */
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        unsigned pov_byte = 0, pov_size = 0;
        for (auto &ent : pov_order[gress])
            if (pov[gress].count(&ent->reg) == 0) {
                pov[gress][&ent->reg] = pov_size;
                pov_size += ent->reg.size; }
        if (pov_size > 8*Target::DEPARSER_MAX_POV_BYTES())
            error(lineno[gress], "Ran out of space in POV in deparser"); }
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

void Deparser::output(json::map &) {
    SWITCH_FOREACH_TARGET(options.target,
        TARGET::deparser_regs    regs;
        declare_registers(&regs);
        write_config(regs);
        undeclare_registers(&regs);
    )
}

bool Deparser::RefOrChksum::check() const {
    if (name_ == "checksum")
        SWITCH_FOREACH_TARGET(options.target, return bool(lookup<TARGET>()); )
    return Phv::Ref::check();
}

Phv::Slice Deparser::RefOrChksum::operator *() const {
    if (name_ == "checksum")
        SWITCH_FOREACH_TARGET(options.target, return lookup<TARGET>(); )
    return Phv::Ref::operator*();
}
