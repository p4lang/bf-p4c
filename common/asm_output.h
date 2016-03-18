#ifndef _TOFINO_COMMON_ASM_OUTPUT_H_
#define _TOFINO_COMMON_ASM_OUTPUT_H_

#include <map>
#include "lib/ordered_map.h"
#include "lib/stringref.h"
#include "tofino/phv/phv_fields.h"

StringRef trim_asm_name(StringRef name);

class canon_name {
    StringRef   name;
    friend std::ostream &operator<<(std::ostream &, canon_name);
 public:
    explicit canon_name(StringRef n) : name(n) {}
};

class Slice {
    const PhvInfo::Info *field;
    int                 lo, hi;
    friend std::ostream &operator<<(std::ostream &, const Slice &);
    Slice &invalidate() { field=0; lo=-1; hi=-2; return *this; }

 public:
    Slice() : field(0), lo(-1), hi(-2) {}   // hi = -2 to make width() = 0
    explicit Slice(const PhvInfo::Info *f) : field(f), lo(0), hi(f->size-1) {}
    Slice(const PhvInfo::Info *f, int bit) : field(f), lo(bit), hi(bit) {}
    Slice(const PhvInfo::Info *f, int l, int h) : field(f), lo(l), hi(h) {}
    Slice(const PhvInfo &phv, cstring n) : field(phv.field(n)), lo(0), hi(field->size-1) {}
    Slice(const PhvInfo &phv, cstring n, int bit) : field(phv.field(n)), lo(bit), hi(bit) {}
    Slice(const PhvInfo &phv, cstring n, int l, int h) : field(phv.field(n)), lo(l), hi(h) {}
    Slice(const Slice &s, int bit) : field(s.field), lo(s.lo + bit), hi(lo) {}
    Slice(const Slice &s, int l, int h) : field(s.field), lo(s.lo + l), hi(s.lo + h) {
        if (hi > s.hi) hi = s.hi;
        if (!field || lo > hi) invalidate(); }
    explicit operator bool() const { return field != nullptr; }
    Slice operator()(int bit) const { return Slice(*this, bit); }
    Slice operator()(int l, int h) const { return Slice(*this, l, h); }
    Slice join(Slice &a) const {
        if (field != a.field || hi + 1 != a.lo) return Slice();
        return Slice(field, lo, a.hi); }
    Slice &operator-=(const Slice &a) {
        if (field != a.field || hi < a.lo || lo > a.hi) return *this;
        if (a.lo <= lo) lo = a.hi+1;
        if (a.hi >= hi) hi = a.lo-1;
        if (lo > hi) invalidate();
        return *this; }
    Slice operator-(const Slice &a) const { auto tmp = *this; tmp -= a; return tmp; }
    Slice &operator&=(const Slice &a) {
        if (field != a.field) return invalidate();
        if (a.lo > lo) lo = a.lo;
        if (a.hi < hi) hi = a.hi;
        if (lo > hi) invalidate();
        return *this; }
    Slice operator&(const Slice &a) const { auto tmp = *this; tmp &= a; return tmp; }
    int width() const { return hi - lo + 1; }
    int bytealign() const { return lo & 7; }
};

inline std::ostream &operator<<(std::ostream &out, const Slice &sl) {
    out << canon_name(trim_asm_name(sl.field->name));
    if (sl.lo > 0 || sl.hi != sl.field->size - 1) {
        out << '(' << sl.lo;
        if (sl.hi > sl.lo) out << ".." << sl.hi;
        out << ')'; }
    return out;
}

/* The rest of this is pretty generic formatting stuff -- should be in lib somewhere? */

template<class K, class V> std::ostream &operator<<(std::ostream &out, const std::map<K, V> &m) {
    const char *sep = " ";
    out << "{";
    for (const auto &kv : m) {
        out << sep << kv.first << ": " << kv.second;
        sep = ", "; }
    out << (sep+1) << "}";
    return out;
}

template<class K, class V> std::ostream &operator<<(std::ostream &out, const ordered_map<K, V> &m) {
    const char *sep = " ";
    out << "{";
    for (const auto &kv : m) {
        out << sep << kv.first << ": " << kv.second;
        sep = ", "; }
    out << "}";
    return out;
}

template<class VEC>
struct emit_vector_formatter {
    const VEC &vec;
    const char *sep;
};

template<class VEC>
std::ostream &operator<<(std::ostream &out, const emit_vector_formatter<VEC> &v) {
    const char *sep = "";
    for (const auto &el : v.vec) {
        out << sep << el;
        sep = v.sep; }
    return out; }

template<class VEC>
emit_vector_formatter<VEC> emit_vector(const VEC &v, const char *sep = ", ") {
    return emit_vector_formatter<VEC>{v, sep}; }

template<class T> inline auto operator<<(std::ostream &out, const T &obj) ->
        decltype((void)obj.print(out), out)
{ obj.print(out); return out; }

template<class T> inline auto operator<<(std::ostream &out, const T *obj) ->
        decltype((void)obj->print(out), out) {
    if (obj)
        obj->print(out);
    else
        out << "<null>";
    return out; }


#endif /* _TOFINO_COMMON_ASM_OUTPUT_H_ */
