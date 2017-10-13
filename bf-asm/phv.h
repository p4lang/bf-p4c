#ifndef _phv_h_
#define _phv_h_

#include "sections.h"
#include "bfas.h"
#include "bitvec.h"
#include "json.h"
#include "misc.h"
#include "target.h"
#include <set>
#include <vector>

class Phv : public Section {
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void output(json::map &);
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
        // FIXME-PHV  various places depend on the uids matching container encoding
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
    };
    class Slice {
        static const Register invalid;
    public:
        const Register  &reg;
        int             lo, hi;
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
        void dbprint(std::ostream &out) const;
    };
protected:
    std::vector<Register *> regs;
    std::map<std::string, Slice> names[2];
private:
    std::map<const Register *, std::pair<gress_t, std::vector<std::string>>, ptrless<Register>>
                user_defined;
    bitvec      phv_use[2];
    std::map<std::string, int> phv_field_sizes [2];
    void init_phv(target_t);
    void gen_phv_field_size_map();
    int addreg(gress_t gress, const char *name, const value_t &what);
    int get_position_offset(gress_t gress, std::string name);
public:
    static const Slice *get(gress_t gress, const std::string &name) {
        phv.init_phv(options.target);
        auto it = phv.names[gress].find(name);
        if (it == phv.names[gress].end()) return 0;
        return &it->second; }
    static const Slice *get(gress_t gress, const char *name) {
        return get(gress, std::string(name)); }
    class Ref {
    protected:
        gress_t         gress;
        std::string     name_;
        int             lo, hi;
    public:
        int             lineno;
        Ref() : gress(INGRESS), lineno(-1) {}
        Ref(gress_t g, const value_t &n);
        Ref(gress_t g, int line, const std::string &n, int l, int h) :
            gress(g), name_(n), lo(l), hi(h), lineno(line) {}
        Ref(const Ref &r, int l, int h) : gress(r.gress), name_(r.name_),
            lo(r.lo < 0 ? l : r.lo + l), hi(r.lo < 0 ? h : r.lo + h),
            lineno(r.lineno) { assert(r.hi < 0 || hi <= r.hi); }
        Ref(const Register &r);
        explicit operator bool() const { return lineno >= 0; }
        Slice operator*() const {
            if (auto *s = phv.get(gress, name_)) {
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
            if (auto *s = phv.get(gress, name_)) {
                if (hi >= 0 && !Slice(*s, lo, hi).valid) {
                    error(lineno, "Invalid slice of %s", name_.c_str());
                    return false; }
                return true;
            } else if (lineno >= 0)
                error(lineno, "No phv record %s", name_.c_str());
            return false; }
        const char *name() const { return name_.c_str(); }
        std::string desc() const;
        int lobit() const { return lo < 0 ? 0 : lo; }
        unsigned size() const {
            if (lo >= 0) return hi - lo + 1;
            if (auto *s = phv.get(gress, name_)) return s->size();
            return 0; }
        bool merge(const Ref &r);
        void dbprint(std::ostream &out) const;
    };
    static const Register *reg(int idx)
        { assert(idx >= 0 && size_t(idx) < phv.regs.size()); return phv.regs[idx]; }
    static const bitvec &use(gress_t gress) { return phv.phv_use[gress]; }
    static void setuse(gress_t gress, const bitvec &u) { phv.phv_use[gress] |= u; }
    static void unsetuse(gress_t gress, const bitvec &u) { phv.phv_use[gress] -= u; }
    static void output_names(json::map &);
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

#endif /* _phv_h_ */
