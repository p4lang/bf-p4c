#ifndef _ubits_h_
#define _ubits_h_

#include <limits.h>
#include <iostream>
#include <functional>
#include "log.h"
#include <sstream>

void declare_registers(const void *addr, size_t sz, std::function<void(std::ostream &, const char *, const void *)> fn);
void undeclare_registers(const void *addr);
void print_regname(std::ostream &out, const void *addr, const void *end);

struct ubits_base;

struct ubits_base {
    unsigned long	value;
    mutable bool        read, write;

    ubits_base() : value(0), read(false), write(false) {}
    ubits_base(unsigned long v) : value(v), read(false), write(false) {}
    operator unsigned long() const { read = true; return value; }
    bool modified() const { return write; }
    virtual unsigned long operator=(unsigned long v) = 0;
};

inline std::ostream &operator<<(std::ostream &out, const ubits_base *u) {
    print_regname(out, u, u+1);
    return out; }

template<int N> struct ubits : ubits_base {
    ubits() : ubits_base() {}
    const ubits &check() {
	if (N < sizeof(unsigned long) * CHAR_BIT && value >= (1UL << N)) {
            ERROR(value << " out of range for " << N << " bits in " << this);
	    value &= (1UL << N) - 1; }
        return *this; }
    ubits(unsigned long v) : ubits_base(v) { check(); }
    ubits(const ubits &) = delete;
    ubits(ubits &&) = delete;
    void log(const char *op, unsigned long v) const {
        std::ostringstream tmp;
        LOG1(this << ' ' << op << ' ' << v <<
             (v != value ?  tmp << " (now " << value << ")", tmp : tmp).str()); }
    unsigned long operator=(unsigned long v) {
        if (write)
            ERRWARN(value != v, "Overwriting " << value << " with " << v << " in " << this);
        value = v;
        write = true;
        log("=", v);
        check();
        return v; }
    const ubits &operator|=(unsigned long v) {
        if (value & v)
            ERRWARN(value != (v|value), "Overwriting " << value << " with " << (v|value) <<
                    " in " << this);
        value |= v;
        write = true;
        log("|=", v);
        return check(); }
    const ubits &operator+=(unsigned long v) {
        value += v;
        write = true;
        log("+=", v);
        return check(); }
    const ubits &set_subfield(unsigned long v, unsigned bit, unsigned size) {
        if (bit + size > N)
            ERROR("subfield " << bit << ".." << (bit+size-1) <<
                  " out of range in " << this);
        else if ((value >> bit) & ((1U << size)-1))
            ERRWARN(((value >> bit) & ((1U << size)-1)) != v,
                    "Overwriting subfield(" << bit << ".." << (bit+size-1) <<
                    ") value " << ((value >> bit) & ((1U << size)-1)) <<
                    " with " << v << " in " << this);
        if (v >= (1U << size))
            ERROR("Subfield value " << v << " too large for " << size <<
                  " bits in " << this);
        value |= v << bit;
        write = true;
        log("|=", v << bit);
        return check(); }
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
