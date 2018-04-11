#ifndef _register_reference_h_
#define _register_reference_h_

#include <iostream>
#include <functional>
#include "log.h"

/* used by `dump_unread` methods to hold a concatenation of string literals for printing.
 * Allocated on the stack, the `pfx` chain prints the calling context */
struct prefix {
    const prefix        *pfx;
    const char          *str;  // should always be a string literal
    prefix(const prefix *p, const char *s) : pfx(p), str(s) {}
};

inline std::ostream &operator<<(std::ostream &out, const prefix *p) {
    if (p) {
        if (p->pfx) out << p->pfx << '.';
        out << p->str; }
    return out; }


/* Class to link register trees together into a larger dag that will expand into a tree
 * when dumped as binary (so trees that appear in mulitple places will be duplicated)
 * 'name' is the json file name to use when dumping as cfg.json, and the name for logging       
 * 'tree' is the subtree to dump as binary at the appropriate offset
 */
template<class REG>
class register_reference {
    REG                 *tree = nullptr;
    std::string         name;
public:
    mutable bool        read = false, write = false, disabled_ = false;
    register_reference() {}
    register_reference(const register_reference &) = default;
    register_reference(register_reference &&) = default;
    register_reference &operator=(const register_reference &) & = default;
    register_reference &operator=(register_reference &&) & = default;
    ~register_reference() {}

    register_reference &set(const char *a, REG *r) {
        if (disabled_)
            ERROR("Writing disabled register value in " << this);
        if (write)
            ERRWARN(name != a || r != tree, "Overwriting \"" << name << "\" with \"" << a <<
                    "\" in " << this);
        name = a;
        tree = r;
        log();
        write = true;
        return *this; }
    const char *c_str() const { return name.c_str(); }
    REG *operator->() const { read = true; return tree; }
    explicit operator bool() const { return tree != nullptr; }
    bool modified() const { return write; }
    void set_modified(bool v = true) { write = v; }
    void rewrite() { write = false; }
    //friend std::ostream &operator<<(std::ostream &out, const register_reference<REG> &u);
    void enable() { disabled_ = false; }
    bool disabled() const { return disabled_; }
    bool disable_if_unmodified() { return false; }
    bool disable_if_zero() { return false; }
    bool disable_if_reset_value() { return false; }
    bool disable() {
        if (!name.empty()) {
            ERROR("Disabling modified register in " << this);
            return false; }
        tree = nullptr;
        disabled_ = true;
        return true; }
    void log() const { LOG1(this << " = \"" << name << "\""); }
};

template<class REG>
inline std::ostream &operator<<(std::ostream &out, const register_reference<REG> *u) {
    print_regname(out, u, u+1);
    return out; }
template<class REG>
inline std::ostream &operator<<(std::ostream &out, const register_reference<REG> &u) {
    if (!*u.c_str()) out << 0;
    else out << '"' << u.c_str() << '"';
    return out; }

#endif /* _register_reference_h_ */
