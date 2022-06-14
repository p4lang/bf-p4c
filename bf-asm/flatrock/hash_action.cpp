#include "hash_action.h"

template<> void HashActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    // error(lineno, "%s:%d: Flatrock hash_action not implemented yet!", __FILE__, __LINE__);
    LOG1("### Hash Action " << name() << " write_regs " << loc());
    int bus_type = physical_id < 8;
    MatchTable::write_regs(regs, bus_type, this);
    if (actions) actions->write_regs(regs, this);
    if (idletime) idletime->write_regs(regs);
    if (gateway) gateway->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}
template void HashActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
