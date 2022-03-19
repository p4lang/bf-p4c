#ifndef BF_ASM_FLATROCK_INPUT_XBAR_H_
#define BF_ASM_FLATROCK_INPUT_XBAR_H_

#include <input_xbar.h>

#if HAVE_FLATROCK
template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs);

namespace Flatrock {

class InputXbar : public ::InputXbar {
    enum { XMU_UNITS = 8 };

    bitvec      xmu_units;

    friend class ::InputXbar;
    void check_input(Group group, Input &input, TcamUseCache &tcam_use) override;
    int group_max_index(Group::type_t t) const override;
    Group group_name(bool ternary, const value_t &value) const override;
    int group_size(Group::type_t t) const override;
    bool parse_unit(Table *t, const pair_t &kv) override;

    InputXbar(Table *table, int lineno) : ::InputXbar(table, lineno) {}
    void write_regs_v(Target::Flatrock::mau_regs &regs) override;
};

}
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_INPUT_XBAR_H_ */
