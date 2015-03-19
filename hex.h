#ifndef _hex_h_
#define _hex_h_

#include <iostream>
#include <iomanip>
#include <vector>

class hex {
    intmax_t	val;
    int		width;
    char	fill;
public:
    hex(intmax_t v, int w=0, char f=' ') : val(v), width(w), fill(f) {}
    hex(void *v, int w=0, char f=' ') : val((intmax_t)v), width(w), fill(f) {}
    friend std::ostream &operator<<(std::ostream &os, const hex &h);
};

inline std::ostream &operator<<(std::ostream &os, const hex &h) {
    auto save = os.flags();
    os << std::hex << std::setw(h.width) << std::setfill(h.fill) << h.val;
    os.flags(save);
    return os; }

class hexvec {
    void        *data;
    size_t      elsize, len;
    int		width;
    char	fill;
public:
    template<typename I> hexvec(I *d, size_t l, int w=0, char f=' ') :
        data(d), elsize(sizeof(I)), len(l), width(w), fill(f) {}
    template<typename T> hexvec(std::vector<T> &d, int w=0, char f=' ') :
        data(d.data()), elsize(sizeof(T)), len(d.size()), width(w), fill(f) {}
    friend std::ostream &operator<<(std::ostream &os, const hexvec &h);
};

std::ostream &operator<<(std::ostream &os, const hexvec &h);

#endif /* _hex_h_ */
