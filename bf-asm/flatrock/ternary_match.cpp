#include "ternary_match.h"

template<> void TernaryMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Ternary match table " << name() << " write_regs " << loc());
    MatchTable::write_regs(regs, 1, indirect);
    if (layout_size() != 0) {
        error(lineno, "%s:%d: Flatrock non-empty ternary match not implemented yet!",
              __FILE__, __LINE__); }
    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

template<> void TernaryIndirectTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Ternary indirect table " << name() << " write_regs");
    if (layout_size() != 0) {
        error(lineno, "%s:%d: Flatrock non-empty ternary indirect not implemented yet!",
              __FILE__, __LINE__); }
    if (actions) actions->write_regs(regs, this);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

