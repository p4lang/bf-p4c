#ifndef _indent_h_
#define _indent_h_

#include <iostream>
#include <iomanip>

class indent_t {
    int         indent;
public:
    static int  tabsz;
    indent_t() : indent(0) {}
    indent_t(int i) : indent(i) {}
    indent_t &operator++() { ++indent; return *this; }
    indent_t &operator--() { --indent; return *this; }
    indent_t operator++(int) { indent_t rv = *this; ++indent; return rv; }
    indent_t operator--(int) { indent_t rv = *this; --indent; return rv; }
    friend std::ostream &operator<<(std::ostream &os, indent_t i);
    indent_t operator+(int v) { indent_t rv = *this; rv.indent += v; return rv; }
    indent_t operator-(int v) { indent_t rv = *this; rv.indent -= v; return rv; }
    indent_t &operator+=(int v) { indent += v; return *this; }
    indent_t &operator-=(int v) { indent += v; return *this; }
};

inline std::ostream &operator<<(std::ostream &os, indent_t i) {
    os << std::setw(i.indent * i.tabsz) << "";
    return os;
}

#endif /* _indent_h_ */
