#ifndef _ubits_h_
#define _ubits_h_

#include <limits.h>
#include <iostream>
#include <functional>

void declare_registers(const void *addr, size_t sz, std::function<void(std::ostream &, const char *)> fn);
void undeclare_registers(const void *addr);
void print_regname(std::ostream &out, const void *addr);

template<int N> struct ubits {
    unsigned long	value;
    mutable bool        read;

    ubits() : value(0), read(false) {}
    const ubits &check() {
	if (N < sizeof(unsigned long) * CHAR_BIT && value >= (1UL << N)) {
	    std::cerr << "Value " << value << " out of range for " << N
		      << " bits" << std::endl;
	    value &= (1UL << N) - 1; }
        return *this; }
    void log(const char *op, unsigned long v) const {
        print_regname(std::clog, this);
        std::clog << ' ' << op << ' ' << v;
        if (v != value)
            std::clog << " (now " << value << ")";
            std::clog << std::endl; }
    ubits(unsigned long v) : value(v), read(false) { check(); }
    const ubits &operator=(unsigned long v) { value = v; log("=", v); return check(); }
    const ubits &operator|=(unsigned long v) { value |= v; log("|=", v); return check(); }
    const ubits &operator+=(unsigned long v) { value += v; log("+=", v); return check(); }
    operator unsigned long() const { read = true; return value; }
};

struct prefix {
    const prefix      *pfx;
    const char  *str;
    prefix(const prefix *p, const char *s) : pfx(p), str(s) {}
};

inline std::ostream &operator<<(std::ostream &out, const prefix *p) {
    if (p) {
        if (p->pfx) out << p->pfx << '.';
        out << p->str; }
    return out; }

#endif /* _ubits_h_ */
