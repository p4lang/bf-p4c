#ifndef _TOFINO_PHV_PHV_H_
#define _TOFINO_PHV_PHV_H_

#include <string.h>
#include <iostream>
#include "lib/exceptions.h"

namespace PHV {

class Container {
    bool        tagalong_ : 1;
    unsigned    log2sz_ : 2;   // 3 (8 byte) means invalid
    unsigned    index_ : 13;

 public:
    Container() : tagalong_(false), log2sz_(3), index_(0) {}
    Container(const char *name) {       // NOLINT(runtime/explicit)
        const char *n = name;
        if (*name == 'T') {
            tagalong_ = true;
            n++;
        } else {
            tagalong_ = false; }
        switch (*n++) {
        case 'B': log2sz_ = 0; break;
        case 'H': log2sz_ = 1; break;
        case 'W': log2sz_ = 2; break;
        default: throw Util::CompilerBug("Invalid register '%s'", name); }
        int v = strtol(n, const_cast<char **>(&n), 10);
        index_ = v;
        if (*n || index_ != v)
            throw Util::CompilerBug("Invalid register '%s'", name); }

    size_t size() { return 8U << log2sz_; }
    explicit operator bool() { return log2sz_ != 3; }
    Container operator++() {
        if (index_ != 0x7ff) ++index_;
        return *this; }
    Container operator++(int) { Container rv = *this; ++*this; return rv; }
    bool operator==(Container c) {
        return tagalong_ == c.tagalong_ && log2sz_ == c.log2sz_ && index_ == c.index_; }
    friend std::ostream &operator<<(std::ostream &out, Container c);
};

inline std::ostream &operator<<(std::ostream &out, PHV::Container c) {
    return out << (c.tagalong_ ? "T" : "") << "BHW?"[c.log2sz_] << c.index_; }

}  // namespace PHV

#endif /* _TOFINO_PHV_PHV_H_ */
