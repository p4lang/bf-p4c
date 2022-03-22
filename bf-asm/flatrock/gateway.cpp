#include "gateway.h"
#include "input_xbar.h"  // FIXME needed only in unified build to ensure proper specialization

template<> void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Gateway table " << name() << " write_regs " << loc());
    for (auto &ixb : input_xbar)
        ixb->write_regs(regs);

    error(lineno, "%s:%d: Flatrock gateway not implemented yet!", __FILE__, __LINE__);
}
template void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
