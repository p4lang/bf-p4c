#ifndef BF_ASM_FLATROCK_COUNTER_H_
#define BF_ASM_FLATROCK_COUNTER_H_

#include <tables.h>

#if HAVE_FLATROCK

class Target::Flatrock::CounterTable : public ::CounterTable {
    void pass1() override;
    void pass2() override;

 public:
    CounterTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::CounterTable(line, n, gr, s, lid) { }

    unsigned get_alu_index() const override {
        BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
        return *physical_ids.begin()/2; }
    int stm_vbus_column() const override {
        BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
        return *physical_ids.begin() + 1; }
};

template<> void CounterTable::write_merge_regs_vt(Target::Flatrock::mau_regs &, MatchTable *,
                int, int, const std::vector<Call::Arg> &);
template<> void CounterTable::write_regs_vt(Target::Flatrock::mau_regs &);

#endif  /* HAVE_FLATROCK */
#endif  /* BF_ASM_FLATROCK_COUNTER_H_ */
