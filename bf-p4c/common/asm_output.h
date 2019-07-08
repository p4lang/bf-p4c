#ifndef BF_P4C_COMMON_ASM_OUTPUT_H_
#define BF_P4C_COMMON_ASM_OUTPUT_H_

#include <map>
#include "lib/ordered_map.h"
#include "lib/safe_vector.h"
#include "lib/stringref.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/bf-p4c-options.h"

StringRef trim_asm_name(StringRef name);

class canon_name {
    StringRef   name;
    friend std::ostream &operator<<(std::ostream &, canon_name);
 public:
    explicit canon_name(StringRef n) : name(n) {}
    explicit canon_name(cstring n) : name(n) {}
    explicit canon_name(IR::ID n) : name(n.name) {}

    operator cstring() const { return cstring::to_cstring(*this); }
};

class Slice {
    const PHV::Field        *field;
    PHV::Container              reg;
    int                         lo, hi;
    friend std::ostream &operator<<(std::ostream &, const Slice &);
    Slice &invalidate() { field = 0; reg = PHV::Container(); lo = -1; hi = -2; return *this; }

 public:
    Slice() : field(0), lo(-1), hi(-2) {}   // hi = -2 to make width() = 0
    explicit Slice(const PHV::Field *f) : field(f), lo(0), hi(f->size-1) {}
    Slice(const PHV::Field *f, int bit) : field(f), lo(bit), hi(bit) {}
    Slice(const PHV::Field *f, int l, int h) : field(f), lo(l), hi(h) {}
    Slice(const PHV::Field *f, le_bitrange r) : field(f), lo(r.lo), hi(r.hi) {}
    Slice(const PhvInfo &phv, cstring n)
    : field(phv.field(n)), lo(0), hi(field->size-1) {}
    Slice(const PhvInfo &phv, cstring n, int bit)
    : field(phv.field(n)), lo(bit), hi(bit) {
        BUG_CHECK((bit >= 0 && bit < field->size),
            "Slice out of range for field = '%s', bit=%d, size=%d",
            field->name, bit, field->size); }
    Slice(const PhvInfo &phv, cstring n, int l, int h)
    : field(phv.field(n)), lo(l), hi(h) {
        BUG_CHECK((lo < field->size),
            "Slice out of range for field = '%s', lo=%d, size=%d",
            field->name, lo, field->size);
        if (lo < 0) lo = 0;
        if (hi >= field->size) hi = field->size-1; }
    explicit Slice(PHV::Container r) : field(0), reg(r), lo(0), hi(r.size()-1) {}
    Slice(PHV::Container r, int bit) : field(0), reg(r), lo(bit), hi(bit) {}
    Slice(PHV::Container r, int lo, int hi) : field(0), reg(r), lo(lo), hi(hi) {}
    Slice(const Slice &s, int bit)
    : field(s.field), reg(s.reg), lo(s.lo + bit), hi(lo) {}
    Slice(const Slice &s, int l, int h)
    : field(s.field), reg(s.reg), lo(s.lo + l), hi(s.lo + h) {
        if (hi > s.hi) hi = s.hi;
        if (!field || lo > hi) invalidate(); }
    explicit operator bool() const { return field != nullptr || reg; }
    Slice operator()(int bit) const { return Slice(*this, bit); }
    Slice operator()(int l, int h) const { return Slice(*this, l, h); }
    Slice join(Slice &a) const;
    Slice &operator-=(const Slice &a) {
        if (field != a.field || reg != a.reg || hi < a.lo || lo > a.hi) return *this;
        if (a.lo <= lo) lo = a.hi+1;
        if (a.hi >= hi) hi = a.lo-1;
        if (lo > hi) invalidate();
        return *this; }
    Slice &operator-=(const std::vector<Slice> &a) {
        for (auto &v : a) *this -= v;
        return *this; }
    Slice operator-(const Slice &a) const { auto tmp = *this; tmp -= a; return tmp; }
    Slice operator-(const std::vector<Slice> &a) const { auto tmp = *this; tmp -= a; return tmp; }
    Slice &operator&=(const Slice &a) {
        if (field != a.field || reg != a.reg) return invalidate();
        if (a.lo > lo) lo = a.lo;
        if (a.hi < hi) hi = a.hi;
        if (lo > hi) invalidate();
        return *this; }
    Slice operator&(const Slice &a) const { auto tmp = *this; tmp &= a; return tmp; }
    safe_vector<Slice> split(const Slice &a, bool &split);
    safe_vector<Slice> split(const safe_vector<Slice> &vec,
                             safe_vector<Slice> &splitters);
    int width() const { return hi - lo + 1; }
    int bytealign() const;
    Slice fullbyte() const;
    const PHV::Field *get_field() const { return field; }
    int get_lo() const { return lo; }
    int get_hi() const { return hi; }
    void shrink_lo(int shrink) {
        if (shrink + lo >= hi)
            lo = hi;
        else
            lo += shrink;
    }
    le_bitrange range() const { return { lo, hi}; }
    void shrink_hi(int shrink) {
        if (hi - shrink <= lo)
            hi = lo;
        else
            hi -= shrink;
    }
};

// Generate the p4 name which gets eventually output in the context.json. In
// multipipe scenarios (P4-16) we want the table names to be fully qualified
// i.e. prefixed with pipe names. This is required to match the names generated
// in bf-rt.json for bf runtime.
cstring gen_p4_name(const cstring pipe, const cstring name);

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

#endif /* BF_P4C_COMMON_ASM_OUTPUT_H_ */
