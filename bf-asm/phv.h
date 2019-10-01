#ifndef _phv_h_
#define _phv_h_

#include "sections.h"
#include "bfas.h"
#include "bitvec.h"
#include "json.h"
#include "misc.h"
#include "target.h"
#include "match_source.h"
#include <set>
#include <vector>

class Phv : public Section {
    void start(int lineno, VECTOR(value_t) args) override;
    void input(VECTOR(value_t) args, value_t data) override;
    void output(json::map &) override;
    Phv() : Section("phv") {}
    Phv(const Phv &) = delete;
    Phv &operator=(const Phv &) = delete;
    ~Phv() {}
    static Phv phv;  // singleton class
    Target::Phv *target = nullptr;
    FOR_ALL_TARGETS(FRIEND_TARGET_CLASS, ::Phv)
public:
    struct Register {
        char                                            name[8];
        enum type_t { NORMAL, TAGALONG, CHECKSUM, MOCHA, DARK }   type;
        // uid is used for "phv_number" in the context.json, but otherwise is just
        // a unique id for the register, encoded differently for different targets
        unsigned short                                  index, uid, size;
        Register() {}
        Register(const Register &) = delete;
        Register &operator=(const Register &) = delete;
        Register(const char *n, type_t t, unsigned i, unsigned u, unsigned s)
        : type(t), index(i), uid(u), size(s) { strncpy(name, n, sizeof(name)); name[7] = 0; }
        bool operator==(const Register &a) const { return uid == a.uid; }
        bool operator!=(const Register &a) const { return uid != a.uid; }
        bool operator<(const Register &a) const { return uid < a.uid; }
        virtual int parser_id() const { return -1; }
        virtual int mau_id() const { return -1; }
        virtual int ixbar_id() const { return -1; }
        virtual int deparser_id() const { return -1; }
        /// return a string representation based on the container type
        const char *type_to_string() const {
            switch (type) {
            case NORMAL:   return "normal";
            case TAGALONG: return "tagalong";
            case CHECKSUM: return "checksum";
            case MOCHA:    return "mocha";
            case DARK:     return "dark";
            }
            return "";
        }
    };
    class Slice {
        static const Register invalid;
    public:
        const Register  &reg;
        int             lo = -1, hi = -1;
        bool            valid;
        Slice() : reg(invalid), valid(false) {}
        Slice(const Register &r, int l, int h) : reg(r), lo(l), hi(h) {
            valid = lo >= 0 && hi >= lo && hi < reg.size; }
        Slice(const Register &r, int b) : reg(r), lo(b), hi(b) {
            valid = lo >= 0 && hi >= lo && hi < reg.size; }
        Slice(const Slice &s, int l, int h) : reg(s.reg), lo(s.lo + l), hi(s.lo + h) {
            valid = lo >= 0 && hi >= lo && hi <= s.hi && hi < reg.size; }
        Slice(const Slice &) = default;
        explicit operator bool() const { return valid; }
        Slice &operator=(const Slice &a) { new(this) Slice(a.reg, a.lo, a.hi); return *this; }
        const Slice *operator->() const { return this; }
        bool operator==(const Slice &s) const {
            return valid && s.valid && reg.uid == s.reg.uid &&
                   lo == s.lo && hi == s.hi; }
        bool operator<(const Slice &a) const {
            if (reg.uid < a.reg.uid) return true;
            if (reg.uid > a.reg.uid) return false;
            if (lo < a.lo) return true;
            if (lo > a.lo) return false;
            return (hi < a.hi); }
        bool overlaps(const Slice &a) const {
            return valid && a.valid && reg.uid == a.reg.uid &&
                lo <= a.hi && a.lo <= hi; }
        unsigned size() const { return valid ? hi - lo + 1 : 0; }
        std::string toString() const;
        void dbprint(std::ostream &out) const;
    };
protected:
    std::vector<Register *> regs;
    struct PerStageInfo {
        int     max_stage = INT_MAX;
        Slice   slice;
    };
    std::map<std::string, std::map<int, PerStageInfo>> names[3];
private:
    typedef std::map<int, std::vector<std::string>> user_stagenames_t;
    std::map<const Register *, std::pair<gress_t, user_stagenames_t>, ptrless<Register>>
                user_defined;
    bitvec      phv_use[3];
    std::map<std::string, int> phv_field_sizes [3];
    std::map<std::string, int> phv_pov_field_sizes [3];

    // Maps P4-level field names (i.e. returned by stack_asm_name_to_p4()) to a
    // map to be embedded in the field's context_json "records" node.
    // Eg. field_context_json["hdr.f1"]["live_start"] == "\"parser\"".
    std::map<std::string, json::map> field_context_json;

    void init_phv(target_t);
    void gen_phv_field_size_map();
    int addreg(gress_t gress, const char *name, const value_t &what,
               int stage = -1, int max_stage = INT_MAX);
    int get_position_offset(gress_t gress, std::string name);
    void add_phv_field_sizes(gress_t gress, std::string name, int size) {
        bool is_pov = (name.find(".$valid") != std::string::npos);
        auto &phv_field_map = is_pov ? phv_pov_field_sizes : phv_field_sizes;
        phv_field_map[gress][name] += size; }
    int get_phv_field_size(gress_t gress, std::string name) {
        if (phv_field_sizes[gress].count(name) > 0)
            return phv_field_sizes[gress][name];
        if (phv_pov_field_sizes[gress].count(name) > 0)
            return phv_pov_field_sizes[gress][name];
        return 0; }
public:
    static const Slice *get(gress_t gress, int stage, const std::string &name) {
        phv.init_phv(options.target);
        if (!phv.names[gress].count(name)) return 0;
        auto &per_stage = phv.names[gress].at(name);
        auto it = per_stage.upper_bound(stage);
        if (it == per_stage.begin()) {
            if (it == per_stage.end() || stage != -1)
                return 0;
        } else {
            --it; }
        if (stage > it->second.max_stage ) return 0;
        return &it->second.slice; }
    static const Slice *get(gress_t gress, int stg, const char *name) {
        return get(gress, stg, std::string(name)); }
    class Ref : public MatchSource{
    protected:
        gress_t         gress_;
        std::string     name_;
        int             stage;
        int             lo, hi;
    public:
        int             lineno;
        Ref() : gress_(INGRESS), lineno(-1) {}
        Ref(gress_t g, int stage, const value_t &n);
        Ref(gress_t g, int stage, int line, const std::string &n, int l, int h) :
            gress_(g), name_(n), stage(stage), lo(l), hi(h), lineno(line) {}
        Ref(const Ref &r, int l, int h) : gress_(r.gress_), name_(r.name_), stage(r.stage),
            lo(r.lo < 0 ? l : r.lo + l), hi(r.lo < 0 ? h : r.lo + h),
            lineno(r.lineno) { BUG_CHECK(r.hi < 0 || hi <= r.hi); }
        Ref(const Register &r, gress_t gr, int lo = -1, int hi = -1);
        explicit operator bool() const { return lineno >= 0; }
        Slice operator*() const {
            if (auto *s = phv.get(gress_, stage, name_)) {
                if (hi >= 0) return Slice(*s, lo, hi);
                return *s;
            } else {
                error(lineno, "No phv record %s", name_.c_str());
                return Slice(); } }
        Slice operator->() const { return **this; }
        bool operator==(const Ref &a) const {
            if (name_ == a.name_ && lo == a.lo && hi == a.hi)
                return true;
            return **this == *a; }
        bool check() const {
            if (auto *s = phv.get(gress_, stage, name_)) {
                if (hi >= 0 && !Slice(*s, lo, hi).valid) {
                    error(lineno, "Invalid slice of %s", name_.c_str());
                    return false; }
                return true;
            } else if (lineno >= 0)
                error(lineno, "No phv record %s", name_.c_str());
            return false; }
        gress_t gress() const { return gress_; }
        const char *name() const override { return name_.c_str(); }
        std::string desc() const;
        int lobit() const { return lo < 0 ? 0 : lo; }
        int hibit() const { return hi < 0 ? (**this).size() - 1 : hi; }
        unsigned size() const override {
            if (lo >= 0) return hi - lo + 1;
            if (auto *s = phv.get(gress_, stage, name_)) return s->size();
            return 0; }
        bool merge(const Ref &r);
        std::string toString() const override;
        void dbprint(std::ostream &out) const;

        int get_lineno() const override { return lineno; }
        int fieldlobit() const override { return lobit(); }
        int fieldhibit() const override { return hibit(); }
        int slicelobit() const override { return (**this).lo; }
        int slicehibit() const override { return (**this).hi; }
    };

    static const Register *reg(int idx)
        { BUG_CHECK(idx >= 0 && size_t(idx) < phv.regs.size()); return phv.regs[idx]; }
    static const bitvec &use(gress_t gress) { return phv.phv_use[gress]; }
    static void setuse(gress_t gress, const bitvec &u) { phv.phv_use[gress] |= u; }
    static void unsetuse(gress_t gress, const bitvec &u) { phv.phv_use[gress] -= u; }
    static void output_names(int, json::map &);
    static std::string db_regset(const bitvec &s);
    static unsigned mau_groupsize();
};

extern void merge_phv_vec(std::vector<Phv::Ref> &vec, const Phv::Ref &r);
extern void merge_phv_vec(std::vector<Phv::Ref> &v1, const std::vector<Phv::Ref> &v2);
extern std::vector<Phv::Ref> split_phv_bytes(const Phv::Ref &r);
extern std::vector<Phv::Ref> split_phv_bytes(const std::vector<Phv::Ref> &v);

class Target::Phv {
    friend class ::Phv;
    virtual void init_regs(::Phv &) = 0;
    virtual target_t type() const = 0;
    virtual unsigned mau_groupsize() const = 0;
};

inline unsigned Phv::mau_groupsize() { return phv.target->mau_groupsize(); }

#include "tofino/phv.h"
#if HAVE_JBAY
#include "jbay/phv.h"
#endif // HAVE_JBAY
#if HAVE_CLOUDBREAK
#include "cloudbreak/phv.h"
#endif // HAVE_CLOUDBREAK

#endif /* _phv_h_ */
