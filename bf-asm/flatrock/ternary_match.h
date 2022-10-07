#ifndef BF_ASM_FLATROCK_TERNARY_MATCH_H_
#define BF_ASM_FLATROCK_TERNARY_MATCH_H_

#include <tables.h>

#if HAVE_FLATROCK

class Target::Flatrock::TernaryMatchTable : public ::TernaryMatchTable {
    static constexpr int LOCAL_TIND_UNITS = 16;
    static constexpr int LOCAL_TIND_DEPTH = 64;
    static constexpr int LOCAL_TIND_WIDTH = 64;
    static constexpr int TCAM_TABLES_PER_STAGE = 8;
    static constexpr int TCAM_TABLES_WITH_INDIRECT_STM = 4;
    friend class ::TernaryMatchTable;
    TernaryMatchTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::TernaryMatchTable(line, n, gr, s, lid) { }

    std::vector<int>    local_tind_units;

    int memunit(const int r, const int c) const override { return r + c*10; }
    void pass1() override;
    void pass2() override;
    int ram_word_width() const override { return LOCAL_TIND_WIDTH; }
    void setup_indirect(const value_t &v) override;
    void gen_match_fields_pvp(json::vector &, unsigned, bool, unsigned, bitvec &) const override;
    void gen_match_fields(json::vector &, std::vector<bitvec> &) const override;
    void gen_tbl_cfg(json::vector &) const override;
    REGSETS_IN_CLASS(Flatrock, TARGET_OVERLOAD,
        void write_regs, (mau_regs &), override; )
};

template<> void TernaryMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
template<> void TernaryIndirectTable::write_regs_vt(Target::Flatrock::mau_regs &regs);

#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_TERNARY_MATCH_H_ */
