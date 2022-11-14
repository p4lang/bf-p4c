#ifndef BF_ASM_FLATROCK_ACTION_TABLE_H_
#define BF_ASM_FLATROCK_ACTION_TABLE_H_

#include "tables.h"

#if HAVE_FLATROCK

template<> void ActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs);

class Target::Flatrock::ActionTable : public ::ActionTable {
    void pass1();
    void pass2();
    void pass3();
    unsigned determine_shiftcount(Table::Call &call, int, unsigned, int) const override;

    int badb_start = -1, badb_size = 0, wadb_start = -1, wadb_size = 0;

    void write_regs(Target::Flatrock::mau_regs &regs) override;

 public:
    ActionTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::ActionTable(line, n, gr, s, lid) { }

    int stm_vbus_column() const override {
        BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
        return *physical_ids.begin() + 1; }
};

#endif

#endif  /* BF_ASM_FLATROCK_ACTION_TABLE_H_ */
