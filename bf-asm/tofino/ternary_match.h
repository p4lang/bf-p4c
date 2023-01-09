#ifndef BF_ASM_TOFINO_TERNARY_MATCH_H_
#define BF_ASM_TOFINO_TERNARY_MATCH_H_

#include <tables.h>

class Target::Tofino::TernaryMatchTable : public ::TernaryMatchTable {
    friend class ::TernaryMatchTable;
    TernaryMatchTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::TernaryMatchTable(line, n, gr, s, lid) { }

    void pass1() override;
    void check_tcam_match_bus(const std::vector<Table::Layout> &);
};

class Target::Tofino::TernaryIndirectTable : public ::TernaryIndirectTable {
    friend class ::TernaryIndirectTable;
    TernaryIndirectTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::TernaryIndirectTable(line, n, gr, s, lid) { }

    void pass1() override;
};

#endif /* BF_ASM_TOFINO_TERNARY_MATCH_H_ */
