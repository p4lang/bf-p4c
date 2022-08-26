#include "ternary_match.h"

template<> void TernaryMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Ternary match table " << name() << " write_regs " << loc());
    MatchTable::write_regs(regs, 1, indirect);
    error(lineno, "%s:%d: Flatrock ternary match not implemented yet!", SRCFILE, __LINE__);
}

template<> void TernaryIndirectTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Ternary indirect table " << name() << " write_regs");
    error(lineno, "%s:%d: Flatrock ternary indirect not implemented yet!", SRCFILE, __LINE__);
    if (actions) actions->write_regs(regs, this);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

