/* template specializations for flatrock -- #included directly in exact_match.cpp */

template<> void ExactMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Exact match table " << name() << " write_regs " << loc());
    SRamMatchTable::write_regs(regs);
    error(lineno, "%s:%d: Flatrock exact_match not implemented yet!", __FILE__, __LINE__);
}

