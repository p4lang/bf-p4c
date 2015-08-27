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
    void rewrite() { write = false; }
    virtual unsigned long operator=(unsigned long v) = 0;
    virtual unsigned size() = 0;
};

inline std::ostream &operator<<(std::ostream &out, const ubits_base *u) {
    print_regname(out, u, u+1);
    return out; }

template<int N> struct ubits : ubits_base {
    ubits() : ubits_base() {}
    const ubits &check(std::true_type) {
	if (value >= (1UL << N)) {
            ERROR(value << " out of range for " << N << " bits in " << this);
	    value &= (1UL << N) - 1; }
        return *this; }
    const ubits &check(std::false_type) { return *this; }
    const ubits &check() {
	return check(std::integral_constant<bool, (N != sizeof(unsigned long) * CHAR_BIT)>{}); }
    ubits(unsigned long v) : ubits_base(v) { check(); }
    ubits(const ubits &) = delete;
    ubits(ubits &&) = default;
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
    unsigned size() { return N; }
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

class ustring;
std::ostream &operator<<(std::ostream &out, const ustring *u);
class ustring {
    std::string         value;
public:
    mutable bool        read = false, write = false;
    ustring() {}
    ustring(const ustring &) = default;
    ustring(ustring &&) = default;
    ustring &operator=(const ustring &) & = default;
    ustring &operator=(ustring &&) & = default;
    ~ustring() {}

    ustring(const std::string &a) : value(a) {}
    ustring &operator=(const std::string &a) {
        if (write)
            ERRWARN(value != a, "Overwriting \"" << value << "\" with \"" << a <<
                    "\" in " << this);
        value = a;
        LOG1(this << " = \"" << value << "\"");
        write = true;
        return *this; }
    ustring &operator=(const char *a) {
        if (write)
            ERRWARN(value != a, "Overwriting \"" << value << "\" with \"" << a <<
                    "\" in " << this);
        value = a;
        LOG1(this << " = \"" << value << "\"");
        write = true;
        return *this; }
    operator const std::string&() const { read = true; return value; }
    const char *c_str() const { read = true; return value.c_str(); }
    bool modified() const { return write; }
    void rewrite() { write = false; }
    friend std::ostream &operator<<(std::ostream &out, const ustring &u);
};

inline std::ostream &operator<<(std::ostream &out, const ustring *u) {
    print_regname(out, u, u+1);
    return out; }
inline std::ostream &operator<<(std::ostream &out, const ustring &u) {
    if (u.value.empty()) out << 0;
    else out << '"' << u.value << '"';
    return out; }

#endif /* _ubits_h_ */
