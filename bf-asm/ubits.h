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
    unsigned long       value;
    mutable bool        read, write;
    mutable bool        disabled;

    ubits_base() : value(0), read(false), write(false), disabled(false) {}
    ubits_base(unsigned long v) : value(v), read(false), write(false), disabled(false) {}
    operator unsigned long() const { read = true; return value; }
    bool modified() const { return write; }
    bool disable_if_zero() const { return value == 0 && !write; }
    bool disable() const {
        if (write) {
            ERROR("Disabling modified register in " << this);
            return false; }
        disabled = true;
        return disabled; }
    void enable() const { disabled = false; };
    void rewrite() { write = false; }
    virtual unsigned long operator=(unsigned long v) = 0;
    virtual const ubits_base &operator|=(unsigned long v) = 0;
    virtual unsigned size() = 0;
    void log(const char *op, unsigned long v) const;
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
    unsigned long operator=(unsigned long v) override {
        if (disabled)
            ERROR("Writing disabled register value in " << this);
        if (write)
            ERRWARN(value != v, "Overwriting " << value << " with " << v << " in " << this);
        value = v;
        write = true;
        log("=", v);
        check();
        return v; }
    const ubits &operator=(const ubits &v) { *this = v.value; v.read = true; return v; }
    const ubits_base &operator=(const ubits_base &v) { *this = v.value; v.read = true; return v; }
    unsigned size() override { return N; }
    const ubits &operator|=(unsigned long v) override {
        if (disabled)
            ERROR("Writing disabled register value in " << this);
        if (write && (value & v))
            ERRWARN(value != (v|value), "Overwriting " << value << " with " << (v|value) <<
                    " in " << this);
        value |= v;
        write = true;
        log("|=", v);
        return check(); }
    const ubits &operator+=(unsigned long v) {
        if (disabled)
            ERROR("Overwriting disabled register value in " << this);
        value += v;
        write = true;
        log("+=", v);
        return check(); }
    const ubits &set_subfield(unsigned long v, unsigned bit, unsigned size) {
        if (disabled)
            ERROR("Overwriting disabled register value in " << this);
        if (bit + size > N)
            ERROR("subfield " << bit << ".." << (bit+size-1) <<
                  " out of range in " << this);
        else if (write && ((value >> bit) & ((1U << size)-1)))
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

#endif /* _ubits_h_ */
