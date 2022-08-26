#ifndef BF_ASM_TOFINO_GATEWAY_H_
#define BF_ASM_TOFINO_GATEWAY_H_

#include <tables.h>

class Target::Tofino::GatewayTable : public ::GatewayTable {
    friend class ::GatewayTable;
    GatewayTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::GatewayTable(line, n, gr, s, lid) { }

    void pass1() override;
    void pass2() override;
    void pass3() override;

    int gw_memory_unit() const override { return layout[0].row * 2 + gw_unit; }
    REGSETS_IN_CLASS(Tofino, TARGET_OVERLOAD,
        void write_next_table_regs, (mau_regs &), override; )
};

template<class REGS> void enable_gateway_payload_exact_shift_ovr(REGS &regs, int bus);
template<> void enable_gateway_payload_exact_shift_ovr(Target::Tofino::mau_regs &regs, int bus);

#endif /* BF_ASM_TOFINO_GATEWAY_H_ */
