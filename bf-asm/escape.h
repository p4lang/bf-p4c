#ifndef BF_ASM_ESCAPE_H_
#define BF_ASM_ESCAPE_H_

#include <iostream>
#include <iomanip>
#include "hex.h"

class escape {
    std::string str;
 public:
    explicit escape(const std::string &s) : str(s) {}
    friend std::ostream &operator<<(std::ostream &os, escape e);
};

inline std::ostream &operator<<(std::ostream &os, escape e) {
    for (char ch : e.str) {
        switch (ch) {
        case '\n': os << "\\n"; break;
        case '\t': os << "\\t"; break;
        case '\\': os << "\\\\"; break;
        default:
            if (ch < 32 || ch >= 127)
                os << "\\x" << hex(ch & 0xff, 2, '0');
            else
                os << ch; } }
    return os;
}

#endif /* BF_ASM_ESCAPE_H_ */
