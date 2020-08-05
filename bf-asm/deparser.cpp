#include <config.h>

#include "constants.h"
#include "deparser.h"
#include "parser.h"
#include "phv.h"
#include "range.h"
#include "target.h"
#include "top_level.h"
#include "../lib/stringref.h"

static unsigned unique_field_list_handle = FIELD_HANDLE_START;

Deparser Deparser::singleton_object;

Deparser::Deparser() : Section("deparser") { }
Deparser::~Deparser() { }

struct Deparser::FDEntry {
    struct Base {
        virtual void check(bitvec &phv_use) = 0;
        virtual unsigned encode() = 0;
        virtual unsigned size() = 0;
        template<class T> bool is() const { return dynamic_cast<const T*>(this) != nullptr; }
        template<class T> T *to() { return dynamic_cast<T*>(this); }
    };
    struct Phv : Base {
        ::Phv::Ref    val;
        Phv(gress_t g, const value_t &v) : val(g, DEPARSER_STAGE, v) {}
        void check(bitvec &phv_use) override {
            if (val.check()) {
                phv_use[val->reg.uid] = 1;
                if (val->lo != 0 || val->hi != val->reg.size - 1)
                    error(val.lineno, "Can only output full phv registers, not slices, "
                                      "in deparser"); } }
        unsigned encode() override { return val->reg.deparser_id(); }
        unsigned size() override { return val->reg.size/8; }
        const ::Phv::Register* reg() { return &val->reg; }
    };
    struct Checksum : Base {
        gress_t         gress;
        int             unit;
        Checksum(gress_t gr, const value_t &v) : gress(gr) {
            if (CHECKTYPE(v, tINT)) {
                if ((unit = v.i) < 0 || v.i >= Target::DEPARSER_CHECKSUM_UNITS())
                    error(v.lineno, "Invalid deparser checksum unit %" PRId64 "", v.i); } }
        void check(bitvec &phv_use) override { }
        template<class TARGET> unsigned encode();
        unsigned encode() override;
        unsigned size() override { return 2; }
    };
    struct Constant : Base {
        int              lineno;
        gress_t          gress;
        int              val;
        Constant(gress_t g, const value_t &v) : gress(g), val(v.i) {
            lineno = v.lineno;
            if (v.i < 0 || v.i >> 8)
                error(lineno, "Invalid deparser constant %" PRId64
                      ", valid constant range is 0-255", v.i);
            bool ok = Deparser::add_constant(gress, val);
            if (!ok)
                error(lineno, "Ran out of deparser constants");
        }
        void check(bitvec &phv_use) override { }
        template<class TARGET> unsigned encode();
        unsigned encode() override;
        unsigned size() override { return 1; }
    };
    struct Clot : Base {
        int                                     lineno;
        gress_t                                 gress;
        std::string                             tag;
        int                                     length = -1;
        std::map<unsigned, ::Phv::Ref>          phv_replace;
        std::map<unsigned, Checksum>            csum_replace;
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
                        pov = ::Phv::Ref(gress, DEPARSER_STAGE, kv.value);
                    } else if (kv.key == "max_length" || kv.key == "length") {
                        if (length >= 0)
                            error(kv.value.lineno, "Duplicate length");
                        if (CHECKTYPE(kv.value, tINT) &&
                            ((length = kv.value.i) < 0 || length > 64))
                            error(kv.value.lineno, "Invalid clot length");
                    } else if (kv.key.type == tINT) {
                        if (phv_replace.count(kv.key.i) || csum_replace.count(kv.key.i))
                            error(kv.value.lineno, "Duplicate value at offset %" PRId64 "",
                                  kv.key.i);
                        if (kv.value.type == tCMD && kv.value.vec.size == 2 &&
                            kv.value == "checksum")
                            csum_replace.emplace(kv.key.i, Checksum(gress, kv.value.vec[1]));
                        else
                            phv_replace.emplace(kv.key.i,
                                                ::Phv::Ref(gress, DEPARSER_STAGE, kv.value));
                    } else {
                        error(kv.value.lineno, "Unknown key for clot: %s", value_desc(kv.key)); } }
            } else {
                pov = ::Phv::Ref(gress, DEPARSER_STAGE, data); } }
        void check(bitvec &phv_use) override {
            if (length < 0) length = Parser::clot_maxlen(gress, tag);
            if (length < 0) error(lineno, "No length for clot %s", tag.c_str());
            if (Parser::clot_tag(gress, tag) < 0) error(lineno, "No tag for clot %s", tag.c_str());
            unsigned next = 0;
            ::Phv::Ref *prev = nullptr;
            for (auto &r : phv_replace) {
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
        unsigned encode() override { BUG(); return -1; }
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
            pov = ::Phv::Ref(gress, DEPARSER_STAGE, p);
        } else if (v.type == tINT) {
            what = new Constant(gress, v);
            pov = ::Phv::Ref(gress, DEPARSER_STAGE, p);
        } else {
            what = new Phv(gress, v);
            pov = ::Phv::Ref(gress, DEPARSER_STAGE, p); } }
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
        BUG_CHECK(!all[t][gr].count(name));
        all[target][gress][name] = this; }
    ~Type() { all[target][gress].erase(name); }
 public:
#define VIRTUAL_TARGET_METHODS(TARGET) \
    virtual void setregs(Target::TARGET::deparser_regs &regs, Deparser &deparser,       \
                         Intrinsic &vals) { BUG_CHECK(!"target mismatch"); }
    FOR_ALL_REGISTER_SETS(VIRTUAL_TARGET_METHODS)
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
        BUG_CHECK(!all[target][gress].count(name));
        all[target][gress][name] = this; }
    ~Type() { all[target][gress].erase(name); }
 public:
#define VIRTUAL_TARGET_METHODS(TARGET)                                                  \
    virtual void setregs(Target::TARGET::deparser_regs &regs, Deparser &deparser,       \
                         Deparser::Digest &data) { BUG_CHECK(!"target mismatch"); }
    FOR_ALL_REGISTER_SETS(VIRTUAL_TARGET_METHODS)
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
        } else if (l.key == "context_json") {
            if (CHECKTYPE(l.value, tMAP))
                context_json = toJson(l.value.map);
        } else if (!CHECKTYPE(l.key, tINT)) {
            continue;
        } else if (l.key.i < 0 || l.key.i >= t->count) {
            error(l.key.lineno, "%s index %" PRId64 " out of range", t->name.c_str(), l.key.i);
        } else if (l.value.type != tVEC) {
            layout[l.key.i].emplace_back(t->gress, DEPARSER_STAGE, l.value);
        } else {
            // XXX(amresh) : Need an empty layout entry if no values are present to
            // set the config registers correctly
            layout.emplace(l.key.i, std::vector<Phv::Ref>());
            for (auto &v : l.value.vec)
                layout[l.key.i].emplace_back(t->gress, DEPARSER_STAGE, v); } }
    if (!select && t->name != "pktgen")
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
        error(lineno, "deparser must specify ingress or egress");
    gress_t gress = args[0] == "egress" ? EGRESS : INGRESS;
    if (!this->lineno[gress]) this->lineno[gress] = lineno;
}

void Deparser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (args.size > 0) {
            if (args[0] == "ingress" && gress != INGRESS) continue;
            if (args[0] == "egress" && gress != EGRESS) continue;
        } else if (error_count > 0) {
            break;
        }
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
                    pov_order[gress].emplace_back(gress, DEPARSER_STAGE, ent);
            } else if (kv.key == "checksum") {
                if (kv.key.type != tCMD || kv.key.vec.size != 2 || kv.key[1].type != tINT ||
                    kv.key[1].i < 0 || kv.key[1].i >= Target::DEPARSER_CHECKSUM_UNITS()) {
                    error(kv.key.lineno, "Invalid deparser checksum unit number");
                } else if (CHECKTYPE2(kv.value, tVEC, tMAP)) {
                    collapse_list_of_maps(kv.value);
                    int unit = kv.key[1].i;
                    if (unit < 0) error(kv.key.lineno, "Invalid checksum unit %d", unit);
                    for (auto &ent : kv.value.map) {
                        if (ent.key == "pov") {
                           checksum_unit[gress][unit].pov
                               = ::Phv::Ref(gress, DEPARSER_STAGE, ent.value);
                        } else if (ent.key == "zeros_as_ones") {
                           checksum_unit[gress][unit].zeros_as_ones_en = ent.value.i;
                        } else if (ent.key == "clot") {
                            checksum_unit[gress][unit].entries.emplace_back(gress,
                                    ent.key[1].i, ent.value);
                        } else {
                            checksum_unit[gress][unit].entries.emplace_back(gress,
                                    ent.key, ent.value);
                        }
                    }
                }
            } else if (auto *itype = ::get(Intrinsic::Type::all[Target::register_set()][gress],
                                           value_desc(&kv.key))) {
                intrinsics.emplace_back(itype, kv.key.lineno);
                auto &intrin = intrinsics.back();
                collapse_list_of_maps(kv.value);
                if (kv.value.type == tVEC) {
                    for (auto &val : kv.value.vec)
                        intrin.vals.emplace_back(gress, val);
                } else if (kv.value.type == tMAP) {
                    for (auto &el : kv.value.map)
                        intrin.vals.emplace_back(gress, el.key, el.value);
                } else {
                    intrin.vals.emplace_back(gress, kv.value); }
            } else if (auto *digest = ::get(Digest::Type::all[Target::register_set()][gress],
                                            value_desc(&kv.key))) {
                if (CHECKTYPE(kv.value, tMAP))
                    digests.emplace_back(digest, kv.value.lineno, kv.value.map);
            } else {
                error(kv.key.lineno, "Unknown deparser tag %s", value_desc(&kv.key));
            }
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
                    pov_order[gress].emplace_back(ent.pov->reg, gress);
                    pov_use[gress][ent.pov->reg.uid] = 1; } } }
        for (int i = 0; i < MAX_DEPARSER_CHECKSUM_UNITS; i++)
            for (auto &ent : checksum_unit[gress][i].entries)
                if (!ent.check())
                    error(ent.lineno, "Invalid checksum entry"); }
    for (auto &intrin : intrinsics) {
        for (auto &el : intrin.vals) {
            if (el.check())
                phv_use[intrin.type->gress][el->reg.uid] = 1;
            if (el.pov.check()) {
                phv_use[intrin.type->gress][el.pov->reg.uid] = 1;
                if (el.pov->lo != el.pov->hi)
                    error(el.pov.lineno, "POV bits should be single bits");
                if (!pov_use[intrin.type->gress][el.pov->reg.uid]) {
                    pov_order[intrin.type->gress].emplace_back(el.pov->reg, intrin.type->gress);
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
                pov_order[digest.type->gress].emplace_back(digest.select.pov->reg,
                                                           digest.type->gress);
                pov_use[digest.type->gress][digest.select.pov->reg.uid] = 1; } }
        for (auto &set : digest.layout)
            for (auto &reg : set.second)
                if (reg.check())
                    phv_use[digest.type->gress][reg->reg.uid] = 1; }
    if (options.match_compiler || 1) {  /* FIXME -- need proper liveness analysis */
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        int pov_byte = 0, pov_size = 0;
        for (auto &ent : pov_order[gress])
            if (pov[gress].count(&ent->reg) == 0) {
                pov[gress][&ent->reg] = pov_size;
                pov_size += ent->reg.size; }
        if (pov_size > 8*Target::DEPARSER_MAX_POV_BYTES())
            error(lineno[gress], "Ran out of space in POV in deparser"); }
}

template<class ENTRIES> static
void write_checksum_entry(ENTRIES &entry, unsigned mask, int swap, int id,
        const char* name = "entry") {
    BUG_CHECK(swap == 0 || swap == 1);
    BUG_CHECK(mask == 0 || mask & 3);
    if (entry.modified())
        error(1, "%s appears multiple times in checksum %d", name, id);
    entry.swap = swap;
    // CSR: The order of operation: data is swapped or not and then zeroed or not
    if (swap)
        mask = (mask & 0x2) >> 1 | (mask & 0x1) << 1;
    switch (mask) {
    case 0:
        entry.zero_m_s_b = 1;
        entry.zero_l_s_b = 1;
        break;
    case 1:
        entry.zero_m_s_b = 1;
        entry.zero_l_s_b = 0;
        break;
    case 2:
        entry.zero_m_s_b = 0;
        entry.zero_l_s_b = 1;
        break;
    case 3:
        entry.zero_m_s_b = 0;
        entry.zero_l_s_b = 0;
        break;
    default:
        break; }
}

// Used for field dictionary logging. Using fd entry and pov, a json::map
// is filled with appropriate field names
void write_field_name_in_json(const Phv::Register* phv, const Phv::Register* pov, int povBit,
                              json::map& chunk_byte, int stageno, gress_t gress) {
    auto povName_ = Phv::get_pov_name(pov->mau_id(), povBit);
    StringRef povName = povName_;
    StringRef headerName;
    if (auto *p = povName.findstr("$valid")) {
        headerName = povName.before(p);
    }
    std::string fieldNames;
    auto allFields = Phv::aliases(phv, stageno);
    for (auto fieldName : allFields) {
         if (fieldName.find(headerName.string()) != std::string::npos)
             fieldNames += (fieldName + ", ");
    }
    chunk_byte["PHV"] = phv->uid;
    chunk_byte["Field"] = fieldNames;
    return;
}


// Used for field dictionary logging. Using fd entry and pov, a json::map
// is filled with appropriate checksum or constant
void write_csum_const_in_json(int deparserPhvIdx,
                              json::map& chunk_byte, gress_t gress) {
    if (options.target == Target::Tofino::tag) {
        if (deparserPhvIdx >= 224 && deparserPhvIdx <= 235) {
            chunk_byte["Checksum"] = deparserPhvIdx - 224 - gress * 6;
        }
    } else if (options.target == Target::JBay::tag) {
        if (deparserPhvIdx > 224 && deparserPhvIdx < 232) {
            chunk_byte["Constant"] = Deparser::get_constant(gress, deparserPhvIdx - 224);
        } else {
            chunk_byte["Checksum"] = deparserPhvIdx - 232;
        }
    } else if (options.target == Target::Cloudbreak::tag) {
        if (deparserPhvIdx > 224 && deparserPhvIdx < 240) {
            chunk_byte["Constant"] = Deparser::get_constant(gress, deparserPhvIdx - 224);
        } else {
            chunk_byte["Checksum"] = deparserPhvIdx - 240;
        }
    }
    return;
}

#include "tofino/deparser.cpp"    // tofino template specializations
#if HAVE_JBAY
#include "jbay/deparser.cpp"      // jbay template specializations
#endif  // HAVE_JBAY
#if HAVE_CLOUDBREAK
#include "cloudbreak/deparser.cpp"      // cloudbreak template specializations
#endif  // HAVE_CLOUDBREAK

/* The following uses of specialized templates must be after the specialization... */
void Deparser::output(json::map& map) {
    SWITCH_FOREACH_TARGET(options.target,
        auto *regs = new TARGET::deparser_regs;
        declare_registers(regs);
        write_config(*regs);
        gen_learn_quanta(*regs, map["learn_quanta"]);
        return;
    )
    error(__LINE__, "Unsupported target %d", options.target);
}

/* this is a bit complicated since the output from compiler digest is as follows:
 context_json:
  0: [ [ ipv4.ihl, 0, 4, 0], [ ipv4.protocol, 0, 8, 1], [ ipv4.srcAddr, 0, 32, 2], [ ethernet.srcAddr, 0, 48, 6], [ ethernet.dstAddr, 0, 48, 12], [ ipv4.fragOffset, 0, 13, 18     ], [ ipv4.identification, 0, 16, 20], [ routing_metadata.learn_meta_1, 0, 20, 22], [ routing_metadata.learn_meta_4, 0, 10, 26] ]
  1: [ [ ipv4.ihl, 0, 4, 0], [ ipv4.identification, 0, 16, 1], [ ipv4.protocol, 0, 8, 3], [ ipv4.srcAddr, 0, 32, 4], [ ethernet.srcAddr, 0, 48, 8], [ ethernet.dstAddr, 0, 48,      14], [ ipv4.fragOffset, 0, 13, 20], [ routing_metadata.learn_meta_2, 0, 24, 22], [ routing_metadata.learn_meta_3, 0, 25, 26] ]
 name: [ learn_1, learn_2 ]
*/
template<class REGS>
void Deparser::gen_learn_quanta(REGS &regs, json::vector &learn_quanta) {
    for (auto &digest : digests) {
        if (digest.type->name != "learning") continue;
        BUG_CHECK(digest.context_json);
        auto namevec = (*(digest.context_json))["name"];
        auto &names = *(namevec->as_vector());
        auto digentry = digest.context_json->begin();
        // Iterate on names. for each name, get the corresponding digest entry and fill in
        for (auto &tname : names) {
            BUG_CHECK(digentry != digest.context_json->end());
            json::map quanta;
            quanta["name"] = (*tname).c_str();
            quanta["lq_cfg_type"] = digentry->first->as_number()->val;
            quanta["handle"] = unique_field_list_handle++;
            auto *digfields = digentry->second->as_vector();
            if (digfields) {
                auto &digfields_vec = *digfields;
                json::vector &fields = quanta["fields"];
                for (auto &tup : digfields_vec) {
                    auto &one = *(tup->as_vector());
                    BUG_CHECK(one.size() == 5);
                    json::map anon;
                    anon["field_name"] = (*(one[0])).clone();
                    anon["start_byte"] = (*(one[1])).clone();
                    anon["field_width"] = (*(one[2])).clone();
                    anon["start_bit"] = (*(one[3])).clone();
                    anon["phv_offset"] = (*(one[4])).clone();
                    fields.push_back(std::move(anon));
                }
            }
            digentry++;
            learn_quanta.push_back(std::move(quanta));
        }
    }
}

unsigned Deparser::FDEntry::Checksum::encode() {
    SWITCH_FOREACH_TARGET(options.target, return encode<TARGET::register_type>(); );
    return -1;
}

unsigned Deparser::FDEntry::Constant::encode() {
    SWITCH_FOREACH_TARGET(options.target, return encode<TARGET::register_type>(); );
    return -1;
}
