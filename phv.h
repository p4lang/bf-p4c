#ifndef _phv_h_
#define _phv_h_

#include "sections.h"

enum {
    NUM_PHV_REGS = 384
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
        unsigned short index, size;
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
            valid = lo >= 0 && hi >= lo && hi < reg.size; }
        Slice(const Slice &) = default;
        //Slice &operator=(const Slice &a) { new(this) Slice(a.reg, a.lo, a.hi); return *this; }
	const Slice *operator->() const { return this; }
        const bool operator==(const Slice &s) {
            return valid && s.valid && reg.index == s.reg.index &&
                   lo == s.lo && hi == s.hi; }
    };
private:
    Register regs[NUM_PHV_REGS];
    std::map<std::string, Slice> names[2];
    int addreg(gress_t gress, const char *name, value_t &what);
public:
    const Slice *get(gress_t gress, const char *name) {
        auto it = names[gress].find(name);
        if (it == names[gress].end()) return 0;
        return &it->second; }
    const Slice *get(gress_t gress, const std::string &name) {
        return get(gress, name.c_str()); }
    class Ref {
	gress_t		gress;
	std::string	name_;
	int		lo, hi;
    public:
	int		lineno;
	Ref(gress_t g, value_t &n);
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
	bool check() {
	    if (auto *s = phv.get(gress, name_)) {
		if (hi >= 0 && !Slice(*s, lo, hi).valid) {
		    error(lineno, "Invalid slice of %s", name_.c_str());
                    return false; }
	    } else {
		error(lineno, "No phv record %s", name_.c_str());
                return false; }
            return true; }
        const char *name() const { return name_.c_str(); }
        void dbprint(std::ostream &out) const;
    };
};

inline std::ostream &operator<<(std::ostream &out, const Phv::Ref &r) {
    r.dbprint(out); return out; }

#endif /* _phv_h_ */
