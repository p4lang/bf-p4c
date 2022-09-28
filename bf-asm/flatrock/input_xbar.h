#ifndef BF_ASM_FLATROCK_INPUT_XBAR_H_
#define BF_ASM_FLATROCK_INPUT_XBAR_H_

#include <input_xbar.h>
#include "tables.h"

#if HAVE_FLATROCK
template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs);
template<> void InputXbar::write_xmu_regs(Target::Flatrock::mau_regs &regs);

namespace Flatrock {

class InputXbar : public ::InputXbar {
    enum { XMU_UNITS = 8,  FIRST_STM_XMU = 4,   // 0-3 are LAMB and 4-7 are STM
           XME_UNITS = 16, FIRST_STM_XME = 8,   // 0-7 are LAMB and 8-15 are STM
           EXACT_HASH_SIZE = 160,
    };

    bitvec      dconfig;
    bitvec      xme_units;
    int         output_unit = -1;
    unsigned    first8 = 0, num8 = 0, first32 = 0, num32 = 0;

    friend class ::InputXbar;
    void check_input(Group group, Input &input, TcamUseCache &tcam_use) override;
    int group_max_index(Group::type_t t) const override;
    Group group_name(bool ternary, const value_t &value) const override;
    int group_size(Group::type_t t) const override;
    bool parse_unit(Table *t, const pair_t &kv) override;
    unsigned exact_physical_ids() const override;

    void pass2() override;

    InputXbar(Table *table, const value_t *key);
    template<class REG> void setup_byte_ixbar(REG &reg, const Input &input, int offset);
    template<class REG> void setup_byte_ixbar_gw(REG &reg, const Input &input);
    void write_regs_v(Target::Flatrock::mau_regs &regs) override;
    void write_xmu_regs_v(Target::Flatrock::mau_regs &regs) override;

    struct xme_cfg_info_t;
    void find_xme_info(xme_cfg_info_t &info, const SRamMatchTable::Way *way);
    void write_xmu_key_mux(Target::Flatrock::mau_regs::_ppu_eml &);
    void write_xmu_key_mux(Target::Flatrock::mau_regs::_ppu_ems &);
    void write_xme_regs(Target::Flatrock::mau_regs::_ppu_eml &, int);
    void write_xme_regs(Target::Flatrock::mau_regs::_ppu_ems &, int);

 public:
    static void write_global_regs(Target::Flatrock::mau_regs &regs, gress_t gress);
    std::vector<const Input *> find_hash_inputs(Phv::Slice sl, HashTable ht) const override {
        return find_all(sl, hashtable_input_group(ht)); }
    int find_offset(const MatchSource *, Group) const override;
    Phv::Ref get_hashtable_bit(HashTable id, unsigned bit) const override {
        return get_group_bit(hashtable_input_group(id), bit); }
    int global_bit_position_adjust(HashTable ht) const override {
        BUG_CHECK(ht.type == HashTable::EXACT, "not an exact hash table %d", ht.type);
        return ht.index * EXACT_HASH_SIZE; }
    bitvec global_column0_extract(HashTable ht,
        const hash_column_t matrix[PARITY_GROUPS_DYN][HASH_MATRIX_WIDTH_DYN]) const override;
    Group hashtable_input_group(HashTable ht) const override;
    void setup_match_key_cfg(const MatchSource *) override;
};

}
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_INPUT_XBAR_H_ */
