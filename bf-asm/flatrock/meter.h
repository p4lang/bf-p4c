#ifndef BF_ASM_FLATROCK_METER_H_
#define BF_ASM_FLATROCK_METER_H_

#include <tables.h>
#include <target.h>

#if HAVE_FLATROCK

class Target::Flatrock::MeterTable : public ::MeterTable {
    void pass1() override;
    void pass2() override;

 public:
    MeterTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::MeterTable(line, n, gr, s, lid) { }

    unsigned get_alu_index() const override {
        BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
        return *physical_ids.begin()/2; }
    int stm_vbus_column() const override {
        BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
        return *physical_ids.begin() + 1; }
};

template<> void MeterTable::write_merge_regs_vt(Target::Flatrock::mau_regs &regs,
            MatchTable *match, int type, int bus, const std::vector<Call::Arg> &args);

template<> void MeterTable::write_color_regs(Target::Flatrock::mau_regs &regs,
                                             MatchTable *match, int type, int bus,
                                             const std::vector<Call::Arg> &args);

template<> void MeterTable::setup_exact_shift(Target::Flatrock::mau_regs &regs,
                                              int bus, int group, int word, int word_group,
                                              Call &meter_call, Call &color_call);

template<> void MeterTable::setup_tcam_shift(Target::Flatrock::mau_regs &regs,
                                             int bus, int tcam_shift,
                                             Call &meter_call, Call &color_call);

template<> void MeterTable::write_regs_vt(Target::Flatrock::mau_regs &regs);

#endif  /* HAVE_FLATROCK */
#endif  /* BF_ASM_FLATROCK_METER_H_ */
