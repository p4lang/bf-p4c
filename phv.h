#ifndef _phv_h_
#define _phv_h_

#include "sections.h"
#include "bitvec.h"
#include "json.h"
#include <set>
#include <vector>

enum {
    NUM_PHV_REGS = 368,
    FIRST_8BIT_PHV = 64,
    COUNT_8BIT_PHV = 64,
    FIRST_16BIT_PHV = 128,
    COUNT_16BIT_PHV = 96,
    FIRST_32BIT_PHV = 0,
    COUNT_32BIT_PHV = 64,
    FIRST_TPHV = 256,
    FIRST_8BIT_TPHV = 288,
    COUNT_8BIT_TPHV = 32,
    FIRST_16BIT_TPHV = 320,
    COUNT_16BIT_TPHV = 48,
    FIRST_32BIT_TPHV = 256,
    COUNT_32BIT_TPHV = 32,
};

class Phv : public Section {
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void output() {}
    Phv();
    ~Phv() {}
    static Phv phv;
public:
    struct Register {
        char            name[8];
        unsigned short  index, size;
        bool operator==(const Register &a) const { return index == a.index; }
        bool operator!=(const Register &a) const { return index != a.index; }
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
        explicit operator bool() { return valid; }
        Slice &operator=(const Slice &a) { new(this) Slice(a.reg, a.lo, a.hi); return *this; }
        const Slice *operator->() const { return this; }
        bool operator==(const Slice &s) const {
            return valid && s.valid && reg.index == s.reg.index &&
                   lo == s.lo && hi == s.hi; }
        unsigned size() const { return valid ? hi - lo + 1 : 0; }
        void dbprint(std::ostream &out) const;
    };
private:
    Register regs[NUM_PHV_REGS];
    std::map<std::string, Slice> names[2];
    std::map<int, std::pair<gress_t, std::vector<std::string>>> user_defined;
    bitvec      phv_use[2];
    int addreg(gress_t gress, const char *name, const value_t &what);
public:
    static const Slice *get(gress_t gress, const std::string &name) {
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
        explicit operator bool() { return lineno >= 0; }
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
        bool check(bool mau = false) const {
            if (auto *s = phv.get(gress, name_)) {
                if (hi >= 0 && !Slice(*s, lo, hi).valid) {
                    error(lineno, "Invalid slice of %s", name_.c_str());
                    return false; }
                if (mau && s->reg.index >= FIRST_TPHV) {
                    error(lineno, "Can't access tagalong phv in mau: %s", name_.c_str());
                    return false; }
                return true;
            } else if (lineno >= 0)
                error(lineno, "No phv record %s", name_.c_str());
            return false; }
        const char *name() const { return name_.c_str(); }
        int lobit() const { return lo < 0 ? 0 : lo; }
        unsigned size() const {
            if (lo >= 0) return hi - lo + 1;
            if (auto *s = phv.get(gress, name_)) return s->size();
            return 0; }
        bool merge(const Ref &r);
        void dbprint(std::ostream &out) const;
    };
    static const Register &reg(int idx)
        { assert(idx >= 0 && idx < NUM_PHV_REGS); return phv.regs[idx]; }
    static const bitvec &use(gress_t gress) { return phv.phv_use[gress]; }
    static const bitvec tagalong_groups[8];
    static void setuse(gress_t gress, const bitvec &u) { phv.phv_use[gress] |= u; }
    static void unsetuse(gress_t gress, const bitvec &u) { phv.phv_use[gress] -= u; }
    static void output_names(json::map &);
    static std::string db_regset(const bitvec &s);
};

extern void merge_phv_vec(std::vector<Phv::Ref> &vec, const Phv::Ref &r);
extern void merge_phv_vec(std::vector<Phv::Ref> &v1, const std::vector<Phv::Ref> &v2);
extern std::vector<Phv::Ref> split_phv_bytes(const Phv::Ref &r);
extern std::vector<Phv::Ref> split_phv_bytes(const std::vector<Phv::Ref> &v);

#endif /* _phv_h_ */
