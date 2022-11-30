#ifndef BF_ASM_FLATROCK_STATEFUL_H_
#define BF_ASM_FLATROCK_STATEFUL_H_

#include <tables.h>
#include <target.h>

#if HAVE_FLATROCK

class Target::Flatrock::StatefulTable : public ::StatefulTable {
    void pass1() override;
    void pass2() override;

 public:
    StatefulTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::StatefulTable(line, n, gr, s, lid) { }

    unsigned get_alu_index() const override {
        BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
        return *physical_ids.begin(); }
    int stm_vbus_column() const override {
        BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
        return *physical_ids.begin() + 1; }
};

template<> void StatefulTable::write_logging_regs(Target::Flatrock::mau_regs &regs);
template<> void StatefulTable::write_action_regs_vt(Target::Flatrock::mau_regs &regs,
            const Actions::Action *act);
template<> void StatefulTable::write_merge_regs_vt(Target::Flatrock::mau_regs &regs,
            MatchTable *match, int type, int bus, const std::vector<Call::Arg> &args);
template<> void StatefulTable::write_regs_vt(Target::Flatrock::mau_regs &regs);

#endif  /* HAVE_FLATROCK */
#endif  /* BF_ASM_FLATROCK_STATEFUL_H_ */
