#ifndef BF_ASM_FLATROCK_ACTION_BUS_H_
#define BF_ASM_FLATROCK_ACTION_BUS_H_

#include <action_bus.h>

#if HAVE_FLATROCK

namespace Flatrock {

class ActionBus : public ::ActionBus {
    void write_regs(Target::Flatrock::mau_regs &regs, Table *tbl) override;

 public:
    ActionBus() : ::ActionBus() {}
    ActionBus(Table *tbl, VECTOR(pair_t) &data) : ::ActionBus(tbl, data) {}

    void alloc_field(Table *, ActionBusSource src, unsigned offset, unsigned sizes_needed) override;
};

}  // end namespace Flatrock
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_ACTION_BUS_H_ */
