#include "asm_output.h"

StringRef trim_asm_name(StringRef name) {
    if (auto *p = name.findlast('['))
        if (strchr(p, ':'))
            name = name.before(p);
    if (auto *p = name.findlast(':'))
        name = name.after(p+1);
    return name;
}

std::ostream &operator<<(std::ostream &out, canon_name n) {
    for (auto ch : n.name) {
        if (ch & ~0x7f) continue;
        if (isalnum(ch) || ch == '_' || ch == '.' || ch == '$' || ch == '-')
            out << ch;
        if (ch == '[')
            out << '$'; }
    return out;
}

