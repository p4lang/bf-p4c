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
    auto name = n.name;
    if (auto cl = name.findstr("::"))
        name = name.after(cl);
    for (auto ch : name) {
        if (ch & ~0x7f) continue;
        if (isalnum(ch) || ch == '_' || ch == '.' || ch == '$' || ch == '-')
            out << ch;
        if (ch == '[')
            out << '$'; }
    return out;
}

std::ostream &operator<<(std::ostream &out, const Slice &sl) {
    out << canon_name(trim_asm_name(sl.field->name));
    for (auto &alloc : sl.field->alloc[sl.gress]) {
        if (sl.lo < alloc.field_bit) continue;
        if (sl.hi > alloc.field_hi())
            WARNING("Slice not contained within a single PHV container");
        if (alloc.field_bit != 0 || alloc.width != sl.field->size)
            out << '.' << alloc.field_bit << '-' << alloc.field_hi();
        if (sl.lo != alloc.field_bit || sl.hi != alloc.field_hi()) {
            out << '(' << (sl.lo - alloc.field_bit);
            if (sl.hi > sl.lo) out << ".." << (sl.hi - alloc.field_bit);
            out << ')'; }
        break; }
    return out;
}

Slice Slice::join(Slice &a) const {
    if (field != a.field || hi + 1 != a.lo || gress != a.gress) return Slice();
    /* don't join if the slices were allocated to different PHV containers */
    for (auto &alloc : field->alloc[gress]) {
        if (lo < alloc.field_bit) continue;
        if (a.hi > alloc.field_hi()) return Slice();
        break; }
    return Slice(field, gress, lo, a.hi);
}
