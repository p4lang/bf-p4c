#include "hash_action.h"

template<> void HashActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    // error(lineno, "%s:%d: Flatrock hash_action not implemented yet!", SRCFILE, __LINE__);
    LOG1("### Hash Action " << name() << " write_regs " << loc());
    int bus_type;
    if (physical_ids.getrange(0, 8)) {
        bus_type = 1;
        BUG_CHECK(physical_ids.ffs(8) == -1, "hash action %s using both exact and "
                  "ternary physical ids", name());
    } else if (physical_ids.ffs(8) >= 8) {
        bus_type = 0;
    } else {
        BUG("hash action %s using neither exact nor ternary physical ids", name());
    }
    MatchTable::write_regs(regs, bus_type, this);
    if (actions) actions->write_regs(regs, this);
    if (idletime) idletime->write_regs(regs);
    if (gateway) gateway->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}
template void HashActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
