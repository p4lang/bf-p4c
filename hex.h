#ifndef _hex_h_
#define _hex_h_

#include <iostream>
#include <iomanip>

class hex {
    intmax_t	val;
    int		width;
    char	fill;
public:
    hex(intmax_t v, int w=0, char f=' ') : val(v), width(w), fill(f) {}
    hex(void *v, int w=0, char f=' ') : val((intmax_t)v), width(w), fill(f) {}
    friend std::ostream &operator<<(std::ostream &os, const hex &h);
};

std::ostream &operator<<(std::ostream &os, const hex &h) {
    auto save = os.flags();
    os << std::hex << std::setw(h.width) << std::setfill(h.fill) << h.val;
    os.flags(save);
    return os; }

#endif /* _hex_h_ */
