#include "asm-types.h"
#include <assert.h>
#include <stdlib.h>
#include <stdlib.h>

const char *value_type_desc[] = {
    "integer", "bigint", "range", "identifier", "match pattern", "list",
    "key: value pairs", "operation"
};

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
