#ifndef BF_ASM_TOFINO_ACTION_TABLE_H_
#define BF_ASM_TOFINO_ACTION_TABLE_H_

#include "tables.h"

class Target::Tofino::ActionTable : public ::ActionTable {
    friend class ::ActionTable;
    ActionTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::ActionTable(line, n, gr, s, lid) { }
};

#endif  /* BF_ASM_TOFINO_ACTION_TABLE_H_ */
