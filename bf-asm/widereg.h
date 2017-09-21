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
    bitvec              value;
    mutable bool        read, write;
    mutable bool        disabled;

    widereg_base() : read(false), write(false), disabled(false) {}
    widereg_base(bitvec v) : value(v), read(false), write(false), disabled(false) {}
    widereg_base(uintptr_t v) : value(v), read(false), write(false), disabled(false) {}
    operator bitvec() const { read = true; return value; }
    bool modified() const { return write; }
    bool disable_if_zero() const { return value.empty() && !write; }
    void disable() const {
        if (write) ERROR("Disabling modified register in " << this);
        disabled = true; };
    void enable() const { disabled = false; }
    void rewrite() { write = false; }
    virtual bitvec operator=(bitvec v) = 0;
    virtual unsigned size() = 0;
    void log(const char *op, bitvec v) const;
};

inline std::ostream &operator<<(std::ostream &out, const widereg_base *u) {
    print_regname(out, u, u+1);
    return out; }
inline std::ostream &operator<<(std::ostream &out, const widereg_base &u) {
    return out << u.value; }

template<int N> struct widereg : widereg_base {
    widereg() : widereg_base() {}
    const widereg &check() {
        if (value.max().index() >= N) {
            ERROR(value << " out of range for " << N << " bits in " << this);
            value.clrrange(N, value.max().index() - N + 1); }
        return *this; }
    widereg(bitvec v) : widereg_base(v) { check(); }
    widereg(const widereg &) = delete;
    widereg(widereg &&) = default;
    bitvec operator=(bitvec v) {
        if (disabled)
            ERROR("Writing disabled register value in " << this);
        if (write)
            ERRWARN(value != v, "Overwriting " << value << " with " << v << " in " << this);
        value = v;
        write = true;
        log("=", v);
        check();
        return v; }
    const widereg &operator=(const widereg &v) { *this = v.value; v.read = true; return v; }
    const widereg_base &operator=(const widereg_base &v) {
        *this = v.value; v.read = true; return v; }
    unsigned size() { return N; }
    const widereg &operator|=(bitvec v) {
        if (disabled)
            ERROR("Writing disabled register value in " << this);
        if (write && (value & v))
            ERRWARN(value != (v|value), "Overwriting " << value << " with " << (v|value) <<
                    " in " << this);
        value |= v;
        write = true;
        log("|=", v);
        return check(); }
    const widereg &set_subfield(uintptr_t v, unsigned bit, unsigned size) {
        if (disabled)
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
