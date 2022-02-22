/* Flatrock template specializations for instructions #included in salu_inst.cpp
 * WARNING -- this is included in an anonymous namespace, as these SaluInstruction
 * subclasses are all defined in that anonymous namespace */

// FIXME -- this should be compatible with jbay/cloudbreak (as the SALU is essentially
// the same) but the register space may be completely different

void DivMod::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
                        Table::Actions::Action *act) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
}
void MinMax::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
}

template<>
void AluOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
}
void AluOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void BitOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
}
void BitOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void CmpOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
}
void CmpOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void TMatchOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
}
void TMatchOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void OutOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
}
void OutOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

void OutOP::decode_output_mux(Target::Flatrock, Table *tbl, value_t &op) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
}

int OutOP::decode_output_option(Target::Flatrock, value_t &op) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", __FILE__, __LINE__);
    return 0;
}
