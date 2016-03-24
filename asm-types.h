#ifndef _asm_types_h_
#define _asm_types_h_

#include <assert.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sstream>
#include "vector.h"

enum gress_t { INGRESS, EGRESS };

struct match_t {
    unsigned long       word0, word1;
#ifdef __cplusplus
    operator bool() const { return (word0 | word1) != 0; }
    bool operator==(const match_t &a) const { return word0 == a.word0 && word1 == a.word1; }
    bool matches(unsigned long v) const {
        return (v | word1) == word1 && ((~v & word1) | word0) == word0; }
    bool matches(const match_t &v) const { assert(0); }
#endif /* __cplusplus */
};

enum value_type { tINT, tBIGINT, tRANGE, tSTR, tMATCH, tVEC, tMAP, tCMD };
extern const char *value_type_desc[];

struct value_t;
struct pair_t;
#ifdef __cplusplus
DECLARE_VECTOR3(value_t, value_t,
    value_t &operator[](int) const;
    value_t *begin() const { return data; }
    value_t *end() const; )
DECLARE_VECTOR3(pair_t, pair_t,
public:
    void push_back(const char *, value_t &&);
    pair_t &operator[](int) const;
    pair_t *operator[](const char *) const;
    pair_t *begin() const { return data; }
    pair_t *end() const;
    )
#else
DECLARE_VECTOR(value_t)
DECLARE_VECTOR(pair_t)
#endif /* __cplusplus */
DECLARE_VECTOR(uintptr_t);

struct value_t {
    enum value_type             type;
    int                         lineno;
    union {
        int                     i;
        VECTOR(uintptr_t)       bigi;
        struct {
            int                 lo;
            int                 hi;
        };
        char                    *s;
        match_t                 m;
        VECTOR(value_t)         vec;
        VECTOR(pair_t)          map;
    };
#ifdef __cplusplus
    value_t &operator[](int i) const {
        assert(type == tVEC || type == tCMD);
        return vec[i]; }
#endif /* __cplusplus */
};

struct pair_t {
    struct value_t      key, value;
#ifdef __cplusplus
    pair_t() = default;
    pair_t(const value_t &k, const value_t &v) : key(k), value(v) {}
#endif /* __cplusplus */
};

void free_value(value_t *p);
const char *value_desc(const value_t *v);
static inline void free_pair(pair_t *p) {
    free_value(&p->key);
    free_value(&p->value); }
bool get_bool(const value_t &v);

#ifdef __cplusplus
bool operator==(const struct value_t &, const struct value_t &);
inline bool operator==(const struct value_t &a, const char *b) {
    if (a.type == tCMD && a.vec.size > 0 && a[0].type == tSTR)
        return !strcmp(a[0].s, b);
    return a.type == tSTR && !strcmp(a.s, b); }
inline bool operator==(const char *a, const struct value_t &b) {
    if (b.type == tCMD && b.vec.size > 0 && b[0].type == tSTR)
        return !strcmp(a, b[0].s);
    return b.type == tSTR && !strcmp(a, b.s); }
inline bool operator==(const struct value_t &a, int b) {
    return a.type == tINT && a.i == b; }
inline bool operator==(int a, const struct value_t &b) {
    return b.type == tINT && a == b.i; }

inline const char *value_desc(value_t &v) { return value_desc(&v); }

template<class A, class B> inline bool operator !=(A a, B b)
    { return !(a == b); }

inline value_t &VECTOR(value_t)::operator[](int i) const {
    assert(i >= 0 && i < size);
    return data[i]; }
inline value_t *VECTOR(value_t)::end() const { return data + size; }
inline pair_t &VECTOR(pair_t)::operator[](int i) const {
    assert(i >= 0 && i < size);
    return data[i]; }
inline pair_t *VECTOR(pair_t)::operator[](const char *k) const {
    for (int i = 0; i < size; i++)
        if (data[i].key == k) return &data[i];
    return 0; }
inline pair_t *VECTOR(pair_t)::end() const { return data + size; }

/* can't call VECTOR(pair_t)::push_back directly except from the compilation unit where
 * it is defined, due to gcc bug.  Workaround via global function */
extern void push_back(VECTOR(pair_t) &m, const char *s, value_t &&v);

inline void fini(value_t &v) { free_value(&v); }
inline void fini(pair_t &p) { free_pair(&p); }
inline void fini(VECTOR(value_t) &v) { VECTOR_foreach(v, free_value); VECTOR_fini(v); }
inline void fini(VECTOR(pair_t) &v) { VECTOR_foreach(v, free_pair); VECTOR_fini(v); }
#endif /* __cplusplus */

#define CHECKTYPE(V, T) \
    ((V).type == (T) || \
     (error((V).lineno, "Syntax error, expecting %s", \
            value_type_desc[T]), 0))
#define PCHECKTYPE(P, V, T) \
    (((P) && (V).type == (T)) || \
     (error((V).lineno, "Syntax error, expecting %s", \
            value_type_desc[T]), 0))
#define CHECKTYPEM(V, T, M) \
    ((V).type == (T) || \
     (error((V).lineno, "Syntax error, expecting %s", M), 0))
#define CHECKTYPEPM(V, T, P, M) \
    (((V).type == (T) && (P)) || \
     (error((V).lineno, "Syntax error, expecting %s", M), 0))
#define PCHECKTYPEM(P, V, T, M) \
    (((P) && (V).type == (T)) || \
     (error((V).lineno, "Syntax error, expecting %s", M), 0))
#define CHECKTYPE2(V, T1, T2) \
    ((V).type == (T1) || (V).type == (T2) || \
     (error((V).lineno, "Syntax error, expecting %s or %s", \
            value_type_desc[T1], value_type_desc[T2]), 0))
#define CHECKTYPE2M(V, T1, T2, M) \
    ((V).type == (T1) || (V).type == (T2) || \
     (error((V).lineno, "Syntax error, expecting %s", M), 0))
#define PCHECKTYPE2M(P, V, T1, T2, M) \
    (((P) && ((V).type == (T1) || (V).type == (T2))) || \
     (error((V).lineno, "Syntax error, expecting %s", M), 0))
#define VALIDATE_RANGE(V) \
    ((V).type != tRANGE || (V).lo <= (V).hi || \
     (error((V).lineno, "Invalid range %d..%d", (V).lo, (V).hi), 0))

inline value_t *get(VECTOR(pair_t) &map, const char *key) {
    for (auto &kv : map) if (kv.key == key) return &kv.value;
    return 0; }
inline const value_t *get(const VECTOR(pair_t) &map, const char *key) {
    for (auto &kv : map) if (kv.key == key) return &kv.value;
    return 0; }

#ifdef __cplusplus
#include <functional>
#include <iostream>
#include "map.h"
#include "tfas.h"
#include "bitops.h"

std::ostream &operator<<(std::ostream &out, match_t m);
void print_match(FILE *fp, match_t m);

inline std::ostream &operator<<(std::ostream &out, gress_t gress) {
    switch (gress) {
    case INGRESS: out << "ingress"; break;
    case EGRESS: out << "egress"; break;
    default: out << "(invalid gress " << (int)gress << ")"; }
    return out; }

class MapIterChecked {
/* Iterate through a map (VECTOR(pair_t)), giving errors for non-string and
 * duplicate keys (and skipping them) */
    const VECTOR(pair_t) &map;
    bool        allow;
    std::map<const char *, int, std::function<bool(const char *, const char *)>>
        keys_seen;
    class iter {
        MapIterChecked  *self;
        pair_t          *p;
        void check() {
            while (p != self->map.end()) {
                if (self->allow && p->key.type != tSTR) break;
                if (!CHECKTYPE(p->key, tSTR)) { p++; continue; }
                if (get(self->keys_seen, p->key.s)) {
                    error(p->key.lineno, "Duplicate element %s", p->key.s);
                    warning(self->keys_seen[p->key.s], "previous element %s",
                            p->key.s);
                    p++;
                    continue; }
                self->keys_seen[p->key.s] = p->key.lineno;
                break; } }
    public:
        iter(MapIterChecked *s, pair_t *p_) : self(s), p(p_) {}
        pair_t &operator*() const { return *p; }
        pair_t *operator->() const { return p; }
        bool operator==(iter &a) const { return p == a.p; }
        iter &operator++() { p++; check(); return *this; } };
public:
    MapIterChecked(const VECTOR(pair_t) &map_, bool o=false) : map(map_), allow(o),
        keys_seen([](const char *a, const char *b) { return strcmp(a,b)<0; }) {}
    iter begin() { return iter(this, map.begin()); }
    iter end() { return iter(this, map.end()); }
};

class MatchIter {
/* Iterate through the integers that match a match_t */
    match_t     m;
    class iter : public MaskCounter {
        MatchIter       *self;
    public:
        iter(MatchIter *s) : MaskCounter(s->m.word0 & s->m.word1), self(s) {
            if (!(self->m.word1 | self->m.word0)) overflow(); }
        unsigned operator *() const {
            return this->operator unsigned() | (self->m.word1 & ~ self->m.word0); }
        iter &end() { overflow();  return *this; }
    };
public:
    MatchIter(match_t m_) : m(m_) {}
    iter begin() { return iter(this); }
    iter end() { return iter(this).end(); }
};

class SrcInfo {
    int lineno;
    friend std::ostream &operator<<(std::ostream &, const SrcInfo &);
public:
    SrcInfo(int l) : lineno(l) {}
};

#endif /* __cplusplus */

#endif /* _asm_types_h_ */
