#include <config.h>

#include "deparser.h"
#include "parser.h"
#include "phv.h"
#include "range.h"
#include "target.h"
#include "top_level.h"

Deparser Deparser::singleton_object;

Deparser::Deparser() : Section("deparser") { }
Deparser::~Deparser() { }

struct Deparser::FDEntry {
    struct Base {
        virtual void check(bitvec &phv_use) = 0;
        virtual unsigned encode() = 0;
        virtual unsigned size() = 0;
        template<class T> bool is() { return dynamic_cast<T*>(this) != nullptr; }
        template<class T> T *to() { return dynamic_cast<T*>(this); }
    };
    struct Phv : Base {
        ::Phv::Ref    val;
        Phv(gress_t g, const value_t &v) : val(g, v) {}
        void check(bitvec &phv_use) override {
            if (val.check()) {
                phv_use[val->reg.uid] = 1;
                if (val->lo != 0 || val->hi != val->reg.size - 1)
                    error(val.lineno, "Can only output full phv registers, not slices, "
                                      "in deparser"); } }
        unsigned encode() override { return val->reg.deparser_id(); }
        unsigned size() override { return val->reg.size/8; }
    };
    struct Checksum : Base {
        gress_t         gress;
        int             unit;
        Checksum(gress_t gr, const value_t &v) : gress(gr) {
            if (CHECKTYPE(v, tINT)) {
                if ((unit = v.i) < 0 || v.i >= Target::DEPARSER_CHECKSUM_UNITS())
                    error(v.lineno, "Invalid deparser checksum unit %d", v.i); } }
        void check(bitvec &phv_use) override { }
        template<class TARGET> unsigned encode();
        unsigned encode() override;
        unsigned size() override { return 2; }
    };
    struct Clot : Base {
        int                                     lineno;
        gress_t                                 gress;
        std::string                             tag;
        int                                     length = -1;
        std::map<unsigned, ::Phv::Ref>          replace;
        Clot(gress_t gr, const value_t &tag, const value_t &data, ::Phv::Ref &pov)
        : lineno(tag.lineno), gress(gr) {
            if (CHECKTYPE2(tag, tINT, tSTR)) {
                if (tag.type == tSTR)
                    this->tag = tag.s;
                else
                    this->tag = std::to_string(tag.i); }
            if (data.type == tMAP) {
                for (auto &kv : data.map) {
                    if (kv.key == "pov") {
                        if (pov) error(kv.value.lineno, "Duplicate POV");
                        pov = ::Phv::Ref(gress, kv.value);
                    } else if (kv.key == "max_length" || kv.key == "length") {
                        if (length >= 0)
                            error(kv.value.lineno, "Duplicate length");
                        if (CHECKTYPE(kv.value, tINT) && ((length = kv.value.i) < 0 || length > 64))
                            error(kv.value.lineno, "Invalid clot length");
                    } else if (kv.key.type == tINT) {
                        if (replace.count(kv.key.i))
                            error(kv.value.lineno, "Duplicate value at offset %d", kv.key.i);
                        replace.emplace(kv.key.i, ::Phv::Ref(gress, kv.value)); } }
            } else {
                pov = ::Phv::Ref(gress, data); } }
        void check(bitvec &phv_use) override {
            if (length < 0) length = Parser::clot_maxlen(gress, tag);
            if (length < 0) error(lineno, "No length for clot %s", tag.c_str());
            if (Parser::clot_tag(gress, tag) < 0) error(lineno, "No tag for clot %s", tag.c_str());
            unsigned next = 0;
            ::Phv::Ref *prev;
            for (auto &r: replace) {
                if (r.first < next) {
                    error(r.second.lineno, "Overlapping phvs in clot");
                    error(prev->lineno, "%s and %s", prev->name(), r.second.name()); }
                if (r.second.check()) {
                    phv_use[r.second->reg.uid] = 1;
                    if (r.second->lo != 0 || r.second->hi != r.second->reg.size - 1)
                        error(r.second.lineno, "Can only output full phv registers, not slices,"
                                               " in deparser");
                    next = r.first + r.second->reg.size/8U;
                    prev = &r.second; } } }
        unsigned size() override { return length; }
        unsigned encode() override { assert(0); }
    };

    int         lineno;
    Base        *what;
    ::Phv::Ref  pov;
    FDEntry(gress_t gress, const value_t &v, const value_t &p) {
        lineno = v.lineno;
        if (v.type == tCMD && v.vec.size == 2 && v == "clot") {
            what = new Clot(gress, v.vec[1], p, pov);
        } else if (v.type == tCMD && v.vec.size == 2 && v == "checksum") {
            what = new Checksum(gress, v.vec[1]);
            pov = ::Phv::Ref(gress, p);
        } else {
            what = new Phv(gress, v);
            pov = ::Phv::Ref(gress, p); } }
    void check(bitvec &phv_use) { what->check(phv_use); }
};

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
                    dictionary[gress].emplace_back(gress, ent.key, ent.value);
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
            ent.check(phv_use[gress]);
            if (ent.pov.check()) {
                phv_use[gress][ent.pov->reg.uid] = 1;
                if (ent.pov->lo != ent.pov->hi)
                    error(ent.pov.lineno, "POV bits should be single bits");
                if (!pov_use[gress][ent.pov->reg.uid]) {
                    pov_order[gress].emplace_back(ent.pov->reg);
                    pov_use[gress][ent.pov->reg.uid] = 1; } } }
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

#include "tofino/deparser.cpp"    // tofino template specializations
#if HAVE_JBAY
#include "jbay/deparser.cpp"      // jbay template specializations
#endif // HAVE_JBAY

/* The following uses of specialized templates must be after the specialization... */

void Deparser::output(json::map &) {
    SWITCH_FOREACH_TARGET(options.target,
        TARGET::deparser_regs    regs;
        declare_registers(&regs);
        write_config(regs);
        undeclare_registers(&regs);
    )
}

unsigned Deparser::FDEntry::Checksum::encode() {
    SWITCH_FOREACH_TARGET(options.target, return encode<TARGET>(); );
}
