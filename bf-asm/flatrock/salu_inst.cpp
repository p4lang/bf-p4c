/* Flatrock template specializations for instructions #included in salu_inst.cpp
 * WARNING -- this is included in an anonymous namespace, as these SaluInstruction
 * subclasses are all defined in that anonymous namespace */

// FIXME -- this should be compatible with jbay/cloudbreak (as the SALU is essentially
// the same) but the register space may be completely different

void DivMod::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
                        Table::Actions::Action *act) {
    BUG("TBD");
}
void MinMax::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    BUG("TBD");
}

template<>
void AluOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    BUG("TBD");
}
void AluOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void BitOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    BUG("TBD");
}
void BitOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void CmpOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    BUG("TBD");
}
void CmpOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void TMatchOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    BUG("TBD");
}
void TMatchOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void OutOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    BUG("TBD");
}
void OutOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

void OutOP::decode_output_mux(Target::Flatrock, value_t &op) {
    BUG("TBD");
}

int OutOP::decode_output_option(Target::Flatrock, value_t &op) {
    BUG("TBD");
    return 0;
}

bool OutOP::output_mux_is_phv(Target::Flatrock) {
    BUG("TBD");
    return false;
}
