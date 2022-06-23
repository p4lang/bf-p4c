#ifndef BF_ASM_FLATROCK_INPUT_XBAR_H_
#define BF_ASM_FLATROCK_INPUT_XBAR_H_

#include <input_xbar.h>

#if HAVE_FLATROCK
template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs);
template<> void InputXbar::write_xmu_regs(Target::Flatrock::mau_regs &regs);

namespace Flatrock {

class InputXbar : public ::InputXbar {
    enum { XME_UNITS = 16, FIRST_STM_UNIT = 8 };  // 0-7 are LAMB and 8-15 are STM

    bitvec      dconfig;
    bitvec      xme_units;
    unsigned    first8, num8, first32, num32;

    friend class ::InputXbar;
    void check_input(Group group, Input &input, TcamUseCache &tcam_use) override;
    int group_max_index(Group::type_t t) const override;
    Group group_name(bool ternary, const value_t &value) const override;
    int group_size(Group::type_t t) const override;
    bool parse_unit(Table *t, const pair_t &kv) override;
    unsigned exact_physical_ids() const override;

    void pass2() override;

    InputXbar(Table *table, const value_t *key);
    void write_regs_v(Target::Flatrock::mau_regs &regs) override;
    void write_xmu_regs_v(Target::Flatrock::mau_regs &regs) override;

    void write_xmu_key_mux(Target::Flatrock::mau_regs::_ppu_eml &);
    void write_xmu_key_mux(Target::Flatrock::mau_regs::_ppu_ems &);
    void write_xme_regs(Target::Flatrock::mau_regs::_ppu_eml &, int);
    void write_xme_regs(Target::Flatrock::mau_regs::_ppu_ems &, int);

 public:
    static void write_global_regs(Target::Flatrock::mau_regs &regs, gress_t gress);
    std::vector<Input *> find_hash_inputs(Phv::Slice sl, int hash_table) override {
        return find_all(sl, Group(Group::EXACT, hash_table)); }
    int global_bit_position_adjust(int hash_table) const {
        return hash_table * 160; }
};

}
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_INPUT_XBAR_H_ */
