#ifndef BF_ASM_FLATROCK_INPUT_XBAR_H_
#define BF_ASM_FLATROCK_INPUT_XBAR_H_

#include <input_xbar.h>

#if HAVE_FLATROCK
template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs);

namespace Flatrock {

class InputXbar : public ::InputXbar {
    friend class ::InputXbar;
    int group_max_index(Group::type_t t) const override;
    Group group_name(bool ternary, const value_t &value) const override;
    int group_size(Group::type_t t) const override;

    InputXbar(Table *table, int lineno) : ::InputXbar(table, lineno) {}
};

}
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_INPUT_XBAR_H_ */
