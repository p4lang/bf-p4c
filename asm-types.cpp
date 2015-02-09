#include "asm-types.h"
#include <assert.h>
#include <stdlib.h>
#include <stdlib.h>

static int chkmask(const match_t &m, int maskbits) {
    unsigned long mask = (1U << maskbits) - 1;
    int shift = 0;
    while (mask && ((m.word0|m.word1) >> shift)) {
        if ((mask & m.word0 & m.word1) && (mask & m.word0 & m.word1) != mask)
            return -1;
        mask <<= maskbits;
        shift += maskbits; }
    return shift - maskbits;
}

std::ostream &operator<<(std::ostream &out, match_t m) {
    int shift, bits;
    if ((shift = chkmask(m, (bits = 4))) >= 0)
        out << "0x";
    else if ((shift = chkmask(m, (bits = 3))) >= 0)
        out << "0o";
    else if ((shift = chkmask(m, (bits = 1))) >= 0)
        out << "0b";
    else
        assert(0);
    unsigned long mask = ((1U << bits) - 1) << shift;
    for (; mask; shift -= bits, mask >>= bits)
        if (mask & m.word0 & m.word1)
            out << '*';
        else
            out << "0123456789abcdef"[(m.word1 >> shift) & mask];
    return out;
}

const char *value_type_desc[] = {
    "integer", "bigint", "range", "identifier", "match pattern", "list",
    "key: value pairs", "operation"
};

const char *value_desc(value_t *p) {
    static char buffer[32];
    switch(p->type) {
    case tINT: sprintf(buffer, "%d", p->i); return buffer;
    case tBIGINT: return "<bigint>";
    case tRANGE: sprintf(buffer, "%d..%d", p->lo, p->hi); return buffer;
    case tMATCH: return "<pattern>";
    case tSTR: return p->s;
    case tVEC: return "<list>";
    case tMAP: return "<map>";
    case tCMD:
        if (p->vec.size > 0 && p->vec.data[0].type == tSTR)
            return p->vec.data[0].s;
        return "<cmd>"; }
    assert(0);
}

void free_value(value_t *p) {
    switch(p->type) {
    case tBIGINT: VECTOR_fini(p->bigi); break;
    case tSTR: free(p->s); break;
    case tVEC: case tCMD:
        VECTOR_foreach(p->vec, free_value);
        VECTOR_fini(p->vec);
        break;
    case tMAP:
        VECTOR_foreach(p->map, free_pair);
        VECTOR_fini(p->map);
        break;
    default:
        break; }
}

bool operator==(const struct value_t &a, const struct value_t &b) {
    int i;
    if (a.type != b.type) {
        if (a.type == tINT && b.type == tBIGINT) {
            if (a.i < 0 || (size_t)a.i != b.bigi.data[0]) return false;
            for (i = 1; i < b.bigi.size; i++)
                if (b.bigi.data[i]) return false;
            return true;
        } else if (a.type == tBIGINT && b.type == tINT) {
            if (b.i < 0 || (size_t)b.i != a.bigi.data[0]) return false;
            for (i = 1; i < a.bigi.size; i++)
                if (a.bigi.data[i]) return false;
            return true; }
        return false; }
    switch(a.type) {
    case tINT: return a.i == b.i;
    case tBIGINT:
        for (i = 0; i < a.bigi.size && i < b.bigi.size; i++)
            if (a.bigi.data[i] != b.bigi.data[i]) return false;
        for (; i < a.bigi.size; i++)
            if (a.bigi.data[i]) return false;
        for (; i < b.bigi.size; i++)
            if (b.bigi.data[i]) return false;
        return true;
    case tRANGE: return a.lo == b.lo && a.hi == b.hi;
    case tSTR: return !strcmp(a.s, b.s);
    case tMATCH: return a.m.word0 == b.m.word0 && a.m.word1 == b.m.word1;
    case tVEC: case tCMD:
        if (a.vec.size != b.vec.size) return false;
        for (int i = 0; i < a.vec.size; i++)
            if (a.vec.data[i] != b.vec.data[i]) return false;
        return true;
    case tMAP:
        if (a.map.size != b.map.size) return false;
        for (int i = 0; i < a.map.size; i++) {
            if (a.map.data[i].key != b.map.data[i].key) return false;
            if (a.map.data[i].value != b.map.data[i].value) return false; }
        return true; }
    assert(0);
}
