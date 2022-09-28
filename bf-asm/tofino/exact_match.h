#ifndef BF_ASM_TOFINO_EXACT_MATCH_H_
#define BF_ASM_TOFINO_EXACT_MATCH_H_

#include <tables.h>

class Target::Tofino::ExactMatchTable : public ::ExactMatchTable {
    friend class ::ExactMatchTable;
    ExactMatchTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::ExactMatchTable(line, n, gr, s, lid) { }

    void setup_ways() override;
};

#endif /* BF_ASM_TOFINO_EXACT_MATCH_H_ */
