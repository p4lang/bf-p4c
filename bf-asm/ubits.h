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
    uint64_t      value, reset_value;
    mutable bool  read, write;
    mutable bool  disabled_;

    ubits_base() : value(0), reset_value(0), read(false), write(false), disabled_(false) {}
    ubits_base(uint64_t v) : value(v), reset_value(v), read(false), write(false),
                                  disabled_(false) {}
    operator uint64_t() const { read = true; return value; }
    bool modified() const { return write; }
    void set_modified(bool v = true) { write = v; }
    bool disabled() const { return disabled_; }
    bool disable_if_unmodified() { return write ? false : (disabled_ = true); }
    bool disable_if_zero() const { return value == 0 && !write; }
    bool disable_if_reset_value() { return value == reset_value ? disabled_ = true : false; }
    bool disable() const {
        if (write) {
            ERROR("Disabling modified register in " << this);
            return false; }
        disabled_ = true;
        return disabled_; }
    void enable() const { disabled_ = false; };
    void rewrite() { write = false; }
    virtual uint64_t operator=(uint64_t v) = 0;
    virtual const ubits_base &operator|=(uint64_t v) = 0;
    virtual unsigned size() = 0;
    void log(const char *op, uint64_t v) const;
};

inline std::ostream &operator<<(std::ostream &out, const ubits_base *u) {
    print_regname(out, u, u+1);
    return out; }

template<int N> struct ubits : ubits_base {
    ubits() : ubits_base() {}
    const ubits &check(std::true_type) {
        if (value >= (uint64_t(1) << N)) {
            ERROR(value << " out of range for " << N << " bits in " << this);
            value &= (uint64_t(1) << N) - 1; }
        return *this; }
    const ubits &check(std::false_type) { return *this; }
    const ubits &check() {
        return check(std::integral_constant<bool, (N != sizeof(uint64_t) * CHAR_BIT)>{}); }
    ubits(uint64_t v) : ubits_base(v) { check(); }
    ubits(const ubits &) = delete;
    ubits(ubits &&) = default;
    uint64_t operator=(uint64_t v) override {
        if (disabled_)
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
    const ubits &operator|=(uint64_t v) override {
        if (disabled_)
            ERROR("Writing disabled register value in " << this);
        if (write && (value & v))
            ERRWARN(value != (v|value), "Overwriting " << value << " with " << (v|value) <<
                    " in " << this);
        value |= v;
        write = true;
        log("|=", v);
        return check(); }
    const ubits &operator+=(uint64_t v) {
        if (disabled_)
            ERROR("Overwriting disabled register value in " << this);
        value += v;
        write = true;
        log("+=", v);
        return check(); }
    const ubits &set_subfield(uint64_t v, unsigned bit, unsigned size) {
        if (disabled_)
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
