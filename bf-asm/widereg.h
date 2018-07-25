#ifndef _widereg_h_
#define _widereg_h_

#include <limits.h>
#include <iostream>
#include <functional>
#include "log.h"
#include <sstream>
#include "bitvec.h"

void print_regname(std::ostream &out, const void *addr, const void *end);

struct widereg_base;

struct widereg_base {
    bitvec              value, reset_value;
    mutable bool        read, write;
    mutable bool        disabled_;

    widereg_base() : read(false), write(false), disabled_(false) {}
    widereg_base(bitvec v) : value(v), reset_value(v), read(false), write(false), disabled_(false) {}
    widereg_base(uintptr_t v) : value(v), reset_value(v), read(false), write(false),
                                disabled_(false) {}
#if __WORDSIZE == 64
    // For 32-bit systems intptr_t is defined as int
    widereg_base(intptr_t v) : value(v), reset_value(v), read(false), write(false),
                               disabled_(false) {}
#endif
    widereg_base(int v) : reset_value(v), value(v), read(false), write(false), disabled_(false) {}
    operator bitvec() const { read = true; return value; }
    bool modified() const { return write; }
    void set_modified(bool v = true) { write = v; }
    bool disabled() const { return disabled_; }
    bool disable_if_unmodified() { return write ? false : (disabled_ = true); }
    bool disable_if_zero() const { return value.empty() && !write; }
    bool disable_if_reset_value() { return value == reset_value ? disabled_ = true : false; }
    bool disable() const {
        if (write) {
            ERROR("Disabling modified register in " << this);
            return false; }
        disabled_ = true;
        return disabled_; };
    void enable() const { disabled_ = false; }
    void rewrite() { write = false; }
    virtual bitvec operator=(bitvec v) = 0;
    virtual unsigned size() = 0;
    void log(const char *op, bitvec v) const;
};

inline static unsigned int to_unsigned(const bitvec& v) {
    std::stringstream ss;
    ss << v;
    std::string str(ss.str());
    unsigned int rv = std::strtoul(str.c_str(), 0, 16);
    return rv;
}

inline std::ostream &operator<<(std::ostream &out, const widereg_base *u) {
    print_regname(out, u, u+1);
    return out; }
inline std::ostream &operator<<(std::ostream &out, const widereg_base &u) {
    return out << to_unsigned(u.value); }

template<int N> struct widereg : widereg_base {
    widereg() : widereg_base() {}
    const widereg &check() {
        if (value.max().index() >= N) {
            ERROR(value << " out of range for " << N << " bits in " << this);
            value.clrrange(N, value.max().index() - N + 1); }
        return *this; }
    widereg(bitvec v) : widereg_base(v) { check(); }
    widereg(uintptr_t v) : widereg_base(v) { check(); }
#if __WORDSIZE == 64
    // For 32-bit systems intptr_t is defined as int
    widereg(intptr_t v) : widereg_base(v) { check(); }
#endif
    widereg(int v) : widereg_base(v) { check(); }
    widereg(const widereg &) = delete;
    widereg(widereg &&) = default;
    bitvec operator=(bitvec v) {
        if (disabled_)
            ERROR("Writing disabled register value in " << this);
        if (write)
            ERRWARN(value != v, "Overwriting " << value << " with " << v << " in " << this);
        value = v;
        write = true;
        log("=", v);
        check();
        return v; }
    uintptr_t operator=(uintptr_t v) { *this = bitvec(v); return v; }
    intptr_t operator=(intptr_t v) { *this = bitvec(v); return v; }
    const widereg &operator=(const widereg &v) { *this = v.value; v.read = true; return v; }
    const widereg_base &operator=(const widereg_base &v) {
        *this = v.value; v.read = true; return v; }
    unsigned size() { return N; }
    const widereg &operator|=(bitvec v) {
        if (disabled_)
            ERROR("Writing disabled register value in " << this);
        if (write && (value & v))
            ERRWARN(value != (v|value), "Overwriting " << value << " with " << (v|value) <<
                    " in " << this);
        value |= v;
        write = true;
        log("|=", v);
        return check(); }
    const widereg &set_subfield(uintptr_t v, unsigned bit, unsigned size) {
        if (disabled_)
            ERROR("Writing disabled register value in " << this);
        if (bit + size > N)
            ERROR("subfield " << bit << ".." << (bit+size-1) <<
                  " out of range in " << this);
        else if (auto o = value.getrange(bit, size)) {
            if (write)
                ERRWARN(o != v, "Overwriting subfield(" << bit << ".." << (bit+size-1) <<
                        ") value " << o << " with " << v << " in " << this); }
        if (v >= (1U << size))
            ERROR("Subfield value " << v << " too large for " << size <<
                  " bits in " << this);
        value.putrange(bit, size, v);
        write = true;
        log("|=", bitvec(v) << bit);
        return check(); }
};

#endif /* _widereg_h_ */
