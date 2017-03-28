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
    if (sl.field) {
        out << canon_name(trim_asm_name(sl.field->name));
        for (auto &alloc : sl.field->alloc) {
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
    } else {
        out << sl.reg;
        if (sl.lo != 0 || sl.hi+1U != sl.reg.size()) {
            out << '(' << sl.lo;
            if (sl.lo != sl.hi) out << ".." << sl.hi;
            out << ')'; } }
    return out;
}

Slice Slice::join(Slice &a) const {
    if (field != a.field || reg != a.reg || hi + 1 != a.lo) return Slice();
    if (!field)
        return Slice(reg, lo, a.hi);
    /* don't join if the slices were allocated to different PHV containers */
    for (auto &alloc : field->alloc) {
        if (lo < alloc.field_bit) continue;
        if (a.hi > alloc.field_hi()) return Slice();
        break; }
    return Slice(field, lo, a.hi);
}

int Slice::bytealign() const {
    if (field) {
        auto &alloc = field->for_bit(lo);
        return (lo - alloc.field_bit + alloc.container_bit) & 7; }
    return lo & 7;
}

Slice Slice::fullbyte() const {
    Slice rv;
    if (field) {
        auto &alloc = field->for_bit(lo);
        rv.reg = alloc.container;
        rv.lo = lo - alloc.field_bit + alloc.container_bit;
        rv.hi = rv.lo + hi - lo;
    } else {
        rv = *this; }
    rv.lo &= ~7;
    rv.hi |= 7;
    return rv;
}

vector<Slice> Slice::split(const Slice &a, bool &split) {
    vector<Slice> vec;
    if (field != a.field) {
        vec.push_back(*this);
        split = false;
    } else {
        if (a.lo > lo && a.lo <= hi) {
           vec.emplace_back(field, lo, a.lo - 1);
           split = true;
        }
        if (a.hi < hi && a.hi >= lo) {
            vec.emplace_back(field, a.hi + 1, hi);
            split = true;
        }
        if (a.hi == hi && a.lo == lo) {
            split = true;
            return vec;
        }

        if ((a.hi >= hi && a.lo < lo) || (a.hi > hi && a.lo <= lo)) {
            BUG("Split cannot work on this scenario");
        }
    }
    if (vec.size() == 0) {
        vec.push_back(*this);
        split = false;
    }
    return vec;
}

/* This algorithm is used to split a particular match fields from the ghost fields in the
   hash analysis in the MAU.  (*this) is the slice we want to split, vec are the
   potential ghost bits, the return value is the split slices, and the splitters vector are
   the ghost bits that affect the bits

   For an analysis for O(n^2), this really shouldn't be an issue.  The size of vec will
   be relatively small, and there is a guarantee that at most, the calculations will 
   be on the order of vec.size()^2.  In the only way that this is used, vec can really at most
   be sized about 12, and is almost entirely going to be sized 2-3 on pretty much every
   reasonable table 
*/
vector<Slice> Slice::split(const vector<Slice> &vec, vector<Slice> &splitters) {
    vector<Slice> rv;
    rv.push_back(*this);
    for (auto mid_slice : vec) {
        vector<Slice> temp;
        temp.clear();
        bool ever_split = false;
        for (auto whole_slice : rv) {
            bool split = false;
            vector<Slice> single = whole_slice.split(mid_slice, split);
            temp.insert(temp.end(), single.begin(), single.end());
            if (split)
                ever_split = true;
        }
        if (ever_split)
            splitters.push_back(mid_slice);
        rv = temp;
    }
    return rv;
}
