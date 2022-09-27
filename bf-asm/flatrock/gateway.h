#ifndef BF_ASM_FLATROCK_GATEWAY_H_
#define BF_ASM_FLATROCK_GATEWAY_H_

#include <tables.h>

#if HAVE_FLATROCK
class Target::Flatrock::GatewayTable : public ::GatewayTable {
    friend class ::GatewayTable;
    static constexpr int GATEWAY_VECTOR_BYTES = 8;
    static constexpr int GATEWAY_FIXED_BYTES = 5;

    GatewayTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::GatewayTable(line, n, gr, s, lid) { }
    void pass1() override;
    void pass2() override;
    // void pass2() override;  -- not needed (yet?)
    int find_next_lut_entry(Table *tbl, const Match &match) override;
    void setup_map_indexing(Table *tbl) override;

    bool check_match_key(MatchKey &, const std::vector<MatchKey> &, bool) override;
    int gw_memory_unit() const override { return layout[0].row; }
    REGSETS_IN_CLASS(Flatrock, TARGET_OVERLOAD,
        void write_next_table_regs, (mau_regs &), override; )
    REGSETS_IN_CLASS(Flatrock, TARGET_OVERLOAD,
        void write_regs, (mau_regs &), override; )

    // tracking which bytes we care about and what the xor bits for them should be.
    unsigned byte_use = 0, byte_xor_value = 0;
    // what match values are needed in each vector byte
    struct byte_match_t {
        int             lineno;
        uint8_t         word0, word1;
    };
    std::map<int, byte_match_t> byte_matches;

    // Flatrock needs to use the same inhibit index for next table and action to run, so
    // we need to correlate the next table map indexes to the actions
    std::map<int, std::string>          inhibit_idx_action;
};

// should never be called as we override write_regs above
template<> void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &);
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_GATEWAY_H_ */
