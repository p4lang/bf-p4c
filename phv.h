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
    public:
        const Register  &reg;
        int             lo, hi;
        bool            valid;
        Slice(const Register &r, int l, int h) : reg(r), lo(l), hi(h) {
            valid = lo >= 0 && hi >= lo && hi < reg.size; }
        Slice(const Register &r, int b) : reg(r), lo(b), hi(b) {
            valid = lo >= 0 && hi >= lo && hi < reg.size; }
        Slice(const Slice &s, int l, int h) : reg(s.reg), lo(s.lo + l), hi(s.lo + h) {
            valid = lo >= 0 && hi >= lo && hi < reg.size; }
        Slice(const Slice &) = default;
        //Slice &operator=(const Slice &a) { new(this) Slice(a.reg, a.lo, a.hi); return *this; }
    };
    const Slice *get(gress_t gress, const char *name);
    const Slice *get(gress_t gress, const std::string &name) { return get(gress, name.c_str()); }
private:
    Register regs[NUM_PHV_REGS];
    std::map<std::string, Slice> names[2];
    int addreg(gress_t gress, const char *name, value_t &what);
};

#endif /* _phv_h_ */
