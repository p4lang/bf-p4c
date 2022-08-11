#ifndef BF_ASM_FLATROCK_GATEWAY_H_
#define BF_ASM_FLATROCK_GATEWAY_H_

#include <tables.h>

#if HAVE_FLATROCK
class Target::Flatrock::GatewayTable : public ::GatewayTable {
    friend class ::GatewayTable;
    GatewayTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::GatewayTable(line, n, gr, s, lid) { }
    void pass1() override;
    // void pass2() override;  -- not needed (yet?)
    // void pass2() override;  -- not needed (yet?)

    int gw_memory_unit() const override { return layout[0].row; }
};

template<> void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_GATEWAY_H_ */
