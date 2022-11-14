#ifndef BF_ASM_FLATROCK_EXACT_MATCH_H_
#define BF_ASM_FLATROCK_EXACT_MATCH_H_

#include <tables.h>

#if HAVE_FLATROCK
class Target::Flatrock::ExactMatchTable : public ::ExactMatchTable {
    friend class ::ExactMatchTable;
    ExactMatchTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::ExactMatchTable(line, n, gr, s, lid) { }

    void pass1() override;
    void setup_ways() override;
};

template<> void ExactMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
#endif  /* HAVE_FLATROCK */

#endif  /* BF_ASM_FLATROCK_EXACT_MATCH_H_ */
