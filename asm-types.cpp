#include "asm-types.h"
#include <assert.h>
#include <stdlib.h>
#include <stdlib.h>

const char *value_type_desc[] = {
    "integer", "range", "identifier", "match pattern", "list", "key: value pairs", "operation"
};

void free_value(value_t *p) {
    switch(p->type) {
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
    if (a.type != b.type) return false;
    switch(a.type) {
    case tINT: return a.i == b.i;
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
