#ifndef TOFINO_PHV_PHV_H_
#define TOFINO_PHV_PHV_H_

#include <string.h>
#include <iostream>
#include <array>
#include "lib/exceptions.h"

namespace PHV {

class Container {
    bool        tagalong_ : 1;
    unsigned    log2sz_ : 2;   // 3 (8 byte) means invalid
    unsigned    index_ : 13;
    Container(bool t, unsigned ls, unsigned i) : tagalong_(t), log2sz_(ls), index_(i) {}

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
        default: BUG("Invalid register '%s'", name); }
        int v = strtol(n, const_cast<char **>(&n), 10);
        index_ = v;
        if (*n || index_ != v)
            BUG("Invalid register '%s'", name); }
    size_t size() const { return 8U << log2sz_; }
    unsigned log2sz() const { return log2sz_; }
    unsigned index() const { return index_; }
    bool tagalong() const { return tagalong_; }
    explicit operator bool() const { return log2sz_ != 3; }
    Container operator++() {
        if (index_ != 0x7ff) ++index_;
        return *this; }
    Container operator++(int) { Container rv = *this; ++*this; return rv; }
    bool operator==(Container c) const {
        return tagalong_ == c.tagalong_ && log2sz_ == c.log2sz_ && index_ == c.index_; }
    bool operator!=(Container c) const { return !(*this == c); }
    bool operator<(Container c) const {
        return (tagalong_ << 15) + (log2sz_ << 13) + index_ <
               (c.tagalong_ << 15) + (c.log2sz_ << 13) + c.index_; }
    friend std::ostream &operator<<(std::ostream &out, Container c);
    static Container B(unsigned idx) { return Container(false, 0, idx); }
    static Container H(unsigned idx) { return Container(false, 1, idx); }
    static Container W(unsigned idx) { return Container(false, 2, idx); }
    static Container TB(unsigned idx) { return Container(true, 0, idx); }
    static Container TH(unsigned idx) { return Container(true, 1, idx); }
    static Container TW(unsigned idx) { return Container(true, 2, idx); }
    cstring toString() const {
        std::stringstream tmp;
        tmp << *this;
        return tmp.str(); }
};

inline std::ostream &operator<<(std::ostream &out, PHV::Container c) {
    return out << (c.tagalong_ ? "T" : "") << "BHW?"[c.log2sz_] << c.index_; }

}  // namespace PHV
#endif /* TOFINO_PHV_PHV_H_ */
